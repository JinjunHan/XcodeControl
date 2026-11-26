//
//  GitService.swift
//  XcodeControl
//

import Foundation

struct GitProjectMetadata: Sendable, Equatable {
    let reference: String
    let worktreePath: String
    let repositoryCommonDirectory: String
    let isLinkedWorktree: Bool
}

struct GitWorktreeInfo: Sendable, Hashable, Identifiable {
    let path: String
    let head: String
    let branch: String?
    let isCurrent: Bool
    let isMain: Bool
    let isBare: Bool
    let isDetached: Bool
    let isLocked: Bool
    let lockedReason: String?
    let isPrunable: Bool
    let prunableReason: String?

    var id: String { path }

    var reference: String {
        branch ?? "HEAD \(String(head.prefix(7)))"
    }
}

struct GitWorktreeSnapshot: Sendable {
    let currentProject: GitProjectMetadata
    let worktrees: [GitWorktreeInfo]
}

struct GitBranchSnapshot: Sendable {
    let currentProject: GitProjectMetadata
    let localBranches: [String]
    let worktrees: [GitWorktreeInfo]
}

enum GitServiceError: LocalizedError {
    case notRepository
    case referenceUnavailable
    case branchUnavailable
    case localChangesWouldBeOverwritten
    case unresolvedConflicts
    case branchUsedByAnotherWorktree
    case switchFailed(String)

    var errorDescription: String? {
        switch self {
        case .notRepository:
            return L10n.t("当前项目不在 Git 仓库中")
        case .referenceUnavailable:
            return L10n.t("无法读取当前 Git 分支")
        case .branchUnavailable:
            return L10n.t("分支已不存在，请刷新列表后重试")
        case .localChangesWouldBeOverwritten:
            return L10n.t("当前修改会被覆盖，请先提交或暂存后再切换分支")
        case .unresolvedConflicts:
            return L10n.t("仓库有未解决的冲突，请先处理后再切换分支")
        case .branchUsedByAnotherWorktree:
            return L10n.t("该分支正在另一个 Git worktree 中使用")
        case .switchFailed(let detail):
            let summary = detail
                .split(whereSeparator: \.isNewline)
                .first
                .map(String.init)
            return L10n.t(
                "切换分支失败：%@",
                summary?.isEmpty == false ? summary! : L10n.t("未知错误")
            )
        }
    }
}

/// 读取和切换工程所在 Git 仓库的本地分支。
enum GitService {

    /// 当前分支；detached HEAD 时回退为 `HEAD <短 commit>`，非 Git 工程返回 nil。
    static func currentReference(forProjectAt projectURL: URL) async throws -> String? {
        let directory = repositorySearchDirectory(for: projectURL)
        guard try await GitAdapter.isWorkTree(at: directory) else {
            return nil
        }
        return try await currentReference(in: directory)
    }

    /// 项目所属仓库与 worktree。项目列表把它当可选元数据，读取失败时直接隐藏。
    static func projectMetadata(forProjectAt projectURL: URL) async throws -> GitProjectMetadata? {
        let directory = repositorySearchDirectory(for: projectURL)
        guard try await GitAdapter.isWorkTree(at: directory) else {
            return nil
        }
        return try await metadata(in: directory)
    }

    /// 当前引用和全部本地分支。非 Git 工程以专门错误返回，调用方可选择静默收起入口。
    static func branchSnapshot(forProjectAt projectURL: URL) async throws -> GitBranchSnapshot {
        let directory = repositorySearchDirectory(for: projectURL)
        guard try await GitAdapter.isWorkTree(at: directory) else {
            throw GitServiceError.notRepository
        }

        async let projectMetadata = metadata(in: directory)
        async let localBranchLoad = GitAdapter.localBranches(in: directory)
        let (metadata, localBranches) = try await (projectMetadata, localBranchLoad)

        let worktrees: [GitWorktreeInfo]
        do {
            worktrees = try await GitAdapter.worktrees(
                in: directory
            )
            .asWorktreeInfo(currentWorktreePath: metadata.worktreePath)
        } catch is CancellationError {
            throw CancellationError()
        } catch {
            // 分支切换本身不依赖 worktree 列表；旧版 Git 或单次读取失败时仍可使用。
            worktrees = []
        }

        return GitBranchSnapshot(
            currentProject: metadata,
            localBranches: localBranches,
            worktrees: worktrees
        )
    }

