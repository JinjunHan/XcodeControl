//
//  FloatingRootView.swift
//  XcodeControl
//

import AppKit
import SwiftUI

/// 悬浮窗的根视图。
///
/// 布局是刻意扁平的一列：上下文条 / 操作行 / 按需展开的次级区域。
/// 核心操作行永远只有设备、运行、停止；状态行承载运行状态与当前 Git branch。
struct FloatingRootView: View {

    @Environment(AppState.self) private var state

    /// 内容理想尺寸变化时回调；由 AppDelegate 异步改窗口，避开 SwiftUI 自调尺寸回路。
    var onContentSizeChange: (CGSize) -> Void = { _ in }

    @State private var isDropTargeted = false

    var body: some View {
        VStack(spacing: 0) {
            switch state.environment {
            case .checking:
                EnvironmentCheckingView()
            case .blocked(let message, let detail, let command):
                EnvironmentBlockedView(message: message, detail: detail, command: command)
            case .ready:
                if state.showsOnboarding {
                    onboarding
                } else {
                    main
                }
            }
        }
        .padding(.horizontal, 6)
        .padding(.top, 5)
        .padding(.bottom, 6)
        .frame(width: Theme.Metrics.panelWidth)
        // 高度跟内容走，不被宿主 view 的当前 frame 撑开——否则量到的永远是窗口旧高度，
        // 下拉面板无法把窗口长高。
        .fixedSize(horizontal: true, vertical: true)
        .background {
            GlassBackground(
                cornerRadius: Theme.Metrics.cornerRadius,
                isGlowing: state.run.phase.isRunning
            )
        }
        .overlay {
            if isDropTargeted {
                RoundedRectangle(cornerRadius: Theme.Metrics.cornerRadius, style: .continuous)
                    .strokeBorder(Theme.Palette.accent.opacity(0.85), lineWidth: 1.5)
                    .background {
                        RoundedRectangle(cornerRadius: Theme.Metrics.cornerRadius, style: .continuous)
                            .fill(Theme.Palette.accent.opacity(0.08))
                    }
                    .allowsHitTesting(false)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: Theme.Metrics.cornerRadius, style: .continuous))
        .projectFileDrop(isTargeted: $isDropTargeted)
        .animation(Motion.state, value: isDropTargeted)
        .onGeometryChange(for: CGSize.self, of: { $0.size }, action: onContentSizeChange)
        .opacity(state.chromeOpacity)
        .animation(Motion.state, value: state.chromeOpacity)
        .onHover { state.setHovering($0) }
    }

    // MARK: - 引导

    private var onboarding: some View {
        VStack(spacing: 0) {
            HStack(spacing: 4) {
                Text("XcodeControl")
                    .font(Theme.Font.secondary)
                    .foregroundStyle(Theme.Palette.textSecondary)
                Spacer(minLength: 0)
                if !state.projects.items.isEmpty {
                    IconButton(symbol: "folder", help: L10n.t("项目列表")) {
                        withAnimation(Motion.panel) { state.togglePanel(.project) }
                    }
                }
                // 与菜单栏同走 `openSettings`：`SettingsLink` 既不激活应用，
                // 也不会把已经开着的设置窗口重新抬到最前。
                IconButton(symbol: "gearshape", help: L10n.t("设置")) {
                    state.openSettings()
                }
            }
            .frame(height: Theme.Metrics.contextBarHeight)
            .padding(.horizontal, 6)

            if state.openPanel == .project {
                ProjectMenuView()
                    .padding(.top, 4)
                    .transition(.dropdown)
            } else {
                ProjectOnboardingView(isTargeted: isDropTargeted)
            }
        }
    }

    // MARK: - 主界面

