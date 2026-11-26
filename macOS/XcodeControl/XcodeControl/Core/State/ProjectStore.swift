//
//  ProjectStore.swift
//  XcodeControl
//

import AppKit
import Foundation
import Observation

/// 当前项目与托管的项目列表。
///
/// 列表由用户显式添加 / 扫描 / 删除管理，不再按「最近 N 条」自动裁剪。
/// 切换项目时自动恢复上次的 scheme / configuration / 设备，
/// 让「切过去就能跑」成为默认体验。
@MainActor
@Observable
final class ProjectStore {

    // MARK: - 状态

    /// 用户管理的项目列表（顺序由用户拖拽决定，持久化时原样保存）
    private(set) var items: [XcodeProject] = []
    private(set) var current: XcodeProject?
    /// 当前项目解析后的真实路径
    private(set) var currentURL: URL?
    private(set) var info: ProjectInfo?
    private(set) var isLoading = false
    private(set) var loadError: String?
    /// 托管项目的 Git/worktree 元数据；非 Git 项目不会出现在字典中。
    private(set) var projectGitMetadata: [UUID: GitProjectMetadata] = [:]
    private(set) var currentGitReference: String?
    private(set) var gitBranches: [String] = []
    private(set) var gitWorktrees: [GitWorktreeInfo] = []
    private(set) var currentGitWorktreePath: String?
    private(set) var isLoadingGitBranches = false
    private(set) var switchingGitBranch: String?
    private(set) var activatingGitWorktreeBranch: String?
    private(set) var gitBranchError: String?
    private(set) var gitBranchErrorDetail: String?

    /// 工程 AppIcon 缩略图缓存（按项目 id）；缺失时 UI 回退 SF Symbol
    private(set) var icons: [UUID: NSImage] = [:]

    var selectedScheme: String? {
        didSet {
            guard selectedScheme != oldValue, !suppressContextPersist else { return }
            persistCurrentContext()
        }
    }

    var selectedConfiguration: String = BuildConfiguration.debug {
        didSet {
            guard selectedConfiguration != oldValue, !suppressContextPersist else { return }
            persistCurrentContext()
        }
    }

    /// 路径已失效的项目 id，列表中置灰
    private(set) var missingProjectIDs: Set<UUID> = []

    /// 由 AppState 注入（轮询间隔等仍从 prefs 读）
    var prefs: Preferences?

    private let store = RecentProjectsStore()
    private var activeAccess: BookmarkStore.Resolved?
    /// 取消过期的图标扫描（批量添加时只保留最后一次）
    private var iconLoadGeneration = 0
    /// 切换项目瞬间先清旧 scheme，此时不要把「空/过渡态」写回 bookmark
    private var suppressContextPersist = false
    /// 忽略过期的 `xcodebuild -list` 结果（快速连点切换时）
    private var infoLoadGeneration = 0
    /// Git 的三类命令分别失效，避免一次悬停刷新误伤正在进行的分支切换。
    private var gitReferenceLoadGeneration = 0
    private var gitBranchLoadGeneration = 0
    private var gitSwitchGeneration = 0
    private var gitMetadataLoadGeneration = 0
    @ObservationIgnored
    private var gitMetadataLoadTask: Task<Void, Never>?

    // MARK: - 生命周期

    init() {
        items = store.load()
        refreshMissingFlags()
        scheduleIconRefresh()
        scheduleGitMetadataRefresh()
    }

    var hasProject: Bool { current != nil && currentURL != nil }
    var isGitBranchBusy: Bool {
        switchingGitBranch != nil || activatingGitWorktreeBranch != nil
    }

    var availableSchemes: [String] { info?.schemes ?? [] }
    var availableConfigurations: [String] { info?.configurations ?? [BuildConfiguration.debug] }

    /// 启动时恢复上次的项目
    func restoreLastProject() async {
        guard let id = store.currentProjectID,
              let project = items.first(where: { $0.id == id })
        else { return }
        await select(project)
    }

    // MARK: - 打开 / 选择

    /// 打开用户选择/拖入的路径，加入列表并激活。
    func open(url rawURL: URL) async {
        await add(url: rawURL, makeCurrent: true)
    }

