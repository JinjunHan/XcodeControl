//
//  GitAdapter.swift
//  XcodeControl
//

import Foundation

enum GitAdapterError: Error {
    case referenceUnavailable
}

/// `/usr/bin/git` 的命令与输出解析入口。Service 层只组合领域行为，不接触 porcelain 文本。
enum GitAdapter {

    struct RepositoryLocation: Sendable {
        let worktreePath: String
        let commonDirectory: String
        let gitDirectory: String
    }

    struct WorktreeRecord: Sendable {
        let path: String
        let head: String
        let branch: String?
        let isBare: Bool
        let isDetached: Bool
        let isLocked: Bool
        let lockedReason: String?
        let isPrunable: Bool
        let prunableReason: String?
    }

    static func isWorkTree(at directory: URL) async throws -> Bool {
        let result = try await run(
            arguments: ["-C", directory.path, "rev-parse", "--is-inside-work-tree"]
        )
        if result.isSuccess {
            return trimmed(result.stdout) == "true"
        }
        if isNotRepository(result) {
            return false
        }
        throw ProcessRunnerError.nonZeroExit(
            command: "/usr/bin/git rev-parse",
            code: result.exitCode,
            output: result.combinedTrimmed
        )
    }

    /// 必须读取完整 ref 后精确去掉 `refs/heads/`。
    ///
    /// `symbolic-ref --short` 在 tag 与 branch 同名时可能返回 `heads/foo`，
    /// 会破坏带斜杠的真实分支名。
    static func currentReference(in directory: URL) async throws -> String {
        let symbolic = try await run(
            arguments: ["-C", directory.path, "symbolic-ref", "--quiet", "HEAD"]
        )
        if symbolic.isSuccess {
            let fullReference = trimmed(symbolic.stdout)
            let prefix = "refs/heads/"
            guard fullReference.hasPrefix(prefix) else {
                throw GitAdapterError.referenceUnavailable
            }
            let branch = String(fullReference.dropFirst(prefix.count))
            guard !branch.isEmpty else {
                throw GitAdapterError.referenceUnavailable
            }
            return branch
        }
        guard symbolic.exitCode == 1 else {
            throw ProcessRunnerError.nonZeroExit(
                command: "/usr/bin/git symbolic-ref",
                code: symbolic.exitCode,
                output: symbolic.combinedTrimmed
            )
        }

        let detached = try await run(
            arguments: ["-C", directory.path, "rev-parse", "--short", "HEAD"]
        )
        let commit = trimmed(detached.stdout)
        guard detached.isSuccess, !commit.isEmpty else {
            throw GitAdapterError.referenceUnavailable
        }
        return "HEAD \(commit)"
    }

    static func repositoryLocation(in directory: URL) async throws -> RepositoryLocation {
        let result = try await run(
            arguments: [
                "-C", directory.path,
                "rev-parse",
                "--show-toplevel",
                "--git-common-dir",
                "--git-dir",
            ]
        )
        guard result.isSuccess else {
            throw ProcessRunnerError.nonZeroExit(
                command: "/usr/bin/git rev-parse",
                code: result.exitCode,
                output: result.combinedTrimmed
            )
        }

        let lines = result.stdout.split(whereSeparator: \.isNewline)
        guard lines.count >= 3 else {
            throw GitAdapterError.referenceUnavailable
        }

        return RepositoryLocation(
            worktreePath: FilePathIdentity.absolute(String(lines[0]), relativeTo: directory),
            commonDirectory: FilePathIdentity.absolute(String(lines[1]), relativeTo: directory),
            gitDirectory: FilePathIdentity.absolute(String(lines[2]), relativeTo: directory)
        )
    }

    static func localBranches(in directory: URL) async throws -> [String] {
        let result = try await run(
            arguments: [
                "-C", directory.path,
                "for-each-ref",
                "--format=%(refname:lstrip=2)",
                "--sort=refname",
                "refs/heads",
            ]
        )
        guard result.isSuccess else {
            throw ProcessRunnerError.nonZeroExit(
                command: "/usr/bin/git for-each-ref",
                code: result.exitCode,
                output: result.combinedTrimmed
            )
        }

        return result.stdout
            .split(whereSeparator: \.isNewline)
            .map(String.init)
    }

