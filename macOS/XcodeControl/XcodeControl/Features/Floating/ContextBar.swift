//
//  ContextBar.swift
//  XcodeControl
//

import AppKit
import SwiftUI

/// 上行的极窄上下文条：左侧项目名、右侧 scheme 名各自可点，中间空白不可点。
///
/// 字号和不透明度都刻意压低——这是次要信息，需要它的时候能找到，
/// 但它不该抢注意力。
struct ContextBar: View {

    let projectName: String
    let projectIcon: NSImage?
    let schemeName: String?
    let configuration: String
    let isExpanded: Bool
    let isLoading: Bool
    let onProjectTap: () -> Void
    let onSchemeTap: () -> Void
    let onSettingsTap: () -> Void

    var body: some View {
        HStack(spacing: 5) {
            ContextBarSegment(isExpanded: isExpanded, action: onProjectTap) {
                HStack(spacing: 5) {
                    if let projectIcon {
                        Image(nsImage: projectIcon)
                            .resizable()
                            .interpolation(.high)
                            .frame(width: 12, height: 12)
                            .clipShape(RoundedRectangle(cornerRadius: 2.5, style: .continuous))
                    }

                    Text(projectName)
                        .font(Theme.Font.secondary)
                        .foregroundStyle(Theme.Palette.textSecondary)
                        .lineLimit(1)

                    Image(systemName: "chevron.down")
                        .font(.system(size: 7, weight: .semibold))
                        .foregroundStyle(Theme.Palette.textTertiary)
                        .rotationEffect(.degrees(isExpanded ? 180 : 0))
                }
            }

            // 中间留白与次要徽章故意不包进按钮，避免整行误触。
            Spacer(minLength: 8)

            if isLoading {
                // 不要再叠 scaleEffect：ProgressView 背后是 AppKit 的
                // NSProgressIndicator，缩放会把它的固有尺寸除成小数
                // （7.5 / 0.7 = 10.714286），AppKit 拿这个值同时当 min 和 max
                // 建约束时会因浮点舍入判定 min > max 而拒绝，然后每个布局周期
                // 重新入队一次——NSISEngine 的待删除列表越堆越大，最终
                // _flushPendingRemovals 的栈上分配撑爆主线程栈。
                // 尺寸交给 controlSize，外框只留整数点位。
                ProgressView()
                    .controlSize(.mini)
                    .frame(width: 12, height: 12)
            }

            if configuration != BuildConfiguration.debug {
                Text(configuration)
                    .font(Theme.Font.tertiary)
                    .foregroundStyle(Theme.Palette.textTertiary)
                    .padding(.horizontal, 4)
                    .padding(.vertical, 1)
                    .background {
                        RoundedRectangle(cornerRadius: 3, style: .continuous)
                            .fill(Theme.Palette.controlFill)
                    }
            }

            ContextBarSegment(isExpanded: isExpanded, action: onSchemeTap) {
                Text(schemeName ?? "—")
                    .font(Theme.Font.secondary)
                    .foregroundStyle(Theme.Palette.textTertiary)
                    .lineLimit(1)
            }
            IconButton(symbol: "gearshape", help: L10n.t("设置"), action: onSettingsTap)
        }
        .padding(.horizontal, 6)
        .frame(height: Theme.Metrics.contextBarHeight)
        .animation(Motion.state, value: isExpanded)
    }
}

/// 上下文条上的一侧触发区：独立 hover / 点击，不占满整行。
private struct ContextBarSegment<Label: View>: View {
    let isExpanded: Bool
    let action: () -> Void
    @ViewBuilder let label: () -> Label

    @State private var isHovering = false

    var body: some View {
        Button(action: action) {
            label()
                .padding(.horizontal, 4)
                .padding(.vertical, 2)
                .background {
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .fill(isHovering || isExpanded ? Theme.Palette.controlFill : .clear)
                }
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .onHover { isHovering = $0 }
        .animation(Motion.hover, value: isHovering)
    }
}

/// 设备选择器的胶囊形触发区：设备类型图标 + 设备名 + 状态点。
struct DeviceTrigger: View {

    let destination: RunDestination?
    let isExpanded: Bool
    let isRefreshing: Bool
    let action: () -> Void

    @State private var isHovering = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: 7) {
                Image(systemName: destination?.symbolName ?? "questionmark.square.dashed")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(Theme.Palette.textPrimary.opacity(0.85))
                    .frame(width: 14)

                VStack(alignment: .leading, spacing: 0) {
                    Text(destination?.name ?? L10n.t("选择设备"))
                        .font(Theme.Font.primary)
                        .foregroundStyle(destination == nil ? Theme.Palette.textSecondary : Theme.Palette.textPrimary)
                        .lineLimit(1)
                }

                Spacer(minLength: 4)

                if isRefreshing {
                    // 同上：去掉 scaleEffect。外框也从 10 放宽到 12——mini 指示器的
                    // 固有边长约 10.7，钉一个比它还小的框同样会制造矛盾约束。
                    ProgressView()
                        .controlSize(.mini)
                        .frame(width: 12, height: 12)
                } else if let destination {
                    StatusDot(isOnline: destination.isReady)
                }

                Image(systemName: "chevron.up.chevron.down")
                    .font(.system(size: 8, weight: .semibold))
                    .foregroundStyle(Theme.Palette.textTertiary)
            }
            .padding(.horizontal, 10)
            .frame(height: Theme.Metrics.controlRowHeight - 8)
            .frame(maxWidth: .infinity)
            .background {
                Capsule(style: .continuous)
                    .fill(fill)
                    .overlay {
                        Capsule(style: .continuous)
                            .strokeBorder(Theme.Palette.hairline.opacity(isExpanded ? 1 : 0.6), lineWidth: 1)
                    }
            }
            .contentShape(Capsule())
        }
        .buttonStyle(.plain)
        .onHover { isHovering = $0 }
        .animation(Motion.hover, value: isHovering)
    }

    private var fill: Color {
        if isExpanded { return Theme.Palette.controlFillActive }
        return isHovering ? Theme.Palette.controlFillHover : Theme.Palette.controlFill
    }
}

/// 状态小圆点：已启动/已连接为强调色，否则为灰。
struct StatusDot: View {
    let isOnline: Bool

    var body: some View {
        Circle()
            .fill(isOnline ? Theme.Palette.accent : Theme.Palette.dotOffline)
            .frame(width: 5, height: 5)
            .overlay {
                Circle()
                    .stroke(Theme.Palette.accent.opacity(isOnline ? 0.28 : 0), lineWidth: 3)
            }
            .animation(Motion.state, value: isOnline)
    }
}