    /// 从列表中选择一个项目并激活。
    func select(_ project: XcodeProject) async {
        isLoading = true
        loadError = nil
        defer { isLoading = false }

        do {
            let resolved = try BookmarkStore.resolve(project.bookmark)
            missingProjectIDs.remove(project.id)

            var updated = project
            updated.lastKnownPath = resolved.url.path
            updated.lastOpenedAt = Date()
            if resolved.needsRefresh, let fresh = try? BookmarkStore.makeBookmark(for: resolved.url) {
                updated.bookmark = fresh
            }
            upsert(updated)
            await makeCurrent(updated, url: resolved.url, access: resolved)
        } catch {
            missingProjectIDs.insert(project.id)
            loadError = error.localizedDescription
        }
    }

    /// 加入列表。`makeCurrent == false` 时只登记不切换当前项目（扫描批量添加用）。
    /// - Returns: 是否新加入（已存在同路径则更新 bookmark，返回 false）
    @discardableResult
    func add(
        url rawURL: URL,
        makeCurrent: Bool,
        refreshIcon: Bool = true,
        refreshGitMetadata: Bool = true
    ) async -> Bool {
        isLoading = true
        loadError = nil
        defer { isLoading = false }

        do {
            let (url, kind) = try ProjectService.normalize(rawURL)
            let bookmark = try BookmarkStore.makeBookmark(for: url)

            let canonicalURLPath = FilePathIdentity.canonical(url.path)
            if let existing = items.first(where: {
                FilePathIdentity.canonical($0.lastKnownPath) == canonicalURLPath
            }) {
                var updated = existing
                updated.bookmark = bookmark
                if makeCurrent { updated.lastOpenedAt = Date() }
                upsert(updated)
                if makeCurrent {
                    await self.makeCurrent(updated, url: url)
                }
                if refreshIcon {
                    scheduleIconRefresh(for: updated.id)
                }
                if refreshGitMetadata {
                    scheduleGitMetadataRefresh()
                }
                return false
            }

            let project = XcodeProject(
                name: ProjectService.displayName(for: url),
                bookmark: bookmark,
                lastKnownPath: url.path,
                kind: kind
            )
            upsert(project)
            if makeCurrent {
                await self.makeCurrent(project, url: url)
            }
            if refreshIcon {
                scheduleIconRefresh(for: project.id)
            }
            if refreshGitMetadata {
                scheduleGitMetadataRefresh()
            }
            return true
        } catch {
            loadError = error.localizedDescription
            return false
        }
    }

    /// 扫描目录下的工程并批量加入列表，不切换当前项目。
    /// - Returns: (新加入数, 已存在跳过数)
    func addDiscovered(under root: URL) async -> (added: Int, skipped: Int) {
        let discovered = ProjectService.discoverProjects(under: root)
        var added = 0
        var skipped = 0
        for url in discovered {
            let isNew = await add(
                url: url,
                makeCurrent: false,
                refreshIcon: false,
                refreshGitMetadata: false
            )
            if isNew { added += 1 } else { skipped += 1 }
        }
        if added > 0 {
            scheduleIconRefresh()
        }
        scheduleGitMetadataRefresh()
        return (added, skipped)
    }

    /// 重新解析当前项目的 scheme 列表。
    func reloadInfo() async {
        guard let project = current, let url = currentURL else { return }
        isLoading = true
        defer { isLoading = false }
        await loadInfo(for: project, url: url)
    }

    func remove(_ project: XcodeProject) {
        items.removeAll { $0.id == project.id }
        missingProjectIDs.remove(project.id)
        icons.removeValue(forKey: project.id)
        projectGitMetadata.removeValue(forKey: project.id)
        store.save(items)
        if current?.id == project.id {
            releaseAccess()
            current = nil
            currentURL = nil
            info = nil
            resetGitState()
            selectedScheme = nil
            store.currentProjectID = nil
        }
        scheduleGitMetadataRefresh()
    }

