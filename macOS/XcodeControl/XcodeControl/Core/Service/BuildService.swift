//
//  BuildService.swift
//  XcodeControl
//

import Foundation
import os

/// 构建与产物定位。把 Adapter 的流式接口包装成 async，并负责构建设置缓存。
struct BuildService {

    private let cache = BuildSettingsCache()

    // MARK: - 构建设置

    /// 取产物路径与 bundle id。这条命令本身耗时 1–3 秒，因此按
    /// (项目路径, scheme, configuration, 平台, derivedDataPath) 缓存，工程文件 mtime 变化时失效。
    /// 构建刚结束后应传 `ignoreCache: true`，避免装到过期路径上的 `.app`。
    func resolveSettings(
        project: URL,
        kind: XcodeProject.Kind,
        scheme: String,
        configuration: String,
        destination: RunDestination,
        derivedDataPath: URL?,
        ignoreCache: Bool = false
    ) async throws -> ResolvedBuildSettings {

        let platformKey = destination.source == .simulator
            ? destination.platform.xcodebuildSimulatorName
            : destination.platform.xcodebuildName
        let key = ResolvedBuildSettings.Key(
            projectPath: project.path,
            scheme: scheme,
            configuration: configuration,
            platform: platformKey,
            derivedDataPath: derivedDataPath?.path
        )
        let mtime = ProjectService.modificationDate(of: project)

        if !ignoreCache, let cached = cache.value(for: key, projectMTime: mtime) {
            return cached
        }

        let resolved = try await XcodebuildAdapter.showBuildSettings(
            project: project,
            kind: kind,
            scheme: scheme,
            configuration: configuration,
            destination: destination,
            derivedDataPath: derivedDataPath
        )

        let settings = ResolvedBuildSettings(
            productPath: resolved.productPath,
            bundleIdentifier: resolved.bundleIdentifier,
            resolvedAt: Date(),
            projectMTime: mtime
        )
        cache.store(settings, for: key)
        return settings
    }

    func clearCache() {
        cache.clear()
    }

    // MARK: - 构建

    enum BuildOutcome: Equatable {
        case succeeded
        case failed(exitCode: Int32, missingModule: String?)
        /// 用户主动取消——不该呈现为错误
        case cancelled
    }

    /// 流式执行构建。`onStart` 交出句柄以便取消，`onLine` 逐行回调原始输出。
    func build(
        _ request: XcodebuildAdapter.BuildRequest,
        onStart: @escaping @Sendable (RunningProcess) -> Void,
        onLine: @escaping @Sendable (String, StreamKind) -> Void
    ) async throws -> BuildOutcome {

        // Capture on the output stream: UI log delivery may lag process exit,
        // and the user may clear the visible log while a build is running.
        let missingModule = OSAllocatedUnfairLock<String?>(initialState: nil)
        let handle = try XcodebuildAdapter.build(
            request,
            onLine: { line, kind in
                if line.contains("ExplicitPrecompiledModules/"), line.contains(".pcm' not found"),
                   let diagnostic = LogParser.parseDiagnostic(line),
                   let path = LogParser.missingPrecompiledModule(in: diagnostic) {
                    missingModule.withLock { $0 = path }
                }
                onLine(line, kind)
            },
            onExit: { _ in }
        )
        onStart(handle)

        let code = await handle.waitUntilExit()
        // 给 readabilityHandler 消费残余输出的时间，确保错误行不丢
        try? await Task.sleep(nanoseconds: 60_000_000)

        if code == 0 { return .succeeded }
        // SIGINT / SIGKILL 导致的退出码：128+2 = 130，128+9 = 137，Process 也可能报负值
        if code == 130 || code == 137 || code == 2 || code == -2 || code == -9 {
            return .cancelled
        }
        return .failed(exitCode: code, missingModule: missingModule.withLock { $0 })
    }
}
