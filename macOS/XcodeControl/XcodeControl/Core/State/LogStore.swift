//
//  LogStore.swift
//  XcodeControl
//

import Foundation
import Observation

/// 日志缓冲：环形缓冲，超出容量的最旧行被丢弃，
/// 避免长时间运行导致的内存增长。容量由设置页可调。
@MainActor
@Observable
final class LogStore {

    /// 容量兜底值；由 AppState 注入 Preferences 后走配置。
    static let defaultCapacity = 5000

    /// 由 AppState 注入。未注入时（无头验证、预览）退回兜底容量。
    var prefs: Preferences?

    private var capacity: Int {
        max(100, prefs?.logCapacity ?? Self.defaultCapacity)
    }

    private(set) var entries: [LogEntry] = []

    /// 当前这一轮运行的标识，`BuildFailure.fullLogRef` 指向它
    private(set) var currentRunID = UUID()

    /// 本轮收集到的诊断（error / warning）
    private(set) var diagnostics: [LogParser.Diagnostic] = []

    var filterText: String = ""
    var autoScroll: Bool = true

    var filteredEntries: [LogEntry] {
        let keyword = filterText.trimmingCharacters(in: .whitespaces)
        guard !keyword.isEmpty else { return entries }
        return entries.filter { $0.text.localizedCaseInsensitiveContains(keyword) }
    }

    var firstError: LogParser.Diagnostic? {
        diagnostics.first { $0.level == .error }
    }

    var errorCount: Int { diagnostics.filter { $0.level == .error }.count }
    var warningCount: Int { diagnostics.filter { $0.level == .warning }.count }

    /// 开始新的一轮运行，清空缓冲并返回新的 run id。
    @discardableResult
    func beginRun() -> UUID {
        entries.removeAll(keepingCapacity: true)
        diagnostics.removeAll(keepingCapacity: true)
        currentRunID = UUID()
        return currentRunID
    }

    func append(_ text: String, level: LogEntry.Level = .output) {
        guard !text.isEmpty else { return }
        entries.append(LogEntry(text: text, level: level))
        let limit = capacity
        if entries.count > limit {
            entries.removeFirst(entries.count - limit)
        }
    }

    func beginBuildRetry() {
        diagnostics.removeAll(keepingCapacity: true)
    }

    func appendDiagnostic(_ diagnostic: LogParser.Diagnostic) {
        // 同一条诊断 xcodebuild 常会重复输出，去重后再记录
        if !diagnostics.contains(diagnostic) {
            diagnostics.append(diagnostic)
        }
    }

    /// 导出为纯文本，用于「拷贝完整日志」
    func plainText() -> String {
        entries.map(\.text).joined(separator: "\n")
    }

    func clear() {
        entries.removeAll()
        diagnostics.removeAll()
    }
}
