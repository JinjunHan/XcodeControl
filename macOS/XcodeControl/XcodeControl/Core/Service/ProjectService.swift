//
//  ProjectService.swift
//  XcodeControl
//

import Foundation

/// 项目的识别与解析。
enum ProjectService {

    enum ProjectError: LocalizedError {
        case notAnXcodeProject(String)
        case ambiguousDirectory(String)

        var errorDescription: String? {
            switch self {
            case .notAnXcodeProject(let path):
                L10n.t("%@ 不是 Xcode 工程", (path as NSString).lastPathComponent)
            case .ambiguousDirectory(let path):
                L10n.t("%@ 中找不到 .xcodeproj 或 .xcworkspace", (path as NSString).lastPathComponent)
            }
        }
    }

    /// 把用户选中/拖入的路径规范化为一个工程。
    ///
    /// 规则：若选择的是目录且内部存在 `.xcworkspace`，优先使用 workspace
    ///（CocoaPods 项目必须如此）；若同时存在 `Package.swift`，仍以 xcodeproj/xcworkspace 为准。
    static func normalize(_ url: URL) throws -> (url: URL, kind: XcodeProject.Kind) {
        let path = url.path

        if path.hasSuffix(".xcworkspace") {
            return (url, .workspace)
        }
        if path.hasSuffix(".xcodeproj") {
            // 同目录下若存在同名 workspace，优先用 workspace
            let sibling = url.deletingPathExtension().appendingPathExtension("xcworkspace")
            if FileManager.default.fileExists(atPath: sibling.path) {
                return (sibling, .workspace)
            }
            return (url, .project)
        }

        var isDirectory: ObjCBool = false
        guard FileManager.default.fileExists(atPath: path, isDirectory: &isDirectory), isDirectory.boolValue else {
            throw ProjectError.notAnXcodeProject(path)
        }

        let contents = (try? FileManager.default.contentsOfDirectory(at: url, includingPropertiesForKeys: nil)) ?? []
        if let workspace = contents.first(where: { $0.pathExtension == "xcworkspace" }) {
            return (workspace, .workspace)
        }
        if let project = contents.first(where: { $0.pathExtension == "xcodeproj" }) {
            return (project, .project)
        }
        throw ProjectError.ambiguousDirectory(path)
    }

    /// 拖放 / 打开面板用的路径展开：工程包原样返回；项目文件夹优先 `normalize`，
    /// 否则按广度扫描收一批工程（例如拖入包含多个 App 的父目录）。
    static func expandDroppedURLs(_ urls: [URL]) -> [URL] {
        var result: [URL] = []
        var seen = Set<String>()

        for url in urls {
            let candidates: [URL]
            let ext = url.pathExtension
            if ext == "xcodeproj" || ext == "xcworkspace" {
                candidates = [url]
            } else if let normalized = try? normalize(url).url {
                candidates = [normalized]
            } else {
                candidates = discoverProjects(under: url)
            }

            for candidate in candidates {
                let key = candidate.standardizedFileURL.path
                guard !seen.contains(key) else { continue }
                seen.insert(key)
                result.append(candidate)
            }
        }

        return result
    }