    /// 当前仓库的全部 worktree。项目管理页据此补齐同仓库的工程。
    static func worktreeSnapshot(forProjectAt projectURL: URL) async throws -> GitWorktreeSnapshot {
        let directory = repositorySearchDirectory(for: projectURL)
        guard try await GitAdapter.isWorkTree(at: directory) else {
            throw GitServiceError.notRepository
        }

        let metadata = try await metadata(in: directory)
        return GitWorktreeSnapshot(
            currentProject: metadata,
            worktrees: try await GitAdapter.worktrees(
                in: directory
            )
            .asWorktreeInfo(currentWorktreePath: metadata.worktreePath)
        )
    }

    /// 切换到已经存在的本地分支。不会猜测远端分支，也不会丢弃本地修改。
    @discardableResult
    static func switchBranch(_ branch: String, forProjectAt projectURL: URL) async throws -> String {
        let directory = repositorySearchDirectory(for: projectURL)
        guard try await GitAdapter.isWorkTree(at: directory) else {
            throw GitServiceError.notRepository
        }

        guard try await GitAdapter.branchExists(branch, in: directory) else {
            throw GitServiceError.branchUnavailable
        }

        let result = try await GitAdapter.switchBranch(branch, in: directory)
        guard result.isSuccess else {
            throw translatedSwitchError(from: result.combinedTrimmed)
        }

        return try await currentReference(in: directory)
    }

    private static func repositorySearchDirectory(for projectURL: URL) -> URL {
        projectURL.deletingLastPathComponent()
    }

    private static func metadata(in directory: URL) async throws -> GitProjectMetadata {
        async let currentReference = currentReference(in: directory)
        async let repositoryLocation = GitAdapter.repositoryLocation(in: directory)
        let (reference, location) = try await (currentReference, repositoryLocation)

        return GitProjectMetadata(
            reference: reference,
            worktreePath: location.worktreePath,
            repositoryCommonDirectory: location.commonDirectory,
            isLinkedWorktree: FilePathIdentity.canonical(location.gitDirectory)
                != FilePathIdentity.canonical(location.commonDirectory)
        )
    }

    private static func currentReference(in directory: URL) async throws -> String {
        do {
            return try await GitAdapter.currentReference(in: directory)
        } catch GitAdapterError.referenceUnavailable {
            throw GitServiceError.referenceUnavailable
        }
    }

    private static func translatedSwitchError(from output: String) -> GitServiceError {
        let lowercased = output.lowercased()

        if lowercased.contains("would be overwritten by checkout")
            || lowercased.contains("would be overwritten by switch") {
            return .localChangesWouldBeOverwritten
        }
        if lowercased.contains("resolve your current index first")
            || lowercased.contains("cannot switch branch while")
            || lowercased.contains("you have unmerged paths") {
            return .unresolvedConflicts
        }
        if lowercased.contains("already checked out at")
            || lowercased.contains("is already used by worktree") {
            return .branchUsedByAnotherWorktree
        }
        if lowercased.contains("invalid reference")
            || (lowercased.contains("pathspec") && lowercased.contains("did not match")) {
            return .branchUnavailable
        }

        return .switchFailed(output.isEmpty ? L10n.t("未知错误") : output)
    }
}

private extension Array where Element == GitAdapter.WorktreeRecord {

    func asWorktreeInfo(currentWorktreePath: String) -> [GitWorktreeInfo] {
        let currentPath = FilePathIdentity.canonical(currentWorktreePath)
        return enumerated().map { index, record in
            GitWorktreeInfo(
                path: record.path,
                head: record.head,
                branch: record.branch,
                isCurrent: FilePathIdentity.canonical(record.path) == currentPath,
                // `git worktree list` guarantees the main worktree is first.
                isMain: index == 0,
                isBare: record.isBare,
                isDetached: record.isDetached,
                isLocked: record.isLocked,
                lockedReason: record.lockedReason,
                isPrunable: record.isPrunable,
                prunableReason: record.prunableReason
            )
        }
    }
}
