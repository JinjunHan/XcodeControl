//
//  AppIconLoader.swift
//  XcodeControl
//

import AppKit
import Foundation

/// 从工程源码树读取 AppIcon，不依赖 `xcodebuild`（选项目时就要显示，等构建设置太慢）。
///
/// 策略：在工程包同级目录下广度搜索 `*.appiconset`，优先 `AppIcon.appiconset`，
/// 再从 Contents.json / 目录内位图里挑一张合适尺寸的图。
enum AppIconLoader {

    private static let skipDirectoryNames: Set<String> = [
        "Pods", "_Pods", "Carthage", "DerivedData", ".build", "build",
        "node_modules", ".git", ".svn", ".hg", "xcuserdata",
    ]

    private static let skipPackageExtensions: Set<String> = [
        "xcodeproj", "xcworkspace", "framework", "bundle", "app", "appex",
    ]

    /// 返回最适合列表展示的图标文件路径；找不到则 nil。
    static func bestImageFile(forProjectAt projectURL: URL) -> URL? {
        let root = projectURL.deletingLastPathComponent()
        return findBestImageFile(under: root)
    }

    // MARK: - 搜索

    private static func findBestImageFile(under root: URL) -> URL? {
        let fm = FileManager.default
        var queue: [URL] = [root]
        var cursor = 0
        var fallback: URL?

        while cursor < queue.count {
            let dir = queue[cursor]
            cursor += 1

            guard let children = try? fm.contentsOfDirectory(
                at: dir,
                includingPropertiesForKeys: [.isDirectoryKey],
                options: [.skipsHiddenFiles]
            ) else { continue }

            for child in children {
                let name = child.lastPathComponent
                if skipDirectoryNames.contains(name) { continue }

                if name.hasSuffix(".appiconset") {
                    guard let image = bestFile(inAppIconSet: child) else { continue }
                    let base = (name as NSString).deletingPathExtension
                    // 主 App 几乎总叫 AppIcon；立刻返回，避免再扫到 Widget 的同名槽
                    if base == "AppIcon" {
                        return image
                    }
                    if fallback == nil {
                        fallback = image
                    }
                    continue
                }

                if skipPackageExtensions.contains(child.pathExtension) {
                    continue
                }

                var isDirectory: ObjCBool = false
                if fm.fileExists(atPath: child.path, isDirectory: &isDirectory),
                   isDirectory.boolValue {
                    queue.append(child)
                }
            }
        }

        return fallback
    }

    // MARK: - 解析 appiconset

    private static func bestFile(inAppIconSet setURL: URL) -> URL? {
        let fm = FileManager.default
        var scored: [(score: Int, url: URL)] = []

        if let entries = parseContents(at: setURL.appendingPathComponent("Contents.json")) {
            for entry in entries {
                guard let filename = entry.filename, !filename.isEmpty else { continue }
                let file = setURL.appendingPathComponent(filename)
                guard fm.fileExists(atPath: file.path) else { continue }
                scored.append((score(for: entry), file))
            }
        }

        if scored.isEmpty {
            let allowed: Set<String> = ["png", "jpg", "jpeg", "icns"]
            if let files = try? fm.contentsOfDirectory(
                at: setURL,
                includingPropertiesForKeys: nil,
                options: [.skipsHiddenFiles]
            ) {
                for file in files where allowed.contains(file.pathExtension.lowercased()) {
                    scored.append((50, file))
                }
            }
        }

        return scored.max(by: { $0.score < $1.score })?.url
    }

    private struct ContentsFile: Decodable {
        struct ImageEntry: Decodable {
            let filename: String?
            let size: String?
            let scale: String?
            let idiom: String?
        }
        let images: [ImageEntry]?
    }

    private static func parseContents(at url: URL) -> [ContentsFile.ImageEntry]? {
        guard let data = try? Data(contentsOf: url),
              let decoded = try? JSONDecoder().decode(ContentsFile.self, from: data)
        else { return nil }
        return decoded.images
    }

    /// 列表约 16–20pt：偏好 64–128px 实图像素；没有则越大越好。
    private static func score(for entry: ContentsFile.ImageEntry) -> Int {
        let scale = Int(entry.scale?.replacingOccurrences(of: "x", with: "") ?? "1") ?? 1
        var side = 0
        if let size = entry.size,
           let width = size.split(separator: "x").first,
           let value = Double(width) {
            side = Int(value * Double(scale))
        }
        if side == 0 { return 10 }
        if (64...128).contains(side) { return 200 + side }
        if (32...256).contains(side) { return 100 + side }
        return side
    }

    // MARK: - 缩略图

    /// 压到固定边长，避免把 1024 原图常驻在列表缓存里。
    static func thumbnail(from fileURL: URL, side: CGFloat = 64) -> NSImage? {
        guard let source = NSImage(contentsOf: fileURL) else { return nil }
        let size = NSSize(width: side, height: side)
        return NSImage(size: size, flipped: false) { rect in
            NSGraphicsContext.current?.imageInterpolation = .high
            source.draw(
                in: rect,
                from: NSRect(origin: .zero, size: source.size),
                operation: .copy,
                fraction: 1
            )
            return true
        }
    }
}