    /// 广度优先扫描目录，收集可打开的工程。
    ///
    /// 某一层目录里一旦出现 `.xcworkspace` / `.xcodeproj`，只收录该层工程，
    /// **不再下钻该目录的子节点**（避免把工程内部的嵌套工程扫进来），
    /// 队列里尚未处理的兄弟目录仍会继续扫。
    ///
    /// 同一目录下若同时存在同名 `.xcworkspace` 与 `.xcodeproj`（典型 CocoaPods），
    /// 只收 workspace。跳过 `Pods/`、`_Pods/` 等目录；工程名是 `Pods` /
    /// `_Pods` / 以 `_Pods` 结尾的也不收。
    static func discoverProjects(
        under root: URL,
        maximumDirectories: Int? = nil
    ) -> [URL] {
        let fm = FileManager.default
        let skipDirectoryNames: Set<String> = [
            "Pods", "_Pods", "Carthage", "DerivedData", ".build", "build",
            "node_modules", ".git", ".svn", ".hg", "xcuserdata",
        ]

        // 用户直接点到工程包时，不必再扫内部
        let rootExt = root.pathExtension
        if rootExt == "xcworkspace" || rootExt == "xcodeproj" {
            let name = root.deletingPathExtension().lastPathComponent
            guard !isPodsProjectName(name) else { return [] }
            if rootExt == "xcodeproj" {
                let sibling = root.deletingPathExtension().appendingPathExtension("xcworkspace")
                if fm.fileExists(atPath: sibling.path) {
                    return isPodsProjectName(sibling.deletingPathExtension().lastPathComponent)
                        ? [] : [sibling]
                }
            }
            return [root]
        }

        var found: [URL] = []
        var queue: [URL] = [root]
        var cursor = 0

        while cursor < queue.count {
            if Task.isCancelled { break }
            if let maximumDirectories, cursor >= maximumDirectories { break }

            let dir = queue[cursor]
            cursor += 1

            guard let children = try? fm.contentsOfDirectory(
                at: dir,
                includingPropertiesForKeys: [.isDirectoryKey],
                options: [.skipsHiddenFiles]
            ) else { continue }

            var workspaces: [URL] = []
            var projects: [URL] = []
            var subdirs: [URL] = []

            for child in children {
                let name = child.lastPathComponent
                if skipDirectoryNames.contains(name) { continue }

                switch child.pathExtension {
                case "xcworkspace":
                    if !isPodsProjectName(child.deletingPathExtension().lastPathComponent) {
                        workspaces.append(child)
                    }
                case "xcodeproj":
                    if !isPodsProjectName(child.deletingPathExtension().lastPathComponent) {
                        projects.append(child)
                    }
                default:
                    var isDirectory: ObjCBool = false
                    if fm.fileExists(atPath: child.path, isDirectory: &isDirectory),
                       isDirectory.boolValue {
                        subdirs.append(child)
                    }
                }
            }

            if !workspaces.isEmpty || !projects.isEmpty {
                // 本目录已有工程：收录后停止下钻，兄弟目录仍在队列里
                let workspaceBases = Set(
                    workspaces.map { $0.deletingPathExtension().lastPathComponent }
                )
                found.append(contentsOf: workspaces)
                for project in projects where !workspaceBases.contains(
                    project.deletingPathExtension().lastPathComponent
                ) {
                    found.append(project)
                }
                continue
            }

            queue.append(contentsOf: subdirs)
        }

        return found.sorted { $0.path.localizedStandardCompare($1.path) == .orderedAscending }
    }

    /// CocoaPods / 本地 `_Pods` 生成物，扫描时不应当成可运行主工程。
    private static func isPodsProjectName(_ name: String) -> Bool {
        name == "Pods" || name == "_Pods" || name.hasSuffix("_Pods")
    }

    /// 显示名：`App.xcworkspace` → `App`
    static func displayName(for url: URL) -> String {
        url.deletingPathExtension().lastPathComponent
    }

    /// 读取 scheme / configuration / target 列表。
    ///
    /// CocoaPods 会为 `Pods/` 下每个 target 自动生成 Scheme，
    /// `xcodebuild -list` 对 workspace 会全部列出；这里按 Pods 工程里的
    /// target 名（以及磁盘上的 `.xcscheme`）把它们剔掉，避免污染主 App 列表。
    static func loadInfo(url: URL, kind: XcodeProject.Kind) async throws -> ProjectInfo {
        var info = try await XcodebuildAdapter.listProject(at: url, kind: kind)
        info.schemes = excludingPodsSchemes(info.schemes, adjacentTo: url)
        return info
    }

