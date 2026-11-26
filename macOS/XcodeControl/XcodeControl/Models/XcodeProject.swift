//
//  XcodeProject.swift
//  XcodeControl
//

import Foundation

/// 一个被记录在历史里的 Xcode 工程。
///
/// 路径以 security-scoped bookmark 持久化而非裸字符串：即便不开沙盒，
/// bookmark 也能在文件被移动后继续跟踪到目标。
struct XcodeProject: Codable, Identifiable, Hashable {

    enum Kind: String, Codable, Hashable {
        case project
        case workspace

        var pathExtension: String {
            switch self {
            case .project: "xcodeproj"
            case .workspace: "xcworkspace"
            }
        }

        /// xcodebuild 用于指定工程的参数名
        var xcodebuildFlag: String {
            switch self {
            case .project: "-project"
            case .workspace: "-workspace"
            }
        }
    }

    let id: UUID
    /// 显示名，取自包名去掉后缀，如 `App.xcworkspace` → `App`
    var name: String
    /// security-scoped bookmark
    var bookmark: Data
    /// 最近一次成功解析出的路径，用于列表中展示父目录、以及 bookmark 失效时的兜底
    var lastKnownPath: String
    var kind: Kind
    var lastScheme: String?
    var lastConfiguration: String
    var lastDestinationID: String?
    var lastOpenedAt: Date

    init(
        id: UUID = UUID(),
        name: String,
        bookmark: Data,
        lastKnownPath: String,
        kind: Kind,
        lastScheme: String? = nil,
        lastConfiguration: String = "Debug",
        lastDestinationID: String? = nil,
        lastOpenedAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.bookmark = bookmark
        self.lastKnownPath = lastKnownPath
        self.kind = kind
        self.lastScheme = lastScheme
        self.lastConfiguration = lastConfiguration
        self.lastDestinationID = lastDestinationID
        self.lastOpenedAt = lastOpenedAt
    }

    /// 列表中显示在项目名下方的灰色父目录
    var parentDirectoryDisplay: String {
        let parent = (lastKnownPath as NSString).deletingLastPathComponent
        return (parent as NSString).abbreviatingWithTildeInPath
    }
}

/// `xcodebuild -list -json` 的解析结果。
struct ProjectInfo: Equatable, Codable {
    var name: String
    var schemes: [String]
    var configurations: [String]
    var targets: [String]

    static let empty = ProjectInfo(name: "", schemes: [], configurations: [], targets: [])
}
