//
//  GitBranchPickerView.swift
//  XcodeControl
//

import SwiftUI

/// 本地 Git 分支列表。斜杠分支按目录展开；占用中的 worktree 分支改为切换对应项目。
struct GitBranchPickerView: View {

    @Environment(AppState.self) private var state
    @State private var expandedFolders: Set<String> = []

    var body: some View {
        let projects = state.projects
        let rows = GitBranchTree.visibleRows(
            for: projects.gitBranches,
            expandedFolders: expandedFolders
        )

        VStack(spacing: 0) {
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 1) {
                        SectionHeader(title: L10n.t("本地分支"))

                        if projects.isLoadingGitBranches && projects.gitBranches.isEmpty {
                            HStack(spacing: 7) {
                                ProgressView()
                                    .controlSize(.mini)
                                    .frame(width: 12, height: 12)
                                Text(L10n.t("正在读取分支…"))
                                    .font(Theme.Font.secondary)
                                    .foregroundStyle(Theme.Palette.textTertiary)
                                Spacer(minLength: 0)
                            }
                            .padding(.horizontal, 10)
                            .padding(.vertical, 12)
                        } else if projects.gitBranches.isEmpty && projects.gitBranchError == nil {
                            EmptyHint(text: L10n.t("没有本地分支"))
                        } else {
                            ForEach(rows) { row in
                                switch row.kind {
                                case .folder(let path, let name):
                                    GitBranchFolderRow(
                                        name: name,
                                        depth: row.depth,
                                        isExpanded: expandedFolders.contains(path)
                                    ) {
                                        withAnimation(Motion.disclosure) {
                                            if expandedFolders.contains(path) {
                                                expandedFolders.remove(path)
                                            } else {
                                                expandedFolders.insert(path)
                                            }
                                        }
                                    }

                                case .branch(let branch, let name, let expandableFolder):
                                    branchRow(
                                        branch: branch,
                                        name: name,
                                        depth: row.depth,
                                        expandableFolder: expandableFolder
                                    )
                                }
                            }
                        }

                        if let error = projects.gitBranchError {
                            Text(error)
                                .font(Theme.Font.tertiary)
                                .foregroundStyle(Theme.Palette.danger.opacity(0.9))
                                .lineLimit(3)
                                .fixedSize(horizontal: false, vertical: true)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 6)
                        }
                    }
                    .padding(.horizontal, 4)
                    .padding(.vertical, 4)
                }
                .frame(maxHeight: Theme.Metrics.dropdownMaxHeight)
                .onAppear {
                    expandCurrentBranch()
                    scrollToCurrent(using: proxy)
                }
                .onChange(of: projects.gitBranches) { _, _ in
                    expandCurrentBranch()
                    scrollToCurrent(using: proxy)
                }
                .onChange(of: projects.currentGitReference) { _, _ in
                    expandCurrentBranch()
                    scrollToCurrent(using: proxy)
                }
            }

            Divider().overlay(Theme.Palette.separator)

            if projects.gitBranchErrorDetail?.isEmpty == false {
                FooterButton(symbol: "text.alignleft", title: L10n.t("查看完整日志")) {
                    withAnimation(Motion.disclosure) {
                        state.isLogPaneExpanded = true
                    }
                }
            }

            FooterButton(symbol: "arrow.clockwise", title: L10n.t("刷新分支列表")) {
                state.refreshGitBranches()
            }
            .disabled(projects.isGitBranchBusy)
        }
        .background { DropdownBackground() }
    }

    @ViewBuilder
    private func branchRow(
        branch: String,
        name: String,
        depth: Int,
        expandableFolder: String?
    ) -> some View {
        let projects = state.projects
        let worktree = projects.displayedWorktree(for: branch)
        let managedProject = worktree.flatMap { projects.managedProject(in: $0) }
        let isExpanded = expandableFolder.map { expandedFolders.contains($0) } ?? false
        let isBusy = branch == projects.switchingGitBranch
            || branch == projects.activatingGitWorktreeBranch

        GitBranchRow(
            branch: branch,
            displayName: name,
            depth: depth,
            expandableFolder: expandableFolder,
            isExpanded: isExpanded,
            worktree: worktree,
            managedProjectName: managedProject?.name,
            isSelected: branch == projects.currentGitReference,
            isBusy: isBusy,
            isDisabled: state.run.phase.isWorking || projects.isGitBranchBusy,
            onToggleExpansion: {
                guard let expandableFolder else { return }
                withAnimation(Motion.disclosure) {
                    if expandedFolders.contains(expandableFolder) {
                        expandedFolders.remove(expandableFolder)
                    } else {
                        expandedFolders.insert(expandableFolder)
                    }
                }
            },
            action: {
                state.selectGitBranch(branch)
            }
        )
        .id(GitBranchTree.branchRowID(branch))
    }

    private func expandCurrentBranch() {
        guard let current = state.projects.currentGitReference else { return }
        expandedFolders.formUnion(GitBranchTree.ancestorFolders(of: current))
    }

    private func scrollToCurrent(using proxy: ScrollViewProxy) {
        guard let current = state.projects.currentGitReference,
              state.projects.gitBranches.contains(current)
        else { return }

        DispatchQueue.main.async {
            proxy.scrollTo(GitBranchTree.branchRowID(current), anchor: .center)
        }
    }
}