    private var main: some View {
        VStack(spacing: 0) {
            ContextBar(
                projectName: state.projects.current?.name ?? L10n.t("未选择项目"),
                projectIcon: state.projects.current.flatMap { state.projects.icons[$0.id] },
                schemeName: state.projects.selectedScheme,
                configuration: state.projects.selectedConfiguration,
                isExpanded: state.openPanel == .project || state.openPanel == .swiftPackage,
                isLoading: state.projects.isLoading,
                onProjectTap: {
                    withAnimation(Motion.panel) { state.toggleProjectPanel(focus: .projects) }
                },
                onSchemeTap: {
                    withAnimation(Motion.panel) { state.toggleProjectPanel(focus: .scheme) }
                },
                onSettingsTap: { state.openSettings() }
            )

            HStack(spacing: 8) {
                DeviceTrigger(
                    destination: state.devices.selected,
                    isExpanded: state.openPanel == .device,
                    isRefreshing: state.devices.isRefreshing && state.devices.destinations.isEmpty
                ) {
                    withAnimation(Motion.panel) { state.togglePanel(.device) }
                }

                RunButton(phase: state.run.phase) {
                    state.run.primaryAction()
                } cleanAction: {
                    state.run.primaryAction(clean: true)
                }

                StopButton(phase: state.run.phase) {
                    state.run.stopAction()
                }
            }
            .frame(height: Theme.Metrics.controlRowHeight)

            // 下拉面板走正常布局流，窗口随内容向下生长
            if state.openPanel == .project || state.openPanel == .swiftPackage || state.openPanel == .device {
                Group {
                    switch state.openPanel {
                    case .project:
                        ProjectMenuView()
                    case .swiftPackage:
                        SwiftPackageToolsView()
                    default:
                        DevicePickerView()
                    }
                }
                .padding(.top, 2)
                .transition(.dropdown)
            }

            if case .failed(let failure) = state.run.phase {
                FailureBar(
                    failure: failure,
                    isLogExpanded: state.isLogPaneExpanded
                ) {
                    withAnimation(Motion.disclosure) { state.isLogPaneExpanded.toggle() }
                } onDismiss: {
                    withAnimation(Motion.state) { state.run.dismissFailure() }
                }
            }

            if showsStatusStrip {
                StatusStrip(
                    text: footerStatus,
                    gitReference: showsGitBranch ? state.projects.currentGitReference : nil,
                    isGitExpanded: state.openPanel == .gitBranch,
                    isGitBusy: state.projects.isGitBranchBusy
                ) {
                    withAnimation(Motion.panel) { state.toggleGitBranchPanel() }
                }
            }

            if showsGitBranch, state.openPanel == .gitBranch {
                GitBranchPickerView()
                    .padding(.top, 2)
                    .transition(.dropdown)
            }

            if state.isLogPaneExpanded {
                LogPaneView()
            } else {
                if state.run.phase.isWorking || !state.logs.entries.isEmpty {
                    LogToggle {
                        withAnimation(Motion.disclosure) { state.isLogPaneExpanded = true }
                    }
                }
            }
        }
        .animation(Motion.state, value: state.run.phase)
        .animation(Motion.panel, value: state.openPanel)
        .animation(Motion.disclosure, value: state.isLogPaneExpanded)
    }

    private var footerStatus: String? {
        // FailureBar 已经承载完整错误摘要；状态行仅保留右侧 Git branch，避免重复一遍。
        guard !state.run.phase.isFailed else { return nil }
        if let status = state.run.statusLine {
            return status
        }
        if let notice = state.unverifiedXcodeNotice, state.isHovering {
            return notice
        }
        return nil
    }

    /// 设置里关掉后，状态行不再显示分支，分支面板也一并不渲染——
    /// `openPanel` 可能还残留 `.gitBranch`（关开关那一刻已由 `setShowsGitBranch` 收起，
    /// 这里再兜一次，保证入口不可见时永远不会有一个收不掉的面板挂在下面）。
    private var showsGitBranch: Bool {
        state.prefs.showGitBranch
    }

