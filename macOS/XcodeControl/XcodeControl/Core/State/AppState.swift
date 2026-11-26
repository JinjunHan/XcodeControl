//
//  AppState.swift
//  XcodeControl
//

import AppKit
import Foundation
import Observation
import SwiftUI

/// 应用级状态：环境预检、各 Store 的组合、浮层的展开态。
@MainActor
@Observable
final class AppState {

    // MARK: - Store

    let prefs = Preferences()
    let notifications = NotificationService()
    let projects = ProjectStore()
    let packages = SwiftPackageStore()
    let devices = DeviceStore()
    let logs = LogStore()
    private(set) var run: RunController!
    /// 由 AppDelegate 注入。设置页需要它来展示快捷键注册状态。
    var hotKeys: HotKeyCenter?

    /// 切换项目的异步任务挂在 AppState 上，而不是 View 的 `Task {}`。
    /// 菜单栏点选后 NSMenu 会立刻拆掉子树，View 作用域里的 Task 会被取消，
    /// `xcodebuild -list` 还没回来 Scheme 就停在上一个工程——这是菜单栏特有的坑。
    @ObservationIgnored
    private var projectSwitchTask: Task<Void, Never>?
    /// 分支面板关闭或重建不应中断已经发起的 Git 查询 / 切换。
    @ObservationIgnored
    private var gitBranchLoadTask: Task<Void, Never>?
    @ObservationIgnored
    private var gitBranchSwitchTask: Task<Void, Never>?
    @ObservationIgnored
    private var gitBranchSwitchGeneration = 0
    @ObservationIgnored
    private var gitReferenceRefreshTask: Task<Void, Never>?

    // MARK: - 环境

    enum EnvironmentStatus: Equatable {
        case checking
        case ready(Toolchain.Environment)
        /// 环境级错误让整个应用无法工作，以全窗口替换的方式提示
        case blocked(message: String, detail: String, command: String?)
    }

    private(set) var environment: EnvironmentStatus = .checking

    /// Xcode 版本超出已验证范围时的温和提示（不阻断）
    private(set) var unverifiedXcodeNotice: String?
    /// 系统选择不可用且检测到多个 Xcode 时，交给错误页让用户明确选择。
    private(set) var recoveryXcodes: [Toolchain.XcodeInstall] = []
    private(set) var needsXcodeInstallation = false

    @ObservationIgnored
    private var didLoadWorkspace = false
    @ObservationIgnored
    private var isLoadingWorkspace = false

    // MARK: - 浮层展开态

    enum Panel: Equatable {
        case none
        case project
        case swiftPackage
        case device
        case gitBranch
    }

    /// 项目下拉展开时滚到哪一段：点项目名 → 顶部；点右侧 scheme → Scheme 区。
    enum ProjectPanelFocus: Equatable {
        case projects
        case scheme
    }

    var openPanel: Panel = .none {
        didSet { if openPanel != .none { devices.searchText = "" } }
    }

    var projectPanelFocus: ProjectPanelFocus = .projects

    /// 点同一个入口两次就收起，这样用户永远不需要去找「关闭」。
    func togglePanel(_ panel: Panel) {
        let isOpening = openPanel != panel
        openPanel = isOpening ? panel : .none
        if isOpening, panel == .device {
            Task { [weak self] in
                await self?.devices.refresh()
            }
        }
    }

    /// 打开项目下拉并定位到指定分区；若已展开且焦点相同则收起。
    func toggleProjectPanel(focus: ProjectPanelFocus) {
        if openPanel == .project, projectPanelFocus == focus {
            openPanel = .none
            return
        }
        projectPanelFocus = focus
        openPanel = .project
    }

    /// 分支入口与其他次级面板互斥；展开时总是重新读取，跟上 Xcode / 终端里的外部切换。
    func toggleGitBranchPanel() {
        let isOpening = openPanel != .gitBranch
        togglePanel(.gitBranch)
        if isOpening { refreshGitBranches() }
    }

    func refreshGitBranches() {
        gitBranchLoadTask?.cancel()
        gitBranchLoadTask = Task { [weak self] in
            guard let self else { return }
            await self.projects.refreshGitBranches()
            guard !Task.isCancelled else { return }
            self.recordGitErrorDetail()
            if self.openPanel == .gitBranch,
               self.projects.currentGitReference == nil,
               self.projects.gitBranchError == nil {
                self.openPanel = .none
            }
        }
    }

