//
//  RecentProjectsStore.swift
//  XcodeControl
//

import Foundation

/// 项目列表的持久化。
///
/// 数据量小、结构简单，`UserDefaults` 足够——不需要 Core Data 或 SwiftData。
/// 键名仍用 `xcc.recentProjects`，兼容旧版本数据；语义已是「托管列表」而非「最近 N 条」。
/// 数组顺序即展示顺序（支持用户拖拽排序），读写时不再按打开时间重排。
struct RecentProjectsStore {

    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func load() -> [XcodeProject] {
        guard let data = defaults.data(forKey: DefaultsKey.recentProjects) else { return [] }
        do {
            // 顺序即用户拖拽后的顺序，不再按 lastOpenedAt 重排
            return try JSONDecoder().decode([XcodeProject].self, from: data)
        } catch {
            return []
        }
    }

    func save(_ projects: [XcodeProject]) {
        guard let data = try? JSONEncoder().encode(projects) else { return }
        defaults.set(data, forKey: DefaultsKey.recentProjects)
    }

    var currentProjectID: UUID? {
        get {
            guard let raw = defaults.string(forKey: DefaultsKey.currentProjectID) else { return nil }
            return UUID(uuidString: raw)
        }
        nonmutating set {
            defaults.set(newValue?.uuidString, forKey: DefaultsKey.currentProjectID)
        }
    }
}

/// 构建产物路径缓存：存在应用支持目录下的 JSON 文件中，可随时清除。
struct BuildSettingsCache {

    private let fileURL: URL

    init() {
        let support = FileManager.default
            .urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? FileManager.default.temporaryDirectory
        let directory = support.appendingPathComponent("XcodeControl", isDirectory: true)
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        fileURL = directory.appendingPathComponent("build-settings-cache.json")
    }

    private struct Entry: Codable {
        let key: ResolvedBuildSettings.Key
        let value: ResolvedBuildSettings
    }

    private func loadAll() -> [Entry] {
        guard let data = try? Data(contentsOf: fileURL),
              let entries = try? JSONDecoder().decode([Entry].self, from: data)
        else { return [] }
        return entries
    }

    private func saveAll(_ entries: [Entry]) {
        guard let data = try? JSONEncoder().encode(Array(entries.suffix(64))) else { return }
        try? data.write(to: fileURL, options: .atomic)
    }

    func value(for key: ResolvedBuildSettings.Key, projectMTime: Date) -> ResolvedBuildSettings? {
        guard let entry = loadAll().first(where: { $0.key == key }) else { return nil }
        // 工程文件 mtime 变化即失效
        guard abs(entry.value.projectMTime.timeIntervalSince(projectMTime)) < 1 else { return nil }
        // 产物可能已被 clean 掉
        guard FileManager.default.fileExists(atPath: entry.value.productPath.path) else { return nil }
        return entry.value
    }

    func store(_ value: ResolvedBuildSettings, for key: ResolvedBuildSettings.Key) {
        var entries = loadAll().filter { $0.key != key }
        entries.append(Entry(key: key, value: value))
        saveAll(entries)
    }

    func clear() {
        try? FileManager.default.removeItem(at: fileURL)
    }
}
