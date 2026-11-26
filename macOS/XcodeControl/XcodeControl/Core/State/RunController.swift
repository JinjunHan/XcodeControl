//
//  RunController.swift
//  XcodeControl
//

import AppKit
import Foundation
import Observation

/// 运行状态机的唯一持有者：build → install → launch → running。
///
/// 关键交互约定：running 状态下再次点击运行 = 停止 + 重新构建运行，
/// 这是最高频的操作路径，必须是一次点击。
@MainActor
@Observable
final class RunController {

    // MARK: - 状态

    private(set) var phase: RunPhase = .idle
    /// 构建已用秒数，用于「Building · 12s」
    private(set) var elapsed: Int = 0

    // MARK: - 依赖

    private let prefs: Preferences
    private let notifications: NotificationService
    private let projects: ProjectStore
    private let devices: DeviceStore
    private let logs: LogStore
    private let buildService = BuildService()

    /// 构建失败时的回调。由 AppState 接上「自动展开日志」——
    /// 状态机不直接改 UI 展开态。
    var onFailure: (() -> Void)?

    /// 成功跑起来之后的回调。由 AppState 接上 DerivedData 自动回收。
    ///
    /// 挂在这里而不是启动时：启动后用户马上要按运行，扫描的磁盘 IO 会和构建抢资源；
    /// 而此刻构建刚结束、App 已经在跑，是这条路径上最空闲的时刻。
    var onRunStarted: (() -> Void)?

    // MARK: - 运行时句柄

    private var runTask: Task<Void, Never>?
    private var buildHandle: RunningProcess?
    private var launchHandle: RunningProcess?
    private var macApp: NSRunningApplication?
    private var macLaunchContainer: URL?
    private var macTerminationObserver: NSObjectProtocol?
    private var activeBundleID: String?
    private var activeDestination: RunDestination?
    private var userCancelled = false
    private var ticker: Timer?

    init(
        prefs: Preferences,
        notifications: NotificationService,
        projects: ProjectStore,
        devices: DeviceStore,
        logs: LogStore
    ) {
        self.prefs = prefs
        self.notifications = notifications
        self.projects = projects
        self.devices = devices
        self.logs = logs
    }

    // MARK: - 对外动作

    /// 运行按钮：idle/failed → 运行；running → 停止后重跑；working → 忽略。
    func primaryAction(clean: Bool = false) {
        switch phase {
        case .idle, .failed:
            start(clean: clean)
        case .running:
            start(clean: clean)     // 内部会先干净地停掉旧进程
        case .building, .installing, .launching:
            break
        }
    }

    /// 停止按钮：构建中 = 取消构建；运行中 = 终止 App。
    func stopAction() {
        switch phase {
        case .building, .installing, .launching:
            cancelRun()
        case .running:
            terminateRunningApp()
            phase = .idle
        case .idle, .failed:
            break
        }
    }

    /// 关闭错误摘要
    func dismissFailure() {
        if phase.isFailed { phase = .idle }
    }

    /// 应用退出前的清理
    ///
    /// 宽限期要大于 xcodebuild 响应 SIGINT 的时间（实测约 0.6s），否则退出时
    /// 会跳过取消握手，把 XCBBuildService 里的编译器留在后台空转。
    func shutdown() {
        runTask?.cancel()
        buildHandle?.cancel(gracePeriod: 1.5)
        launchHandle?.cancel(gracePeriod: 1.5)
        stopTicker()
        if let macTerminationObserver {
            NSWorkspace.shared.notificationCenter.removeObserver(macTerminationObserver)
        }
        MacAppLauncher.removeContainer(macLaunchContainer)
        macLaunchContainer = nil
    }

    // MARK: - 主流程

    private func start(clean: Bool) {
        guard let project = projects.current,
              let projectURL = projects.currentURL
        else {
            fail(L10n.t("还没有选择项目"))
            return
        }
        guard let scheme = projects.selectedScheme else {
            fail(L10n.t("还没有选择 scheme"))
            return
        }
        guard let destination = devices.selected else {
            fail(L10n.t("还没有选择运行目标"))
            return
        }

        runTask?.cancel()
        terminateRunningApp()
        userCancelled = false

        logs.beginRun()
        let startedAt = Date()
        phase = .building(startedAt: startedAt, stage: clean ? L10n.t("清理后构建") : nil)
        elapsed = 0
        startTicker()

        activeDestination = destination
        projects.rememberDestination(destination.id)

        let request = XcodebuildAdapter.BuildRequest(
            project: projectURL,
            kind: project.kind,
            scheme: scheme,
            configuration: projects.selectedConfiguration,
            destination: destination,
            derivedDataPath: prefs.derivedDataPath(for: projectURL),
            clean: clean
        )

        runTask = Task { [weak self] in
            await self?.perform(request: request, project: project, startedAt: startedAt)
        }
    }

