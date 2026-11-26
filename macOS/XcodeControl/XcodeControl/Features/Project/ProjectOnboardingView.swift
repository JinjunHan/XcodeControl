//
//  ProjectOnboardingView.swift
//  XcodeControl
//

import SwiftUI

/// 首次启动时的引导卡片：一个虚线拖放区，一句话说明。
///
/// 没有欢迎流程、没有多步向导——用户要做的只有一件事：把项目给我。
/// 拖放由外层 `FloatingRootView` 统一接收，这里只负责按 `isTargeted` 高亮。
struct ProjectOnboardingView: View {

    @Environment(AppState.self) private var state
    var isTargeted: Bool = false

    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: "square.and.arrow.down.on.square")
                .font(.system(size: 22, weight: .light))
                .foregroundStyle(isTargeted ? Theme.Palette.accent : Theme.Palette.textSecondary)

            VStack(spacing: 3) {
                Text(L10n.t("选择或拖入 Xcode 项目"))
                    .font(Theme.Font.primary)
                    .foregroundStyle(Theme.Palette.textPrimary)
                Text(subtitle)
                    .font(Theme.Font.tertiary)
                    .foregroundStyle(Theme.Palette.textTertiary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            }

            if state.projects.isLoading {
                ProgressView()
                    .controlSize(.small)
                    .frame(height: 18)
            } else {
                Button {
                    state.presentOpenPanel()
                } label: {
                    Text(L10n.t("选择项目…"))
                        .font(Theme.Font.secondary)
                        .foregroundStyle(Theme.Palette.textPrimary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 5)
                        .background {
                            Capsule(style: .continuous)
                                .fill(Theme.Palette.controlFill)
                                .overlay { Capsule().strokeBorder(Theme.Palette.hairline, lineWidth: 1) }
                        }
                }
                .buttonStyle(.plain)
                .frame(height: 18)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 18)
        .background {
            RoundedRectangle(cornerRadius: Theme.Metrics.innerCornerRadius, style: .continuous)
                .fill(isTargeted ? Theme.Palette.accent.opacity(0.06) : Color.clear)
                .overlay {
                    RoundedRectangle(cornerRadius: Theme.Metrics.innerCornerRadius, style: .continuous)
                        .strokeBorder(
                            isTargeted ? Theme.Palette.accent.opacity(0.7) : Theme.Palette.hairline,
                            style: StrokeStyle(lineWidth: 1, dash: [4, 3])
                        )
                }
        }
        .padding(.horizontal, 4)
        .padding(.bottom, 4)
        .animation(Motion.state, value: isTargeted)
    }

    private var subtitle: String {
        if let error = state.projects.loadError { return error }
        return L10n.t("拖入 .xcodeproj / .xcworkspace，或项目文件夹")
    }
}
