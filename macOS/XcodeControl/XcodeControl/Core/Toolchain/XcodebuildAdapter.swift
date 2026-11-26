//
//  XcodebuildAdapter.swift
//  XcodeControl
//

import Foundation

/// 封装 `xcodebuild` 的全部调用与输出解析。
///
/// 输出格式会随 Xcode 版本变化，所有解析逻辑都收敛在这里，
/// 上层 Service 只面对结构化的 Swift 类型。
enum XcodebuildAdapter {

    // MARK: - 项目解析

    /// `xcodebuild -list -json`
    ///
    /// workspace 与 project 的顶层 key 不同，需分别处理。
    static func listProject(at url: URL, kind: XcodeProject.Kind) async throws -> ProjectInfo {
        // Shared Scheme 和基础元数据都已经落盘，优先直接读取可把项目切换从
        // 一次完整的 Xcode/SwiftPM 启动缩短为纯文件 I/O。
        if let local = SharedSchemeMetadataReader.read(at: url, kind: kind) {
            return local
        }

        // 保留 xcodebuild 作为兼容兜底，但 Scheme 查询绝不能顺带更新依赖。
        // 某些非标准 workspace 会由 Xcode 动态暴露 Scheme，磁盘扫描无法覆盖。
        let result = try await ProcessRunner.run(
            Toolchain.xcodebuildPath,
            [
                "-list", "-json",
                "-skipPackageUpdates",
                "-disableAutomaticPackageResolution",
                kind.xcodebuildFlag, url.path,
            ],
            environment: Toolchain.environment(),
            timeout: 45
        )
        guard result.isSuccess else {
            throw XcodebuildError.listFailed(result.combinedTrimmed)
        }
        return try parseList(result.stdout)
    }

    static func parseList(_ json: String) throws -> ProjectInfo {
        // xcodebuild 偶尔在 JSON 前打印警告行，从第一个 `{` 开始截取
        guard let start = json.firstIndex(of: "{"),
              let data = String(json[start...]).data(using: .utf8),
              let root = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        else {
            throw XcodebuildError.listFailed(L10n.t("无法解析 xcodebuild -list 的输出"))
        }

        // { "project": { ... } } 或 { "workspace": { ... } }
        let container = (root["project"] as? [String: Any]) ?? (root["workspace"] as? [String: Any])
        guard let container else {
            throw XcodebuildError.listFailed(L10n.t("xcodebuild -list 输出中既没有 project 也没有 workspace"))
        }

        let info = ProjectInfo(
            name: container["name"] as? String ?? "",
            schemes: container["schemes"] as? [String] ?? [],
            configurations: container["configurations"] as? [String] ?? [],
            targets: container["targets"] as? [String] ?? []
        )
        guard !info.schemes.isEmpty else {
            throw XcodebuildError.noSchemes
        }
        return info
    }

    // MARK: - Swift Package

    enum PackageResolutionMode: Equatable {
        /// 严格使用 Package.resolved，不更新版本；适合先判断本地缓存是否完整。
        case resolvedFileOnly
        /// 允许 SwiftPM 访问网络，并按工程声明重新解析依赖。
        case updateAllowed
    }

    struct PackageResolutionRequest {
        var project: URL
        var kind: XcodeProject.Kind
        var scheme: String
        var derivedDataPath: URL?
        var mode: PackageResolutionMode
    }

    static func packageResolutionArguments(_ request: PackageResolutionRequest) -> [String] {
        var args = [
            "-resolvePackageDependencies",
            request.kind.xcodebuildFlag, request.project.path,
        ]
        // xcodebuild 要求指定 -derivedDataPath 时必须同时给出 scheme；即使解析依赖
        // 本身是工程级操作，也不能省略这个参数。
        args += ["-scheme", request.scheme]
        if let derivedDataPath = request.derivedDataPath {
            args += ["-derivedDataPath", derivedDataPath.path]
        }
        if request.mode == .resolvedFileOnly {
            args += [
                "-disableAutomaticPackageResolution",
                "-onlyUsePackageVersionsFromResolvedFile",
                "-skipPackageUpdates",
            ]
        }
        return args
    }

    /// 解析当前工程的 Swift Package。命令参数在 Adapter 层集中维护，
    /// 避免 UI 和状态层各自拼一套、随 Xcode 版本演进后发生漂移。
    static func resolvePackageDependencies(
        _ request: PackageResolutionRequest
    ) async throws -> ProcessResult {
        let result = try await ProcessRunner.run(
            Toolchain.xcodebuildPath,
            packageResolutionArguments(request),
            cwd: request.project.deletingLastPathComponent(),
            environment: Toolchain.environment(),
            timeout: 600
        )
        guard result.isSuccess else {
            throw XcodebuildError.packageResolutionFailed(result.combinedTrimmed)
        }
        return result
    }