    private func perform(request: XcodebuildAdapter.BuildRequest, project: XcodeProject, startedAt: Date) async {
        let destination = request.destination

        // 模拟器可以在构建的同时预热，省掉串行等待
        let bootTask: Task<Void, Error>? = {
            guard destination.source == .simulator, destination.state != .booted else { return nil }
            let udid = destination.id
            return Task {
                try await SimctlAdapter.boot(udid: udid)
                try await SimctlAdapter.waitUntilBooted(udid: udid)
            }
        }()

        // 1. 构建
        let runID = logs.currentRunID
        var outcome: BuildService.BuildOutcome
        do {
            outcome = try await build(request, startedAt: startedAt, runID: runID)
            if case .failed(_, let path?) = outcome, !Task.isCancelled, !userCancelled,
               runID == logs.currentRunID, !FileManager.default.fileExists(atPath: path) {
                let message = L10n.t("模块缓存缺失，正在清理并重试")
                logs.append("\(message) · \(path)", level: .note)
                logs.beginBuildRetry()
                phase = .building(startedAt: startedAt, stage: message)
                var retry = request
                retry.clean = true
                outcome = try await build(retry, startedAt: startedAt, runID: runID)
            }
        } catch {
            bootTask?.cancel()
            guard runID == logs.currentRunID, !Task.isCancelled else { return }
            fail(ErrorTranslator.summarize(error.localizedDescription))
            return
        }
        guard runID == logs.currentRunID else {
            bootTask?.cancel()
            return
        }
        buildHandle = nil

        if Task.isCancelled || userCancelled {
            bootTask?.cancel()
            finishCancelled()
            return
        }

        switch outcome {
        case .cancelled:
            bootTask?.cancel()
            finishCancelled()
            return
        case .failed:
            bootTask?.cancel()
            failFromLog(fallback: L10n.t("构建失败"))
            return
        case .succeeded:
            break
        }

        // 2. 定位产物与 bundle id
        // 刚编完必须绕过缓存：历史上曾因 DerivedData 目录漂移，缓存仍指向旧 .app，
        // 导致「构建成功、磁盘变大，装上去的却是旧包」。
        let settings: ResolvedBuildSettings
        do {
            settings = try await buildService.resolveSettings(
                project: request.project,
                kind: request.kind,
                scheme: request.scheme,
                configuration: request.configuration,
                destination: destination,
                derivedDataPath: request.derivedDataPath,
                ignoreCache: true
            )
        } catch {
            bootTask?.cancel()
            fail(ErrorTranslator.summarize(error.localizedDescription))
            return
        }
        activeBundleID = settings.bundleIdentifier

        guard !userCancelled, !Task.isCancelled else {
            bootTask?.cancel()
            finishCancelled()
            return
        }

        // 3. 安装
        phase = .installing
        do {
            switch destination.source {
            case .simulator:
                try await bootTask?.value
                await SimctlAdapter.openSimulatorApp(udid: destination.id)
                logs.append("Installing \(settings.productPath.lastPathComponent) → \(destination.name)", level: .note)
                try await SimctlAdapter.install(udid: destination.id, appPath: settings.productPath)
            case .device:
                guard destination.state == .connected else {
                    fail(L10n.t("设备未连接或未信任本机，请检查连接后重试"))
                    return
                }
                logs.append("Installing \(settings.productPath.lastPathComponent) → \(destination.name)", level: .note)
                try await DevicectlAdapter.install(deviceID: destination.id, appPath: settings.productPath)
            case .mac:
                break   // macOS 直接运行产物，无需安装
            }
        } catch {
            fail(ErrorTranslator.summarize(error.localizedDescription))
            return
        }

        guard !userCancelled, !Task.isCancelled else {
            finishCancelled()
            return
        }

        // 4. 启动
        phase = .launching
        do {
            let pid = try await launch(destination: destination, settings: settings)
            let duration = max(0, Int(Date().timeIntervalSince(startedAt)))
            stopTicker()
            phase = .running(pid: pid)
            notifySucceeded(scheme: request.scheme, duration: duration)
            onRunStarted?()
        } catch {
            fail(ErrorTranslator.summarize(error.localizedDescription))
        }
    }

    private func build(
        _ request: XcodebuildAdapter.BuildRequest, startedAt: Date, runID: UUID
    ) async throws -> BuildService.BuildOutcome {
        try Task.checkCancellation()
        logs.append("$ xcodebuild \(XcodebuildAdapter.buildArguments(request).joined(separator: " "))", level: .note)
        return try await buildService.build(request, onStart: { [weak self] handle in
            Task { @MainActor in
                guard let self, self.logs.currentRunID == runID, !self.userCancelled else {
                    handle.cancel()
                    return
                }
                self.buildHandle = handle
            }
        }, onLine: { [weak self] line, kind in
            Task { @MainActor in
                guard let self, self.logs.currentRunID == runID else { return }
                self.ingest(line, kind: kind, startedAt: startedAt)
            }
        })
    }

