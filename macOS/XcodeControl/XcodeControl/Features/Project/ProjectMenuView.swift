//
//  ProjectMenuView.swift
//  XcodeControl
//

import AppKit
import SwiftUI

/// 项目下拉面板：项目列表 + 当前项目的 scheme / configuration。
///
/// 这里是「次要信息主动收起」原则的落点——主界面只留项目名，
/// 真正需要切换的时候才展开这一层。
struct ProjectMenuView: View {

    @Environment(AppState.self) private var state

    private enum ScrollID {
        static let scheme = "project-menu-scheme"
    }

    var body: some View {
        let projects = state.projects
        let showSchemes = projects.availableSchemes.count > 1

        VStack(spacing: 0) {
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 1) {
                        if !projects.items.isEmpty {
                            SectionHeader(title: L10n.t("项目"))
                            ForEach(projects.items) { project in
                                ProjectRow(
                                    project: project,
                                    icon: projects.icons[project.id],
                                    gitMetadata: projects.gitMetadata(for: project),
                                    isSelected: project.id == projects.current?.id,
                                    isMissing: projects.missingProjectIDs.contains(project.id),
                                    onSelect: { state.selectProject(project) },
                                    onRemove: { projects.remove(project) }
                                )
                            }
                        }

                        if showSchemes {
                            SectionHeader(title: "Scheme")
                                .id(ScrollID.scheme)
                            ForEach(projects.availableSchemes, id: \.self) { scheme in
                                CheckRow(
                                    title: scheme,
                                    symbol: "square.stack.3d.up",
                                    isSelected: scheme == projects.selectedScheme
                                ) {
                                    state.selectScheme(scheme)
                                }
                            }
                        }

                        if projects.availableConfigurations.count > 1 {
                            SectionHeader(title: "Configuration")
                            ForEach(projects.availableConfigurations, id: \.self) { configuration in
                                CheckRow(
                                    title: configuration,
                                    symbol: "slider.horizontal.3",
                                    isSelected: configuration == projects.selectedConfiguration
                                ) {
                                    state.projects.selectedConfiguration = configuration
                                    state.openPanel = .none
                                }
                            }
                        }

                        if let error = projects.loadError {
                            Text(error)
                                .font(Theme.Font.tertiary)
                                .foregroundStyle(Theme.Palette.danger.opacity(0.9))
                                .lineLimit(2)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 6)
                        }
                    }
                    .padding(.horizontal, 4)
                    .padding(.vertical, 4)
                }
                .frame(maxHeight: Theme.Metrics.dropdownMaxHeight)
                .onAppear {
                    scrollToFocus(proxy, showSchemes: showSchemes)
                }
                .onChange(of: state.projectPanelFocus) { _, _ in
                    scrollToFocus(proxy, showSchemes: showSchemes)
                }
            }

            Divider().overlay(Theme.Palette.separator)

            FooterButton(symbol: "folder", title: L10n.t("添加项目…")) {
                state.presentOpenPanel()
            }

            if state.projects.hasProject {
                FooterButton(symbol: "shippingbox", title: L10n.t("Swift Package 工具…")) {
                    withAnimation(Motion.panel) { state.openSwiftPackageTools() }
                }
            }

            // 重命名、排序、批量删除、扫描文件夹都在设置页的「项目」分页里。
            // 这里只留一个入口，不把那些操作搬进浮窗——浮窗的职责是切项目，不是管项目。
            FooterButton(symbol: "folder.badge.gearshape", title: L10n.t("管理项目…")) {
                state.openSettings(tab: .project)
            }

            if state.projects.hasProject {
                Divider().overlay(Theme.Palette.separator)
                FooterButton(symbol: "arrow.up.forward.app", title: L10n.t("在 Xcode 中打开")) {
                    state.openInXcode()
                }
            }
        }
        .background { DropdownBackground() }
    }

    private func scrollToFocus(_ proxy: ScrollViewProxy, showSchemes: Bool) {
        guard state.projectPanelFocus == .scheme, showSchemes else { return }
        // 等布局落地后再滚；LazyVStack 里目标行可能尚未物化
        DispatchQueue.main.async {
            withAnimation(Motion.state) {
                proxy.scrollTo(ScrollID.scheme, anchor: .top)
            }
        }
    }
}

/// 项目列表的一行：项目名 + 灰色父目录路径。
private struct ProjectRow: View {

    let project: XcodeProject
    let icon: NSImage?
    let gitMetadata: GitProjectMetadata?
    let isSelected: Bool
    let isMissing: Bool
    let onSelect: () -> Void
    let onRemove: () -> Void

    @State private var isHovering = false

    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 8) {
                ProjectAppIcon(project: project, image: icon, size: 16)

                VStack(alignment: .leading, spacing: 1) {
                    HStack(spacing: 5) {
                        Text(project.name)
                            .font(Theme.Font.secondary)
                            .foregroundStyle(
                                isMissing ? Theme.Palette.textDisabled : Theme.Palette.textPrimary
                            )
                            .lineLimit(1)

                        if gitMetadata?.isLinkedWorktree == true {
                            Text(L10n.t("worktree"))
                                .font(.system(size: 8.5, weight: .medium))
                                .foregroundStyle(Theme.Palette.textTertiary)
                        }
                    }

                    if isMissing {
                        Text(L10n.t("路径已失效"))
                            .font(Theme.Font.tertiary)
                            .foregroundStyle(Theme.Palette.danger.opacity(0.7))
                    } else {
                        HStack(spacing: 3) {
                            if let gitMetadata {
                                Image(systemName: "arrow.triangle.branch")
                                    .font(.system(size: 7.5, weight: .medium))
                                Text(gitMetadata.reference)
                                Text("·")
                            }
                            Text(project.parentDirectoryDisplay)
                        }
                        .font(Theme.Font.tertiary)
                        .foregroundStyle(Theme.Palette.textTertiary)
                        .lineLimit(1)
                        .truncationMode(.middle)
                    }
                }

                Spacer(minLength: 4)

                if isHovering {
                    IconButton(symbol: "xmark", help: L10n.t("从列表移除"), action: onRemove)
                } else if isSelected {
                    Image(systemName: "checkmark")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(Theme.Palette.accent)
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 5)
            .background {
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .fill(isHovering ? Theme.Palette.controlFillHover : .clear)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .onHover { isHovering = $0 }
        .help(project.lastKnownPath)
    }
}

/// 单行可勾选项（scheme / configuration 共用）
struct CheckRow: View {
    let title: String
    var symbol: String?
    let isSelected: Bool
    let action: () -> Void

    @State private var isHovering = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if let symbol {
                    Image(systemName: symbol)
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(Theme.Palette.textTertiary)
                        .frame(width: 14)
                }
                Text(title)
                    .font(Theme.Font.secondary)
                    .foregroundStyle(Theme.Palette.textPrimary)
                    .lineLimit(1)
                Spacer(minLength: 4)
                if isSelected {
                    Image(systemName: "checkmark")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(Theme.Palette.accent)
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 5)
            .background {
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .fill(isHovering ? Theme.Palette.controlFillHover : .clear)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .onHover { isHovering = $0 }
    }
}
