//
//  RunButton.swift
//  XcodeControl
//

import SwiftUI

/// 运行按钮不是一个静态控件，它的形态本身就是状态指示器。
struct RunButton: View {

    let phase: RunPhase
    /// 构建已用秒数（用于不确定态进度环旁的计时，这里只驱动动画不显示）
    let action: () -> Void
    /// 长按触发清理后构建
    let cleanAction: () -> Void

    @State private var isHovering = false
    @State private var spin = false

    @GestureState private var holding = false
    private let holdDuration = 0.6

    private var isWorking: Bool { phase.isWorking }
    private var isRunning: Bool { phase.isRunning }

    private var symbol: String {
        if isRunning { return "arrow.triangle.2.circlepath" }
        return "play.fill"
    }

    var body: some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .fill(isWorking ? AnyShapeStyle(Theme.Palette.controlFill) : AnyShapeStyle(Color.accentColor.opacity(isHovering ? 0.72 : 0.55)))
                    .overlay {
                        // 顶部提亮 + 底部压暗叠在系统强调色上，换主题色时体积感仍在。
                        if !isWorking {
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(isHovering ? 0.22 : 0.14),
                                    Color.clear,
                                    Color.black.opacity(isHovering ? 0.10 : 0.16)
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                            .clipShape(Circle())
                        }
                    }
                    .overlay {
                        Circle()
                            .strokeBorder(
                                Color.white.opacity(isWorking ? 0 : (isHovering ? 0.22 : 0.12)),
                                lineWidth: 0.8
                            )
                    }
                    .overlay {
                        Circle()
                            .strokeBorder(Color.accentColor.opacity(isWorking ? 0.18 : 0), lineWidth: 2)
                    }
                    .shadow(
                        color: Color.accentColor.opacity(isWorking ? 0 : (isHovering ? 0.32 : 0.18)),
                        radius: isHovering ? 10 : 7,
                        y: 1
                    )

                if isWorking {
                    // xcodebuild 的进度不可精确获取，采用不确定态旋转
                    Circle()
                        .trim(from: 0, to: 0.28)
                        .stroke(Color.accentColor.opacity(0.7), style: StrokeStyle(lineWidth: 2.2, lineCap: .round))
                        .padding(2)
                        .rotationEffect(.degrees(spin ? 360 : 0))
                } else {
                    Image(systemName: holding ? "sparkles" : symbol)
                        .font(.system(size: isRunning ? 13 : 12, weight: .semibold))
                        .foregroundStyle(Color.white.opacity(0.95))
                        .shadow(color: Color.black.opacity(0.22), radius: 0.5, y: 0.5)
                        .offset(x: isRunning ? 0 : 1)   // 三角形的光学居中
                }
            }
            .frame(width: Theme.Metrics.actionButton, height: Theme.Metrics.actionButton)
            .overlay {
                if holding && !isWorking {
                    HoldProgressRing(duration: holdDuration)
                }
            }
            .scaleEffect(holding && !isWorking ? 0.92 : isHovering && !isWorking ? 1.06 : 1)
            .animation(Motion.hover, value: isHovering)
            .animation(Motion.state, value: isWorking)
            .animation(Motion.state, value: isRunning)
        }
        .buttonStyle(.plain)
        // One pointer gesture owns both outcomes. The underlying button still
        // supplies keyboard and accessibility activation.
        .overlay {
            if !isWorking {
                Circle().fill(.clear).contentShape(Circle())
                    .gesture(
                        LongPressGesture(minimumDuration: holdDuration)
                            .exclusively(before: TapGesture())
                            .onEnded { result in
                                switch result {
                                case .first(true):
                                    NSHapticFeedbackManager.defaultPerformer.perform(.alignment, performanceTime: .now)
                                    cleanAction()
                                case .second: action()
                                default: break
                                }
                            }
                    )
                    .simultaneousGesture(DragGesture(minimumDistance: 0)
                        .updating($holding) { value, pressed, _ in
                            pressed = hypot(value.translation.width, value.translation.height) <= 10
                        })
                    .accessibilityHidden(true)
            }
        }
        .onHover { isHovering = $0 }
        .disabled(isWorking)
        .accessibilityAction(named: Text(L10n.t("清理后构建"))) { cleanAction() }
        .onChange(of: isWorking, initial: true) { _, working in
            if working {
                spin = false
                withAnimation(Motion.spin) { spin = true }
            } else {
                withAnimation(.default) { spin = false }
            }
        }
        .help(helpText)
        .accessibilityLabel(helpText)
    }

    private var helpText: String {
        if isWorking { return L10n.t("正在构建…") }
        if isRunning { return L10n.t("重新运行（长按可清理后构建）") }
        return L10n.t("运行（长按可清理后构建）")
    }
}

private struct HoldProgressRing: View {
    let duration: Double
    @State private var startedAt = Date()

    var body: some View {
        TimelineView(.animation) { tick in
            Circle()
                .trim(from: 0, to: min(1, max(0, tick.date.timeIntervalSince(startedAt) / duration)))
                .stroke(.white, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .padding(2)
        }
        .allowsHitTesting(false)
    }
}

/// 停止按钮：构建中语义是「取消构建」，运行中是「终止 App」。
struct StopButton: View {

    let phase: RunPhase
    let action: () -> Void

    @State private var isHovering = false

    private var isEnabled: Bool { phase.canStop }
    private var isDangerous: Bool { phase.isRunning }

    var body: some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .fill(Theme.Palette.controlFill.opacity(isEnabled && isHovering ? 1.6 : 1))
                    .overlay {
                        Circle().strokeBorder(strokeColor, lineWidth: 1.2)
                    }
                Image(systemName: "stop.fill")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(iconColor)
            }
            .frame(width: Theme.Metrics.actionButton, height: Theme.Metrics.actionButton)
            .scaleEffect(isHovering && isEnabled ? 1.06 : 1)
            .animation(Motion.hover, value: isHovering)
            .animation(Motion.state, value: isEnabled)
            .animation(Motion.state, value: isDangerous)
        }
        .buttonStyle(.plain)
        .disabled(!isEnabled)
        .onHover { isHovering = $0 && isEnabled }
        .help(helpText)
        .accessibilityLabel(helpText)
    }

    private var strokeColor: Color {
        guard isEnabled else { return .clear }
        return isDangerous ? Theme.Palette.danger.opacity(0.9) : Theme.Palette.hairline
    }

    private var iconColor: Color {
        guard isEnabled else { return Theme.Palette.textDisabled }
        return isDangerous ? Theme.Palette.danger : Theme.Palette.textPrimary.opacity(0.85)
    }

    private var helpText: String {
        switch phase {
        case .building, .installing, .launching: L10n.t("取消构建")
        case .running: L10n.t("停止运行")
        default: L10n.t("停止")
        }
    }
}
