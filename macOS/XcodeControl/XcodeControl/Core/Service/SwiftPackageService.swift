//
//  SwiftPackageService.swift
//  XcodeControl
//

import Foundation

/// 当前工程的 Swift Package 文件与项目级缓存管理。
///
/// 这里只处理工程自身的 `Package.resolved` 和 DerivedData/SourcePackages；
/// 不触碰 `~/Library/Caches/org.swift.swiftpm`，因为全局缓存可能同时被其他工程使用。
enum SwiftPackageService {

    struct CacheRemovalResult: Equatable {
        var itemCount: Int
        var bytes: UInt64
        var sourcePackagesURL: URL?
    }

    /// Xcode 把锁定文件放在工程/工作区内部。workspace 还可能引用同目录下的
    /// xcodeproj，因此直达路径不存在时再做一次有边界的同目录探测。
    static func packageResolvedURL(project: URL, kind: XcodeProject.Kind) -> URL? {
        let direct = project
            .appendingPathComponent("xcshareddata", isDirectory: true)
            .appendingPathComponent("swiftpm", isDirectory: true)
            .appendingPathComponent("Package.resolved")
        let projectDirect = project
            .appendingPathComponent("project.xcworkspace", isDirectory: true)
            .appendingPathComponent("xcshareddata", isDirectory: true)
            .appendingPathComponent("swiftpm", isDirectory: true)
            .appendingPathComponent("Package.resolved")

        let candidates = kind == .project ? [projectDirect, direct] : [direct, projectDirect]
        if let existing = candidates.first(where: { FileManager.default.fileExists(atPath: $0.path) }) {
            return existing
        }

        let parent = project.deletingLastPathComponent()
        let siblings = (try? FileManager.default.contentsOfDirectory(
            at: parent,
            includingPropertiesForKeys: nil,
            options: [.skipsHiddenFiles]
        )) ?? []
        for sibling in siblings where sibling.pathExtension == "xcodeproj" {
            let resolved = sibling
                .appendingPathComponent("project.xcworkspace", isDirectory: true)
                .appendingPathComponent("xcshareddata", isDirectory: true)
                .appendingPathComponent("swiftpm", isDirectory: true)
                .appendingPathComponent("Package.resolved")
            if FileManager.default.fileExists(atPath: resolved.path) { return resolved }
        }
        return nil
    }

    /// 返回当前配置真正会使用的 SourcePackages 目录。
    ///
    /// 自定义 DerivedData 能直接定位；Xcode 默认根的目录名带私有哈希，只能根据
    /// `info.plist/WorkspacePath` 反查，绝不能按工程名模糊删除。
    static func sourcePackagesURL(
        project: URL,
        configuredDerivedDataPath: URL?,
        defaultDerivedDataRoot: URL
    ) -> URL? {
        if let configuredDerivedDataPath {
            return configuredDerivedDataPath.appendingPathComponent("SourcePackages", isDirectory: true)
        }

        let fm = FileManager.default
        let children = (try? fm.contentsOfDirectory(
            at: defaultDerivedDataRoot,
            includingPropertiesForKeys: [.isDirectoryKey],
            options: [.skipsHiddenFiles]
        )) ?? []
        let expected = project.standardizedFileURL.path

        for directory in children {
            let info = directory.appendingPathComponent("info.plist")
            guard let data = try? Data(contentsOf: info),
                  let object = try? PropertyListSerialization.propertyList(from: data, format: nil),
                  let dictionary = object as? [String: Any],
                  let workspacePath = dictionary["WorkspacePath"] as? String
            else { continue }

            let actual = URL(fileURLWithPath: workspacePath).standardizedFileURL.path
            guard actual == expected else { continue }
            return directory.appendingPathComponent("SourcePackages", isDirectory: true)
        }
        return nil
    }

    /// 清理项目级 SwiftPM 工作缓存。保留工程内的 Package.resolved，下一次可按锁定版本恢复。
    static func removeProjectCache(at sourcePackagesURL: URL?) async -> CacheRemovalResult {
        guard let sourcePackagesURL else {
            return CacheRemovalResult(itemCount: 0, bytes: 0, sourcePackagesURL: nil)
        }

        return await Task.detached(priority: .utility) {
            let fm = FileManager.default
            let names = ["artifacts", "checkouts", "repositories", "workspace-state.json"]
            var count = 0
            var bytes: UInt64 = 0

            for name in names {
                let url = sourcePackagesURL.appendingPathComponent(name)
                guard fm.fileExists(atPath: url.path) else { continue }
                let size = DiskUsage.directorySizeSync(url) + DiskUsage.fileSizeSync(url)
                do {
                    try fm.removeItem(at: url)
                    count += 1
                    bytes += size
                } catch {
                    continue
                }
            }
            return CacheRemovalResult(itemCount: count, bytes: bytes, sourcePackagesURL: sourcePackagesURL)
        }.value
    }
}