    /// 清空托管列表并卸下当前项目。
    func clearAll() {
        guard !items.isEmpty else { return }
        items = []
        missingProjectIDs = []
        icons = [:]
        projectGitMetadata = [:]
        iconLoadGeneration += 1
        invalidateGitMetadataRefresh()
        store.save(items)
        releaseAccess()
        current = nil
        currentURL = nil
        info = nil
        resetGitState()
        selectedScheme = nil
        store.currentProjectID = nil
    }

    /// 拖放未能解析出工程时，给引导区 / 下拉一个可执行提示。
    func failImport(_ message: String) {
        loadError = message
    }

    /// 拖拽排序：保持用户自定义顺序。
    func move(from source: IndexSet, to destination: Int) {
        // State 层不 import SwiftUI，手写与 Array.move(fromOffsets:toOffset:) 等价的逻辑
        var result = items
        let from = source.sorted()
        guard !from.isEmpty else { return }

        var moving: [XcodeProject] = []
        moving.reserveCapacity(from.count)
        for index in from.reversed() {
            moving.insert(result.remove(at: index), at: 0)
        }

        var dest = destination
        for index in from where index < destination {
            dest -= 1
        }
        dest = min(max(dest, 0), result.count)
        result.insert(contentsOf: moving, at: dest)
        items = result
        store.save(items)
    }

    // MARK: - 上下文持久化

    /// 记录最后使用的设备，供下次切回该项目时恢复。
    func rememberDestination(_ destinationID: String?) {
        guard var project = current else { return }
        guard project.lastDestinationID != destinationID else { return }
        project.lastDestinationID = destinationID
        current = project
        upsert(project)
    }

    var rememberedDestinationID: String? { current?.lastDestinationID }

    /// 刷新当前工程所在仓库的分支。浮窗重新悬停时调用，以跟上外部切分支。
    func refreshGitReference() async {
        guard !isGitBranchBusy else { return }
        guard let projectID = current?.id, let url = currentURL else {
            resetGitState()
            return
        }

        gitReferenceLoadGeneration += 1
        let generation = gitReferenceLoadGeneration

        do {
            if let cached = projectGitMetadata[projectID] {
                let reference = try await GitService.currentReference(forProjectAt: url)
                guard !Task.isCancelled,
                      generation == gitReferenceLoadGeneration,
                      current?.id == projectID,
                      currentURL == url
                else { return }

                guard let reference else {
                    clearCurrentGitState(removingMetadataFor: projectID)
                    return
                }

                let metadata = GitProjectMetadata(
                    reference: reference,
                    worktreePath: cached.worktreePath,
                    repositoryCommonDirectory: cached.repositoryCommonDirectory,
                    isLinkedWorktree: cached.isLinkedWorktree
                )
                applyCurrentGitMetadata(metadata, projectID: projectID)
            } else {
                let metadata = try await GitService.projectMetadata(forProjectAt: url)
                guard !Task.isCancelled,
                      generation == gitReferenceLoadGeneration,
                      current?.id == projectID,
                      currentURL == url
                else { return }

                guard let metadata else {
                    clearCurrentGitState(removingMetadataFor: projectID)
                    return
                }
                applyCurrentGitMetadata(metadata, projectID: projectID)
            }
        } catch is CancellationError {
            return
        } catch {
            // 悬停刷新只是同步外部状态；短暂的 Git 失败不应抹掉最后一次有效分支。
            return
        }
    }

    /// 展开分支面板时刷新当前引用与本地分支列表。
    func refreshGitBranches() async {
        guard !isGitBranchBusy else { return }
        guard let url = currentURL else {
            resetGitState()
            return
        }

        gitBranchLoadGeneration += 1
        let generation = gitBranchLoadGeneration
        isLoadingGitBranches = true
        gitBranchError = nil
        defer {
            if generation == gitBranchLoadGeneration {
                isLoadingGitBranches = false
            }
        }

        do {
            let snapshot = try await GitService.branchSnapshot(forProjectAt: url)
            guard generation == gitBranchLoadGeneration, currentURL == url else { return }
            let projectID = current?.id
            if let projectID {
                applyCurrentGitMetadata(snapshot.currentProject, projectID: projectID)
            }
            gitBranches = snapshot.localBranches
            gitWorktrees = snapshot.worktrees
            gitBranchError = nil
            gitBranchErrorDetail = nil
            mergeManagedWorktreeMetadata(
                snapshot.worktrees,
                repositoryCommonDirectory: snapshot.currentProject.repositoryCommonDirectory
            )
        } catch GitServiceError.notRepository {
            guard generation == gitBranchLoadGeneration, currentURL == url else { return }
            clearCurrentGitState(removingMetadataFor: current?.id)
        } catch {
            guard generation == gitBranchLoadGeneration, currentURL == url else { return }
            if Task.isCancelled { return }
            gitBranchError = error.localizedDescription
            gitBranchErrorDetail = rawGitErrorDetail(error)
        }
    }

