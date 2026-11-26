//
//  Motion.swift
//  XcodeControl
//

import SwiftUI

/// 动效规范。
///
/// 两条原则：状态切换用有回弹但不夸张的 spring；任何超过 300ms 的等待都必须有
/// 连续动画，绝不允许界面「冻住」——这是工具类应用可信度的基础。
enum Motion {

    /// 状态切换
    static let state = Animation.spring(response: 0.35, dampingFraction: 0.8)
    /// 下拉面板展开/收起
    static let panel = Animation.spring(response: 0.32, dampingFraction: 0.86)
    /// 悬停等轻量反馈
    static let hover = Animation.easeOut(duration: 0.14)
    /// 错误条出现
    static let disclosure = Animation.spring(response: 0.4, dampingFraction: 0.85)

    /// 进度环旋转（不确定态）
    static let spin = Animation.linear(duration: 0.9).repeatForever(autoreverses: false)
    /// 运行中的边缘辉光呼吸
    static let glow = Animation.easeInOut(duration: 1.8).repeatForever(autoreverses: true)
}

/// 下拉面板的展开过渡：高度 + 不透明度联动，配合 anchor 为 top 的轻微缩放。
extension AnyTransition {
    static var dropdown: AnyTransition {
        .scale(scale: 0.96, anchor: .top)
            .combined(with: .opacity)
    }
}
