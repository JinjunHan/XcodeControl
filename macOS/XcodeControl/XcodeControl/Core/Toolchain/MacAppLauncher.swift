//
//  MacAppLauncher.swift
//  XcodeControl
//

import AppKit
import Foundation

/// 在 Mac 上启动构建出的 App。
///
/// Xcode 的「My Mac (Designed for iPhone)」产物仍然是 iPhoneOS .app，不能把
/// 这个目录直接交给 NSWorkspace——LaunchServices 会按原生 macOS App 校验，
/// 然后报「不兼容此电脑」。Xcode 实际使用的是一个只包含 WrappedBundle 的
/// 外层容器，里面再放 iOS App；这里复现这个公开可观察到的容器格式，避免
/// 重新打开 Xcode 或把构建/运行流程交还给 IDE。
enum MacAppLauncher {

    struct LaunchResult {
        let application: NSRunningApplication
        /// Designed for iPhone 外层容器。原生 macOS App 为 nil。
        let temporaryContainer: URL?
    }

    enum LaunchError: LocalizedError {
        case productMissing(URL)
        case wrapperPreparationFailed(String)

        var errorDescription: String? {
            switch self {
            case .productMissing(let url):
                L10n.t("构建产物不存在：%@", url.path)
            case .wrapperPreparationFailed(let detail):
                detail.isEmpty
                    ? L10n.t("无法准备 Mac 启动容器")
                    : L10n.t("无法准备 Mac 启动容器：%@", detail)
            }
        }
    }

    private static let temporaryRoot =
        FileManager.default.temporaryDirectory.appendingPathComponent("XcodeControl-MacLaunch", isDirectory: true)

    static func launch(productAt productURL: URL) async throws -> LaunchResult {
        guard FileManager.default.fileExists(atPath: productURL.path) else {
            throw LaunchError.productMissing(productURL)
        }

        let container: URL?
        let launchURL: URL
        if isDesignedForIPhoneApp(at: productURL) {
            let prepared = try makeDesignedForIPhoneContainer(for: productURL)
            container = prepared
            launchURL = prepared
        } else {
            // 原生 macOS scheme 仍然走原来的 LaunchServices 路径。
            container = nil
            launchURL = productURL
        }

        do {
            let configuration = NSWorkspace.OpenConfiguration()
            configuration.activates = true
            configuration.createsNewApplicationInstance = true
            let application = try await NSWorkspace.shared.openApplication(
                at: launchURL,
                configuration: configuration
            )
            return LaunchResult(application: application, temporaryContainer: container)
        } catch {
            if let container { removeContainer(container) }
            throw error
        }
    }

    static func removeContainer(_ url: URL?) {
        guard let url else { return }
        try? FileManager.default.removeItem(at: url)
        // 容器的父目录是 UUID 目录；一并删除空目录，避免每次运行留下垃圾。
        try? FileManager.default.removeItem(at: url.deletingLastPathComponent())
    }

    private static func isDesignedForIPhoneApp(at url: URL) -> Bool {
        // 不依赖 Bundle 的缓存/类型桥接，直接解析最终写入 App 的 Info.plist。
        // CFBundleSupportedPlatforms 可能桥接成 NSArray，PropertyListSerialization
        // 可以稳定地把它读取为 [String]。
        guard let data = try? Data(contentsOf: url.appendingPathComponent("Info.plist")),
              let plist = try? PropertyListSerialization.propertyList(
                  from: data,
                  options: [],
                  format: nil
              ) as? [String: Any]
        else { return false }

        let platforms = (plist["CFBundleSupportedPlatforms"] as? [Any])?.compactMap { $0 as? String } ?? []
        let requiresIPhoneOS = (plist["LSRequiresIPhoneOS"] as? NSNumber)?.boolValue ?? false
        return platforms.contains { $0.caseInsensitiveCompare("iPhoneOS") == .orderedSame }
            || requiresIPhoneOS
    }

    private static func makeDesignedForIPhoneContainer(for productURL: URL) throws -> URL {
        let fileManager = FileManager.default
        let directory = temporaryRoot.appendingPathComponent(UUID().uuidString, isDirectory: true)
        let outerApp = directory.appendingPathComponent(productURL.deletingPathExtension().lastPathComponent + "-Mac.app")
        let wrapperDirectory = outerApp.appendingPathComponent("Wrapper", isDirectory: true)
        let innerApp = wrapperDirectory.appendingPathComponent(productURL.lastPathComponent, isDirectory: true)

        do {
            try fileManager.createDirectory(at: wrapperDirectory, withIntermediateDirectories: true)
            try fileManager.copyItem(at: productURL, to: innerApp)
            // 这个相对链接是 LaunchServices 识别 Designed for iPhone 外层容器的关键。
            // 使用 path 版本而不是 URL 版本：URL(fileURLWithPath:) 会把相对
            // 路径解析成当前工作目录下的绝对路径，导致 WrappedBundle 指向错误位置，
            // LaunchServices 随后会报告外层 App「已损坏 / 缺少可执行文件」。
            try fileManager.createSymbolicLink(
                atPath: outerApp.appendingPathComponent("WrappedBundle").path,
                withDestinationPath: "Wrapper/\(productURL.lastPathComponent)"
            )
            return outerApp
        } catch {
            removeContainer(outerApp)
            throw LaunchError.wrapperPreparationFailed(error.localizedDescription)
        }
    }
}