    /// 切换到本地分支。失败时保留面板和列表，让用户能看到原因并重试。
    @discardableResult
    func switchGitBranch(to branch: String) async -> Bool {
        guard !isGitBranchBusy,
              let projectID = current?.id,
              let url = currentURL
        else { return false }

        if branch == currentGitReference {
            gitBranchError = nil
            return true
        }

        gitReferenceLoadGeneration += 1
        gitBranchLoadGeneration += 1
        gitSwitchGeneration += 1
        // 启动时或项目列表变更触发的旧扫描，可能仍握着切换前的分支名。
        invalidateGitMetadataRefresh()
        let generation = gitSwitchGeneration
        isLoadingGitBranches = false
        switchingGitBranch = branch
        gitBranchError = nil
        gitBranchErrorDetail = nil
        defer {
            if generation == gitSwitchGeneration,
               current?.id == projectID,
               currentURL == url {
                switchingGitBranch = nil
            }
        }

        do {
            let reference = try await GitService.switchBranch(branch, forProjectAt: url)
            guard generation == gitSwitchGeneration,
                  current?.id == projectID,
                  currentURL == url
            else { return false }
            currentGitReference = reference
            updateCurrentGitMetadata(reference: reference)
            return true
        } catch GitServiceError.notRepository {
            guard generation == gitSwitchGeneration,
                  current?.id == projectID,
                  currentURL == url
            else { return false }
            clearCurrentGitState(removingMetadataFor: projectID)
            return false
        } catch {
            guard generation == gitSwitchGeneration,
                  current?.id == projectID,
                  currentURL == url
            else { return false }
            if Task.isCancelled { return false }
            gitBranchError = error.localizedDescription
            gitBranchErrorDetail = rawGitErrorDetail(error)
            return false
        }
    }

    func gitMetadata(for project: XcodeProject) -> GitProjectMetadata? {
        projectGitMetadata[project.id]
    }

    /// 分支若已在另一个 worktree 中使用，点击应切换项目而不是执行必然失败的 `git switch`。
    func worktreeUsingBranch(_ branch: String) -> GitWorktreeInfo? {
        gitWorktrees.first { $0.branch == branch && !$0.isCurrent }
    }

    /// 分支列表还要标出当前 linked worktree；主工作树本身不需要重复强调。
    func displayedWorktree(for branch: String) -> GitWorktreeInfo? {
        gitWorktrees.first {
            $0.branch == branch && (!$0.isCurrent || !$0.isMain)
        }
    }

    /// 一个 worktree 可能登记了多个工程；只把当前工程的对应项视为可直接切换。
    func managedProject(in worktree: GitWorktreeInfo) -> XcodeProject? {
        let candidates = items.filter {
            isProjectPath($0.lastKnownPath, ownedBy: worktree)
        }
        guard !candidates.isEmpty else { return nil }

        if let expected = counterpartProjectURL(
            in: worktree,
            currentWorktreePath: currentGitWorktreePath
                ?? current.flatMap { projectGitMetadata[$0.id]?.worktreePath }
        ) {
            return candidates.first {
                FilePathIdentity.canonical($0.lastKnownPath)
                    == FilePathIdentity.canonical(expected.path)
            }
        }

        guard let current else { return nil }
        let matchingProjects = candidates.filter {
            $0.name == current.name && $0.kind == current.kind
        }
        return matchingProjects.count == 1 ? matchingProjects[0] : nil
    }

