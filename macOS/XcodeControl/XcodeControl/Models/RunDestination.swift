//
//  RunDestination.swift
//  XcodeControl
//

import Foundation

/// 一个可运行的目标：iOS 模拟器、已连接真机，或本机 macOS。
struct RunDestination: Identifiable, Hashable, Codable {

    // MARK: - 子类型

    enum Source: String, Codable, Hashable, CaseIterable {
        case simulator
        case device
        case mac

        var groupTitle: String {
            switch self {
            case .simulator: L10n.t("模拟器")
            case .device: L10n.t("已连接设备")
            case .mac: L10n.t("本机")
            }
        }

        /// 分组在下拉列表中的排序权重
        var sortOrder: Int {
            switch self {
            case .device: 0
            case .simulator: 1
            case .mac: 2
            }
        }
    }

    enum Platform: String, Codable, Hashable {
        case iOS
        case iPadOS
        case macOS
        case tvOS
        case watchOS
        case visionOS

        /// `-destination` 中真机使用的 platform 名
        var xcodebuildName: String {
            switch self {
            case .iOS, .iPadOS: "iOS"
            case .macOS: "macOS"
            case .tvOS: "tvOS"
            case .watchOS: "watchOS"
            case .visionOS: "visionOS"
            }
        }

        /// `-destination` 中模拟器使用的 platform 名
        var xcodebuildSimulatorName: String { "\(xcodebuildName) Simulator" }

        /// 由 CoreSimulator runtime key 解析，如
        /// `com.apple.CoreSimulator.SimRuntime.iOS-18-2` → (.iOS, "18.2")
        static func fromRuntimeIdentifier(_ identifier: String) -> (platform: Platform, version: String)? {
            let prefix = "com.apple.CoreSimulator.SimRuntime."
            guard identifier.hasPrefix(prefix) else { return nil }
            let tail = String(identifier.dropFirst(prefix.count))   // iOS-18-2
            let parts = tail.split(separator: "-")
            guard let rawPlatform = parts.first else { return nil }
            let version = parts.dropFirst().joined(separator: ".")

            let platform: Platform?
            switch rawPlatform.lowercased() {
            case "ios": platform = .iOS
            case "tvos": platform = .tvOS
            case "watchos": platform = .watchOS
            case "xros", "visionos": platform = .visionOS
            case "macos": platform = .macOS
            default: platform = nil
            }
            guard let platform else { return nil }
            return (platform, version)
        }
    }

    enum State: String, Codable, Hashable {
        case booted
        case shutdown
        case connected
        case disconnected

        var isOnline: Bool { self == .booted || self == .connected }
    }

    enum Family: String, Codable, Hashable {
        case phone
        case pad
        case mac
        case tv
        case watch
        case vision

        /// 下拉面板中的分节标题
        var sectionTitle: String {
            switch self {
            case .phone: "iPhone"
            case .pad: "iPad"
            case .mac: "Mac"
            case .tv: "Apple TV"
            case .watch: "Apple Watch"
            case .vision: "Apple Vision"
            }
        }

        var sortOrder: Int {
            switch self {
            case .phone: 0
            case .pad: 1
            case .mac: 2
            case .vision: 3
            case .tv: 4
            case .watch: 5
            }
        }

        var symbolName: String {
            switch self {
            case .phone: "iphone"
            case .pad: "ipad"
            case .mac: "macbook"
            case .tv: "appletv"
            case .watch: "applewatch"
            case .vision: "visionpro"
            }
        }

        /// 由 `com.apple.CoreSimulator.SimDeviceType.iPhone-16-Pro` 这类标识推断
        static func fromDeviceTypeIdentifier(_ identifier: String) -> Family {
            let lower = identifier.lowercased()
            if lower.contains("ipad") { return .pad }
            if lower.contains("iphone") || lower.contains("ipod") { return .phone }
            if lower.contains("apple-tv") || lower.contains("appletv") { return .tv }
            if lower.contains("watch") { return .watch }
            if lower.contains("vision") || lower.contains("reality") { return .vision }
            return .phone
        }

        /// 由 devicectl 的 `hardwareProperties.deviceType` 推断
        static func fromHardwareDeviceType(_ raw: String) -> Family {
            let lower = raw.lowercased()
            if lower.hasPrefix("ipad") { return .pad }
            if lower.hasPrefix("iphone") || lower.hasPrefix("ipod") { return .phone }
            if lower.hasPrefix("appletv") { return .tv }
            if lower.hasPrefix("watch") || lower.hasPrefix("applewatch") { return .watch }
            if lower.hasPrefix("realitydevice") || lower.contains("vision") { return .vision }
            if lower.hasPrefix("mac") { return .mac }
            return .phone
        }
    }

    // MARK: - 属性

    /// 模拟器为 CoreSimulator UDID；真机为 devicectl identifier；本机固定为 `macos-local`。
    let id: String
    let name: String
    let source: Source
    let platform: Platform
    let osVersion: String
    let state: State
    let deviceFamily: Family

    /// 是否可以直接安装/启动（模拟器未启动时会先 boot，因此模拟器始终可用）
    var isReady: Bool { state.isOnline }

    // MARK: - 派生

    var symbolName: String { deviceFamily.symbolName }

    /// 副标题：`iOS 18.2` / `iOS 18.7 · 已连接`
    var subtitle: String {
        var parts = ["\(platform.xcodebuildName) \(osVersion)"]
        switch state {
        case .booted: parts.append(L10n.t("已启动"))
        case .connected: parts.append(L10n.t("已连接"))
        case .disconnected: parts.append(L10n.t("未连接"))
        case .shutdown: break
        }
        return parts.joined(separator: " · ")
    }

    /// 传给 `xcodebuild -destination` 的字符串
    var xcodebuildDestination: String {
        switch source {
        case .simulator: "platform=\(platform.xcodebuildSimulatorName),id=\(id)"
        case .device: "platform=\(platform.xcodebuildName),id=\(id)"
        case .mac:
            // iOS 工程在 Apple silicon Mac 上的「我的 Mac」不是原生 macOS target。
            // Xcode 用 Designed for iPhone 变体构建出 iPhoneOS App，再通过
            // WrappedBundle 交给 LaunchServices；只传 platform=macOS 会得到一个
            // 看似构建成功、但无法被 macOS 直接打开的 iOS .app。
            "platform=macOS,variant=Designed for iPhone"
        }
    }

    /// 模拟器构建可关闭签名以提速；真机与 macOS 必须保留签名。
    var allowsDisablingCodeSigning: Bool { source == .simulator }

    // MARK: - 本机

    static let macLocalID = "macos-local"

    static func localMac() -> RunDestination {
        RunDestination(
            id: macLocalID,
            name: L10n.t("我的 Mac"),
            source: .mac,
            platform: .macOS,
            osVersion: ProcessInfo.processInfo.operatingSystemVersionString
                .replacingOccurrences(of: "Version ", with: ""),
            state: .connected,
            deviceFamily: .mac
        )
    }
}

extension RunDestination {
    /// 下拉列表的稳定排序：已启动/已连接优先，其次按名称。
    static func displayOrder(_ lhs: RunDestination, _ rhs: RunDestination) -> Bool {
        if lhs.isReady != rhs.isReady { return lhs.isReady }
        if lhs.osVersion != rhs.osVersion { return lhs.osVersion.compare(rhs.osVersion, options: .numeric) == .orderedDescending }
        return lhs.name.localizedStandardCompare(rhs.name) == .orderedAscending
    }
}
