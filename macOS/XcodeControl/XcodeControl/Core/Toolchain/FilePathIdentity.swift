//
//  FilePathIdentity.swift
//  XcodeControl
//

import Foundation

/// 文件路径比较统一经过标准化与符号链接解析，避免 worktree 软链接导致重复项目。
enum FilePathIdentity {

    static func canonical(_ path: String) -> String {
        URL(fileURLWithPath: path)
            .standardizedFileURL
            .resolvingSymlinksInPath()
            .path
    }

    static func absolute(_ path: String, relativeTo directory: URL) -> String {
        let url = path.hasPrefix("/")
            ? URL(fileURLWithPath: path)
            : URL(fileURLWithPath: path, relativeTo: directory)
        return canonical(url.path)
    }

    static func relativeComponents(for path: String, inside root: String) -> [String]? {
        let pathComponents = URL(fileURLWithPath: canonical(path)).pathComponents
        let rootComponents = URL(fileURLWithPath: canonical(root)).pathComponents

        guard pathComponents.starts(with: rootComponents) else { return nil }
        return Array(pathComponents.dropFirst(rootComponents.count))
    }
}
