//
//  LocalizedModifier.swift
//  XcodeControl
//

import SwiftUI

/// 浮窗根视图的语言包装。
///
/// `AppDelegate` 是 `NSObject` 而非视图，在那里读 `state.language` 无法建立
/// observation；套一层视图，让「读语言」发生在 SwiftUI 的求值上下文里。
struct LocalizedFloatingRoot: View {

    let state: AppState
    let onContentSizeChange: (CGSize) -> Void

    var body: some View {
        // Keep the measured content at the top while AppKit applies its new
        // window height on the next run loop.
        GeometryReader { _ in
            FloatingRootView(onContentSizeChange: onContentSizeChange)
                .localized(state.language)
        }
    }
}

extension View {

    /// 让整棵子树跟随界面语言：切换语言时重建，并按语言设置书写方向与 `Locale`。
    ///
    /// **为什么需要显式 `.id`：** `L10n.t(_:)` 返回普通 `String`，读的是
    /// `Localization.current` 这个静态变量——它不可观察，改了不会让 SwiftUI 失效。
    /// 用 `.id(language)` 把语言变成视图身份的一部分，换语言即换身份，整棵树重建。
    /// 代价是重建时丢掉子树里的 `@State`（如设置页的滑块缓冲值），但语言切换是
    /// 低频动作，且用户此刻的预期本来就是「界面整体换了一次」。
    ///
    /// `layoutDirection` 必须一起给：阿语与乌尔都语从右向左书写，只换文案不换方向
    /// 会得到一个左对齐的阿语界面——比不翻译更难读。
    func localized(_ language: AppLanguage) -> some View {
        self
            .environment(\.layoutDirection, language.isRightToLeft ? .rightToLeft : .leftToRight)
            .environment(\.locale, language.locale)
            .id(language)
    }
}
