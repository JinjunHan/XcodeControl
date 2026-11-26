//
//  LogPaneView.swift
//  XcodeControl
//

import AppKit
import SwiftUI

/// 日志面板：默认收起，展开后固定高度，等宽字体，错误行高亮。
///
/// 它是「按需展开」的典型——绝大多数成功构建里用户根本不需要看它。
struct LogPaneView: View {

    @Environment(AppState.self) private var state
    @State private var isFilterVisible = false

    var body: some View {
        @Bindable var logs = state.logs

        VStack(spacing: 0) {
            Divider().overlay(Theme.Palette.separator)

            // 工具条
            HStack(spacing: 4) {
                Text(L10n.t("日志"))
                    .font(Theme.Font.tertiary)
                    .foregroundStyle(Theme.Palette.textTertiary)

                if logs.errorCount > 0 {
                    CountBadge(count: logs.errorCount, color: Theme.Palette.danger)
                }
                if logs.warningCount > 0 {
                    CountBadge(count: logs.warningCount, color: .orange)
                }

                if isFilterVisible {
                    SearchField(text: $logs.filterText, placeholder: L10n.t("过滤"))
                        .frame(maxWidth: 140)
                }

                Spacer(minLength: 4)

                IconButton(
                    symbol: "line.3.horizontal.decrease",
                    help: L10n.t("过滤"),
                    isActive: isFilterVisible
                ) {
                    withAnimation(Motion.state) {
                        isFilterVisible.toggle()
                        if !isFilterVisible { logs.filterText = "" }
                    }
                }
                IconButton(
                    symbol: "arrow.down.to.line",
                    help: logs.autoScroll ? L10n.t("自动滚动：开") : L10n.t("自动滚动：关"),
                    isActive: logs.autoScroll
                ) {
                    logs.autoScroll.toggle()
                }
                IconButton(symbol: "doc.on.doc", help: L10n.t("拷贝完整日志")) {
                    let text = logs.plainText()
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(text, forType: .string)
                }
                IconButton(symbol: "chevron.down", help: L10n.t("收起日志")) {
                    withAnimation(Motion.disclosure) { state.isLogPaneExpanded = false }
                }
            }
            .padding(.horizontal, 6)
            .padding(.vertical, 4)

            // 正文
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 0) {
                        ForEach(logs.filteredEntries) { entry in
                            Text(entry.text)
                                .font(Theme.Font.mono)
                                .foregroundStyle(color(for: entry.level))
                                .textSelection(.enabled)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 0.5)
                                .id(entry.id)
                        }
                        Color.clear.frame(height: 1).id(Self.bottomAnchor)
                    }
                    .padding(.vertical, 4)
                }
                .frame(height: Theme.Metrics.logPaneHeight)
                .onChange(of: logs.entries.count) { _, _ in
                    guard logs.autoScroll else { return }
                    proxy.scrollTo(Self.bottomAnchor, anchor: .bottom)
                }
            }
            .background(Color.black.opacity(0.18))
        }
        .transition(.opacity.combined(with: .move(edge: .top)))
    }

    private static let bottomAnchor = "log-bottom"

    private func color(for level: LogEntry.Level) -> Color {
        switch level {
        case .error: Theme.Palette.danger
        case .warning: .orange.opacity(0.9)
        case .note: Theme.Palette.textSecondary
        case .output: Theme.Palette.textSecondary.opacity(0.85)
        }
    }
}

/// 错误 / 警告计数徽标
struct CountBadge: View {
    let count: Int
    let color: Color

    var body: some View {
        Text("\(count)")
            .font(Theme.Font.tertiary.monospacedDigit())
            .foregroundStyle(color)
            .padding(.horizontal, 4)
            .padding(.vertical, 0.5)
            .background {
                Capsule().fill(color.opacity(0.14))
            }
    }
}