private struct GitBranchFolderRow: View {

    let name: String
    let depth: Int
    let isExpanded: Bool
    let action: () -> Void

    @State private var isHovering = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Color.clear
                    .frame(width: CGFloat(depth) * 12)

                Image(systemName: "chevron.right")
                    .font(.system(size: 7, weight: .semibold))
                    .rotationEffect(.degrees(isExpanded ? 90 : 0))
                    .frame(width: 10)

                Image(systemName: isExpanded ? "folder.fill" : "folder")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(Theme.Palette.textTertiary)
                    .frame(width: 14)

                Text(name)
                    .font(Theme.Font.secondary)
                    .foregroundStyle(Theme.Palette.textSecondary)
                    .lineLimit(1)
                    .truncationMode(.middle)

                Spacer(minLength: 4)
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

private struct GitBranchRow: View {

    let branch: String
    let displayName: String
    let depth: Int
    let expandableFolder: String?
    let isExpanded: Bool
    let worktree: GitWorktreeInfo?
    let managedProjectName: String?
    let isSelected: Bool
    let isBusy: Bool
    let isDisabled: Bool
    let onToggleExpansion: () -> Void
    let action: () -> Void

    @State private var isHovering = false

    var body: some View {
        HStack(spacing: 0) {
            Color.clear
                .frame(width: CGFloat(depth) * 12)

            if expandableFolder != nil {
                Button(action: onToggleExpansion) {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 7, weight: .semibold))
                        .rotationEffect(.degrees(isExpanded ? 90 : 0))
                        .frame(width: 16)
                }
                .buttonStyle(.plain)
                .help(expandableFolder ?? branch)
            } else {
                Color.clear.frame(width: 16)
            }

            Button(action: action) {
                HStack(spacing: 8) {
                    Image(systemName: "arrow.triangle.branch")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(Theme.Palette.textTertiary)
                        .frame(width: 14)

                    VStack(alignment: .leading, spacing: 1) {
                        Text(displayName)
                            .font(Theme.Font.secondary)
                            .foregroundStyle(
                                isDisabled && !isBusy
                                    ? Theme.Palette.textDisabled
                                    : Theme.Palette.textPrimary
                            )
                            .lineLimit(1)
                            .truncationMode(.middle)

                        if let worktree {
                            Text(worktreeSubtitle(worktree))
                                .font(.system(size: 9))
                                .foregroundStyle(Theme.Palette.textTertiary)
                                .lineLimit(1)
                                .truncationMode(.middle)
                        }
                    }

                    Spacer(minLength: 6)

                    if isBusy {
                        ProgressView()
                            .controlSize(.mini)
                            .frame(width: 12, height: 12)
                    } else if isSelected {
                        Image(systemName: "checkmark")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundStyle(Theme.Palette.accent)
                    } else if worktree != nil {
                        Image(
                            systemName: managedProjectName == nil
                                ? "plus.circle"
                                : "arrow.right.circle"
                        )
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(Theme.Palette.textTertiary)
                    }
                }
                .padding(.trailing, 8)
                .padding(.vertical, worktree == nil ? 5 : 4)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .disabled(isSelected || isDisabled)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.leading, 8)
        .background {
            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .fill(isHovering ? Theme.Palette.controlFillHover : .clear)
        }
        .contentShape(Rectangle())
        .onHover { isHovering = $0 }
        .help(helpText)
    }

    private func worktreeSubtitle(_ worktree: GitWorktreeInfo) -> String {
        let directory = URL(fileURLWithPath: worktree.path).lastPathComponent
        let worktreeLabel = L10n.t("worktree")
        if let managedProjectName {
            return "\(managedProjectName) · \(worktreeLabel) · \(directory)"
        }
        return "\(worktreeLabel) · \(directory)"
    }