    // MARK: - 通知

    /// 「发送通知」与「播放声音」是两个正交开关：可以只响不弹。
    private func notifySucceeded(scheme: String, duration: Int) {
        if prefs.notifyOnSuccess {
            notifications.notifyBuildSucceeded(
                scheme: scheme,
                duration: duration,
                playSound: prefs.soundOnSuccess
            )
        } else if prefs.soundOnSuccess {
            notifications.playSoundOnly()
        }
    }

    private func notifyFailed(summary: String) {
        if prefs.notifyOnFailure {
            notifications.notifyBuildFailed(summary: summary, playSound: prefs.soundOnFailure)
        } else if prefs.soundOnFailure {
            notifications.playSoundOnly()
        }
    }

    // MARK: - 启动

    private func launch(destination: RunDestination, settings: ResolvedBuildSettings) async throws -> Int32? {
        switch destination.source {
        case .simulator:
            if prefs.attachConsole {
                let handle = try SimctlAdapter.launchAttached(
                    udid: destination.id,
                    bundleID: settings.bundleIdentifier,
                    onLine: { [weak self] line, kind in
                        guard let self else { return }
                        Task { @MainActor in self.logs.append(line, level: kind == .stderr ? .warning : .output) }
                    },
                    onExit: { [weak self] code in
                        guard let self else { return }
                        Task { @MainActor in self.handleAttachedLaunchExit(code) }
                    }
                )
                launchHandle = handle
                // 附着模式下命令不会返回，用「短暂等待后仍存活」作为启动成功的判据
                try await Task.sleep(nanoseconds: 900_000_000)
                if !handle.isRunning {
                    throw SimctlError.launchFailed(recentErrorText() ?? L10n.t("App 启动后立即退出"))
                }
                return nil
            } else {
                return try await SimctlAdapter.launchDetached(
                    udid: destination.id,
                    bundleID: settings.bundleIdentifier
                )
            }

        case .device:
            if prefs.attachConsole {
                let handle = try DevicectlAdapter.launchAttached(
                    deviceID: destination.id,
                    bundleID: settings.bundleIdentifier,
                    onLine: { [weak self] line, kind in
                        guard let self else { return }
                        Task { @MainActor in self.logs.append(line, level: kind == .stderr ? .warning : .output) }
                    },
                    onExit: { [weak self] code in
                        guard let self else { return }
                        Task { @MainActor in self.handleAttachedLaunchExit(code) }
                    }
                )
                launchHandle = handle
                try await Task.sleep(nanoseconds: 1_500_000_000)
                if !handle.isRunning {
                    throw DevicectlError.launchFailed(recentErrorText() ?? L10n.t("App 启动后立即退出"))
                }
                return nil
            } else {
                return try await DevicectlAdapter.launchDetached(
                    deviceID: destination.id,
                    bundleID: settings.bundleIdentifier
                )
            }

        case .mac:
            let result = try await MacAppLauncher.launch(productAt: settings.productPath)
            macApp = result.application
            macLaunchContainer = result.temporaryContainer
            observeMacTermination(result.application, container: result.temporaryContainer)
            logs.append("Launched \(settings.productPath.lastPathComponent) (pid \(result.application.processIdentifier))", level: .note)
            return result.application.processIdentifier
        }
    }

    /// 附着的 launch 进程退出：正常退出说明 App 已结束，非零则是启动失败。
    private func handleAttachedLaunchExit(_ code: Int32) {
        launchHandle = nil
        guard phase.isRunning || phase == .launching else { return }
        if code == 0 {
            phase = .idle
        } else if !userCancelled {
            failFromLog(fallback: L10n.t("App 已退出（退出码 %d）", code))
        } else {
            phase = .idle
        }
        stopTicker()
    }

