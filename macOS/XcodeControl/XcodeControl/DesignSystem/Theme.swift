//
//  Theme.swift
//  XcodeControl
//

import SwiftUI

/// 视觉规范的唯一来源。
///
/// 基调是深色毛玻璃 + 单色强调：界面强调色固定为系统绿；运行按钮单独跟随
/// 系统主题色。红色仅用于停止激活态与错误提示，除此之外不出现第三种彩色。
/// 所有层级差异靠不透明度和字重表达。
enum Theme {

    // MARK: - 颜色

    enum Palette {
        /// #30D158 系统绿——在线状态点、勾选、运行中辉光等界面强调色。
        /// 运行按钮不走这里，见 `Color.accentColor`。
        static let accent = Color(red: 0x30 / 255, green: 0xD1 / 255, blue: 0x58 / 255)
        /// #FF453A ——仅用于停止按钮激活态与错误提示
        static let danger = Color(red: 0xFF / 255, green: 0x45 / 255, blue: 0x3A / 255)

        /// 主要文本 100% 白
        static let textPrimary = Color.white
        /// 次要文本 55% 白
        static let textSecondary = Color.white.opacity(0.55)
        /// 辅助文本 35% 白
        static let textTertiary = Color.white.opacity(0.35)
        /// 不可用状态
        static let textDisabled = Color.white.opacity(0.22)

        /// 玻璃暗场：压在毛玻璃**之上**的一层固定深色，给对比度兜底。
        ///
        /// `.behindWindow` 混合会把背后的桌面亮度原样透上来——浅色壁纸、一张白底网页、
        /// 浅色主题的 Xcode，都会把面板整体抬到中灰，55% / 35% 的白字直接糊掉。
        /// 毛玻璃本身没有对比度下限，这一层就是那个下限：不管背后是什么，
        /// 白字底下永远压着一个足够深的底。
        /// 代价是深色背景下玻璃感略减，这是为「任何背景下都读得出」付的钱，刻意为之。
        static let glassScrim = Color.black.opacity(0.30)

        /// 窗口内描边 12% 白——深色背景下的玻璃边缘
        static let hairline = Color.white.opacity(0.12)
        /// 窗口最外一圈暗描边——浅色背景下 12% 白的内描边形同虚设，
        /// 靠这圈暗边配合系统阴影才能把浮层从白底里切出来。
        /// 两条边一明一暗，深浅背景各由其中一条负责，不需要判断背景色。
        static let hairlineOuter = Color.black.opacity(0.22)
        /// 控件底色
        static let controlFill = Color.white.opacity(0.08)
        static let controlFillHover = Color.white.opacity(0.13)
        static let controlFillActive = Color.white.opacity(0.18)
        /// 分隔线
        static let separator = Color.white.opacity(0.08)
        /// 顶部提亮渐变（模拟玻璃边缘折射）
        static let glassHighlight = Color.white.opacity(0.08)
        /// 状态点：离线
        static let dotOffline = Color.white.opacity(0.28)
    }

    // MARK: - 字体

    enum Font {
        /// 主要文本 13pt medium
        static let primary = SwiftUI.Font.system(size: 13, weight: .medium)
        /// 次要文本 11pt regular
        static let secondary = SwiftUI.Font.system(size: 11, weight: .regular)
        /// 辅助文本 10pt regular
        static let tertiary = SwiftUI.Font.system(size: 10, weight: .regular)
        /// 分组标题
        static let sectionTitle = SwiftUI.Font.system(size: 10, weight: .semibold)
        /// 含数字的状态文案——启用 monospacedDigit 避免跳动
        static let status = SwiftUI.Font.system(size: 10, weight: .regular).monospacedDigit()
        /// 日志等宽
        static let mono = SwiftUI.Font.system(size: 10.5, weight: .regular, design: .monospaced)
    }

    // MARK: - 尺寸

    enum Metrics {
        /// 主界面宽度——设备胶囊吃掉剩余空间，收窄这里就能直接把设备框缩短。
        static let panelWidth: CGFloat = 280
        /// 主界面高度（两行）
        static let panelHeight: CGFloat = 76
        /// 引导卡片高度
        static let onboardingHeight: CGFloat = 156

        static let cornerRadius: CGFloat = 16
        static let innerCornerRadius: CGFloat = 11
        static let horizontalPadding: CGFloat = 10

        /// 圆形按钮直径
        static let actionButton: CGFloat = 34
        /// 上下文条高度
        static let contextBarHeight: CGFloat = 22
        /// 操作区高度
        static let controlRowHeight: CGFloat = 42

        static let dropdownMaxHeight: CGFloat = 320
        static let logPaneHeight: CGFloat = 220
    }
}

// MARK: - 便捷修饰

extension View {
    /// 主要文本
    func textPrimaryStyle() -> some View {
        font(Theme.Font.primary).foregroundStyle(Theme.Palette.textPrimary)
    }

    /// 次要文本
    func textSecondaryStyle() -> some View {
        font(Theme.Font.secondary).foregroundStyle(Theme.Palette.textSecondary)
    }

    /// 辅助文本
    func textTertiaryStyle() -> some View {
        font(Theme.Font.tertiary).foregroundStyle(Theme.Palette.textTertiary)
    }
}
