//
//  LogParser.swift
//  XcodeControl
//

import Foundation

/// 一条日志。
struct LogEntry: Identifiable, Equatable {
    enum Level: Equatable {
        case output
        case note
        case warning
        case error
    }

    let id: UUID
    let text: String
    let level: Level
    let timestamp: Date

    init(id: UUID = UUID(), text: String, level: Level = .output, timestamp: Date = Date()) {
        self.id = id
        self.text = text
        self.level = level
        self.timestamp = timestamp
    }
}

/// 从 xcodebuild 的流式输出中提取结构化信息。
///
/// 原始输出极其冗长，直接展示没有意义；这里只负责两件事：
/// 识别诊断（error / warning），以及从阶段关键词推断粗粒度进度。
enum LogParser {

    /// `/path/File.swift:42:15: error: cannot find 'foo' in scope`
    private static let diagnosticRegex = try? NSRegularExpression(
        pattern: #"^(.+?):(\d+):(\d+): (error|warning|note): (.+)$"#
    )

    /// `/path/File.swift:42: error: ...`（没有列号的变体）
    private static let diagnosticNoColumnRegex = try? NSRegularExpression(
        pattern: #"^(.+?):(\d+): (error|warning|note): (.+)$"#
    )

    /// `error: ...` / `warning: ...`（无文件位置，如链接与签名错误）
    private static let bareDiagnosticRegex = try? NSRegularExpression(
        pattern: #"^(?:.*\b)?(error|warning): (.+)$"#
    )

    struct Diagnostic: Equatable {
        var level: LogEntry.Level
        var file: String?
        var line: Int?
        var column: Int?
        var message: String

        /// 展示给用户的一句话摘要
        var summary: String {
            guard let file else { return message }
            let base = (file as NSString).lastPathComponent
            if let line { return "\(base):\(line) — \(message)" }
            return "\(base) — \(message)"
        }
    }

    static func parseDiagnostic(_ line: String) -> Diagnostic? {
        let trimmed = line.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return nil }
        let range = NSRange(trimmed.startIndex..<trimmed.endIndex, in: trimmed)

        if let match = diagnosticRegex?.firstMatch(in: trimmed, range: range), match.numberOfRanges == 6 {
            let file = substring(trimmed, match.range(at: 1))
            let line = Int(substring(trimmed, match.range(at: 2)) ?? "")
            let column = Int(substring(trimmed, match.range(at: 3)) ?? "")
            let level = level(from: substring(trimmed, match.range(at: 4)) ?? "")
            let message = substring(trimmed, match.range(at: 5)) ?? ""
            return Diagnostic(level: level, file: file, line: line, column: column, message: message)
        }

        if let match = diagnosticNoColumnRegex?.firstMatch(in: trimmed, range: range), match.numberOfRanges == 5 {
            let file = substring(trimmed, match.range(at: 1))
            let line = Int(substring(trimmed, match.range(at: 2)) ?? "")
            let level = level(from: substring(trimmed, match.range(at: 3)) ?? "")
            let message = substring(trimmed, match.range(at: 4)) ?? ""
            return Diagnostic(level: level, file: file, line: line, column: nil, message: message)
        }

        // 链接错误与签名错误不遵循上述格式
        if trimmed.hasPrefix("ld: ") {
            return Diagnostic(level: .error, file: nil, line: nil, column: nil,
                              message: String(trimmed.dropFirst(4)))
        }
        if trimmed.localizedCaseInsensitiveContains("Code Signing Error") {
            return Diagnostic(level: .error, file: nil, line: nil, column: nil, message: trimmed)
        }

        if let match = bareDiagnosticRegex?.firstMatch(in: trimmed, range: range), match.numberOfRanges == 3 {
            let level = level(from: substring(trimmed, match.range(at: 1)) ?? "")
            let message = substring(trimmed, match.range(at: 2)) ?? ""
            // 过滤掉「** BUILD FAILED **」这类没有信息量的行
            guard !message.isEmpty else { return nil }
            return Diagnostic(level: level, file: nil, line: nil, column: nil, message: message)
        }

        return nil
    }

    /// Only retry diagnostics for a missing generated PCM. A missing module map,
    /// framework, or source file needs a different fix.
    static func missingPrecompiledModule(in diagnostic: Diagnostic) -> String? {
        let prefix = "module file '"
        let suffix = ".pcm' not found"
        guard diagnostic.level == .error,
              let start = diagnostic.message.range(of: prefix),
              let end = diagnostic.message.range(of: suffix, range: start.upperBound..<diagnostic.message.endIndex)
        else { return nil }
        let path = String(diagnostic.message[start.upperBound..<end.lowerBound]) + ".pcm"
        guard path.hasPrefix("/"),
              URL(fileURLWithPath: path).deletingLastPathComponent().lastPathComponent == "ExplicitPrecompiledModules",
              !FileManager.default.fileExists(atPath: path)
        else { return nil }
        return path
    }

    // MARK: - 阶段推断

    /// 把不确定的构建进度粗略映射为几个可读阶段。
    ///
    /// 表里存中文原文当查表 key，翻译放在返回处——阶段名会被
    /// `RunPhase.statusText` 拼进「Building · 编译 Swift」，两边必须同一种语言。
    static func stage(from line: String) -> String? {
        let checks: [(prefix: String, stage: String)] = [
            ("CompileSwiftSources", "编译 Swift"),
            ("SwiftCompile", "编译 Swift"),
            ("CompileSwift", "编译 Swift"),
            ("CompileC", "编译 C/ObjC"),
            ("CompileAssetCatalog", "编译资源"),
            ("CompileStoryboard", "编译界面"),
            ("ProcessInfoPlistFile", "处理 Info.plist"),
            ("PhaseScriptExecution", "运行脚本"),
            ("Ld ", "链接"),
            ("Linking", "链接"),
            ("CodeSign", "签名"),
            ("Touch ", "收尾"),
            ("RegisterExecutionPolicyException", "收尾"),
            ("Validate ", "校验"),
        ]
        for check in checks where line.hasPrefix(check.prefix) {
            return L10n.t(check.stage)
        }
        if line.hasPrefix("Compiling") { return L10n.t("编译 Swift") }
        if line.hasPrefix("=== BUILD TARGET") || line.hasPrefix("=== CLEAN TARGET") { return L10n.t("准备") }
        if line.contains("Prepare packages") || line.contains("Resolve Package Graph") { return L10n.t("解析依赖") }
        return nil
    }

    /// 是否是「构建成功」的标志行
    static func isBuildSucceeded(_ line: String) -> Bool {
        line.contains("** BUILD SUCCEEDED **") || line.contains("** CLEAN SUCCEEDED **")
    }

    static func isBuildFailed(_ line: String) -> Bool {
        line.contains("** BUILD FAILED **")
    }

    // MARK: - 私有

    private static func level(from raw: String) -> LogEntry.Level {
        switch raw.lowercased() {
        case "error": .error
        case "warning": .warning
        default: .note
        }
    }

    private static func substring(_ string: String, _ range: NSRange) -> String? {
        guard let swiftRange = Range(range, in: string) else { return nil }
        return String(string[swiftRange])
    }
}
