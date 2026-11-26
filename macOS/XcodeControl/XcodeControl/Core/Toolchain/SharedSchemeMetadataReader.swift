//
//  SharedSchemeMetadataReader.swift
//  XcodeControl
//

import Foundation

/// 不启动 Xcode 工具链，直接从工程包读取 Shared Scheme 与基础项目元数据。
///
/// `xcodebuild -list` 会先解析 Swift Package；网络不可用或缓存不完整时，
/// 一个本应纯本地的 Scheme 查询也可能被拖到超时。这里作为 Adapter 层的
/// 离线兜底，只读取已经落盘的 Shared Scheme，不把用户私有 Scheme 暴露出来。
enum SharedSchemeMetadataReader {

    static func read(at url: URL, kind: XcodeProject.Kind) -> ProjectInfo? {
        let projectURLs = projectBundles(referencedBy: url, kind: kind)
        var schemes = Set(schemeNames(in: url))
        var configurations = Set<String>()
        var targets = Set<String>()

        for projectURL in projectURLs {
            schemes.formUnion(schemeNames(in: projectURL))
            let metadata = projectMetadata(in: projectURL)
            configurations.formUnion(metadata.configurations)
            targets.formUnion(metadata.targets)
        }

        guard !schemes.isEmpty else { return nil }
        return ProjectInfo(
            name: url.deletingPathExtension().lastPathComponent,
            schemes: schemes.sorted(by: localizedAscending),
            configurations: configurations.sorted(by: localizedAscending),
            targets: targets.sorted(by: localizedAscending)
        )
    }

    private static func schemeNames(in bundleURL: URL) -> [String] {
        let directory = bundleURL
            .appendingPathComponent("xcshareddata", isDirectory: true)
            .appendingPathComponent("xcschemes", isDirectory: true)
        let files = (try? FileManager.default.contentsOfDirectory(
            at: directory,
            includingPropertiesForKeys: [.isRegularFileKey],
            options: [.skipsHiddenFiles]
        )) ?? []
        return files
            .filter { $0.pathExtension == "xcscheme" }
            .map { $0.deletingPathExtension().lastPathComponent }
    }

    private static func projectBundles(
        referencedBy url: URL,
        kind: XcodeProject.Kind
    ) -> [URL] {
        switch kind {
        case .project:
            return [url]
        case .workspace:
            let contents = url.appendingPathComponent("contents.xcworkspacedata")
            guard let parser = XMLParser(contentsOf: contents) else { return [] }
            let delegate = WorkspaceProjectReferenceParser(
                workspaceDirectory: url.deletingLastPathComponent()
            )
            parser.delegate = delegate
            guard parser.parse() else { return [] }
            return delegate.projectURLs
        }
    }

    private static func projectMetadata(in projectURL: URL) -> (
        configurations: Set<String>,
        targets: Set<String>
    ) {
        let pbxproj = projectURL.appendingPathComponent("project.pbxproj")
        guard let data = try? Data(contentsOf: pbxproj),
              let root = try? PropertyListSerialization.propertyList(from: data, format: nil),
              let plist = root as? [String: Any],
              let objects = plist["objects"] as? [String: Any],
              let rootID = plist["rootObject"] as? String,
              let project = objects[rootID] as? [String: Any]
        else { return ([], []) }

        var configurations = Set<String>()
        if let listID = project["buildConfigurationList"] as? String,
           let list = objects[listID] as? [String: Any],
           let configurationIDs = list["buildConfigurations"] as? [String] {
            for id in configurationIDs {
                guard let configuration = objects[id] as? [String: Any],
                      let name = configuration["name"] as? String
                else { continue }
                configurations.insert(name)
            }
        }

        var targets = Set<String>()
        for id in project["targets"] as? [String] ?? [] {
            guard let target = objects[id] as? [String: Any],
                  let name = target["name"] as? String
            else { continue }
            targets.insert(name)
        }
        return (configurations, targets)
    }

    private static func localizedAscending(_ lhs: String, _ rhs: String) -> Bool {
        lhs.localizedStandardCompare(rhs) == .orderedAscending
    }
}

/// workspace 可以用嵌套 Group 改变相对路径基准，不能只对 XML 文本做正则。
private final class WorkspaceProjectReferenceParser: NSObject, XMLParserDelegate {

    private let workspaceDirectory: URL
    private var groupDirectories: [URL]
    private var seen = Set<String>()
    private(set) var projectURLs: [URL] = []

    init(workspaceDirectory: URL) {
        self.workspaceDirectory = workspaceDirectory
        self.groupDirectories = [workspaceDirectory]
    }

    func parser(
        _ parser: XMLParser,
        didStartElement elementName: String,
        namespaceURI: String?,
        qualifiedName qName: String?,
        attributes attributeDict: [String: String] = [:]
    ) {
        if elementName == "Group" {
            let parent = groupDirectories.last ?? workspaceDirectory
            let directory = attributeDict["location"]
                .flatMap { resolve($0, relativeTo: parent) }
                ?? parent
            groupDirectories.append(directory)
            return
        }

        guard elementName == "FileRef",
              let location = attributeDict["location"],
              let url = resolve(location, relativeTo: groupDirectories.last ?? workspaceDirectory),
              url.pathExtension == "xcodeproj"
        else { return }

        let normalized = url.standardizedFileURL
        guard seen.insert(normalized.path).inserted else { return }
        projectURLs.append(normalized)
    }

    func parser(
        _ parser: XMLParser,
        didEndElement elementName: String,
        namespaceURI: String?,
        qualifiedName qName: String?
    ) {
        if elementName == "Group", groupDirectories.count > 1 {
            groupDirectories.removeLast()
        }
    }

    private func resolve(_ location: String, relativeTo groupDirectory: URL) -> URL? {
        guard let separator = location.firstIndex(of: ":") else {
            return groupDirectory.appendingPathComponent(location)
        }
        let scheme = String(location[..<separator])
        let path = String(location[location.index(after: separator)...])
        switch scheme {
        case "group":
            return groupDirectory.appendingPathComponent(path)
        case "container":
            return workspaceDirectory.appendingPathComponent(path)
        case "absolute":
            return URL(fileURLWithPath: path)
        case "self":
            return nil
        default:
            return groupDirectory.appendingPathComponent(path)
        }
    }
}
