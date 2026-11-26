//
//  AppLanguage.swift
//  XcodeControl
//

import Foundation

/// 界面语言。
///
/// 收录范围：联合国六种官方语言（英/中/西/法/俄/阿），
/// 加上具备区域级影响力的葡、日、德、印地、乌尔都、韩、土。
///
/// `rawValue` 用 BCP 47 标签，同时充当 UserDefaults 里的持久化值，
/// 因此**不要改动已有 case 的 rawValue**——改了等于把用户的选择清零。
enum AppLanguage: String, CaseIterable, Identifiable, Hashable, Sendable {
    case zhHans = "zh-Hans"
    case en
    case es
    case fr
    case ru
    case ar
    case ptBR = "pt-BR"
    case ja
    case de
    case hi
    case ur
    case ko
    case tr

    var id: String { rawValue }

    /// 源语言。所有查表 key 都是这门语言的原文，因此它不需要译表。
    static let source: AppLanguage = .zhHans

    /// 语言选择器里用该语言自己的写法（endonym），且**不跟随界面语言翻译**。
    ///
    /// 用户误切到看不懂的语言后，唯一的自救路径就是在列表里找回母语字形；
    /// 若这一栏也被翻译，那条路就断了。
    var endonym: String {
        switch self {
        case .zhHans: "简体中文"
        case .en: "English"
        case .es: "Español"
        case .fr: "Français"
        case .ru: "Русский"
        case .ar: "العربية"
        case .ptBR: "Português (Brasil)"
        case .ja: "日本語"
        case .de: "Deutsch"
        case .hi: "हिन्दी"
        case .ur: "اردو"
        case .ko: "한국어"
        case .tr: "Türkçe"
        }
    }

    /// 从右向左书写，需要整套布局镜像。
    var isRightToLeft: Bool {
        switch self {
        case .ar, .ur: true
        default: false
        }
    }

    /// 用于日期/数字格式化。与文案查表无关，那一套走 `Localization`。
    var locale: Locale { Locale(identifier: rawValue) }

    // MARK: - 跟随系统

    /// 按 `Locale.preferredLanguages` 的优先级挑第一个支持的语言。
    ///
    /// 用户的偏好列表是有序的，因此第一个命中项就是最佳答案；
    /// 全部落空时退到英语而不是中文——中文只对能读中文的人才是友好默认值。
    static func matchingSystem(
        preferred: [String] = Locale.preferredLanguages
    ) -> AppLanguage {
        for tag in preferred {
            if let match = match(languageTag: tag) { return match }
        }
        return .en
    }

    /// 把系统语言标签解析为受支持的语言。
    ///
    /// 必须做前缀降级而不是全等比较：系统给出的是 `zh-Hans-CN` / `en-US` /
    /// `pt-PT` 这类带地区的标签，全等匹配会一路落空到英语。
    ///
    /// 副作用是 `zh-Hant` 会落到简体上（我们没有繁体表）。这是有意的：
    /// 对繁体读者来说简体远比英语可读。
    static func match(languageTag tag: String) -> AppLanguage? {
        let lower = tag.lowercased()

        // 1. 完全匹配，涵盖带 script / 地区的 zh-Hans、pt-BR
        if let exact = allCases.first(where: { $0.rawValue.lowercased() == lower }) {
            return exact
        }

        // 2. 基础语言匹配：zh-Hans-CN、en-US、pt-PT 都在这里收口。
        //    `allCases` 的声明顺序决定同基础语言下的优先项（zh → zh-Hans）。
        guard let base = lower.split(separator: "-").first else { return nil }
        return allCases.first { $0.rawValue.lowercased().split(separator: "-").first == base }
    }
}