    /// 打开占用分支的 worktree：已登记则直接切项目，否则按当前工程的相对路径自动加入。
    @discardableResult
    func activateWorktree(_ worktree: GitWorktreeInfo, forBranch branch: String) async -> Bool {
        guard !Task.isCancelled,
              !isGitBranchBusy,
              let sourceProjectID = current?.id,
              let sourceURL = currentURL
        else { return false }

        gitSwitchGeneration += 1
        let generation = gitSwitchGeneration
        activatingGitWorktreeBranch = branch
        gitBranchError = nil
        gitBranchErrorDetail = nil
        defer {
            if generation == gitSwitchGeneration,
               activatingGitWorktreeBranch == branch {
                activatingGitWorktreeBranch = nil
            }
        }

        let worktreeRoot = URL(fileURLWithPath: worktree.path, isDirectory: true)
        guard !worktree.isBare,
              !worktree.isPrunable,
              FileManager.default.fileExists(atPath: worktreeRoot.path)
        else {
            gitBranchError = L10n.t("Git worktree 路径已失效，请先在终端清理该 worktree")
            return false
        }

        if let project = managedProject(in: worktree) {
            let projectID = project.id
            await select(project)
            let didActivate = current?.id == projectID
            if !didActivate, let loadError {
                gitBranchError = loadError
            }
            return didActivate
        }

        let sourceRoot = currentGitWorktreePath
            ?? current.flatMap { projectGitMetadata[$0.id]?.worktreePath }
        let target = await correspondingProjectURL(
            in: worktree,
            currentWorktreePath: sourceRoot
        )
        guard !Task.isCancelled,
              generation == gitSwitchGeneration,
              current?.id == sourceProjectID,
              currentURL == sourceURL
        else { return false }

        guard let target else {
            gitBranchError = L10n.t("未识别到 .xcodeproj / .xcworkspace")
            NSWorkspace.shared.open(worktreeRoot)
            return false
        }

        _ = await add(
            url: target,
            makeCurrent: true,
            refreshGitMetadata: false
        )
        let normalizedTarget = (try? ProjectService.normalize(target).url) ?? target
        let didActivate = currentURL.map {
            FilePathIdentity.canonical($0.path)
                == FilePathIdentity.canonical(normalizedTarget.path)
        } ?? false
        if !didActivate, let loadError {
            gitBranchError = loadError
        }
        return didActivate
    }

    /// 以当前工程为模板，把同仓库其它 worktree 里的对应工程加入托管列表。
    /// 非 Git 项目返回 nil；单个 worktree 无工程时计数并继续处理其余条目。
    func addProjectsFromCurrentRepositoryWorktrees() async throws -> (
        added: Int,
        existing: Int,
        withoutProject: Int
    )? {
        guard let url = currentURL else { return nil }

        let snapshot: GitWorktreeSnapshot
        do {
            snapshot = try await GitService.worktreeSnapshot(forProjectAt: url)
        } catch GitServiceError.notRepository {
            return nil
        }
        try Task.checkCancellation()
        guard currentURL == url else { throw CancellationError() }

        invalidateGitMetadataRefresh()
        var added = 0
        var existing = 0
        var withoutProject = 0
        defer {
            if added > 0 {
                scheduleIconRefresh()
            }
            scheduleGitMetadataRefresh()
        }

        if let projectID = current?.id {
            applyCurrentGitMetadata(snapshot.currentProject, projectID: projectID)
        }
        gitWorktrees = snapshot.worktrees
        mergeManagedWorktreeMetadata(
            snapshot.worktrees,
            repositoryCommonDirectory: snapshot.currentProject.repositoryCommonDirectory
        )

        for worktree in snapshot.worktrees
        where !worktree.isCurrent && !worktree.isBare {
            try Task.checkCancellation()
            let candidate = await correspondingProjectURL(
                in: worktree,
                currentWorktreePath: snapshot.currentProject.worktreePath
            )
            try Task.checkCancellation()
            guard let candidate else {
                withoutProject += 1
                continue
            }

            let isNew = await add(
                url: candidate,
                makeCurrent: false,
                refreshIcon: false,
                refreshGitMetadata: false
            )
            if isNew {
                added += 1
            } else {
                existing += 1
            }
        }

        mergeManagedWorktreeMetadata(
            snapshot.worktrees,
            repositoryCommonDirectory: snapshot.currentProject.repositoryCommonDirectory
        )
        return (added, existing, withoutProject)
    }

