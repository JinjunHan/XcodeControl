//
//  MenuBarMenu.swift
//  XcodeControl
//

import SwiftUI

/// 系统菜单栏状态项的下拉菜单——浮窗收起后的备用入口。
///
/// 用系统原生 `.menu` 样式，不复刻浮窗自定义 UI；图标保持模板色，
/// 运行态不在菜单栏做彩色动画，状态仍以浮窗为准。
struct MenuBarMenu: View {

    @Environment(AppState.self) private var state

    var body: some View {
        Button(state.isFloatingPanelVisible ? L10n.t("隐藏悬浮窗") : L10n.t("显示悬浮窗")) {
            state.toggleFloatingPanelVisibility()
        }

        Divider()

        ProjectSubmenu()

        Divider()

        Button(L10n.t("运行")) {
            state.showFloatingPanel()
            state.run.primaryAction()
        }

        Button(L10n.t("停止")) {
            state.run.stopAction()
        }
        .disabled(!state.run.phase.canStop)

        Divider()

        // 不用 `SettingsLink`：它不激活应用、也不重新前置已经开着的窗口，
        // 于是被别的应用压住时点了没反应。三步齐全的入口在 `AppState.openSettings`。
        Button(L10n.t("设置…")) {
            state.openSettings()
        }

        Button(L10n.t("检查更新…")) {
            state.checkForUpdates()
        }

        Button(L10n.t("退出 XcodeControl")) {
            state.quit()
        }
    }
}

/// 「项目」子菜单：项目列表 + 当前项目的 scheme。
///
/// 与浮窗里的 `ProjectMenuView` 是同一份数据的两种呈现。差异有两处，都是刻意的：
///
/// 1. **scheme 只有一个时这里照样显示。** 浮窗受「能不占地方就不占」约束
///    （`count > 1` 才出现），但菜单栏是折叠的备用入口、不占屏幕空间，
///    结构稳定比省一行更值钱——用户不必猜「Scheme 段怎么没了」。
/// 2. **不展开成三级（每个项目再挂自己的 scheme）。** 非当前项目的 scheme 需要
///    额外跑一次 `xcodebuild -list`，要数秒才回来，而 NSMenu 是同步填充的。
struct ProjectSubmenu: View {

    @Environment(AppState.self) private var state

    var body: some View {
        Menu {
            if !state.projects.items.isEmpty {
                Section(L10n.t("项目")) {
                    ForEach(state.projects.items) { project in
                        projectItem(project)
                    }
                }
            }

            Section("Scheme") {
                if state.projects.availableSchemes.isEmpty {
                    Button(schemePlaceholder) {}
                        .disabled(true)
                } else {
                    ForEach(state.projects.availableSchemes, id: \.self) { scheme in
                        schemeItem(scheme)
                    }
                }
            }

            Divider()

            Button(L10n.t("添加项目…")) {
                state.presentOpenPanel()
            }
        } label: {
            Text(L10n.t("项目"))
        }
    }

    // MARK: - 行

    /// 用 `Toggle` 而不是带 checkmark 图标的 `Button`：原生菜单会为可勾选项统一预留
    /// 勾号栏位，未选中的行也保持同一缩进；用 `Label(systemImage:)` 手搓则只有选中行
    /// 有图标，其余行会左移一截。
    private func projectItem(_ project: XcodeProject) -> some View {
        let isSelected = project.id == state.projects.current?.id
        let isMissing = state.projects.missingProjectIDs.contains(project.id)

        return Toggle(isOn: .init(
            get: { isSelected },
            // 再点当前项目不该触发一次重新解析，直接吞掉
            set: { if $0, !isSelected { state.selectProject(project) } }
        )) {
            // 菜单里放不下浮窗那样的第二行父目录，失效状态只能并进标题
            let title = projectMenuTitle(project)
            Text(isMissing ? L10n.t("%@（路径已失效）", title) : title)
        }
    }

    private func projectMenuTitle(_ project: XcodeProject) -> String {
        guard let metadata = state.projects.gitMetadata(for: project) else {
            return project.name
        }
        let worktree = metadata.isLinkedWorktree ? " · \(L10n.t("worktree"))" : ""
        return "\(project.name) [\(metadata.reference)\(worktree)]"
    }

    private func schemeItem(_ scheme: String) -> some View {
        let isSelected = scheme == state.projects.selectedScheme

        return Toggle(isOn: .init(
            get: { isSelected },
            set: { if $0, !isSelected { state.selectScheme(scheme) } }
        )) {
            Text(scheme)
        }
    }

    // MARK: - 文案

    /// scheme 段为空的三种成因要给出各自的下一步，而不是一律「无」
    private var schemePlaceholder: String {
        if state.projects.isLoading { return L10n.t("正在解析…") }
        if !state.projects.hasProject { return L10n.t("尚未选择项目") }
        return state.projects.loadError == nil ? L10n.t("未解析到 scheme") : L10n.t("解析失败，见悬浮窗")
    }
}
