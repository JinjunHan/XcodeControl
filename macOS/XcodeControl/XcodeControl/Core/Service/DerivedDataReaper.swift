//
//  DerivedDataReaper.swift
//  XcodeControl
//

import Foundation

/// DerivedData 的回收。
///
/// **Xcode 自己从不回收 DerivedData**：没有 TTL，也没有 GC。工程被移动、改名或删除后，
/// Xcode 按新路径的哈希新建一份缓存，旧的那份永远留在磁盘上。
///
/// 需要先澄清一个常见误解：同一工程同一配置的增量构建是**原地覆盖**，并不会每编译一次
/// 叠一层。真正无界增长的是三类——孤儿目录、顶层共享缓存（`ModuleCache.noindex` 等，
/// 按编译器版本与 flag 组合分桶）、以及每个 (配置, SDK) 各存一份的产物。
/// 回收器只处理前一类和「长期没再构建」的整份工程目录；共享缓存不属于任何单个工程，
/// 删不删与「工程是否还在」无关，交给「全部清除」。
enum DerivedDataReaper {

    // MARK: - 模型

    enum Reason: Equatable {
        /// 归属工程已不存在。产物再也不会被任何构建复用，删除没有代价。
        case orphaned
        /// 归属工程还在，但已有 N 天没再构建。删除的代价是下次全量重编。
        case stale(days: Int)
    }

    struct Candidate: Identifiable, Equatable {
        var id: String { url.path }
        let url: URL
        /// 目录名去掉哈希后缀后的工程名，纯展示用
        let displayName: String
        let sizeBytes: UInt64
        let lastUsed: Date
        let reason: Reason
        /// `info.plist` 里记录的工程路径。自定义根目录下没有这个文件，为 nil。
        let workspacePath: String?
        /// 能否确定这份缓存属于哪个工程。false 时删除决策只能靠时间，不能靠孤儿判定。
        let ownerKnown: Bool
    }

    struct Policy {
        /// 已托管工程的真实路径，用于在自定义根目录下反算目录名。
        var knownProjectPaths: [String] = []
        /// 当前工程的路径。它的缓存目录永远不参与回收（默认模式靠 info.plist 归属判定，
        /// 算不出哈希也不至于误删——绝不在受保护清单里用「根目录」凑数）。
        var currentProjectPath: String?
        /// 当前工程的显示名，用于兜底保护：默认模式下 CLI 构建的目录没有 info.plist，
        /// 只能靠「目录名前缀 == 工程名」来认领（如 `XcodeControl-goxfrfs…`）。
        /// 宁可多护一份也绝不误删。
        var currentProjectName: String?
        /// 超过这么多天没再构建就回收；`nil` = 不按时间回收。
        var staleDays: Int?
        /// 是否回收孤儿目录。
        var reapOrphans: Bool = true
        /// 根目录是否与 Xcode 共用（即「默认」模式）。
        var sharesRootWithXcode: Bool
    }

    // MARK: - 常量

    /// 顶层共享缓存的目录名后缀。`ModuleCache.noindex`、`SymbolCache.noindex`、
    /// `SDKStatCaches.noindex`、`CompilationCache.noindex` 都在此列。
    private static let sharedCacheSuffix = ".noindex"

    /// 「这确实是一个 DerivedData 工程目录」的标志物。
    ///
    /// 自定义根目录是用户拿 NSOpenPanel 随便选的——万一选到「文稿」，没有这道闸门
    /// 就会把用户的真实文件当候选删掉。宁可漏删也不能误删：一个都对不上就跳过。
    private static let markers = ["Build", "Index.noindex", "Logs", "info.plist", "SourcePackages"]

    /// 判断「最近有没有再构建」时参考的子目录，取其中最新的修改时间。
    /// 只看目录本身的 mtime 不够：往里写文件不一定会更新父目录的时间戳。
    private static let activityProbes = ["Build", "Index.noindex", "Logs"]

    // MARK: - 扫描

    /// 列出根目录下所有可回收的目录。不做任何删除。
    static func scan(root: URL, policy: Policy) async -> [Candidate] {
        await Task.detached(priority: .utility) {
            scanSync(root: root, policy: policy)
        }.value
    }