    /// 构建链路运行中不改工作树；切换成功后刷新工程信息，适配分支间的工程配置差异。
    func selectGitBranch(_ branch: String) {
        guard !run.phase.isWorking, !projects.isGitBranchBusy else { return }

        if let worktree = projects.worktreeUsingBranch(branch) {
            activateGitWorktree(worktree, branch: branch)
            return
        }

        gitBranchSwitchGeneration += 1
        let generation = gitBranchSwitchGeneration
        let projectID = projects.current?.id
        gitBranchSwitchTask?.cancel()
        gitBranchSwitchTask = Task { [weak self] in
            guard let self else { return }
            defer {
                if self.gitBranchSwitchGeneration == generation {
                    self.gitBranchSwitchTask = nil
                }
            }
            let switched = await self.projects.switchGitBranch(to: branch)
            guard !Task.isCancelled,
                  self.gitBranchSwitchGeneration == generation,
                  self.projects.current?.id == projectID
            else { return }
            guard switched else {
                self.recordGitErrorDetail()
                return
            }
            self.openPanel = .none
            await self.projects.reloadInfo()
        }
    }

    private func activateGitWorktree(_ worktree: GitWorktreeInfo, branch: String) {
        gitBranchSwitchGeneration += 1
        let generation = gitBranchSwitchGeneration
        projectSwitchTask?.cancel()
        gitBranchSwitchTask?.cancel()
        openPanel = .none

        gitBranchSwitchTask = Task { [weak self] in
            guard let self else { return }
            defer {
                if self.gitBranchSwitchGeneration == generation {
                    self.gitBranchSwitchTask = nil
                }
            }

            let activated = await self.projects.activateWorktree(worktree, forBranch: branch)
            guard !Task.isCancelled,
                  self.gitBranchSwitchGeneration == generation
            else { return }

            if activated {
                self.devices.restoreSelection(self.projects.rememberedDestinationID)
            } else if self.projects.currentGitReference != nil {
                self.recordGitErrorDetail()
                self.openPanel = .gitBranch
            }
        }
    }

    private func recordGitErrorDetail() {
        guard let detail = projects.gitBranchErrorDetail,
              !detail.isEmpty
        else { return }

        let entry = L10n.t("Git 操作详情：%@", detail)
        guard logs.entries.last?.text != entry else { return }
        logs.append(entry, level: .error)
    }

    var isLogPaneExpanded: Bool {
        didSet { UserDefaults.standard.set(isLogPaneExpanded, forKey: DefaultsKey.logPaneExpanded) }
    }

    /// 窗口是否处于激活/悬停状态——失焦时整体不透明度降至 92%
    var isHovering = false
    var isKeyWindow = true

    func setHovering(_ hovering: Bool) {
        isHovering = hovering
        gitReferenceRefreshTask?.cancel()
        // 分支不显示时这次探测的结果没有任何去处，省掉一次 git 子进程。
        guard hovering, prefs.showGitBranch else {
            gitReferenceRefreshTask = nil
            return
        }

        gitReferenceRefreshTask = Task { [weak self] in
            try? await Task.sleep(nanoseconds: 150_000_000)
            guard !Task.isCancelled, let self, self.isHovering else { return }
            await self.projects.refreshGitReference()
            if !Task.isCancelled {
                self.gitReferenceRefreshTask = nil
            }
        }
    }

    var chromeOpacity: Double {
        if isHovering || isKeyWindow { return 1.0 }
        return prefs.dimOnResign ? prefs.dimmedOpacity : 1.0
    }

    // MARK: - 浮窗可见性（菜单栏镜像用）

    /// 悬浮窗当前是否可见。隐藏后进程仍在，靠菜单栏唤回。
    private(set) var isFloatingPanelVisible = true

    /// 由 AppDelegate 注入：真正操作 NSPanel 的 orderFront / orderOut。
    var showFloatingPanelHandler: (() -> Void)?
    var hideFloatingPanelHandler: (() -> Void)?
    /// 由 AppDelegate 注入，避免 SwiftUI 页面直接依赖 Sparkle。
    var checkForUpdatesHandler: (() -> Void)?

    // MARK: - 生命周期

