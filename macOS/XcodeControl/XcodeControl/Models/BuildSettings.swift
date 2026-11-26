//
//  BuildSettings.swift
//  XcodeControl
//

import Foundation

/// `xcodebuild -showBuildSettings` 解析出的、定位产物所需的最小集合。
///
/// 这条命令本身要 1–3 秒，因此按
/// (项目路径, scheme, configuration, 平台, derivedDataPath) 缓存，
/// 以工程文件 mtime 作为失效判据。
/// `derivedDataPath` 必须进 key：独立 / 共享两套目录下的 `.app` 路径不同，
/// 漏掉的话会在新目录编完后仍安装旧路径里的包。
struct ResolvedBuildSettings: Codable, Equatable {
    let productPath: URL
    let bundleIdentifier: String
    let resolvedAt: Date
    /// 缓存失效判据：解析时工程文件的修改时间
    let projectMTime: Date

    /// 缓存 key
    struct Key: Codable, Hashable {
        let projectPath: String
        let scheme: String
        let configuration: String
        /// 目标平台，如 `iOS Simulator`
        let platform: String
        /// 独立 DerivedData 的绝对路径；`nil` 表示与 Xcode 共享默认目录
        let derivedDataPath: String?
    }
}

/// 构建配置（Debug / Release 等）
enum BuildConfiguration {
    static let debug = "Debug"
    static let release = "Release"
}