    private func observeMacTermination(_ app: NSRunningApplication, container: URL?) {
        if let macTerminationObserver {
            NSWorkspace.shared.notificationCenter.removeObserver(macTerminationObserver)
        }
        macTerminationObserver = NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.didTerminateApplicationNotification,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            guard let terminated = notification.userInfo?[NSWorkspace.applicationUserInfoKey]
                    as? NSRunningApplication,
                  terminated.processIdentifier == app.processIdentifier
            else { return }
            Task { @MainActor [weak self] in
                guard let self else { return }
                // 重跑时旧 App 的退出通知可能晚于新 App 的启动。只更新当前
                // 状态；旧的 WrappedBundle 无论如何都要清掉，但不能误删新容器。
                MacAppLauncher.removeContainer(container)
                if self.macLaunchContainer == container {
                    self.macLaunchContainer = nil
                }
                guard self.macApp?.processIdentifier == app.processIdentifier
                        || self.macApp == nil
                else { return }
                self.macApp = nil
                guard self.phase.isRunning else { return }
                self.phase = .idle
            }
        }
    }

    // MARK: - 停止与取消

    private func cancelRun() {
        userCancelled = true
        runTask?.cancel()
        buildHandle?.cancel()
        launchHandle?.cancel()
        buildHandle = nil
        launchHandle = nil
        finishCancelled()
    }

    /// 取消是用户主动行为，不该呈现为错误——状态直接置为 idle。
    private func finishCancelled() {
        stopTicker()
        logs.append(L10n.t("已取消"), level: .note)
        phase = .idle
    }

    private func terminateRunningApp() {
        launchHandle?.cancel(gracePeriod: 1)
        launchHandle = nil

        if let destination = activeDestination, let bundleID = activeBundleID {
            switch destination.source {
            case .simulator:
                let udid = destination.id
                Task { await SimctlAdapter.terminate(udid: udid, bundleID: bundleID) }
            case .device:
                let deviceID = destination.id
                Task { await DevicectlAdapter.terminate(deviceID: deviceID, bundleID: bundleID) }
            case .mac:
                let app = macApp
                app?.terminate()
                macApp = nil
                // 正常情况下由 didTerminate 通知清理；进程已先退出时通知可能已经
                // 发出，因此这里补一次无害的兜底清理。
                if app?.isTerminated == true {
                    MacAppLauncher.removeContainer(macLaunchContainer)
                    macLaunchContainer = nil
                }
            }
        }
    }

    // MARK: - 日志与失败

    private func ingest(_ line: String, kind: StreamKind, startedAt: Date) {
        if let diagnostic = LogParser.parseDiagnostic(line) {
            logs.appendDiagnostic(diagnostic)
            logs.append(line, level: diagnostic.level)
        } else {
            logs.append(line, level: kind == .stderr ? .warning : .output)
        }

        // 阶段推断：把不确定进度粗略映射为几个可读阶段
        if case .building = phase, let stage = LogParser.stage(from: line) {
            phase = .building(startedAt: startedAt, stage: stage)
        }
    }

    private func recentErrorText() -> String? {
        let tail = logs.entries.suffix(20)
            .filter { $0.level == .error || $0.level == .warning }
            .map(\.text)
        return tail.isEmpty ? nil : tail.joined(separator: "\n")
    }

    private func failFromLog(fallback: String) {
        if let diagnostic = logs.firstError {
            fail(
                ErrorTranslator.translate(diagnostic.message) ?? diagnostic.message,
                // 只有这条路径带原文：它是一条结构化诊断，拷出来最多两行。
                // recentErrorText() 那条是二十行的尾部输出，整段塞进剪贴板不如
                // 让用户走日志面板的「拷贝完整日志」。
                raw: diagnostic.message,
                file: diagnostic.file,
                line: diagnostic.line
            )
            return
        }
        if let text = recentErrorText() {
            fail(ErrorTranslator.summarize(text))
            return
        }
        fail(fallback)
    }

    private func fail(_ summary: String, raw: String? = nil, file: String? = nil, line: Int? = nil) {
        stopTicker()
        phase = .failed(
            BuildFailure(
                summary: summary,
                raw: raw,
                file: file,
                line: line,
                fullLogRef: logs.currentRunID
            )
        )
        // 用户主动取消走 finishCancelled()，不经过这里——取消不发通知，
        // 与「取消不呈现为错误」的既有立场一致。
        notifyFailed(summary: summary)
        onFailure?()
    }

    // MARK: - 计时

    private func startTicker() {
        stopTicker()
        let timer = Timer(timeInterval: 1, repeats: true) { _ in
            Task { @MainActor [weak self] in
                guard let self, let startedAt = self.phase.startedAt ?? self.tickerStart else { return }
                self.elapsed = max(0, Int(Date().timeIntervalSince(startedAt)))
            }
        }
        tickerStart = Date()
        RunLoop.main.add(timer, forMode: .common)
        ticker = timer
    }

    private var tickerStart: Date?

    private func stopTicker() {
        ticker?.invalidate()
        ticker = nil
    }

    // MARK: - 派生展示

    /// 「Building · 12s」中的时间片段
    var elapsedDisplay: String { "\(elapsed)s" }

    var statusLine: String? {
        switch phase {
        case .idle: return nil
        case .building(_, let stage):
            let prefix = stage.map { "Building · \($0)" } ?? "Building"
            return "\(prefix) · \(elapsedDisplay)"
        case .installing: return "Installing · \(elapsedDisplay)"
        case .launching: return "Launching · \(elapsedDisplay)"
        case .running: return "Running"
        case .failed(let failure): return failure.summary
        }
    }
}
