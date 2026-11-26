//
//  StatusStrip.swift
//  XcodeControl
//

import AppKit
import SwiftUI

/// 浮窗状态行：左侧构建状态，右侧 Git branch。
struct StatusStrip: View {
    let text: String?
    let gitReference: String?
    let isGitExpanded: Bool
    let isGitBusy: Bool
    let onGitReferenceTap: () -> Void

    @State private var isGitHovering = false

    var body: some View {
        HStack(spacing: 6) {
            if let text {
                Text(text)
                    .font(Theme.Font.status)
                    .foregroundStyle(Theme.Palette.textSecondary)
                    .lineLimit(1)
            }

            Spacer(minLength: 0)

            if let gitReference {
                Button(action: onGitReferenceTap) {
                    HStack(spacing: 3) {
                        if isGitBusy {
                            ProgressView()
                                .controlSize(.mini)
                                .frame(width: 12, height: 12)
                        } else {
                            Image(systemName: "arrow.triangle.branch")
                                .font(.system(size: 8, weight: .medium))
                                .frame(width: 12)
                        }
                        Text(gitReference)
                            .font(Theme.Font.tertiary)
                            .lineLimit(1)
                            .truncationMode(.middle)
                        Image(systemName: "chevron.down")
                            .font(.system(size: 6.5, weight: .semibold))
                            .rotationEffect(.degrees(isGitExpanded ? 180 : 0))
                    }
                    .foregroundStyle(
                        isGitHovering || isGitExpanded
                            ? Theme.Palette.textSecondary
                            : Theme.Palette.textTertiary
                    )
                    .padding(.horizontal, 4)
                    .padding(.vertical, 2)
                    .background {
                        RoundedRectangle(cornerRadius: 5, style: .continuous)
                            .fill(
                                isGitHovering || isGitExpanded
                                    ? Theme.Palette.controlFill
                                    : .clear
                            )
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .frame(maxWidth: 130, alignment: .trailing)
                .layoutPriority(1)
                .onHover { isGitHovering = $0 }
                .help(L10n.t("切换 Git 分支"))
                .accessibilityLabel(L10n.t("切换 Git 分支"))
            }
        }
        .padding(.leading, 4)
        .padding(.trailing, 6)
        .padding(.top, 2)
        .padding(.bottom, 4)
        .transition(.opacity.combined(with: .move(edge: .top)))
    }
}

/// 失败时展开的错误摘要：红色左边线 + 首条 error 的文件名与描述。
///
/// 摘要必须一眼可读——不要把 xcodebuild 的原始输出直接甩给用户。
/// 文件名一行与描述一行都开了 `textSelection`：这张卡片上的每个字都可能是用户
/// 想拿走的东西（文件名用于跳转，描述用于搜索），只让一半可选没有道理。
struct FailureBar: View {

    let failure: BuildFailure
    let isLogExpanded: Bool
    let onToggleLog: () -> Void
    let onDismiss: () -> Void

    @State private var didCopy = false

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Rectangle()
                .fill(Theme.Palette.danger)
                .frame(width: 2)
                .clipShape(Capsule())

            VStack(alignment: .leading, spacing: 2) {
                if let location = failure.locationDisplay {
                    Text(location)
                        .font(Theme.Font.tertiary.monospacedDigit())
                        .foregroundStyle(Theme.Palette.danger.opacity(0.9))
                        .lineLimit(1)
                        .textSelection(.enabled)
                        // 卡片窄，显示的是 basename；完整路径挂在 tooltip 上。
                        .help(failure.file ?? location)
                }
                Text(failure.summary)
                    .font(Theme.Font.secondary)
                    .foregroundStyle(Theme.Palette.textPrimary.opacity(0.9))
                    .lineLimit(3)
                    .fixedSize(horizontal: false, vertical: true)
                    .textSelection(.enabled)
            }

            Spacer(minLength: 4)

            HStack(spacing: 2) {
                IconButton(
                    symbol: didCopy ? "checkmark" : "doc.on.doc",
                    help: L10n.t("拷贝错误信息"),
                    action: copy
                )
                // 失败时日志默认已经展开（`autoExpandLogOnFailure`），所以这个入口
                // 必须是开关而不是「设为展开」——否则点下去界面毫无变化，
                // 看起来像个坏按钮。与其他次级入口一致：同一入口点两次即收起。
                IconButton(
                    symbol: "text.alignleft",
                    help: isLogExpanded ? L10n.t("收起日志") : L10n.t("查看完整日志"),
                    isActive: isLogExpanded,
                    action: onToggleLog
                )
                IconButton(symbol: "xmark", help: L10n.t("关闭"), action: onDismiss)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 7)
        .background {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(Theme.Palette.danger.opacity(0.1))
        }
        .padding(.horizontal, 2)
        .padding(.bottom, 2)
        .transition(.opacity.combined(with: .move(edge: .top)))
        // 勾号是一次反馈，不是状态：留着就看不出下一次点击「又拷了一次」。
        // 用 `.task(id:)` 而不是裸 Task，取消与主线程回写都由 SwiftUI 管。
        .task(id: didCopy) {
            guard didCopy else { return }
            try? await Task.sleep(for: .seconds(1.2))
            guard !Task.isCancelled else { return }
            didCopy = false
        }
    }

    private func copy() {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(failure.copyText, forType: .string)
        didCopy = true
    }
}

/// 小号图标按钮，用于错误条与日志面板的次级操作。
struct IconButton: View {
    let symbol: String
    var help: String = ""
    var isActive: Bool = false
    let action: () -> Void

    @State private var isHovering = false

    var body: some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: 9.5, weight: .medium))
                .foregroundStyle(isActive ? Theme.Palette.textPrimary : Theme.Palette.textSecondary)
                .frame(width: 20, height: 20)
                .background {
                    RoundedRectangle(cornerRadius: 5, style: .continuous)
                        .fill(isHovering ? Theme.Palette.controlFillHover : .clear)
                }
        }
        .buttonStyle(.plain)
        .onHover { isHovering = $0 }
        .help(help)
        .accessibilityLabel(help.isEmpty ? symbol : help)
    }
}