    private func persistCurrentContext() {
        guard var project = current else { return }
        project.lastScheme = selectedScheme
        project.lastConfiguration = selectedConfiguration
        current = project
        upsert(project)
    }

    // MARK: - 私有

    private func makeCurrent(_ project: XcodeProject, url: URL, access: BookmarkStore.Resolved? = nil) async {
        releaseAccess()
        activeAccess = access

        current = project
        currentURL = url
        resetGitState()
        store.currentProjectID = project.id

        // 先清掉上一个工程的 scheme 列表，避免菜单/浮窗在 -list 完成前继续显示旧数据
        infoLoadGeneration += 1
        let generation = infoLoadGeneration
        suppressContextPersist = true
        info = nil
        selectedScheme = project.lastScheme
        selectedConfiguration = project.lastConfiguration
        suppressContextPersist = false

        async let infoLoad: Void = loadInfo(for: project, url: url, generation: generation)
        async let gitLoad: Void = refreshGitReference()
        _ = await (infoLoad, gitLoad)
    }

    private func resetGitState() {
        gitReferenceLoadGeneration += 1
        gitBranchLoadGeneration += 1
        gitSwitchGeneration += 1
        clearCurrentGitState(removingMetadataFor: nil)
        isLoadingGitBranches = false
        switchingGitBranch = nil
        activatingGitWorktreeBranch = nil
    }

    private func clearCurrentGitState(removingMetadataFor projectID: UUID?) {
        currentGitReference = nil
        gitBranches = []
        gitWorktrees = []
        currentGitWorktreePath = nil
        gitBranchError = nil
        gitBranchErrorDetail = nil
        if let projectID {
            projectGitMetadata.removeValue(forKey: projectID)
        }
    }

    private func applyCurrentGitMetadata(_ metadata: GitProjectMetadata, projectID: UUID) {
        currentGitReference = metadata.reference
        currentGitWorktreePath = metadata.worktreePath
        projectGitMetadata[projectID] = metadata
    }

    /// `git worktree list` 已经带着每个工作树的 branch，可直接刷新同仓库的托管项目。
    private func mergeManagedWorktreeMetadata(
        _ worktrees: [GitWorktreeInfo],
        repositoryCommonDirectory: String
    ) {
        let commonDirectory = FilePathIdentity.canonical(repositoryCommonDirectory)

        for project in items {
            guard let existing = projectGitMetadata[project.id],
                  FilePathIdentity.canonical(existing.repositoryCommonDirectory)
                    == commonDirectory,
                  let worktree = matchingWorktree(
                      for: project.lastKnownPath,
                      in: worktrees
                  )
            else { continue }

            projectGitMetadata[project.id] = GitProjectMetadata(
                reference: worktree.reference,
                worktreePath: worktree.path,
                repositoryCommonDirectory: repositoryCommonDirectory,
                isLinkedWorktree: !worktree.isMain
            )
        }
    }

    private func matchingWorktree(
        for projectPath: String,
        in worktrees: [GitWorktreeInfo]
    ) -> GitWorktreeInfo? {
        worktrees
            .filter {
                FilePathIdentity.relativeComponents(
                    for: projectPath,
                    inside: $0.path
                ) != nil
            }
            .max {
                URL(fileURLWithPath: FilePathIdentity.canonical($0.path)).pathComponents.count
                    < URL(fileURLWithPath: FilePathIdentity.canonical($1.path)).pathComponents.count
            }
    }

    /// linked worktree 偶尔会放在另一个工作树目录下，归属必须以最深根路径为准。
    private func isProjectPath(
        _ projectPath: String,
        ownedBy worktree: GitWorktreeInfo
    ) -> Bool {
        var candidates = gitWorktrees
        let targetPath = FilePathIdentity.canonical(worktree.path)
        if !candidates.contains(where: {
            FilePathIdentity.canonical($0.path) == targetPath
        }) {
            candidates.append(worktree)
        }
        guard let owner = matchingWorktree(for: projectPath, in: candidates) else {
            return false
        }
        return FilePathIdentity.canonical(owner.path) == targetPath
    }

