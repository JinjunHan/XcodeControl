//
//  SwiftPackageToolsView.swift
//  XcodeControl
//

import SwiftUI

/// 当前项目的 Swift Package 修复工具。
///
/// 它是项目菜单下钻的一层二级面板，而不是核心操作行的一部分：依赖修复是低频、
/// 项目级操作，常驻展示会挤占「设备 / 运行 / 停止」三个最高频动作。
struct SwiftPackageToolsView: View {

    @Environment(AppState.self) private var state
    @State private var confirmsCacheRemoval = false

    var body: some View {
        let packages = state.packages
        let disabled = packages.isWorking || state.run.phase.isWorking

        VStack(spacing: 0) {
            header

            Divider().overlay(Theme.Palette.separator)

            VStack(alignment: .leading, spacing: 2) {
                ToolRow(
                    symbol: "lock.doc",
                    title: L10n.t("按 Package.resolved 修复"),
                    detail: L10n.t("不更新版本；优先使用锁定文件恢复依赖"),
                    isWorking: isRunning(.resolvedFileOnly),
                    disabled: disabled || packages.packageResolvedURL == nil
                ) {
                    state.resolveSwiftPackages(useResolvedFileOnly: true)
                }

                ToolRow(
                    symbol: "arrow.triangle.2.circlepath",
                    title: L10n.t("重新解析依赖"),
                    detail: L10n.t("允许联网，并按工程声明重新解析版本"),
                    isWorking: isRunning(.updateAllowed),
                    disabled: disabled
                ) {
                    state.resolveSwiftPackages(useResolvedFileOnly: false)
                }

                ToolRow(
                    symbol: "trash",
                    title: L10n.t("清理项目 Package 缓存…"),
                    detail: L10n.t("只清当前项目的 SourcePackages，不影响其他项目"),
                    isWorking: isRunning(.clearCache),
                    disabled: disabled || packages.sourcePackagesURL == nil,
                    role: .destructive
                ) {
                    confirmsCacheRemoval = true
                }
            }
            .padding(.horizontal, 4)
            .padding(.vertical, 4)

            if let message = statusMessage {
                Divider().overlay(Theme.Palette.separator)
                HStack(alignment: .top, spacing: 6) {
                    Image(systemName: statusSymbol)
                        .font(.system(size: 9, weight: .semibold))
                        .foregroundStyle(statusColor)
                        .frame(width: 12, height: 14)
                    Text(message)
                        .font(Theme.Font.tertiary)
                        .foregroundStyle(statusColor)
                        .fixedSize(horizontal: false, vertical: true)
                    Spacer(minLength: 0)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 7)
            }

            Divider().overlay(Theme.Palette.separator)

            if packages.isWorking {
                FooterButton(symbol: "xmark.circle", title: L10n.t("停止当前操作")) {
                    state.cancelSwiftPackageOperation()
                }
            } else {
                if packages.packageResolvedURL != nil {
                    FooterButton(symbol: "doc.text.magnifyingglass", title: L10n.t("在 Finder 中显示 Package.resolved")) {
                        state.revealPackageResolved()
                    }
                }
                if cacheDirectoryExists {
                    FooterButton(symbol: "folder", title: L10n.t("打开项目 Package 缓存")) {
                        state.revealSwiftPackageCache()
                    }
                }
            }
        }
        .background { DropdownBackground() }
        .confirmationDialog(
            L10n.t("清理当前项目的 Package 缓存？"),
            isPresented: $confirmsCacheRemoval
        ) {
            Button(L10n.t("清理缓存"), role: .destructive) {
                state.clearSwiftPackageCache()
            }
            Button(L10n.t("取消"), role: .cancel) {}
        } message: {
            Text(L10n.t("将删除当前 DerivedData 中的 checkouts、repositories 和 artifacts。Package.resolved 会保留；清理后需要重新解析依赖。"))
        }
    }

    private var header: some View {
        HStack(spacing: 7) {
            IconButton(symbol: "chevron.left", help: L10n.t("返回项目列表")) {
                withAnimation(Motion.panel) { state.openPanel = .project }
            }
            VStack(alignment: .leading, spacing: 1) {
                Text("Swift Package")
                    .font(Theme.Font.secondary.weight(.semibold))
                    .foregroundStyle(Theme.Palette.textPrimary)
                Text(state.projects.current?.name ?? "—")
                    .font(Theme.Font.tertiary)
                    .foregroundStyle(Theme.Palette.textTertiary)
                    .lineLimit(1)
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 7)
    }

    private func isRunning(_ operation: SwiftPackageStore.Operation) -> Bool {
        if case .running(let current) = state.packages.status { return current == operation }
        return false
    }

    private var statusMessage: String? {
        switch state.packages.status {
        case .idle:
            if state.packages.packageResolvedURL == nil {
                return L10n.t("未找到 Package.resolved；可直接重新解析依赖。")
            }
            return nil
        case .running(let operation):
            return L10n.t("正在%@…", operation.title)
        case .succeeded(let message), .failed(let message):
            return message
        }
    }

    private var statusSymbol: String {
        switch state.packages.status {
        case .failed: "exclamationmark.triangle.fill"
        case .succeeded: "checkmark.circle.fill"
        case .running: "clock"
        case .idle: "info.circle"
        }
    }

    private var statusColor: Color {
        switch state.packages.status {
        case .failed: Theme.Palette.danger.opacity(0.9)
        case .succeeded: Theme.Palette.accent.opacity(0.9)
        default: Theme.Palette.textTertiary
        }
    }

    private var cacheDirectoryExists: Bool {
        guard let url = state.packages.sourcePackagesURL else { return false }
        return FileManager.default.fileExists(atPath: url.path)
    }
}

private struct ToolRow: View {
    let symbol: String
    let title: String
    let detail: String
    let isWorking: Bool
    let disabled: Bool
    var role: ButtonRole?
    let action: () -> Void

    @State private var isHovering = false

    var body: some View {
        Button(role: role, action: action) {
            HStack(spacing: 8) {
                Group {
                    if isWorking {
                        ProgressView().controlSize(.mini)
                    } else {
                        Image(systemName: symbol)
                            .font(.system(size: 10, weight: .medium))
                    }
                }
                .foregroundStyle(role == .destructive ? Theme.Palette.danger.opacity(0.8) : Theme.Palette.textSecondary)
                .frame(width: 14)

                VStack(alignment: .leading, spacing: 1) {
                    Text(title)
                        .font(Theme.Font.secondary)
                        .foregroundStyle(disabled ? Theme.Palette.textDisabled : Theme.Palette.textPrimary)
                    Text(detail)
                        .font(Theme.Font.tertiary)
                        .foregroundStyle(Theme.Palette.textTertiary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
            .background {
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .fill(isHovering && !disabled ? Theme.Palette.controlFillHover : .clear)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(disabled)
        .onHover { isHovering = $0 }
    }
}
