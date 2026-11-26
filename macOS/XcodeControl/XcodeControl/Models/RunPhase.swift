//
//  RunPhase.swift
//  XcodeControl
//

import Foundation

/// 运行生命周期状态机。
///
/// ```
/// [idle] ──▶ [building] ──▶ [installing] ──▶ [launching] ──▶ [running]
///    ▲           │              │               │              │
///    └───────── [failed] ◀──────┴───────────────┘              └──▶ [idle]
/// ```
enum RunPhase: Equatable {
    case idle
    case building(startedAt: Date, stage: String?)
    case installing
    case launching
    case running(pid: Int32?)
    case failed(BuildFailure)

    /// 是否处于「有工作正在进行」的阶段——此时停止按钮语义为取消。
    var isWorking: Bool {
        switch self {
        case .building, .installing, .launching: true
        case .idle, .running, .failed: false
        }
    }

    var isRunning: Bool {
        if case .running = self { return true }
        return false
    }

    var isFailed: Bool {
        if case .failed = self { return true }
        return false
    }

    /// 停止按钮是否可点
    var canStop: Bool { isWorking || isRunning }

    /// 底部细状态条的文案，nil 表示不显示
    ///
    /// 这几个 key 是英文而非中文——它们沿用 Xcode 自己的状态词汇，
    /// 简体中文下查表落空即返回 key，行为与加入多语言之前完全一致。
    var statusText: String? {
        switch self {
        case .idle: nil
        case .building(_, let stage):
            stage.map { "\(L10n.t("Building")) · \($0)" } ?? L10n.t("Building")
        case .installing: L10n.t("Installing")
        case .launching: L10n.t("Launching")
        case .running: L10n.t("Running")
        case .failed: L10n.t("Failed")
        }
    }

    /// 进度环是否应该转
    var showsProgress: Bool { isWorking }

    var startedAt: Date? {
        if case .building(let startedAt, _) = self { return startedAt }
        return nil
    }
}

/// 一次构建/运行失败的可读摘要。
struct BuildFailure: Equatable, Identifiable {
    let id: UUID
    /// 首条 error 的可读描述（已做已知错误模式翻译）
    let summary: String
    /// 翻译前的原始诊断。界面上不显示，只在拷贝时附上——
    /// 翻译后的中文提示适合读，但拿它去搜索或喂给 AI 是搜不到东西的，原文才行。
    /// 与 `summary` 相同时视为没有翻译发生，存 nil 避免拷出重复的两行。
    let raw: String?
    let file: String?
    let line: Int?
    /// 指向日志缓冲，用于「查看完整日志」
    let fullLogRef: UUID

    init(
        id: UUID = UUID(),
        summary: String,
        raw: String? = nil,
        file: String? = nil,
        line: Int? = nil,
        fullLogRef: UUID
    ) {
        self.id = id
        self.summary = summary
        self.raw = raw == summary ? nil : raw
        self.file = file
        self.line = line
        self.fullLogRef = fullLogRef
    }

    /// `File.swift:42` —— 没有文件信息时返回 nil
    var locationDisplay: String? {
        guard let file else { return nil }
        let base = (file as NSString).lastPathComponent
        if let line { return "\(base):\(line)" }
        return base
    }

    /// 拷贝到剪贴板的文本。
    ///
    /// 用完整路径而不是卡片上显示的 basename：粘到终端、issue 或 AI 对话里时，
    /// `File.swift:42` 定位不到任何东西，完整路径才能。格式沿用编译器自己的
    /// `路径:行: error: 描述`，收下这段文本的工具链大多认得它。
    var copyText: String {
        var text = summary
        if let file {
            let position = line.map { "\(file):\($0)" } ?? file
            text = "\(position): error: \(summary)"
        }
        if let raw, !raw.isEmpty {
            text += "\n\(raw)"
        }
        return text
    }
}