    private func updateCurrentGitMetadata(reference: String) {
        guard let projectID = current?.id else { return }
        guard let metadata = projectGitMetadata[projectID] else { return }
        projectGitMetadata[projectID] = GitProjectMetadata(
            reference: reference,
            worktreePath: metadata.worktreePath,
            repositoryCommonDirectory: metadata.repositoryCommonDirectory,
            isLinkedWorktree: metadata.isLinkedWorktree
        )
    }

    /// worktree 中只自动选择当前工程的明确对应项，避免 monorepo 扫描后误选任意工程。
    private func correspondingProjectURL(
        in worktree: GitWorktreeInfo,
        currentWorktreePath: String?
    ) async -> URL? {
        guard !Task.isCancelled, !worktree.isBare, !worktree.isPrunable else { return nil }

        if let counterpart = counterpartProjectURL(
            in: worktree,
            currentWorktreePath: currentWorktreePath
        ), isProjectPath(counterpart.path, ownedBy: worktree) {
            return counterpart
        }

        let root = URL(fileURLWithPath: worktree.path, isDirectory: true)
        guard FileManager.default.fileExists(atPath: root.path) else { return nil }
        let scanTask = Task.detached(priority: .utility) {
            ProjectService.discoverProjects(
                under: root,
                maximumDirectories: 5_000
            )
        }
        let discovered = await withTaskCancellationHandler {
            await scanTask.value
        } onCancel: {
            scanTask.cancel()
        }
        guard !Task.isCancelled, let current else { return nil }
        let matchingProjects = discovered.filter {
            isProjectPath($0.path, ownedBy: worktree)
                && ProjectService.displayName(for: $0) == current.name
                && (try? ProjectService.normalize($0).kind) == current.kind
        }
        return matchingProjects.count == 1 ? matchingProjects[0] : nil
    }

    private func counterpartProjectURL(
        in worktree: GitWorktreeInfo,
        currentWorktreePath: String?
    ) -> URL? {
        guard let currentURL, let currentWorktreePath,
              let relative = FilePathIdentity.relativeComponents(
                  for: currentURL.path,
                  inside: currentWorktreePath
              )
        else { return nil }

        var candidate = URL(fileURLWithPath: worktree.path, isDirectory: true)
        for component in relative {
            candidate.appendPathComponent(component)
        }
        guard FileManager.default.fileExists(atPath: candidate.path),
              let normalized = try? ProjectService.normalize(candidate).url
        else { return nil }
        return normalized
    }

    private func loadInfo(for project: XcodeProject, url: URL, generation: Int? = nil) async {
        let generation = generation ?? {
            infoLoadGeneration += 1
            return infoLoadGeneration
        }()

        do {
            let loaded = try await ProjectService.loadInfo(url: url, kind: project.kind)
            guard generation == infoLoadGeneration else { return }

            info = loaded
            loadError = nil

            // 优先沿用上次的 scheme，失效则回落到第一个
            if let last = project.lastScheme, loaded.schemes.contains(last) {
                selectedScheme = last
            } else {
                selectedScheme = loaded.schemes.first
            }
            if !loaded.configurations.isEmpty,
               !loaded.configurations.contains(selectedConfiguration) {
                selectedConfiguration = loaded.configurations.contains(BuildConfiguration.debug)
                    ? BuildConfiguration.debug
                    : (loaded.configurations.first ?? BuildConfiguration.debug)
            }
            persistCurrentContext()
        } catch {
            guard generation == infoLoadGeneration else { return }
            // 取消不算失败——菜单关闭曾误伤过这里，现在任务挂在 AppState，仍可能被新的切换打断
            if Task.isCancelled { return }
            info = nil
            selectedScheme = nil
            loadError = error.localizedDescription
        }
    }

    private func upsert(_ project: XcodeProject) {
        if let index = items.firstIndex(where: { $0.id == project.id }) {
            items[index] = project
        } else {
            // 新项目插到顶部，不打乱用户已排好的其余顺序
            items.insert(project, at: 0)
        }
        if current?.id == project.id { current = project }
        store.save(items)
    }