    /// 从 scheme 列表中去掉 CocoaPods 自动生成的那些。
    ///
    /// 若过滤后为空（例如用户直接打开了 `Pods.xcodeproj`），保留原列表，
    /// 以免整个浮窗变得不可用。
    static func excludingPodsSchemes(_ schemes: [String], adjacentTo projectURL: URL) -> [String] {
        let podsSchemes = podsGeneratedSchemeNames(adjacentTo: projectURL)
        guard !podsSchemes.isEmpty else { return schemes }
        let filtered = schemes.filter { !podsSchemes.contains($0) }
        return filtered.isEmpty ? schemes : filtered
    }

    /// 收集工程旁 `Pods/` 自动生成的 scheme 名。
    ///
    /// 以 `project.pbxproj` 里的 Native/Aggregate target 名为准——Xcode 会按
    /// target 自动创建同名 scheme，即使磁盘上还没有 `.xcscheme` 文件，
    /// `xcodebuild -list` 也会列出来。再并上已落盘的 scheme 文件名作为兜底。
    static func podsGeneratedSchemeNames(adjacentTo projectURL: URL) -> Set<String> {
        let podsDir = projectURL
            .deletingLastPathComponent()
            .appendingPathComponent("Pods", isDirectory: true)
        var isDirectory: ObjCBool = false
        guard FileManager.default.fileExists(atPath: podsDir.path, isDirectory: &isDirectory),
              isDirectory.boolValue
        else { return [] }

        var names = Set<String>()
        for projectBundle in podProjectBundles(under: podsDir) {
            names.formUnion(targetNames(inProjectBundle: projectBundle))
            names.formUnion(schemeFileNames(under: projectBundle))
        }
        return names
    }

    /// `Pods/` 根目录及其直接子目录里的 `.xcodeproj`（兼容多工程生成模式）。
    private static func podProjectBundles(under podsDir: URL) -> [URL] {
        let fm = FileManager.default
        let top = (try? fm.contentsOfDirectory(
            at: podsDir,
            includingPropertiesForKeys: [.isDirectoryKey],
            options: [.skipsHiddenFiles]
        )) ?? []

        var bundles = top.filter { $0.pathExtension == "xcodeproj" }

        for item in top where item.pathExtension != "xcodeproj" {
            var isDirectory: ObjCBool = false
            guard fm.fileExists(atPath: item.path, isDirectory: &isDirectory),
                  isDirectory.boolValue
            else { continue }
            // 跳过体积巨大且不含 xcodeproj 的目录，避免无意义遍历
            let name = item.lastPathComponent
            if name == "Headers" || name == "Target Support Files"
                || name == "Local Podspecs" || name.hasSuffix(".framework")
                || name.hasSuffix(".bundle") {
                continue
            }
            let nested = (try? fm.contentsOfDirectory(
                at: item,
                includingPropertiesForKeys: nil,
                options: [.skipsHiddenFiles]
            )) ?? []
            bundles.append(contentsOf: nested.filter { $0.pathExtension == "xcodeproj" })
        }
        return bundles
    }

    /// 从 `project.pbxproj` 提取 PBXNativeTarget / PBXAggregateTarget 的 name。
    private static func targetNames(inProjectBundle projectBundle: URL) -> Set<String> {
        let pbxproj = projectBundle.appendingPathComponent("project.pbxproj")
        guard let text = try? String(contentsOf: pbxproj, encoding: .utf8) else { return [] }

        var names = Set<String>()
        // pbxproj 用 /* Begin … section */ 分块；只在 target section 里取 name，
        // 避免误伤 PBXBuildFile / PBXFileReference 等其它条目的 name 字段。
        let sectionTypes = ["PBXNativeTarget", "PBXAggregateTarget"]
        for type in sectionTypes {
            let begin = "/* Begin \(type) section */"
            let end = "/* End \(type) section */"
            guard let beginRange = text.range(of: begin),
                  let endRange = text.range(of: end, range: beginRange.upperBound..<text.endIndex)
            else { continue }
            let section = text[beginRange.upperBound..<endRange.lowerBound]
            for line in section.split(separator: "\n") {
                let trimmed = line.trimmingCharacters(in: .whitespaces)
                guard trimmed.hasPrefix("name = ") else { continue }
                var value = trimmed.dropFirst("name = ".count)
                if value.hasSuffix(";") { value = value.dropLast() }
                let name = value.trimmingCharacters(in: CharacterSet(charactersIn: "\""))
                if !name.isEmpty { names.insert(String(name)) }
            }
        }
        return names
    }