    init() {
        isLogPaneExpanded = UserDefaults.standard.bool(forKey: DefaultsKey.logPaneExpanded)

        // 配置先于各 Store 注入：容量 / 保留数量都从这里读。
        logs.prefs = prefs
        projects.prefs = prefs

        run = RunController(
            prefs: prefs,
            notifications: notifications,
            projects: projects,
            devices: devices,
            logs: logs
        )
        // 构建失败时自动展开日志：状态机不该直接改 UI 展开态，用回调穿回来。
        run.onFailure = { [weak self] in
            guard let self, self.prefs.autoExpandLogOnFailure else { return }
            self.isLogPaneExpanded = true
        }
        run.onRunStarted = { [weak self] in
            self?.reapDerivedDataIfNeeded()
        }
    }

    /// 是否显示首次启动引导
    var showsOnboarding: Bool {
        !projects.hasProject
    }

    // MARK: - 语言

    /// 当前生效的界面语言。
    ///
    /// `Localization.current` 是静态的、不可观察的（查表在渲染路径上每帧调用几十次，
    /// 不能付 observation 的代价），因此这里再存一份可观察副本：
    /// 三个根视图用 `.id(state.language)` 依赖它，切换语言时整棵树重建。
    private(set) var language: AppLanguage = Localization.current

    /// 切换界面语言。`nil` = 跟随系统。
    func setLanguage(_ selection: AppLanguage?) {
        prefs.appLanguage = selection
        let resolved = prefs.resolvedLanguage
        Localization.setCurrent(resolved)
        language = resolved
    }

    /// 开关状态行的 Git branch 显示。
    ///
    /// 关掉时必须同时收起分支面板：面板是靠状态行那个入口点开点收的，
    /// 入口一消失，展开着的面板就没有任何办法收回去了。
    func setShowsGitBranch(_ shows: Bool) {
        prefs.showGitBranch = shows

        guard shows else {
            if openPanel == .gitBranch { openPanel = .none }
            return
        }

        // 关闭期间悬停刷新是跳过的，缓存里那个分支名可能已经被外部切换甩下了；
        // 重新显示前补一次，免得先亮出一个旧分支再被下次悬停改掉。
        gitReferenceRefreshTask?.cancel()
        gitReferenceRefreshTask = Task { [weak self] in
            guard let self else { return }
            await self.projects.refreshGitReference()
            if !Task.isCancelled {
                self.gitReferenceRefreshTask = nil
            }
        }
    }

    func bootstrap() async {
        await redetectEnvironment()
    }

    /// 重跑环境预检。首次从阻断状态恢复后，会继续完成原本中断的启动加载。
    func redetectEnvironment() async {
        environment = .checking
        do {
            let env = try await Toolchain.detect()
            environment = .ready(env)
            recoveryXcodes = []
            needsXcodeInstallation = false
            if !env.isVerified {
                unverifiedXcodeNotice = L10n.t("Xcode %@ 尚未验证，若行为异常请反馈", env.xcodeVersion)
            } else {
                unverifiedXcodeNotice = nil
            }
            await loadWorkspaceIfNeeded()
        } catch let error as Toolchain.EnvironmentError {
            recoveryXcodes = error.recoveryXcodes
            if case .xcodeNotFound = error {
                needsXcodeInstallation = true
            } else {
                needsXcodeInstallation = false
            }
            environment = .blocked(
                message: error.errorDescription ?? L10n.t("环境不可用"),
                detail: error.detail,
                command: error.recoveryCommand
            )
        } catch {
            recoveryXcodes = []
            needsXcodeInstallation = false
            environment = .blocked(
                message: L10n.t("环境检查失败"),
                detail: error.localizedDescription,
                command: nil
            )
        }
    }

    func useXcode(_ xcode: Toolchain.XcodeInstall) async {
        Toolchain.overrideDeveloperDir = xcode.developerDir
        await redetectEnvironment()
    }

    func openXcodeDownloadPage() {
        guard let url = URL(string: "https://apps.apple.com/app/xcode/id497799835") else { return }
        NSWorkspace.shared.open(url)
    }

    private func loadWorkspaceIfNeeded() async {
        guard !didLoadWorkspace, !isLoadingWorkspace else { return }
        isLoadingWorkspace = true
        defer { isLoadingWorkspace = false }

        async let deviceLoad: Void = devices.refresh()
        await projects.restoreLastProject()
        await deviceLoad

        devices.restoreSelection(projects.rememberedDestinationID)
        didLoadWorkspace = true
    }

