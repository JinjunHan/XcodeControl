//
//  Preferences.swift
//  XcodeControl
//

import Foundation
import Observation

/// DerivedData 位置策略，对齐 Xcode Locations 的 Default / Custom。
enum DerivedDataLocation: String, CaseIterable, Identifiable {
    /// 与 Xcode 共用 `~/Library/Developer/Xcode/DerivedData`（不传 `-derivedDataPath`）
    case `default`
    /// 使用自定义根目录；其下再按工程分子目录
    case custom

    var id: String { rawValue }

    var menuTitle: String {
        switch self {
        case .default: L10n.t("默认")
        case .custom: L10n.t("自定义")
        }
    }
}

/// 全部标量配置的集中管理。
///
/// 每个属性的 didSet 回写 UserDefaults，不再散落在各个 Store 里。
/// 迁移自 RunController 的 useSharedDerivedData / attachConsole，以及所有硬编码常量。
@MainActor
@Observable
final class Preferences {

    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults

        // DerivedData：优先新键；否则从旧布尔开关迁移
        if let raw = defaults.string(forKey: DefaultsKey.derivedDataLocation),
           let location = DerivedDataLocation(rawValue: raw) {
            self.derivedDataLocation = location
        } else {
            let shared = defaults.object(forKey: DefaultsKey.useSharedDerivedData) as? Bool ?? true
            self.derivedDataLocation = shared ? .default : .custom
        }
        self.customDerivedDataRoot = defaults.string(forKey: DefaultsKey.customDerivedDataRoot)
            ?? ProjectService.defaultCustomDerivedDataRoot.path

        self.attachConsole = defaults.object(forKey: DefaultsKey.attachConsole) as? Bool ?? true

        // 自动回收：孤儿默认开（删除没有代价），按时间回收默认关（代价是全量重编）
        self.autoReapOrphans = defaults.object(forKey: DefaultsKey.autoReapOrphans) as? Bool ?? true
        self.autoReapStaleEnabled = defaults.object(forKey: DefaultsKey.autoReapStaleEnabled) as? Bool ?? false
        self.autoReapStaleDays = defaults.object(forKey: DefaultsKey.autoReapStaleDays) as? Int ?? 30
        self.lastReapAt = defaults.object(forKey: DefaultsKey.lastReapAt) as? Date

        // 新增配置的初值
        self.dimOnResign = defaults.object(forKey: DefaultsKey.dimOnResign) as? Bool ?? true
        self.dimmedOpacity = defaults.object(forKey: DefaultsKey.dimmedOpacity) as? Double ?? 0.92
        self.showPanelOnLaunch = defaults.object(forKey: DefaultsKey.showPanelOnLaunch) as? Bool ?? true
        self.showSettingsOnLaunch = defaults.object(forKey: DefaultsKey.showSettingsOnLaunch) as? Bool ?? false
        self.showGitBranch = defaults.object(forKey: DefaultsKey.showGitBranch) as? Bool ?? true
        self.logCapacity = defaults.object(forKey: DefaultsKey.logCapacity) as? Int ?? 5000
        self.autoExpandLogOnFailure = defaults.object(forKey: DefaultsKey.autoExpandLogOnFailure) as? Bool ?? true

        self.notifyOnSuccess = defaults.bool(forKey: DefaultsKey.notifyOnSuccess)
        self.soundOnSuccess = defaults.bool(forKey: DefaultsKey.soundOnSuccess)
        self.notifyOnFailure = defaults.object(forKey: DefaultsKey.notifyOnFailure) as? Bool ?? true
        self.soundOnFailure = defaults.bool(forKey: DefaultsKey.soundOnFailure)

        self.hotKeysEnabled = defaults.object(forKey: DefaultsKey.hotKeysEnabled) as? Bool ?? true
        // Carbon：optionKey(2048) | cmdKey(256) = 2304；R=15，S=1
        self.hotKeyRunKeyCode = defaults.object(forKey: DefaultsKey.hotKeyRunKeyCode) as? UInt32 ?? 15  // ⌥⌘R
        self.hotKeyRunModifiers = defaults.object(forKey: DefaultsKey.hotKeyRunModifiers) as? UInt32 ?? 2304
        self.hotKeyStopKeyCode = defaults.object(forKey: DefaultsKey.hotKeyStopKeyCode) as? UInt32 ?? 1  // ⌥⌘S
        self.hotKeyStopModifiers = defaults.object(forKey: DefaultsKey.hotKeyStopModifiers) as? UInt32 ?? 2304


