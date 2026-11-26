//
//  Localization.swift
//  XcodeControl
//

import Foundation

/// 文案查表。
///
/// **为什么不用 `.lproj` / String Catalog：** 需要支持
/// `Models/`、`Core/Toolchain/`、`Core/Service/`、`Core/Storage/` 能被
/// `xcrun swiftc` 单独编成命令行程序跑无头验证。那种场景下没有 app bundle，
/// `NSLocalizedString` 只会把 key 原样返回——ErrorTranslator 的 19 条提示、
/// 各 Adapter 的失败原因全都退化成 key，无头验证也就看不出真实文案。
/// 纯 Swift 表在两种宿主里行为一致，代价是失去 Xcode 的字符串目录编辑器。
///
/// 附带的收益是可以在运行时切换语言：`.lproj` 走的 `AppleLanguages` 覆写
/// 需要重启进程才生效，而浮窗是常驻的，重启等于打断用户手上的构建。
enum Localization {

    /// 当前语言。写入请走 `AppState.setLanguage(_:)`，那里会一并触发界面重建。
    ///
    /// 用 `nonisolated(unsafe)` 而不是 actor 隔离：查表在渲染路径上每帧调用
    /// 几十次，加 await 会把 `Text(L10n.run)` 这种同步表达式全部染成异步。
    /// 实际写入只发生在用户切换语言时，且只在主线程，不存在竞争。
    nonisolated(unsafe) private(set) static var current: AppLanguage = .source

    /// 各语言的译表。key 是简体中文原文，value 是目标语言译文。
    ///
    /// 源语言不建表：查不到就返回 key 本身，而 key 就是中文原文。
    private static let tables: [AppLanguage: [String: String]] = [
        .en: L10nTable.en,
        .es: L10nTable.es,
        .fr: L10nTable.fr,
        .ru: L10nTable.ru,
        .ar: L10nTable.ar,
        .ptBR: L10nTable.ptBR,
        .ja: L10nTable.ja,
        .de: L10nTable.de,
        .hi: L10nTable.hi,
        .ur: L10nTable.ur,
        .ko: L10nTable.ko,
        .tr: L10nTable.tr,
    ]

    static func setCurrent(_ language: AppLanguage) {
        current = language
    }

    /// 查表。缺条目时返回 key（即中文原文），不返回空串也不 crash——
    /// 漏翻译应该表现为「这一处还是中文」，而不是界面上出现空白。
    static func string(_ key: String) -> String {
        guard current != .source else { return key }
        return tables[current]?[key] ?? key
    }

    // MARK: - 校验

    /// 每种语言缺失的 key。仅供无头验证与调试用，不进 UI。
    ///
    /// 以 `L10nTable.en` 的 key 集合为基准：英语表是人工维护最全的一份，
    /// 新增文案时先补英语，其余语言的缺口由这里报出来。
    static func missingKeys() -> [AppLanguage: [String]] {
        let baseline = Set(L10nTable.en.keys)
        var result: [AppLanguage: [String]] = [:]
        for language in AppLanguage.allCases where language != .source {
            guard let table = tables[language] else {
                result[language] = baseline.sorted()
                continue
            }
            let missing = baseline.subtracting(table.keys)
            if !missing.isEmpty { result[language] = missing.sorted() }
        }
        return result
    }
}

/// 查表的简写。`L10n.t("运行")` 读起来比 `Localization.string("运行")` 短，
/// 在 SwiftUI 的 `Text(...)` 里尤其明显。
enum L10n {

    static func t(_ key: String) -> String {
        Localization.string(key)
    }

    /// 带插值的文案。译文里用 `%@` 标记占位，顺序与 `args` 一致。
    ///
    /// 不能直接拼字符串：中文的「已添加 3 个项目」在英语里是
    /// "Added 3 projects"，德语要把数字放到别处，位置差异只能由译文自己决定。
    static func t(_ key: String, _ args: CVarArg...) -> String {
        String(format: Localization.string(key), arguments: args)
    }
}