    static func branchExists(_ branch: String, in directory: URL) async throws -> Bool {
        let result = try await run(
            arguments: [
                "-C", directory.path,
                "show-ref", "--verify", "--quiet",
                "refs/heads/\(branch)",
            ]
        )
        if result.exitCode == 0 { return true }
        if result.exitCode == 1 { return false }
        throw ProcessRunnerError.nonZeroExit(
            command: "/usr/bin/git show-ref",
            code: result.exitCode,
            output: result.combinedTrimmed
        )
    }

    static func switchBranch(_ branch: String, in directory: URL) async throws -> ProcessResult {
        try await run(
            arguments: ["-C", directory.path, "switch", "--quiet", "--no-guess", "--", branch],
            timeout: 30
        )
    }

    static func worktrees(in directory: URL) async throws -> [WorktreeRecord] {
        let result = try await run(
            arguments: ["-C", directory.path, "worktree", "list", "--porcelain", "-z"]
        )
        guard result.isSuccess else {
            throw ProcessRunnerError.nonZeroExit(
                command: "/usr/bin/git worktree list",
                code: result.exitCode,
                output: result.combinedTrimmed
            )
        }

        let records = result.stdout
            .split(separator: "\0", omittingEmptySubsequences: false)
            .reduce(into: [[String]]()) { groups, field in
                if field.isEmpty {
                    if groups.last?.isEmpty == false {
                        groups.append([])
                    }
                } else {
                    if groups.isEmpty { groups.append([]) }
                    groups[groups.count - 1].append(String(field))
                }
            }
            .filter { !$0.isEmpty }

        return records.compactMap { fields in
            var parsed = ParsedWorktree()

            for field in fields {
                if field.hasPrefix("worktree ") {
                    parsed.path = String(field.dropFirst("worktree ".count))
                } else if field.hasPrefix("HEAD ") {
                    parsed.head = String(field.dropFirst("HEAD ".count))
                } else if field.hasPrefix("branch ") {
                    let reference = String(field.dropFirst("branch ".count))
                    let prefix = "refs/heads/"
                    parsed.branch = reference.hasPrefix(prefix)
                        ? String(reference.dropFirst(prefix.count))
                        : reference
                } else if field == "bare" {
                    parsed.isBare = true
                } else if field == "detached" {
                    parsed.isDetached = true
                } else if field == "locked" || field.hasPrefix("locked ") {
                    parsed.isLocked = true
                    parsed.lockedReason = annotationReason(in: field, keyword: "locked")
                } else if field == "prunable" || field.hasPrefix("prunable ") {
                    parsed.isPrunable = true
                    parsed.prunableReason = annotationReason(in: field, keyword: "prunable")
                }
            }

            guard let rawPath = parsed.path else { return nil }
            let path = FilePathIdentity.canonical(rawPath)
            return WorktreeRecord(
                path: path,
                head: parsed.head,
                branch: parsed.branch,
                isBare: parsed.isBare,
                isDetached: parsed.isDetached,
                isLocked: parsed.isLocked,
                lockedReason: parsed.lockedReason,
                isPrunable: parsed.isPrunable,
                prunableReason: parsed.prunableReason
            )
        }
    }

    private struct ParsedWorktree {
        var path: String?
        var head = ""
        var branch: String?
        var isBare = false
        var isDetached = false
        var isLocked = false
        var lockedReason: String?
        var isPrunable = false
        var prunableReason: String?
    }

    private static func annotationReason(in field: String, keyword: String) -> String? {
        guard field.count > keyword.count else { return nil }
        let reason = String(field.dropFirst(keyword.count))
            .trimmingCharacters(in: .whitespaces)
        return reason.isEmpty ? nil : reason
    }

    private static func isNotRepository(_ result: ProcessResult) -> Bool {
        result.combinedTrimmed
            .localizedCaseInsensitiveContains("not a git repository")
    }

    private static func run(
        arguments: [String],
        timeout: TimeInterval = 5
    ) async throws -> ProcessResult {
        try await ProcessRunner.run(
            "/usr/bin/git",
            arguments,
            environment: ["LC_ALL": "C", "LANG": "C"],
            timeout: timeout
        )
    }

    private static func trimmed(_ value: String) -> String {
        value.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