    nonisolated static func scanSync(root: URL, policy: Policy) -> [Candidate] {
        let fm = FileManager.default
        guard let children = try? fm.contentsOfDirectory(
            at: root,
            includingPropertiesForKeys: [.isDirectoryKey],
            options: [.skipsHiddenFiles]
        ) else { return [] }

        // 自定义模式下目录名是我们自己用 djb2 算的（见 ProjectService.derivedDataPath），
        // 可以精确反算——托管列表里每个工程对应哪个目录是确定的，对不上的就是孤儿。
        // 默认模式下 Xcode 的哈希是私有算法，算不出来，只能读 info.plist 反查。
        let expectedNames: Set<String>? = policy.sharesRootWithXcode ? nil : Set(
            policy.knownProjectPaths.map {
                ProjectService.derivedDataPath(for: URL(fileURLWithPath: $0), root: root).lastPathComponent
            }
        )

        // 当前工程的缓存要保护起来。两种模式的识别方式不同：自定义模式能直接算出目录名；
        // 默认模式算不出哈希，只能等下面读到 info.plist 时按 WorkspacePath 比对。
        let currentProjectPath = policy.currentProjectPath.map {
            URL(fileURLWithPath: $0).standardizedFileURL.path
        }
        let protectedName: String? = {
            guard !policy.sharesRootWithXcode, let currentProjectPath else { return nil }
            return ProjectService
                .derivedDataPath(for: URL(fileURLWithPath: currentProjectPath), root: root)
                .lastPathComponent
        }()

        let now = Date()
        var result: [Candidate] = []

        for child in children {
            let name = child.lastPathComponent
            guard name.hasSuffix(sharedCacheSuffix) == false else { continue }
            guard (try? child.resourceValues(forKeys: [.isDirectoryKey]))?.isDirectory == true else { continue }
            guard name != protectedName else { continue }
            guard markers.contains(where: { fm.fileExists(atPath: child.appendingPathComponent($0).path) })
            else { continue }

            let workspacePath = workspacePath(in: child)
            if let workspacePath, let currentProjectPath,
               URL(fileURLWithPath: workspacePath).standardizedFileURL.path == currentProjectPath {
                continue
            }
            // 没有 info.plist 时按名字兜底认领当前工程（CLI 构建的目录就是这种）
            if workspacePath == nil, let currentProjectName = policy.currentProjectName,
               displayName(fromDirectoryName: name) == currentProjectName {
                continue
            }

            let ownerKnown: Bool
            let isOrphan: Bool

            if let expectedNames {
                // 自定义根：这个根目录只由本应用写入，摘要对不上就是没人再用的残留
                ownerKnown = true
                isOrphan = !expectedNames.contains(name)
            } else if let workspacePath {
                ownerKnown = true
                isOrphan = !fm.fileExists(atPath: workspacePath)
            } else {
                // 默认根 + 没有 info.plist：无法判定归属。
                // 绝不能当孤儿删——它可能属于一个还在天天用的工程，只是 Xcode 没写这个文件
                //（命令行 xcodebuild 构建出来的目录就没有）。只让时间规则来管。
                ownerKnown = false
                isOrphan = false
            }

            let lastUsed = lastUsedDate(of: child)
            let ageDays = max(0, Int(now.timeIntervalSince(lastUsed) / 86_400))

            let reason: Reason
            if isOrphan, policy.reapOrphans {
                reason = .orphaned
            } else if let staleDays = policy.staleDays, ageDays >= staleDays {
                reason = .stale(days: ageDays)
            } else {
                continue
            }

            result.append(
                Candidate(
                    url: child,
                    displayName: displayName(fromDirectoryName: name),
                    sizeBytes: DiskUsage.directorySizeSync(child),
                    lastUsed: lastUsed,
                    reason: reason,
                    workspacePath: workspacePath,
                    ownerKnown: ownerKnown
                )
            )
        }

        return result.sorted { $0.sizeBytes > $1.sizeBytes }
    }

    // MARK: - 删除

