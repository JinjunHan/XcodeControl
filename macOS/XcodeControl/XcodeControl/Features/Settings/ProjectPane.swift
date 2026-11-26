//
//  ProjectPane.swift
//  XcodeControl
//

import AppKit
import SwiftUI

/// 项目：托管列表的添加 / 删除 / 文件夹扫描。
///
/// 不再做「最近 N 条」裁剪——列表完全由用户管理。
/// 扫描时若同目录同时有 `.xcworkspace` 与 `.xcodeproj`，只收 workspace。
struct ProjectPane: View {

    @Environment(AppState.self) private var state
    @State private var scanSummary: String?
    @State private var isScanning = false
    @State private var isSyncingWorktrees = false
    @State private var confirmClear = false
    @State private var isDropTargeted = false

    var body: some View {
        let store = state.projects

        List {
            if store.items.isEmpty {
                Text(L10n.t("选择或拖入 Xcode 项目"))
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, 4)
            } else {
                ForEach(store.items) { project in
                    projectRow(project)
                }
                .onDelete(perform: deleteProjects)
                .onMove(perform: moveProjects)
            }
        }
        // 不用 alternatesRowBackgrounds：交替底色会铺满整个列表高度，
        // 只有一两个项目时剩余空间被画成一排「空行」，像是加载失败。
        .listStyle(.inset)
        .safeAreaInset(edge: .top, spacing: 0) {
            HStack(spacing: 8) {
                Text(L10n.t("项目列表"))
                    .font(.title2.bold())
                    .accessibilityAddTraits(.isHeader)
                Text(store.items.count, format: .number)
                    .font(.callout.monospacedDigit())
                    .foregroundStyle(.secondary)
                Spacer(minLength: 4)
                if isScanning || isSyncingWorktrees {
                    ProgressView().controlSize(.small)
                }
                Button(action: presentAddPanel) {
                    Label(L10n.t("添加项目…"), systemImage: "plus")
                }
                .buttonStyle(.borderedProminent)
                .disabled(isScanning || isSyncingWorktrees)
                Menu {
                    Button(L10n.t("扫描文件夹…"), action: presentScanPanel)
                    if canSyncWorktreeProjects {
                        Button(L10n.t("同步 Worktree 项目"), action: syncWorktreeProjects)
                    }
                    Divider()
                    Button(L10n.t("清空项目"), role: .destructive) { confirmClear = true }
                        .disabled(store.items.isEmpty)
                } label: {
                    Image(systemName: "ellipsis")
                        .font(.body.weight(.semibold))
                }
                .menuStyle(.button)
                .buttonStyle(ProjectActionsButtonStyle())
                .menuIndicator(.hidden)
                .fixedSize()
                .help(L10n.t("管理项目…"))
                .accessibilityLabel(L10n.t("管理项目…"))
                .disabled(isScanning || isSyncingWorktrees)
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 12)
            .background(Color(nsColor: .textBackgroundColor), ignoresSafeAreaEdges: [])
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            VStack(spacing: 0) {
                Divider()
                HStack(spacing: 12) {
                    Text(statusText)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .truncationMode(.middle)
                    Spacer(minLength: 8)

                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
            }
            // 不用 `.bar`：那层材质在浅色下是淡灰的，而设置窗口整窗要求纯白底。
            // 底栏与列表的分界交给上面那条 Divider，不靠底色区分。
            .background(Color(nsColor: .textBackgroundColor))
        }
        .overlay {
            if isDropTargeted {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .strokeBorder(Color.accentColor.opacity(0.8), lineWidth: 2)
                    .padding(6)
                    .allowsHitTesting(false)
            }
        }
        .projectFileDrop(isTargeted: $isDropTargeted) { added in
            scanSummary = added > 0
                ? L10n.t("已通过拖放加入 %d 个项目。", added)
                : L10n.t("没有新项目加入（可能已在列表中或无法识别）。")
        }
        .animation(.easeInOut(duration: 0.15), value: isDropTargeted)
        .confirmationDialog(L10n.t("清空全部项目？"), isPresented: $confirmClear) {
            Button(L10n.t("清空"), role: .destructive) {
                state.projects.clearAll()
                scanSummary = nil
            }
            Button(L10n.t("取消"), role: .cancel) {}
        } message: {
            Text(L10n.t("列表中的 %d 个项目都会移除，当前项目也会取消。", store.items.count))
        }
    }

    /// 底栏左侧的一行状态。扫描/添加刚结束时报结果，否则给一句与当前列表状态匹配的提示。
    private var statusText: String {
        if let scanSummary { return scanSummary }
        return state.projects.items.isEmpty
            ? L10n.t("支持拖入 .xcodeproj / .xcworkspace，或包含它们的文件夹。")
            : L10n.t("拖拽行可调整顺序；也可拖入工程文件或文件夹添加。")
    }

    private var canSyncWorktreeProjects: Bool {
        guard let current = state.projects.current else { return false }
        return state.projects.currentGitReference != nil
            || state.projects.gitMetadata(for: current) != nil
    }