    /// 已落盘的 Shared / User scheme 文件名（不含扩展名）。
    private static func schemeFileNames(under projectBundle: URL) -> Set<String> {
        var names = Set<String>()
        let fm = FileManager.default
        guard let enumerator = fm.enumerator(
            at: projectBundle,
            includingPropertiesForKeys: nil,
            options: [.skipsHiddenFiles]
        ) else { return [] }

        for case let fileURL as URL in enumerator {
            // .xcodeproj 是包，enumerator 默认会走进去；只要 .xcscheme 即可
            guard fileURL.pathExtension == "xcscheme" else { continue }
            names.insert(fileURL.deletingPathExtension().lastPathComponent)
        }
        return names
    }

    /// 工程文件的修改时间，用于构建设置缓存失效判定。
    static func modificationDate(of url: URL) -> Date {
        // .xcodeproj 是包，取其 project.pbxproj 的 mtime 更敏感
        let candidates = [
            url.appendingPathComponent("project.pbxproj"),
            url.appendingPathComponent("contents.xcworkspacedata"),
            url,
        ]
        for candidate in candidates {
            if let attributes = try? FileManager.default.attributesOfItem(atPath: candidate.path),
               let date = attributes[.modificationDate] as? Date {
                return date
            }
        }
        return .distantPast
    }

    /// Xcode 默认 DerivedData（与「默认」位置模式对应）。
    static var xcodeDefaultDerivedDataRoot: URL {
        FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Library/Developer/Xcode/DerivedData", isDirectory: true)
    }

    /// 应用内置的独立 DerivedData 根（「自定义」未另选路径时的默认值）。
    static var defaultCustomDerivedDataRoot: URL {
        let support = FileManager.default
            .urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? FileManager.default.temporaryDirectory
        return support
            .appendingPathComponent("XcodeControl", isDirectory: true)
            .appendingPathComponent("DerivedData", isDirectory: true)
    }

    /// 应用自己管理的 DerivedData 目录，避免与 Xcode 正在进行的构建争抢同一份缓存。
    /// - Parameter root: 自定义根目录；`nil` 时用 `defaultCustomDerivedDataRoot`。
    static func derivedDataPath(for project: URL, root: URL? = nil) -> URL {
        let base = root ?? defaultCustomDerivedDataRoot
        // 用路径的稳定摘要做目录名，避免同名工程互相覆盖。
        // 绝不能用 String.hashValue：Swift 4.2 起每次进程启动会重新随机化，
        // 会导致每次启动新建一份 DerivedData，同时产物路径缓存仍指向旧目录里的 .app，
        // 表现为「磁盘越来越大，跑的却是旧代码」。
        let digest = stablePathDigest(project.path)
        let name = "\(displayName(for: project))-\(digest)"
        return base.appendingPathComponent(name, isDirectory: true)
    }

    /// 进程无关的路径摘要（djb2），只用于目录命名，不要求密码学强度。
    private static func stablePathDigest(_ path: String) -> String {
        var hash: UInt64 = 5381
        for byte in path.utf8 {
            hash = ((hash << 5) &+ hash) &+ UInt64(byte)
        }
        return String(format: "%08x", UInt32(truncatingIfNeeded: hash))
    }
}