    /// 打开系统文件选择器（限定 .xcodeproj / .xcworkspace）
    func presentOpenPanel() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = true
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.treatsFilePackagesAsDirectories = false
        panel.prompt = L10n.t("选择")
        panel.message = L10n.t("选择 .xcodeproj 或 .xcworkspace")
        panel.allowedContentTypes = []
        // 有当前项目时定位到其所在目录，方便就近再开同仓库其它工程
        if let currentURL = projects.currentURL {
            panel.directoryURL = currentURL.deletingLastPathComponent()
        }

        // NSPanel 是 nonactivating 的，弹出系统面板前需要短暂激活自身
        NSApp.activate(ignoringOtherApps: true)
        panel.begin { [weak self] response in
            guard response == .OK, let url = panel.url else { return }
            Task { @MainActor in await self?.openProject(at: url) }
        }
    }

    func openProject(at url: URL) async {
        openPanel = .none
        packages.cancel(reset: true)
        await projects.open(url: url)
        devices.restoreSelection(projects.rememberedDestinationID)
    }

    /// 拖入的工程包 / 项目文件夹：可多选；第一个激活为当前，其余只加入列表。
    @discardableResult
    func importDroppedURLs(_ urls: [URL]) async -> (added: Int, activated: Bool) {
        let expanded = ProjectService.expandDroppedURLs(urls)
        guard !expanded.isEmpty else {
            projects.failImport(L10n.t("未识别到 .xcodeproj / .xcworkspace"))
            openPanel = .none
            return (0, false)
        }

        openPanel = .none
        var added = 0
        var pendingCurrent = true

        for url in expanded {
            let isNew = await projects.add(url: url, makeCurrent: pendingCurrent)
            if pendingCurrent {
                devices.restoreSelection(projects.rememberedDestinationID)
                pendingCurrent = false
            }
            if isNew { added += 1 }
        }

        return (added, projects.current != nil)
    }

    /// 切换当前项目。菜单栏请走同步入口 `selectProject(_:)`（内部自管 Task），
    /// 需要等待完成时用 `await selectProjectAsync`。
    func selectProject(_ project: XcodeProject) {
        openPanel = .none
        packages.cancel(reset: true)
        projectSwitchTask?.cancel()
        let targetID = project.id
        projectSwitchTask = Task { [weak self] in
            guard let self else { return }
            await self.projects.select(project)
            guard !Task.isCancelled else { return }
            guard self.projects.current?.id == targetID else { return }
            self.devices.restoreSelection(self.projects.rememberedDestinationID)
        }
    }

    func selectProjectAsync(_ project: XcodeProject) async {
        selectProject(project)
        await projectSwitchTask?.value
    }

    func selectScheme(_ scheme: String) {
        projects.selectedScheme = scheme
        openPanel = .none
    }

    func selectDestination(_ destination: RunDestination) {
        devices.selectedID = destination.id
        projects.rememberDestination(destination.id)
        openPanel = .none
    }

    // MARK: - Swift Package 工具

    func openSwiftPackageTools() {
        guard let project = projects.current, let url = projects.currentURL else { return }
        packages.prepare(
            project: url,
            kind: project.kind,
            configuredDerivedDataPath: prefs.derivedDataPath(for: url),
            defaultDerivedDataRoot: prefs.activeDerivedDataRoot
        )
        openPanel = .swiftPackage
    }

    func resolveSwiftPackages(useResolvedFileOnly: Bool) {
        guard !run.phase.isWorking,
              let project = projects.current,
              let url = projects.currentURL,
              let scheme = projects.selectedScheme
        else { return }

        packages.prepare(
            project: url,
            kind: project.kind,
            configuredDerivedDataPath: prefs.derivedDataPath(for: url),
            defaultDerivedDataRoot: prefs.activeDerivedDataRoot
        )
        packages.resolve(
            project: url,
            kind: project.kind,
            scheme: scheme,
            derivedDataPath: prefs.derivedDataPath(for: url),
            mode: useResolvedFileOnly ? .resolvedFileOnly : .updateAllowed,
            logs: logs
        ) { [weak self] in
            guard let self else { return }
            if self.prefs.autoExpandLogOnFailure {
                self.isLogPaneExpanded = true
            }
        }
    }

    func clearSwiftPackageCache() {
        guard !run.phase.isWorking,
              let project = projects.current,
              let url = projects.currentURL
        else { return }
        packages.prepare(
            project: url,
            kind: project.kind,
            configuredDerivedDataPath: prefs.derivedDataPath(for: url),
            defaultDerivedDataRoot: prefs.activeDerivedDataRoot
        )
        packages.clearCache(logs: logs)
    }

    func cancelSwiftPackageOperation() {
        packages.cancel()
    }

    func revealPackageResolved() {
        guard let url = packages.packageResolvedURL else { return }
        NSWorkspace.shared.activateFileViewerSelecting([url])
    }

    func revealSwiftPackageCache() {
        guard let url = packages.sourcePackagesURL else { return }
        NSWorkspace.shared.open(url)
    }

    // MARK: - DerivedData 自动回收

    /// 回收任务的句柄。扫描是秒级 IO，必须能被下一次构建打断。
    @ObservationIgnored
    private var reapTask: Task<Void, Never>?

    /// 构建成功后的自动回收。开关全关、或今天已经跑过，就直接返回。
    ///
    /// 「每天最多一次」是必要的节流：扫描要逐个工程目录累加文件大小，
    /// 在本机 39G 的根目录上是秒级 IO，每次构建都跑会和用户紧接着的操作抢磁盘。
    func reapDerivedDataIfNeeded() {
        guard prefs.autoReapOrphans || prefs.autoReapStaleEnabled else { return }
        if let last = prefs.lastReapAt, Calendar.current.isDateInToday(last) { return }

        reapTask?.cancel()
        reapTask = Task { [weak self] in
            guard let self else { return }
            // 记在发起时刻而不是完成时刻：即使这次被下一轮构建打断，
            // 也不该在同一天里反复重扫。
            self.prefs.lastReapAt = Date()

            let root = self.prefs.activeDerivedDataRoot
            let policy = self.prefs.reapPolicy(
                knownProjectPaths: self.projects.items.map(\.lastKnownPath),
                currentProjectPath: self.projects.currentURL?.path
            )
            let candidates = await DerivedDataReaper.scan(root: root, policy: policy)
            guard !Task.isCancelled, !candidates.isEmpty else { return }

            // 构建期间绝不动手：默认模式下和 Xcode 共用同一份缓存，
            // 删到一半会让正在跑的构建失败。宁可等下一次机会。
            guard !self.run.phase.isWorking else { return }

            let (count, bytes) = await DerivedDataReaper.remove(candidates)
            guard count > 0 else { return }
            self.logs.append(
                L10n.t("已回收 %d 份无用的 Derived Data，释放 %@", count, DiskUsage.formatBytes(bytes)),
                level: .note
            )
        }
    }

    var showSettingsHandler: (() -> Void)?

    func openSettings(tab: SettingsTab? = nil) {
        if let tab { requestedSettingsTab = tab }
        // The destination is a separate window. Collapse the dropdown immediately
        // so its removal transition cannot move the controls during the handoff.
        var transaction = Transaction(animation: nil)
        transaction.disablesAnimations = true
        withTransaction(transaction) { openPanel = .none }
        showSettingsHandler?()
    }

    /// 待处理的设置分页请求，由 `SettingsView` 读走后置空。
    ///
    /// 为什么要隔一层状态：分页选择是设置窗口自己的 `@State`（见 `SettingsView`），
    /// 而请求方在浮窗里，两边没有直接引用。
    /// 消费后必须置空——否则用户切到别的分页、再点一次「管理项目…」时，
    /// 写入的还是同一个值，SwiftUI 不发变更通知，分页就不会跳回来。
    var requestedSettingsTab: SettingsTab?

    /// 用 Xcode 打开当前项目——需要写代码时的唯一出口。
    func openInXcode() {
        guard let url = projects.currentURL else { return }
        openPanel = .none
        NSWorkspace.shared.open(url)
    }

    func showFloatingPanel() {
        showFloatingPanelHandler?()
        isFloatingPanelVisible = true
    }

    func hideFloatingPanel() {
        openPanel = .none
        hideFloatingPanelHandler?()
        isFloatingPanelVisible = false
    }

    func toggleFloatingPanelVisibility() {
        if isFloatingPanelVisible {
            hideFloatingPanel()
        } else {
            showFloatingPanel()
        }
    }

    func checkForUpdates() {
        openPanel = .none
        NSApp.activate(ignoringOtherApps: true)
        checkForUpdatesHandler?()
    }

    func quit() {
        NSApp.terminate(nil)
    }

    func shutdown() {
        reapTask?.cancel()
        gitBranchLoadTask?.cancel()
        gitBranchSwitchTask?.cancel()
        gitReferenceRefreshTask?.cancel()
        packages.cancel(reset: true)
        run.shutdown()
    }
}
