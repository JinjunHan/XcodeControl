//
//  SwiftPackageStore.swift
//  XcodeControl
//

import Foundation
import Observation

/// 当前项目的 Swift Package 修复任务。
///
/// Task 挂在 Store 上而不是 View 上：用户收起二级面板后，已经开始的解析不应被
/// SwiftUI 销毁视图顺带取消；只有显式停止、切换项目或应用退出才取消。
@MainActor
@Observable
final class SwiftPackageStore {

    enum Operation: Equatable {
        case resolvedFileOnly
        case updateAllowed
        case clearCache

        var title: String {
            switch self {
            case .resolvedFileOnly: L10n.t("按 Package.resolved 修复")
            case .updateAllowed: L10n.t("重新解析依赖")
            case .clearCache: L10n.t("清理项目 Package 缓存")
            }
        }
    }

    enum Status: Equatable {
        case idle
        case running(Operation)
        case succeeded(String)
        case failed(String)
    }

    private(set) var status: Status = .idle
    private(set) var projectPath: String?
    private(set) var packageResolvedURL: URL?
    private(set) var sourcePackagesURL: URL?

    @ObservationIgnored
    private var task: Task<Void, Never>?
    @ObservationIgnored
    private var generation = 0

    var isWorking: Bool {
        if case .running = status { return true }
        return false
    }

    func prepare(
        project: URL,
        kind: XcodeProject.Kind,
        configuredDerivedDataPath: URL?,
        defaultDerivedDataRoot: URL
    ) {
        let path = project.standardizedFileURL.path
        if projectPath != path {
            cancel(reset: true)
            projectPath = path
        }
        packageResolvedURL = SwiftPackageService.packageResolvedURL(project: project, kind: kind)
        sourcePackagesURL = SwiftPackageService.sourcePackagesURL(
            project: project,
            configuredDerivedDataPath: configuredDerivedDataPath,
            defaultDerivedDataRoot: defaultDerivedDataRoot
        )
    }

    func resolve(
        project: URL,
        kind: XcodeProject.Kind,
        scheme: String,
        derivedDataPath: URL?,
        mode: XcodebuildAdapter.PackageResolutionMode,
        logs: LogStore,
        onFailure: @escaping @MainActor () -> Void
    ) {
        guard !isWorking else { return }
        if mode == .resolvedFileOnly, packageResolvedURL == nil {
            status = .failed(L10n.t("未找到 Package.resolved，请改用“重新解析依赖”。"))
            return
        }

        let operation: Operation = mode == .resolvedFileOnly ? .resolvedFileOnly : .updateAllowed
        begin(operation)
        let currentGeneration = generation
        let request = XcodebuildAdapter.PackageResolutionRequest(
            project: project,
            kind: kind,
            scheme: scheme,
            derivedDataPath: derivedDataPath,
            mode: mode
        )
        let arguments = XcodebuildAdapter.packageResolutionArguments(request)
        logs.append("$ xcodebuild \(arguments.joined(separator: " "))", level: .note)

        task = Task { [weak self] in
            do {
                let result = try await XcodebuildAdapter.resolvePackageDependencies(request)
                guard let self, !Task.isCancelled, self.generation == currentGeneration else { return }
                if !result.combinedTrimmed.isEmpty {
                    result.combinedTrimmed
                        .split(separator: "\n", omittingEmptySubsequences: false)
                        .forEach { logs.append(String($0)) }
                }
                self.status = .succeeded(L10n.t("Swift Package 依赖已解析完成。"))
                self.task = nil
            } catch is CancellationError {
                guard let self, self.generation == currentGeneration else { return }
                self.status = .idle
                self.task = nil
            } catch {
                guard let self, self.generation == currentGeneration else { return }
                let detail = error.localizedDescription
                logs.append(L10n.t("Swift Package 操作详情：%@", detail), level: .error)
                self.status = .failed(Self.failureMessage(detail))
                self.task = nil
                onFailure()
            }
        }
    }

    func clearCache(logs: LogStore) {
        guard !isWorking else { return }
        begin(.clearCache)
        let currentGeneration = generation
        let target = sourcePackagesURL

        task = Task { [weak self] in
            let result = await SwiftPackageService.removeProjectCache(at: target)
            guard let self, !Task.isCancelled, self.generation == currentGeneration else { return }
            self.task = nil

            guard result.sourcePackagesURL != nil else {
                self.status = .failed(L10n.t("没有找到当前项目的 SourcePackages 缓存目录。"))
                return
            }
            guard result.itemCount > 0 else {
                self.status = .succeeded(L10n.t("项目 Package 缓存已经是空的。"))
                return
            }

            let message = L10n.t(
                "已清理 %d 项项目缓存，释放 %@。",
                result.itemCount,
                DiskUsage.formatBytes(result.bytes)
            )
            logs.append(message, level: .note)
            self.status = .succeeded(message)
        }
    }

    func cancel(reset: Bool = false) {
        generation += 1
        task?.cancel()
        task = nil
        status = .idle
        if reset {
            projectPath = nil
            packageResolvedURL = nil
            sourcePackagesURL = nil
        }
    }

    private func begin(_ operation: Operation) {
        generation += 1
        status = .running(operation)
    }

    private static func failureMessage(_ detail: String) -> String {
        let lower = detail.lowercased()
        let networkMarkers = [
            "could not resolve host", "failed to connect", "connection timed out",
            "operation timed out", "network is unreachable", "couldn't connect",
            "repository not found", "the remote end hung up",
        ]
        if networkMarkers.contains(where: lower.contains) {
            return L10n.t("无法访问依赖仓库。请开启代理或 VPN，确认 GitHub 可访问后重试。")
        }
        let damagedCacheMarkers = [
            "unable to read sha1 file", "invalid object", "object file", "is empty",
            "couldn't check out revision", "couldn’t check out revision",
        ]
        if damagedCacheMarkers.contains(where: lower.contains) {
            return L10n.t("项目 Package Git 缓存已损坏。请先清理项目 Package 缓存；若仍失败，开启代理或 VPN 后重新解析依赖。")
        }
        if lower.contains("onlyusepackageversionsfromresolvedfile")
            || lower.contains("package.resolved") && lower.contains("missing") {
            return L10n.t("Package.resolved 不可用，请改用“重新解析依赖”。")
        }
        if lower.contains("revision") && (lower.contains("not found") || lower.contains("missing")) {
            return L10n.t("锁定的依赖版本在本地缓存中缺失。联网后重新解析，或先清理项目缓存再重试。")
        }
        return ErrorTranslator.summarize(detail)
    }
}