    /// 删除给定候选，返回实际清出的字节数与条目数。失败的条目静默跳过
    /// （目录可能正被 Xcode 持有），不把「少删了一个缓存」升格成用户可见的错误。
    @discardableResult
    static func remove(_ candidates: [Candidate]) async -> (count: Int, bytes: UInt64) {
        await Task.detached(priority: .utility) {
            var count = 0
            var bytes: UInt64 = 0
            for candidate in candidates {
                do {
                    try FileManager.default.removeItem(at: candidate.url)
                    count += 1
                    bytes += candidate.sizeBytes
                } catch {
                    continue
                }
            }
            return (count, bytes)
        }.value
    }

    // MARK: - 私有

    /// 读 `info.plist` 的 `WorkspacePath`。这是 Xcode 记录「这份缓存属于谁」的唯一位置。
    nonisolated private static func workspacePath(in directory: URL) -> String? {
        let plist = directory.appendingPathComponent("info.plist")
        guard let data = try? Data(contentsOf: plist),
              let object = try? PropertyListSerialization.propertyList(from: data, format: nil),
              let dict = object as? [String: Any],
              let path = dict["WorkspacePath"] as? String,
              !path.isEmpty
        else { return nil }
        return path
    }

    nonisolated private static func lastUsedDate(of directory: URL) -> Date {
        var newest = modificationDate(of: directory) ?? .distantPast
        for probe in activityProbes {
            if let date = modificationDate(of: directory.appendingPathComponent(probe)), date > newest {
                newest = date
            }
        }
        return newest
    }

    nonisolated private static func modificationDate(of url: URL) -> Date? {
        (try? url.resourceValues(forKeys: [.contentModificationDateKey]))?.contentModificationDate
    }

    /// `StepSnack-hijsvcpiihohiffnbijieuyxvden` → `StepSnack`。
    /// 哈希段是纯小写字母且很长，据此切掉；切不掉就原样返回。
    nonisolated private static func displayName(fromDirectoryName name: String) -> String {
        guard let separator = name.lastIndex(of: "-") else { return name }
        let suffix = name[name.index(after: separator)...]
        guard suffix.count >= 8, suffix.allSatisfy({ $0.isLowercase && $0.isLetter }) else { return name }
        return String(name[..<separator])
    }
}

// MARK: - DiskUsage

/// 文件体积计算。不继承 MainActor，可在 `Task.detached` 里跑。
enum DiskUsage {

    static func measure(derivedDataRoot: URL?, cacheFile: URL?) async -> (UInt64, UInt64) {
        let root = derivedDataRoot
        let cache = cacheFile
        return await Task.detached(priority: .utility) {
            let dd = root.map { directorySizeSync($0) } ?? 0
            let cf = cache.map { fileSizeSync($0) } ?? 0
            return (dd, cf)
        }.value
    }

    static func directorySize(_ url: URL) async -> UInt64 {
        await Task.detached(priority: .utility) {
            directorySizeSync(url)
        }.value
    }

    static func fileSize(_ url: URL) async -> UInt64 {
        await Task.detached(priority: .utility) {
            fileSizeSync(url)
        }.value
    }

    nonisolated static func directorySizeSync(_ url: URL) -> UInt64 {
        guard let enumerator = FileManager.default.enumerator(
            at: url,
            includingPropertiesForKeys: [.fileSizeKey, .isRegularFileKey],
            options: [.skipsHiddenFiles]
        ) else { return 0 }
        var total: UInt64 = 0
        for case let fileURL as URL in enumerator {
            guard let values = try? fileURL.resourceValues(forKeys: [.fileSizeKey, .isRegularFileKey]),
                  values.isRegularFile == true,
                  let size = values.fileSize
            else { continue }
            total += UInt64(size)
        }
        return total
    }

    nonisolated static func fileSizeSync(_ url: URL) -> UInt64 {
        guard let attrs = try? FileManager.default.attributesOfItem(atPath: url.path),
              let size = attrs[.size] as? UInt64 else { return 0 }
        return size
    }

    nonisolated static func formatBytes(_ bytes: UInt64) -> String {
        if bytes == 0 { return "0 KB" }
        let kb = Double(bytes) / 1024.0
        if kb < 1024 { return String(format: "%.1f KB", kb) }
        let mb = kb / 1024.0
        if mb < 1024 { return String(format: "%.1f MB", mb) }
        let gb = mb / 1024.0
        return String(format: "%.2f GB", gb)
    }
}
