//
//  Toolchain.swift
//  XcodeControl
//

import Foundation

/// Xcode 命令行工具的定位与环境预检。
///
/// `xcrun` 解析依赖 `DEVELOPER_DIR`：若用户装了多个 Xcode，可在设置里指定，
/// 默认取 `xcode-select -p` 的结果。
enum Toolchain {

    static let xcrunPath = "/usr/bin/xcrun"
    static let xcodebuildPath = "/usr/bin/xcodebuild"
    static let xcodeSelectPath = "/usr/bin/xcode-select"
    static let openPath = "/usr/bin/open"

    /// 用户在设置里手动指定的 Xcode.app 路径（`.../Xcode.app/Contents/Developer`）
    static var overrideDeveloperDir: String? {
        get { UserDefaults.standard.string(forKey: DefaultsKey.developerDirOverride) }
        set {
            UserDefaults.standard.set(newValue, forKey: DefaultsKey.developerDirOverride)
            autoDetectedDeveloperDir = nil
        }
    }

    /// 传给所有子进程的环境变量增量
    static func environment() -> [String: String]? {
        let dir = overrideDeveloperDir ?? autoDetectedDeveloperDir
        guard let dir, !dir.isEmpty else { return nil }
        return ["DEVELOPER_DIR": dir]
    }

    /// 启动期间自动发现的 Xcode。故意不写入 UserDefaults：
    /// 用户下次安装第二个 Xcode 时，应用仍会重新评估候选，而不是默默沿用旧版本。
    private static var autoDetectedDeveloperDir: String?

    // MARK: - 环境预检

    struct Environment: Equatable {
        var developerDir: String
        var xcodeVersion: String
        var xcodeBuildNumber: String

        /// 已在开发中验证过的 Xcode 主版本上限；超出只温和提示，不阻断。
        static let verifiedMajorVersions: ClosedRange<Int> = 15...27

        var majorVersion: Int {
            Int(xcodeVersion.split(separator: ".").first.map(String.init) ?? "") ?? 0
        }

        var isVerified: Bool { Self.verifiedMajorVersions.contains(majorVersion) }
    }

    enum EnvironmentError: LocalizedError {
        case xcodeSelectFailed(String)
        case xcodeSelectionRequired(String, [XcodeInstall])
        case xcodeNotFound(String)
        case xcodebuildUnavailable(String)

        var errorDescription: String? {
            switch self {
            case .xcodeSelectFailed:
                L10n.t("未能确定 Xcode 位置")
            case .xcodeSelectionRequired:
                L10n.t("请选择要使用的 Xcode")
            case .xcodeNotFound:
                L10n.t("未找到完整的 Xcode")
            case .xcodebuildUnavailable:
                L10n.t("xcodebuild 不可用")
            }
        }

        /// 可执行的修复指引
        var recoveryCommand: String? {
            switch self {
            case .xcodeSelectFailed, .xcodeSelectionRequired, .xcodeNotFound:
                nil
            case .xcodebuildUnavailable:
                "xcode-select --install"
            }
        }

        var detail: String {
            switch self {
            case .xcodeSelectFailed(let d),
                 .xcodeSelectionRequired(let d, _),
                 .xcodeNotFound(let d),
                 .xcodebuildUnavailable(let d):
                d
            }
        }

        var recoveryXcodes: [XcodeInstall] {
            guard case .xcodeSelectionRequired(_, let xcodes) = self else { return [] }
            return xcodes
        }
    }

    /// 启动时预检：Xcode 是否安装、命令行工具是否选定、xcodebuild 是否可用。
    static func detect() async throws -> Environment {
        let selectedDeveloperDir: String
        var selectionFailure: String?

        if let override = overrideDeveloperDir, isUsableDeveloperDir(override) {
            selectedDeveloperDir = override
        } else {
            if overrideDeveloperDir != nil {
                // 已保存的 Xcode 已被删除或移动，先回退到当前系统选择。
                overrideDeveloperDir = nil
            }
            let result = try await ProcessRunner.run(xcodeSelectPath, ["-p"], timeout: 15)
            if result.isSuccess {
                selectedDeveloperDir = result.stdout.trimmingCharacters(in: .whitespacesAndNewlines)
            } else {
                selectedDeveloperDir = ""
                selectionFailure = result.combinedTrimmed
            }
        }

        let developerDir: String
        if isUsableDeveloperDir(selectedDeveloperDir) {
            autoDetectedDeveloperDir = nil
            developerDir = selectedDeveloperDir
        } else {
            let installed = listInstalledXcodes()
            if installed.count == 1, let xcode = installed.first {
                // 只影响本应用。后续所有子进程通过 DEVELOPER_DIR 使用这个 Xcode。
                autoDetectedDeveloperDir = xcode.developerDir
                developerDir = xcode.developerDir
            } else if !installed.isEmpty {
                throw EnvironmentError.xcodeSelectionRequired(selectedDeveloperDir, installed)
            } else if let selectionFailure {
                throw EnvironmentError.xcodeSelectFailed(selectionFailure)
            } else {
                throw EnvironmentError.xcodeNotFound(selectedDeveloperDir)
            }
        }

        let version = try await ProcessRunner.run(
            xcodebuildPath, ["-version"],
            environment: ["DEVELOPER_DIR": developerDir],
            timeout: 30
        )
        guard version.isSuccess else {
            throw EnvironmentError.xcodebuildUnavailable(version.combinedTrimmed)
        }

        // Xcode 27.0
        // Build version 27A266a
        var xcodeVersion = ""
        var buildNumber = ""
        for line in version.stdout.split(separator: "\n") {
            if line.hasPrefix("Xcode ") {
                xcodeVersion = String(line.dropFirst("Xcode ".count)).trimmingCharacters(in: .whitespaces)
            } else if line.hasPrefix("Build version ") {
                buildNumber = String(line.dropFirst("Build version ".count)).trimmingCharacters(in: .whitespaces)
            }
        }

        return Environment(
            developerDir: developerDir,
            xcodeVersion: xcodeVersion.isEmpty ? L10n.t("未知") : xcodeVersion,
            xcodeBuildNumber: buildNumber
        )
    }