    private func rawGitErrorDetail(_ error: Error) -> String? {
        if let gitError = error as? GitServiceError {
            guard case .switchFailed(let detail) = gitError else { return nil }
            return detail
        }

        let localized = error.localizedDescription
        let reflected = String(reflecting: error)
        return reflected == localized
            ? localized
            : "\(localized)\n\(reflected)"
    }

    /// Git 信息只是项目列表的装饰数据；并发读取、整批替换，失败项目自然不显示。
    private func scheduleGitMetadataRefresh() {
        invalidateGitMetadataRefresh()
        let generation = gitMetadataLoadGeneration
        let targets = items.map { ($0.id, $0.lastKnownPath) }

        guard !targets.isEmpty else {
            projectGitMetadata = [:]
            return
        }

        let task = Task { [weak self] in
            var loaded: [UUID: GitProjectMetadata] = [:]
            await withTaskGroup(of: (UUID, GitProjectMetadata?).self) { group in
                let concurrencyLimit = min(4, targets.count)
                var nextIndex = 0

                while nextIndex < concurrencyLimit {
                    let (id, path) = targets[nextIndex]
                    nextIndex += 1
                    group.addTask {
                        let metadata = try? await GitService.projectMetadata(
                            forProjectAt: URL(fileURLWithPath: path)
                        )
                        return (id, metadata)
                    }
                }

                while let (id, metadata) = await group.next() {
                    guard !Task.isCancelled else {
                        group.cancelAll()
                        break
                    }
                    if let metadata {
                        loaded[id] = metadata
                    }
                    if nextIndex < targets.count {
                        let (nextID, nextPath) = targets[nextIndex]
                        nextIndex += 1
                        group.addTask {
                            let metadata = try? await GitService.projectMetadata(
                                forProjectAt: URL(fileURLWithPath: nextPath)
                            )
                            return (nextID, metadata)
                        }
                    }
                }
            }

            guard !Task.isCancelled,
                  let self,
                  self.gitMetadataLoadGeneration == generation
            else { return }

            self.projectGitMetadata = loaded
            self.gitMetadataLoadTask = nil
        }
        gitMetadataLoadTask = task
    }

    private func invalidateGitMetadataRefresh() {
        gitMetadataLoadGeneration += 1
        gitMetadataLoadTask?.cancel()
        gitMetadataLoadTask = nil
    }

    /// 后台扫描源码树 AppIcon；`onlyID` 为 nil 时刷新整表。
    private func scheduleIconRefresh(for onlyID: UUID? = nil) {
        // 单条刷新不抬 generation，避免把启动时的全量扫描冲掉
        if onlyID == nil {
            iconLoadGeneration += 1
        }
        let generation = iconLoadGeneration
        let targets: [(UUID, String)]
        if let onlyID, let project = items.first(where: { $0.id == onlyID }) {
            targets = [(project.id, project.lastKnownPath)]
        } else {
            targets = items.map { ($0.id, $0.lastKnownPath) }
        }

        Task { [weak self] in
            var loaded: [UUID: NSImage] = [:]
            for (id, path) in targets {
                let file = await Task.detached(priority: .utility) {
                    AppIconLoader.bestImageFile(forProjectAt: URL(fileURLWithPath: path))
                }.value
                guard let file,
                      let thumb = AppIconLoader.thumbnail(from: file)
                else { continue }
                loaded[id] = thumb
            }

            await MainActor.run {
                guard let self else { return }
                if onlyID == nil {
                    guard self.iconLoadGeneration == generation else { return }
                    self.icons = loaded
                } else {
                    for (id, image) in loaded where self.items.contains(where: { $0.id == id }) {
                        self.icons[id] = image
                    }
                }
            }
        }
    }

    private func refreshMissingFlags() {
        missingProjectIDs = Set(
            items
                .filter { !FileManager.default.fileExists(atPath: $0.lastKnownPath) }
                .map(\.id)
        )
    }

    private func releaseAccess() {
        if let activeAccess {
            BookmarkStore.endAccess(activeAccess)
        }
        activeAccess = nil
    }
}