    private var helpText: String {
        if isDisabled && !isBusy {
            return L10n.t("构建进行中，停止后可切换分支")
        }
        guard let worktree else { return branch }
        if managedProjectName != nil {
            return "\(L10n.t("设为当前项目")) · \(worktree.path)"
        }
        return "\(L10n.t("添加项目…")) · \(worktree.path)"
    }
}

private enum GitBranchTree {

    struct Row: Identifiable {
        enum Kind {
            case folder(path: String, name: String)
            case branch(fullName: String, name: String, expandableFolder: String?)
        }

        let kind: Kind
        let depth: Int

        var id: String {
            switch kind {
            case .folder(let path, _): "folder:\(path)"
            case .branch(let fullName, _, _): GitBranchTree.branchRowID(fullName)
            }
        }
    }

    private struct Node {
        let name: String
        let path: String
        var branch: String?
        var children: [Node] = []

        var isFolder: Bool { !children.isEmpty }
    }

    static func branchRowID(_ branch: String) -> String {
        "branch:\(branch)"
    }

    static func ancestorFolders(of branch: String) -> Set<String> {
        let components = branch.split(separator: "/").map(String.init)
        guard components.count > 1 else { return [] }

        var result: Set<String> = []
        var path = ""
        for component in components.dropLast() {
            path = path.isEmpty ? component : "\(path)/\(component)"
            result.insert(path)
        }
        return result
    }

    static func visibleRows(
        for branches: [String],
        expandedFolders: Set<String>
    ) -> [Row] {
        var result: [Row] = []
        appendVisibleRows(
            from: nodes(for: branches),
            depth: 0,
            expandedFolders: expandedFolders,
            to: &result
        )
        return result
    }

    private static func nodes(for branches: [String]) -> [Node] {
        var roots: [Node] = []
        for branch in branches {
            let components = branch.split(separator: "/").map(String.init)
            guard !components.isEmpty else { continue }
            insert(
                components[...],
                fullBranch: branch,
                parentPath: "",
                into: &roots
            )
        }
        sort(&roots)
        return roots
    }

    private static func insert(
        _ components: ArraySlice<String>,
        fullBranch: String,
        parentPath: String,
        into nodes: inout [Node]
    ) {
        guard let component = components.first else { return }
        let path = parentPath.isEmpty ? component : "\(parentPath)/\(component)"
        let isLeaf = components.count == 1

        if let index = nodes.firstIndex(where: { $0.name == component }) {
            if isLeaf {
                nodes[index].branch = fullBranch
            } else {
                insert(
                    components.dropFirst(),
                    fullBranch: fullBranch,
                    parentPath: path,
                    into: &nodes[index].children
                )
            }
            return
        }

        var node = Node(name: component, path: path, branch: isLeaf ? fullBranch : nil)
        if !isLeaf {
            insert(
                components.dropFirst(),
                fullBranch: fullBranch,
                parentPath: path,
                into: &node.children
            )
        }
        nodes.append(node)
    }

    private static func sort(_ nodes: inout [Node]) {
        for index in nodes.indices {
            sort(&nodes[index].children)
        }
        nodes.sort {
            if $0.isFolder != $1.isFolder {
                return $0.isFolder
            }
            return $0.name.localizedStandardCompare($1.name) == .orderedAscending
        }
    }

    private static func appendVisibleRows(
        from nodes: [Node],
        depth: Int,
        expandedFolders: Set<String>,
        to rows: inout [Row]
    ) {
        for node in nodes {
            if let branch = node.branch {
                rows.append(
                    Row(
                        kind: .branch(
                            fullName: branch,
                            name: node.name,
                            expandableFolder: node.children.isEmpty ? nil : node.path
                        ),
                        depth: depth
                    )
                )
                if !node.children.isEmpty, expandedFolders.contains(node.path) {
                    appendVisibleRows(
                        from: node.children,
                        depth: depth + 1,
                        expandedFolders: expandedFolders,
                        to: &rows
                    )
                }
            } else if node.isFolder {
                rows.append(Row(kind: .folder(path: node.path, name: node.name), depth: depth))
                if expandedFolders.contains(node.path) {
                    appendVisibleRows(
                        from: node.children,
                        depth: depth + 1,
                        expandedFolders: expandedFolders,
                        to: &rows
                    )
                }
            }
        }
    }
}