    // MARK: - 构建设置

    /// `xcodebuild -showBuildSettings -json`，取产物路径与 bundle id。
    static func showBuildSettings(
        project: URL,
        kind: XcodeProject.Kind,
        scheme: String,
        configuration: String,
        destination: RunDestination,
        derivedDataPath: URL?
    ) async throws -> (productPath: URL, bundleIdentifier: String) {

        var args = [
            "-showBuildSettings", "-json",
            kind.xcodebuildFlag, project.path,
            "-scheme", scheme,
            "-configuration", configuration,
            "-destination", destination.xcodebuildDestination,
        ]
        if let derivedDataPath {
            args += ["-derivedDataPath", derivedDataPath.path]
        }

        let result = try await ProcessRunner.run(
            Toolchain.xcodebuildPath, args,
            environment: Toolchain.environment(),
            timeout: 120
        )
        guard result.isSuccess else {
            throw XcodebuildError.buildSettingsFailed(result.combinedTrimmed)
        }
        return try parseBuildSettings(result.stdout)
    }

    static func parseBuildSettings(_ json: String) throws -> (productPath: URL, bundleIdentifier: String) {
        guard let start = json.firstIndex(of: "["),
              let data = String(json[start...]).data(using: .utf8),
              let array = try JSONSerialization.jsonObject(with: data) as? [[String: Any]],
              let settings = array.first?["buildSettings"] as? [String: Any]
        else {
            throw XcodebuildError.buildSettingsFailed(L10n.t("无法解析 -showBuildSettings 的输出"))
        }

        guard let dir = settings["BUILT_PRODUCTS_DIR"] as? String,
              let productName = settings["FULL_PRODUCT_NAME"] as? String
        else {
            throw XcodebuildError.buildSettingsFailed(L10n.t("构建设置中缺少 BUILT_PRODUCTS_DIR / FULL_PRODUCT_NAME"))
        }
        guard let bundleID = settings["PRODUCT_BUNDLE_IDENTIFIER"] as? String, !bundleID.isEmpty else {
            throw XcodebuildError.missingBundleIdentifier
        }

        let path = URL(fileURLWithPath: dir).appendingPathComponent(productName)
        return (path, bundleID)
    }

    // MARK: - 构建

    struct BuildRequest {
        var project: URL
        var kind: XcodeProject.Kind
        var scheme: String
        var configuration: String
        var destination: RunDestination
        var derivedDataPath: URL?
        var clean: Bool = false
    }

    static func buildArguments(_ request: BuildRequest) -> [String] {
        var args: [String] = []
        if request.clean { args.append("clean") }
        args.append("build")
        args += [
            request.kind.xcodebuildFlag, request.project.path,
            "-scheme", request.scheme,
            "-configuration", request.configuration,
            "-destination", request.destination.xcodebuildDestination,
        ]
        if let derived = request.derivedDataPath {
            args += ["-derivedDataPath", derived.path]
        }
        // 仅模拟器构建关闭签名：显著加快构建并避免钥匙串弹窗。
        if request.destination.allowsDisablingCodeSigning {
            args += ["CODE_SIGNING_ALLOWED=NO", "CODE_SIGNING_REQUIRED=NO", "CODE_SIGN_IDENTITY="]
        }
        return args
    }

    /// 流式执行构建，返回句柄以支持取消。
    static func build(
        _ request: BuildRequest,
        onLine: @escaping @Sendable (String, StreamKind) -> Void,
        onExit: @escaping @Sendable (Int32) -> Void
    ) throws -> RunningProcess {
        try ProcessRunner.stream(
            Toolchain.xcodebuildPath,
            buildArguments(request),
            cwd: request.project.deletingLastPathComponent(),
            environment: Toolchain.environment(),
            onLine: onLine,
            onExit: onExit
        )
    }
}

enum XcodebuildError: LocalizedError {
    case listFailed(String)
    case noSchemes
    case buildSettingsFailed(String)
    case packageResolutionFailed(String)
    case missingBundleIdentifier

    var errorDescription: String? {
        switch self {
        case .listFailed(let detail):
            detail.isEmpty ? L10n.t("读取项目信息失败") : detail
        case .noSchemes:
            L10n.t("该项目没有可用的 scheme（只有勾选 Shared 的 scheme 才会出现在列表中）")
        case .buildSettingsFailed(let detail):
            detail.isEmpty ? L10n.t("读取构建设置失败") : detail
        case .packageResolutionFailed(let detail):
            detail.isEmpty ? L10n.t("Swift Package 解析失败") : detail
        case .missingBundleIdentifier:
            L10n.t("构建设置中没有 PRODUCT_BUNDLE_IDENTIFIER，该 scheme 可能不是可运行的 App target")
        }
    }
}