    @ViewBuilder
    private func projectRow(_ project: XcodeProject) -> some View {
        let isCurrent = project.id == state.projects.current?.id
        let isMissing = state.projects.missingProjectIDs.contains(project.id)
        let parent = (project.lastKnownPath as NSString).deletingLastPathComponent
        let gitMetadata = state.projects.gitMetadata(for: project)

        HStack(alignment: .center, spacing: 10) {
            ProjectAppIcon(
                project: project,
                image: state.projects.icons[project.id],
                size: 32,
                fallbackForeground: .secondary
            )

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(project.name)
                        .font(.body.weight(.medium))
                        .lineLimit(1)
                        .truncationMode(.middle)
                        .help(project.name)
                        .foregroundStyle(isMissing ? .secondary : .primary)
                    Text(project.kind == .workspace ? "workspace" : "project")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                        .padding(.horizontal, 5)
                        .padding(.vertical, 1)
                        .background(.quaternary.opacity(0.8), in: Capsule())
                    if isCurrent {
                        Text(L10n.t("当前"))
                            .font(.caption2)
                            .foregroundStyle(.tint)
                    }
                    if isMissing {
                        Text(L10n.t("路径失效"))
                            .font(.caption2)
                            .foregroundStyle(.orange)
                    }
                    if gitMetadata?.isLinkedWorktree == true {
                        Text(L10n.t("worktree"))
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                    }
                }

                HStack(spacing: 4) {
                    if let gitMetadata {
                        Image(systemName: "arrow.triangle.branch")
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                        Text(gitMetadata.reference)
                            .lineLimit(1)
                            .truncationMode(.middle)
                            .layoutPriority(1)
                        Text("·")
                            .foregroundStyle(.tertiary)
                    }
                    Text(parent)
                        .lineLimit(1)
                        .truncationMode(.middle)
                        .textSelection(.enabled)
                        .help(project.lastKnownPath)
                }
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: 8)

            Button {
                state.selectProject(project)
            } label: {
                Image(systemName: isCurrent ? "checkmark.circle.fill" : "checkmark.circle")
            }
            .buttonStyle(.borderless)
            .help(L10n.t("设为当前项目"))
            .disabled(isCurrent || isMissing)

            Button(role: .destructive) {
                state.projects.remove(project)
            } label: {
                Image(systemName: "trash")
            }
            .buttonStyle(.borderless)
            .help(L10n.t("从列表中删除"))
        }
        .padding(.vertical, 5)
        .listRowBackground(isCurrent ? Color.accentColor.opacity(0.09) : Color.clear)
    }

    private func deleteProjects(at offsets: IndexSet) {
        let targets = offsets.map { state.projects.items[$0] }
        for project in targets {
            state.projects.remove(project)
        }
    }

    private func moveProjects(from source: IndexSet, to destination: Int) {
        state.projects.move(from: source, to: destination)
    }

    private func presentAddPanel() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = true
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = true
        panel.treatsFilePackagesAsDirectories = false
        panel.prompt = L10n.t("添加")
        panel.message = L10n.t("选择 .xcodeproj / .xcworkspace，或包含它们的目录")
        panel.allowedContentTypes = []
        NSApp.activate(ignoringOtherApps: true)
        guard panel.runModal() == .OK else { return }
        Task {
            var added = 0
            for url in panel.urls {
                if await state.projects.add(url: url, makeCurrent: state.projects.current == nil) {
                    added += 1
                }
            }
            scanSummary = added > 0
                ? L10n.t("已添加 %d 个项目。", added)
                : L10n.t("没有新项目加入（可能已在列表中）。")
        }
    }

    private func presentScanPanel() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.prompt = L10n.t("扫描")
        panel.message = L10n.t("选择要扫描的根目录。同目录下若同时有 workspace 与 xcodeproj，只导入 workspace。")
        NSApp.activate(ignoringOtherApps: true)
        guard panel.runModal() == .OK, let root = panel.url else { return }

        isScanning = true
        scanSummary = nil
        Task {
            let result = await state.projects.addDiscovered(under: root)
            isScanning = false
            if result.added == 0 && result.skipped == 0 {
                scanSummary = L10n.t("未在该目录下发现可导入的工程。")
            } else {
                scanSummary = L10n.t("扫描完成：新增 %d 个，已存在 %d 个。", result.added, result.skipped)
            }
        }
    }

    private func syncWorktreeProjects() {
        guard !isScanning, !isSyncingWorktrees else { return }

        isSyncingWorktrees = true
        scanSummary = nil
        Task {
            defer { isSyncingWorktrees = false }

            do {
                guard let result = try await state.projects
                    .addProjectsFromCurrentRepositoryWorktrees()
                else {
                    scanSummary = L10n.t("当前项目不在 Git 仓库中")
                    return
                }
                guard !Task.isCancelled else { return }
                scanSummary = L10n.t(
                    "Worktree 同步完成：新增项目 %d 个，已存在 %d 个，未找到工程的 worktree %d 个。",
                    result.added,
                    result.existing,
                    result.withoutProject
                )
            } catch is CancellationError {
                return
            } catch {
                scanSummary = error.localizedDescription
            }
        }
    }
}

private struct ProjectActionsButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .frame(width: 32, height: 24)
            .background(.quaternary.opacity(configuration.isPressed ? 1 : 0.7),
                        in: RoundedRectangle(cornerRadius: 6))
            .contentShape(Rectangle())
    }
}