    // MARK: - 已安装的 Xcode

    struct XcodeInstall: Identifiable, Hashable {
        var id: String { developerDir }
        let appURL: URL
        let developerDir: String
        let displayName: String
    }

    /// 扫描系统与当前用户的 Applications 目录，寻找可用的完整 Xcode。
    static func listInstalledXcodes() -> [XcodeInstall] {
        let roots = [
            URL(fileURLWithPath: "/Applications", isDirectory: true),
            FileManager.default.homeDirectoryForCurrentUser
                .appendingPathComponent("Applications", isDirectory: true),
        ]
        var seen = Set<String>()
        var installs: [XcodeInstall] = []

        for root in roots {
            guard let contents = try? FileManager.default.contentsOfDirectory(
                at: root,
                includingPropertiesForKeys: [.isApplicationKey],
                options: [.skipsHiddenFiles]
            ) else { continue }

            for appURL in contents where appURL.pathExtension.caseInsensitiveCompare("app") == .orderedSame {
                guard let install = xcodeInstall(at: appURL) else { continue }
                let key = install.appURL.standardizedFileURL.path
                guard seen.insert(key).inserted else { continue }
                installs.append(install)
            }
        }

        return installs.sorted {
            $0.displayName.localizedStandardCompare($1.displayName) == .orderedAscending
        }
    }

    /// 将用户选择的应用校验并转换为可用的 Xcode 安装。
    static func xcodeInstall(at appURL: URL) -> XcodeInstall? {
        let normalizedURL = appURL.standardizedFileURL
        guard normalizedURL.pathExtension.caseInsensitiveCompare("app") == .orderedSame else {
            return nil
        }

        let developer = normalizedURL.appendingPathComponent("Contents/Developer", isDirectory: true)
        guard isUsableDeveloperDir(developer.path) else { return nil }

        let bundle = Bundle(url: normalizedURL)
        guard bundle?.bundleIdentifier == "com.apple.dt.Xcode" else { return nil }

        let info = bundle?.infoDictionary
        let version = info?["CFBundleShortVersionString"] as? String
        let build = info?["CFBundleVersion"] as? String
        let appName = normalizedURL.deletingPathExtension().lastPathComponent
        let display: String
        if let version, let build {
            display = "\(appName) \(version) (\(build))"
        } else if let version {
            display = "\(appName) \(version)"
        } else {
            display = appName
        }
        return XcodeInstall(
            appURL: normalizedURL,
            developerDir: developer.path,
            displayName: display
        )
    }

    private static func isUsableDeveloperDir(_ path: String) -> Bool {
        guard !path.isEmpty, path.hasSuffix("/Contents/Developer") else { return false }
        let xcodebuild = URL(fileURLWithPath: path)
            .appendingPathComponent("usr/bin/xcodebuild")
        return FileManager.default.isExecutableFile(atPath: xcodebuild.path)
    }
}

/// UserDefaults key 的集中定义，避免字符串散落。
enum DefaultsKey {
    static let recentProjects = "xcc.recentProjects" // 托管项目列表（历史键名保留）
    static let currentProjectID = "xcc.currentProjectID"
    static let panelTopLeft = "xcc.panelTopLeft"
    static let developerDirOverride = "xcc.developerDir"
    static let useSharedDerivedData = "xcc.useSharedDerivedData" // 迁移用，新逻辑读 derivedDataLocation
    static let derivedDataLocation = "xcc.derivedDataLocation"
    static let customDerivedDataRoot = "xcc.customDerivedDataRoot"
    static let attachConsole = "xcc.attachConsole"
    static let logPaneExpanded = "xcc.logPaneExpanded"

    // DerivedData 自动回收
    static let autoReapOrphans = "xcc.autoReapOrphans"
    static let autoReapStaleEnabled = "xcc.autoReapStaleEnabled"
    static let autoReapStaleDays = "xcc.autoReapStaleDays"
    static let lastReapAt = "xcc.lastReapAt"

    // 通用
    static let dimOnResign = "xcc.dimOnResign"
    static let dimmedOpacity = "xcc.dimmedOpacity"
    static let showPanelOnLaunch = "xcc.showPanelOnLaunch"
    static let showSettingsOnLaunch = "xcc.showSettingsOnLaunch"
    static let showGitBranch = "xcc.showGitBranch"
    static let logCapacity = "xcc.logCapacity"

    // 构建
    static let autoExpandLogOnFailure = "xcc.autoExpandLogOnFailure"

    // 行为
    static let notifyOnSuccess = "xcc.notifyOnSuccess"
    static let soundOnSuccess = "xcc.soundOnSuccess"
    static let notifyOnFailure = "xcc.notifyOnFailure"
    static let soundOnFailure = "xcc.soundOnFailure"
    static let hotKeysEnabled = "xcc.hotKeysEnabled"
    static let hotKeyRunKeyCode = "xcc.hotKeyRun.keyCode"
    static let hotKeyRunModifiers = "xcc.hotKeyRun.modifiers"
    static let hotKeyStopKeyCode = "xcc.hotKeyStop.keyCode"
    static let hotKeyStopModifiers = "xcc.hotKeyStop.modifiers"

    // 语言。缺键 = 跟随系统，因此这里存的是可选值而不是带 "system" 哨兵的字符串。
    static let appLanguage = "xcc.appLanguage"
}