        // 语言：缺键表示跟随系统。存了无法识别的值（降级安装、手改 plist）也当跟随系统。
        self.appLanguage = defaults.string(forKey: DefaultsKey.appLanguage)
            .flatMap(AppLanguage.init(rawValue:))

        // 查表器是静态的，必须在任何 UI 取文案之前对齐，否则首帧会是中文原文。
        Localization.setCurrent(resolvedLanguage)
    }

    // MARK: - 构建 / 位置

    /// 对齐 Xcode Locations：默认 = 共享 Xcode DerivedData；自定义 = 独立根目录。
    var derivedDataLocation: DerivedDataLocation {
        didSet {
            defaults.set(derivedDataLocation.rawValue, forKey: DefaultsKey.derivedDataLocation)
            // 保持旧键同步，避免其他残留读取分叉
            defaults.set(derivedDataLocation == .default, forKey: DefaultsKey.useSharedDerivedData)
        }
    }

    /// 自定义模式下的 DerivedData 根目录（其下再按工程分子目录）。
    var customDerivedDataRoot: String {
        didSet { defaults.set(customDerivedDataRoot, forKey: DefaultsKey.customDerivedDataRoot) }
    }

    /// 传给 xcodebuild 的 `-derivedDataPath`；默认模式返回 `nil`。
    func derivedDataPath(for project: URL) -> URL? {
        switch derivedDataLocation {
        case .default:
            return nil
        case .custom:
            let root = URL(fileURLWithPath: customDerivedDataRoot, isDirectory: true)
            return ProjectService.derivedDataPath(for: project, root: root)
        }
    }

    /// 设置页展示 / 清理用的根目录。
    var activeDerivedDataRoot: URL {
        switch derivedDataLocation {
        case .default:
            return ProjectService.xcodeDefaultDerivedDataRoot
        case .custom:
            return URL(fileURLWithPath: customDerivedDataRoot, isDirectory: true)
        }
    }

    /// 组装回收策略。自动回收与设置页的「立即回收」共用这里，避免两条路径的判定标准漂移。
    ///
    /// - Parameters:
    ///   - knownProjectPaths: 托管列表里所有工程的真实路径。
    ///   - currentProjectPath: 当前工程的路径；它的缓存目录永远不参与回收——
    ///     用户下一步大概率就要构建它，删了等于凭空多一次全量编译。
    ///   - ignoringUserToggles: 设置页手动触发时传 true，这时两项判定都跑，
    ///     让用户即使没开自动回收也能看到完整的可回收列表。
    func reapPolicy(
        knownProjectPaths: [String],
        currentProjectPath: String?,
        ignoringUserToggles: Bool = false
    ) -> DerivedDataReaper.Policy {
        DerivedDataReaper.Policy(
            knownProjectPaths: knownProjectPaths,
            currentProjectPath: currentProjectPath,
            currentProjectName: currentProjectPath.map {
                ProjectService.displayName(for: URL(fileURLWithPath: $0))
            },
            staleDays: (ignoringUserToggles || autoReapStaleEnabled) ? autoReapStaleDays : nil,
            reapOrphans: ignoringUserToggles || autoReapOrphans,
            sharesRootWithXcode: derivedDataLocation == .default
        )
    }

    var attachConsole: Bool {
        didSet { defaults.set(attachConsole, forKey: DefaultsKey.attachConsole) }
    }

    // MARK: - DerivedData 自动回收

    /// 回收归属工程已不存在的缓存目录。
    ///
    /// 默认开：这些产物再也不会被任何构建复用，删除没有代价。
    /// 判定的可靠性依赖位置模式——自定义根下目录名是我们自己算的摘要，可精确反算；
    /// 默认根下只能读 `info.plist` 的 `WorkspacePath`，读不到的一律不当孤儿。
    var autoReapOrphans: Bool {
        didSet { defaults.set(autoReapOrphans, forKey: DefaultsKey.autoReapOrphans) }
    }

    /// 回收长期没再构建的缓存目录。
    ///
    /// 默认关：与孤儿不同，这里删的是**还在用的工程**的缓存，代价是下次全量重编。
    /// 要不要拿一次全量编译换磁盘空间，只能由用户自己判断。
    var autoReapStaleEnabled: Bool {
        didSet { defaults.set(autoReapStaleEnabled, forKey: DefaultsKey.autoReapStaleEnabled) }
    }

    var autoReapStaleDays: Int {
        didSet { defaults.set(autoReapStaleDays, forKey: DefaultsKey.autoReapStaleDays) }
    }

    /// 上次自动回收的时间，用于「每天最多一次」的节流。
    ///
    /// 扫描要遍历每个工程目录算体积，在 39G 的根目录上是秒级 IO；
    /// 每次构建成功都跑一遍会和用户紧接着的操作抢磁盘。
    var lastReapAt: Date? {
        didSet {
            if let lastReapAt {
                defaults.set(lastReapAt, forKey: DefaultsKey.lastReapAt)
            } else {
                defaults.removeObject(forKey: DefaultsKey.lastReapAt)
            }
        }
    }

    var autoExpandLogOnFailure: Bool {
        didSet { defaults.set(autoExpandLogOnFailure, forKey: DefaultsKey.autoExpandLogOnFailure) }
    }

    // MARK: - 通用

    var dimOnResign: Bool {
        didSet { defaults.set(dimOnResign, forKey: DefaultsKey.dimOnResign) }
    }

    var dimmedOpacity: Double {
        didSet { defaults.set(dimmedOpacity, forKey: DefaultsKey.dimmedOpacity) }
    }

    var showPanelOnLaunch: Bool {
        didSet { defaults.set(showPanelOnLaunch, forKey: DefaultsKey.showPanelOnLaunch) }
    }

    /// 启动应用时是否自动打开设置窗口。
    var showSettingsOnLaunch: Bool {
        didSet { defaults.set(showSettingsOnLaunch, forKey: DefaultsKey.showSettingsOnLaunch) }
    }

    /// 状态行是否显示当前 Git branch（也就是分支切换入口）。
    ///
    /// 默认开：分支是「这次构建到底编的是哪份代码」的唯一线索，多工作树场景下尤其。
    /// 但不用 Git 或只有单一分支的用户，这一格就是纯占位——关掉后状态行连带
    /// 悬停时的 `git` 探测一起省掉，见 `AppState.setHovering(_:)`。
    ///
    /// 写入请走 `AppState.setShowsGitBranch(_:)`：关掉时得顺手收起已展开的分支面板，
    /// 否则入口没了、面板还在，用户找不到关闭它的地方。
    var showGitBranch: Bool {
        didSet { defaults.set(showGitBranch, forKey: DefaultsKey.showGitBranch) }
    }

    var logCapacity: Int {
        didSet { defaults.set(logCapacity, forKey: DefaultsKey.logCapacity) }
    }

    // MARK: - 行为

    var notifyOnSuccess: Bool {
        didSet { defaults.set(notifyOnSuccess, forKey: DefaultsKey.notifyOnSuccess) }
    }

    var soundOnSuccess: Bool {
        didSet { defaults.set(soundOnSuccess, forKey: DefaultsKey.soundOnSuccess) }
    }

    var notifyOnFailure: Bool {
        didSet { defaults.set(notifyOnFailure, forKey: DefaultsKey.notifyOnFailure) }
    }

    var soundOnFailure: Bool {
        didSet { defaults.set(soundOnFailure, forKey: DefaultsKey.soundOnFailure) }
    }

    var hotKeysEnabled: Bool {
        didSet { defaults.set(hotKeysEnabled, forKey: DefaultsKey.hotKeysEnabled) }
    }

    var hotKeyRunKeyCode: UInt32 {
        didSet { defaults.set(hotKeyRunKeyCode, forKey: DefaultsKey.hotKeyRunKeyCode) }
    }

    var hotKeyRunModifiers: UInt32 {
        didSet { defaults.set(hotKeyRunModifiers, forKey: DefaultsKey.hotKeyRunModifiers) }
    }

    var hotKeyStopKeyCode: UInt32 {
        didSet { defaults.set(hotKeyStopKeyCode, forKey: DefaultsKey.hotKeyStopKeyCode) }
    }

    var hotKeyStopModifiers: UInt32 {
        didSet { defaults.set(hotKeyStopModifiers, forKey: DefaultsKey.hotKeyStopModifiers) }
    }

    // MARK: - 语言

    /// 用户显式选择的界面语言；`nil` 表示跟随系统。
    ///
    /// 保留 `nil` 这一档而不是启动时把系统语言固化下来：用户在系统里改了
    /// 首选语言后，本应用应当跟着变，固化就会把它钉死在第一次启动时的那门语言。
    ///
    /// 写入请走 `AppState.setLanguage(_:)`——那里会同步刷新查表器并重建界面。
    var appLanguage: AppLanguage? {
        didSet {
            if let appLanguage {
                defaults.set(appLanguage.rawValue, forKey: DefaultsKey.appLanguage)
            } else {
                defaults.removeObject(forKey: DefaultsKey.appLanguage)
            }
        }
    }

    /// 实际生效的语言：显式选择优先，否则按系统首选语言列表匹配。
    var resolvedLanguage: AppLanguage {
        appLanguage ?? AppLanguage.matchingSystem()
    }
}