    private var showsStatusStrip: Bool {
        guard state.openPanel != .project,
              state.openPanel != .swiftPackage,
              state.openPanel != .device
        else { return false }
        return footerStatus != nil
            || (showsGitBranch && state.projects.currentGitReference != nil)
    }
}

/// 收起状态下的日志入口，独立于运行状态与 Git branch。
private struct LogToggle: View {
    let action: () -> Void
    @State private var isHovering = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: 3) {
                Spacer(minLength: 0)
                Image(systemName: "chevron.up")
                    .font(.system(size: 7, weight: .semibold))
                Text(L10n.t("日志"))
                    .font(Theme.Font.tertiary)
                Spacer(minLength: 0)
            }
            .foregroundStyle(Theme.Palette.textTertiary.opacity(isHovering ? 1 : 0.6))
            .frame(height: 14)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .onHover { isHovering = $0 }
    }
}

// MARK: - 环境状态

private struct EnvironmentCheckingView: View {
    var body: some View {
        HStack(spacing: 8) {
            ProgressView().controlSize(.small)
            Text(L10n.t("正在检查 Xcode 环境…"))
                .font(Theme.Font.secondary)
                .foregroundStyle(Theme.Palette.textSecondary)
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 6)
        .frame(height: Theme.Metrics.controlRowHeight)
    }
}

/// 环境级错误占据整个窗口，并优先提供应用内可完成的恢复操作。
private struct EnvironmentBlockedView: View {
    @Environment(AppState.self) private var state

    let message: String
    let detail: String
    let command: String?

    @State private var didCopy = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 12))
                    .foregroundStyle(Theme.Palette.danger)
                Text(message)
                    .font(Theme.Font.primary)
                    .foregroundStyle(Theme.Palette.textPrimary)
                    .lineLimit(2)
                Spacer(minLength: 0)
            }

            if !detail.isEmpty {
                Text(detail)
                    .font(Theme.Font.tertiary)
                    .foregroundStyle(Theme.Palette.textTertiary)
                    .lineLimit(3)
                    .textSelection(.enabled)
            }

            if let command {
                HStack(spacing: 6) {
                    Text(command)
                        .font(Theme.Font.mono)
                        .foregroundStyle(Theme.Palette.textSecondary)
                        .lineLimit(1)
                        .truncationMode(.middle)
                        .textSelection(.enabled)
                    Spacer(minLength: 0)
                    IconButton(symbol: didCopy ? "checkmark" : "doc.on.doc", help: L10n.t("拷贝命令")) {
                        NSPasteboard.general.clearContents()
                        NSPasteboard.general.setString(command, forType: .string)
                        didCopy = true
                    }
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 5)
                .background {
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .fill(Theme.Palette.controlFill)
                }
            }

            HStack(spacing: 6) {
                if !state.recoveryXcodes.isEmpty {
                    Menu {
                        ForEach(state.recoveryXcodes) { xcode in
                            Button(xcode.displayName) {
                                Task { await state.useXcode(xcode) }
                            }
                        }
                    } label: {
                        Label(L10n.t("选择 Xcode.app"), systemImage: "hammer")
                    }
                    .menuStyle(.button)
                    .controlSize(.small)
                }

                Button {
                    state.openSettings(tab: .locations)
                } label: {
                    Label(L10n.t("前往设置"), systemImage: "gearshape")
                }
                .controlSize(.small)

                if state.needsXcodeInstallation {
                    Button(L10n.t("安装 Xcode")) {
                        state.openXcodeDownloadPage()
                    }
                    .controlSize(.small)
                }

                Spacer(minLength: 0)

                Button {
                    Task { await state.redetectEnvironment() }
                } label: {
                    Image(systemName: "arrow.clockwise")
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                .help(L10n.t("正在检查 Xcode 环境…"))
            }
        }
        .padding(.horizontal, 4)
        .padding(.vertical, 6)
    }
}
