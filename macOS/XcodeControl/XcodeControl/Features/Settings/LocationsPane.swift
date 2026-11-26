//
//  LocationsPane.swift
//  XcodeControl
//

import AppKit
import SwiftUI
import UniformTypeIdentifiers

/// 位置：对齐 Xcode Settings › Locations 的交互与排版。
///
/// 每条统一两行：标题行（标题 + 右侧控件），路径行（路径 + 箭头）。
/// 体积并进标题旁，避免和路径抢同一行导致右缘参差。
struct LocationsPane: View {

    @Environment(AppState.self) private var state

    /// Picker 哨兵值：选中后弹出 Xcode.app 选择面板，不会真正写入 DEVELOPER_DIR
    private static let otherXcodeTag = "__xcc_choose_other_xcode__"

    @State private var installedXcodes: [Toolchain.XcodeInstall] = []
    /// 空字符串 = 跟随系统 `xcode-select -p`
    @State private var selectedDeveloperDir: String = Toolchain.overrideDeveloperDir ?? ""
    @State private var showingDerivedDataSheet = false
    @State private var derivedDataSize: String?
    @State private var cacheSize: String?
    @State private var isMeasuringSizes = false
    @State private var isReaping = false

    var body: some View {
        let prefs = state.prefs

        Form {
            Section {
                locationBlock(
                    title: "Derived Data",
                    size: derivedDataSize,
                    path: prefs.activeDerivedDataRoot.path,
                    revealURL: prefs.activeDerivedDataRoot
                ) {
                    // 用 Menu 而非 Picker：「自定义…」每次都能打开位置表改目录
                    HStack(spacing: 8) {
                        Menu {
                            Button {
                                prefs.derivedDataLocation = .default
                            } label: {
                                derivedDataMenuLabel(L10n.t("默认"), selected: prefs.derivedDataLocation == .default)
                            }
                            Button {
                                prefs.derivedDataLocation = .custom
                                showingDerivedDataSheet = true
                            } label: {
                                derivedDataMenuLabel(L10n.t("自定义…"), selected: prefs.derivedDataLocation == .custom)
                            }
                        } label: {
                            Text(prefs.derivedDataLocation.menuTitle)
                        }

                        Button(L10n.t("回收…"), action: confirmReap)
                            .disabled(isReaping)
                        Button(L10n.t("全部清除…"), action: confirmCleanDerivedData)
                    }
                    .controlSize(.small)
                }
            } footer: {
                Text(L10n.t("Xcode 自己从不回收 Derived Data：工程移动或删除后，旧缓存会一直留在磁盘上。"))
            }

            Section(L10n.t("自动回收")) {
                Toggle(L10n.t("回收已删除工程的缓存"), isOn: Binding(
                    get: { prefs.autoReapOrphans },
                    set: { prefs.autoReapOrphans = $0 }
                ))
                Text(orphanFooter)
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Toggle(L10n.t("回收长期未构建的缓存"), isOn: Binding(
                    get: { prefs.autoReapStaleEnabled },
                    set: { prefs.autoReapStaleEnabled = $0 }
                ))

                if prefs.autoReapStaleEnabled {
                    Stepper(
                        value: Binding(
                            get: { prefs.autoReapStaleDays },
                            set: { prefs.autoReapStaleDays = $0 }
                        ),
                        in: 7...365,
                        step: 1
                    ) {
                        Text(L10n.t("超过 %d 天未构建", prefs.autoReapStaleDays))
                    }
                }

                Text(L10n.t("这一项删的是仍在使用的工程的缓存，代价是下次全量重编。构建成功后在后台执行，每天最多一次。"))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section {
                locationBlock(
                    title: L10n.t("命令行工具"),
                    size: nil,
                    path: currentDeveloperPathDisplay,
                    revealURL: currentDeveloperAppURL
                ) {
                    Picker("", selection: $selectedDeveloperDir) {
                        Text(L10n.t("系统默认（xcode-select）")).tag("")
                        ForEach(installedXcodes) { xcode in
                            Text(xcode.displayName).tag(xcode.developerDir)
                        }
                        Divider()
                        Text(L10n.t("其他…")).tag(Self.otherXcodeTag)
                    }
                    .labelsHidden()
                    .pickerStyle(.menu)
                    .controlSize(.small)
                    .fixedSize()
                    .onChange(of: selectedDeveloperDir) { _, newValue in
                        if newValue == Self.otherXcodeTag {
                            chooseXcode()
                        } else {
                            applyDeveloperDir(newValue)
                        }
                    }
                }
            } footer: {
                Text(L10n.t("更改仅影响本应用的 DEVELOPER_DIR，不会改动系统的 xcode-select。"))
            }

            Section {
                locationBlock(
                    title: L10n.t("构建设置缓存"),
                    size: cacheSize,
                    path: cachePath?.path ?? "—",
                    revealURL: cachePath
                ) {
                    Button(L10n.t("清理…"), action: confirmCleanCache)
                        .controlSize(.small)
                }

                locationBlock(
                    title: L10n.t("偏好设置"),
                    size: nil,
                    path: prefsPath?.path ?? "—",
                    revealURL: prefsPath
                ) {
                    EmptyView()
                }
            }
        }
        .formStyle(.grouped)
        .task {
            installedXcodes = Toolchain.listInstalledXcodes()
            await refreshSizes()
        }
        .sheet(isPresented: $showingDerivedDataSheet) {
            DerivedDataLocationSheet(
                location: Binding(
                    get: { prefs.derivedDataLocation },
                    set: { prefs.derivedDataLocation = $0 }
                ),
                customRootPath: Binding(
                    get: { prefs.customDerivedDataRoot },
                    set: { prefs.customDerivedDataRoot = $0 }
                ),
                onDismiss: {
                    showingDerivedDataSheet = false
                    Task { await refreshSizes() }
                }
            )
        }
        .onChange(of: prefs.derivedDataLocation) { _, _ in
            Task { await refreshSizes() }
        }
        .onChange(of: prefs.customDerivedDataRoot) { _, _ in
            Task { await refreshSizes() }
        }
    }

    // MARK: - 统一两行块

    /// 左：标题 / 路径；右：控件贴齐卡片右缘。
    @ViewBuilder
    private func locationBlock<Trailing: View>(
        title: String,
        size: String?,
        path: String,
        revealURL: URL?,
        @ViewBuilder trailing: () -> Trailing
    ) -> some View {
        HStack(alignment: .top, spacing: 16) {
            VStack(alignment: .leading, spacing: 3) {
                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    Text(title)
                        .font(.body)
                    titleSizeLabel(size)
                }

                HStack(alignment: .center, spacing: 4) {
                    Text(path)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .truncationMode(.middle)
                        .textSelection(.enabled)

                    if let revealURL {
                        Button {
                            reveal(revealURL)
                        } label: {
                            Image(systemName: "arrow.forward.circle.fill")
                                .symbolRenderingMode(.hierarchical)
                                .foregroundStyle(.tint)
                                .imageScale(.small)
                        }
                        .buttonStyle(.borderless)
                        .help(L10n.t("在 Finder 中显示"))
                        .fixedSize()
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            trailing()
        }
        .padding(.vertical, 2)
    }

    @ViewBuilder
    private func titleSizeLabel(_ text: String?) -> some View {
        if let text {
            Text("· \(text)")
                .font(.caption)
                .foregroundStyle(.tertiary)
                .monospacedDigit()
        } else if isMeasuringSizes {
            ProgressView()
                .controlSize(.mini)
                .padding(.leading, 2)
        }
    }

    @ViewBuilder
    private func derivedDataMenuLabel(_ title: String, selected: Bool) -> some View {
        if selected {
            Label(title, systemImage: "checkmark")
        } else {
            Text(title)
        }
    }

    // MARK: - 路径展示

    private var currentDeveloperPathDisplay: String {
        if case .ready(let env) = state.environment {
            if env.developerDir.hasSuffix("/Contents/Developer") {
                return String(env.developerDir.dropLast("/Contents/Developer".count))
            }
            return env.developerDir
        }
        if selectedDeveloperDir.isEmpty {
            return L10n.t("启动后获取")
        }
        if selectedDeveloperDir.hasSuffix("/Contents/Developer") {
            return String(selectedDeveloperDir.dropLast("/Contents/Developer".count))
        }
        return selectedDeveloperDir
    }

    private var currentDeveloperAppURL: URL? {
        let path: String
        if case .ready(let env) = state.environment {
            path = env.developerDir
        } else {
            path = selectedDeveloperDir
        }
        guard !path.isEmpty else { return nil }
        var url = URL(fileURLWithPath: path)
        if url.lastPathComponent == "Developer",
           url.deletingLastPathComponent().lastPathComponent == "Contents" {
            url = url.deletingLastPathComponent().deletingLastPathComponent()
        }
        return url
    }

    private var cachePath: URL? {
        let support = FileManager.default
            .urls(for: .applicationSupportDirectory, in: .userDomainMask).first
        return support?.appendingPathComponent("XcodeControl/build-settings-cache.json")
    }

    private var prefsPath: URL? {
        let home = FileManager.default.homeDirectoryForCurrentUser
        let bundleID = Bundle.main.bundleIdentifier ?? "com.han.XcodeControl"
        return home
            .appendingPathComponent("Library/Preferences", isDirectory: true)
            .appendingPathComponent("\(bundleID).plist")
    }

    // MARK: - 体积

    private func refreshSizes() async {
        isMeasuringSizes = true
        defer { isMeasuringSizes = false }

        let root = state.prefs.activeDerivedDataRoot
        let cache = cachePath
        let (ddBytes, cacheBytes) = await DiskUsage.measure(derivedDataRoot: root, cacheFile: cache)
        guard !Task.isCancelled else { return }

        derivedDataSize = DiskUsage.formatBytes(ddBytes)
        cacheSize = cache.map { _ in DiskUsage.formatBytes(cacheBytes) }
    }

    // MARK: - 动作

    /// 孤儿判定的可靠性随位置模式而变，说明文案也得跟着变——
    /// 默认模式下有一类目录（命令行构建产生的、没有 info.plist 的）根本判不出归属，
    /// 不能让用户以为「开了这个开关就都清干净了」。
    private var orphanFooter: String {
        if state.prefs.derivedDataLocation == .default {
            return L10n.t("依据缓存里记录的工程路径判定；路径已不存在即回收。判不出归属的目录会跳过。")
        }
        return L10n.t("自定义目录由本应用管理，可精确判定归属；不属于任何已托管工程的目录即回收。")
    }

    /// 先扫出候选、列清单给用户看，再删。
    ///
    /// 和「全部清除」的区别正在这里：那个是无差别 `removeItem(root)`，
    /// 默认模式下会把 Xcode 自身的索引和其他工程的缓存一起带走。
    private func confirmReap() {
        let prefs = state.prefs
        let root = prefs.activeDerivedDataRoot
        // 手动触发时忽略两个自动开关：用户点的是「让我看看有什么能删」，
        // 不该因为自动回收没开就报告「没有可回收的」。
        let policy = prefs.reapPolicy(
            knownProjectPaths: state.projects.items.map(\.lastKnownPath),
            currentProjectPath: state.projects.currentURL?.path,
            ignoringUserToggles: true
        )

        Task {
            isReaping = true
            let candidates = await DerivedDataReaper.scan(root: root, policy: policy)
            isReaping = false
            guard !Task.isCancelled else { return }

            guard !candidates.isEmpty else {
                let alert = NSAlert()
                alert.messageText = L10n.t("没有可回收的 Derived Data")
                alert.informativeText = L10n.t("所有缓存都属于仍在使用的工程。")
                alert.addButton(withTitle: L10n.t("好的"))
                alert.runModal()
                return
            }

            let total = candidates.reduce(UInt64(0)) { $0 + $1.sizeBytes }
            let alert = NSAlert()
            alert.messageText = L10n.t("回收 %d 份 Derived Data？", candidates.count)
            alert.informativeText = """
                \(candidateList(candidates))

                \(L10n.t("共可释放 %@。此操作不可撤销。", DiskUsage.formatBytes(total)))
                """
            alert.alertStyle = .warning
            alert.addButton(withTitle: L10n.t("回收"))
            alert.addButton(withTitle: L10n.t("取消"))
            guard alert.runModal() == .alertFirstButtonReturn else { return }

            let (count, bytes) = await DerivedDataReaper.remove(candidates)
            state.logs.append(
                L10n.t("已回收 %d 份无用的 Derived Data，释放 %@", count, DiskUsage.formatBytes(bytes)),
                level: .note
            )
            await refreshSizes()
        }
    }

    /// 清单最多列 12 条，多出来的折成一行——弹窗被上百行撑爆就没人看了。
    private func candidateList(_ candidates: [DerivedDataReaper.Candidate]) -> String {
        let shown = candidates.prefix(12).map { candidate in
            let reason: String
            switch candidate.reason {
            case .orphaned:
                reason = L10n.t("工程已不存在")
            case .stale(let days):
                reason = L10n.t("%d 天未构建", days)
            }
            return "• \(candidate.displayName) — \(DiskUsage.formatBytes(candidate.sizeBytes))（\(reason)）"
        }
        guard candidates.count > shown.count else { return shown.joined(separator: "\n") }
        return (shown + [L10n.t("…另有 %d 份", candidates.count - shown.count)]).joined(separator: "\n")
    }

    private func applyDeveloperDir(_ value: String) {
        let trimmed = value.trimmingCharacters(in: .whitespaces)
        Toolchain.overrideDeveloperDir = trimmed.isEmpty ? nil : trimmed
        Task { await state.redetectEnvironment() }
    }

    private func chooseXcode() {
        // 取消时回到真正在用的值，避免 Picker 停在「其他…」哨兵上
        let previous = Toolchain.overrideDeveloperDir ?? ""
        let panel = NSOpenPanel()
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = false
        panel.allowedContentTypes = [.application]
        panel.directoryURL = URL(fileURLWithPath: "/Applications")
        panel.message = L10n.t("选择 Xcode.app")
        NSApp.activate(ignoringOtherApps: true)
        guard panel.runModal() == .OK, let url = panel.url else {
            selectedDeveloperDir = previous
            return
        }
        let developer = url.appendingPathComponent("Contents/Developer").path
        guard let selectedXcode = Toolchain.xcodeInstall(at: url) else {
            selectedDeveloperDir = previous
            return
        }
        selectedDeveloperDir = developer
        if !installedXcodes.contains(where: { $0.developerDir == developer }) {
            installedXcodes = Toolchain.listInstalledXcodes()
            if !installedXcodes.contains(where: { $0.developerDir == developer }) {
                installedXcodes.append(selectedXcode)
            }
        }
        applyDeveloperDir(developer)
    }

    private func confirmCleanDerivedData() {
        let prefs = state.prefs
        let root = prefs.activeDerivedDataRoot
        let isXcodeDefault = prefs.derivedDataLocation == .default
        Task {
            let sizeLabel: String
            if let derivedDataSize {
                sizeLabel = derivedDataSize
            } else {
                isMeasuringSizes = true
                let bytes = await DiskUsage.directorySize(root)
                isMeasuringSizes = false
                guard !Task.isCancelled else { return }
                sizeLabel = DiskUsage.formatBytes(bytes)
                derivedDataSize = sizeLabel
            }

            let alert = NSAlert()
            alert.messageText = L10n.t("清除全部 Derived Data？")
            if isXcodeDefault {
                alert.informativeText = """
                    将删除 Xcode 默认 DerivedData：

                    \(root.path)

                    当前占用：\(sizeLabel)
                    这也会影响 Xcode 自身的索引与构建缓存，且不可撤销。
                    """
            } else {
                alert.informativeText = """
                    将删除自定义 DerivedData 根目录下的所有构建产物：

                    \(root.path)

                    当前占用：\(sizeLabel)
                    此操作不可撤销。
                    """
            }
            alert.alertStyle = .warning
            alert.addButton(withTitle: L10n.t("清理"))
            alert.addButton(withTitle: L10n.t("取消"))
            guard alert.runModal() == .alertFirstButtonReturn else { return }

            try? FileManager.default.removeItem(at: root)
            derivedDataSize = DiskUsage.formatBytes(0)
        }
    }

    private func confirmCleanCache() {
        guard let path = cachePath else { return }
        Task {
            let sizeLabel: String
            if let cacheSize {
                sizeLabel = cacheSize
            } else {
                let bytes = await DiskUsage.fileSize(path)
                sizeLabel = DiskUsage.formatBytes(bytes)
                cacheSize = sizeLabel
            }

            let alert = NSAlert()
            alert.messageText = L10n.t("清除构建设置缓存？")
            alert.informativeText = """
                将删除 \(path.path)。

                当前大小：\(sizeLabel)
                下次构建会自动重建。
                """
            alert.alertStyle = .warning
            alert.addButton(withTitle: L10n.t("清除"))
            alert.addButton(withTitle: L10n.t("取消"))
            guard alert.runModal() == .alertFirstButtonReturn else { return }

            try? FileManager.default.removeItem(at: path)
            cacheSize = DiskUsage.formatBytes(0)
        }
    }

    private func reveal(_ url: URL) {
        let parent = url.deletingLastPathComponent()
        if FileManager.default.fileExists(atPath: url.path) {
            NSWorkspace.shared.activateFileViewerSelecting([url])
        } else if FileManager.default.fileExists(atPath: parent.path) {
            NSWorkspace.shared.open(parent)
        } else {
            NSWorkspace.shared.open(url.deletingLastPathComponent())
        }
    }
}

// MARK: - Derived Data 位置表（对齐 Xcode 弹层）

private struct DerivedDataLocationSheet: View {
    @Binding var location: DerivedDataLocation
    @Binding var customRootPath: String
    var onDismiss: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 8) {
                Text(L10n.t("Derived Data 位置"))
                    .font(.headline)
                Spacer()
                Picker("", selection: $location) {
                    ForEach(DerivedDataLocation.allCases) { loc in
                        Text(loc.menuTitle).tag(loc)
                    }
                }
                .labelsHidden()
                .pickerStyle(.menu)
                .fixedSize()
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
            .padding(.bottom, 12)

            Divider()

            HStack(alignment: .center, spacing: 6) {
                Text(displayedPath)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                    .truncationMode(.middle)
                    .textSelection(.enabled)
                    .frame(maxWidth: .infinity, alignment: .leading)

                Button {
                    revealCurrent()
                } label: {
                    Image(systemName: "arrow.forward.circle.fill")
                        .symbolRenderingMode(.hierarchical)
                        .foregroundStyle(.tint)
                }
                .buttonStyle(.borderless)
                .help(L10n.t("在 Finder 中显示"))

                if location == .custom {
                    Button {
                        chooseCustomFolder()
                    } label: {
                        Image(systemName: "folder")
                    }
                    .buttonStyle(.borderless)
                    .help(L10n.t("选择自定义目录"))
                }
            }
            .padding(16)

            HStack {
                Spacer()
                Button(L10n.t("完成")) { onDismiss() }
                    .keyboardShortcut(.defaultAction)
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 14)
        }
        .frame(width: 460)
    }

    private var displayedPath: String {
        switch location {
        case .default:
            return ProjectService.xcodeDefaultDerivedDataRoot.path
        case .custom:
            return customRootPath
        }
    }

    private func revealCurrent() {
        let url = URL(fileURLWithPath: displayedPath, isDirectory: true)
        if FileManager.default.fileExists(atPath: url.path) {
            NSWorkspace.shared.activateFileViewerSelecting([url])
        } else {
            NSWorkspace.shared.open(url.deletingLastPathComponent())
        }
    }

    private func chooseCustomFolder() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.canCreateDirectories = true
        panel.directoryURL = URL(fileURLWithPath: customRootPath, isDirectory: true)
        panel.message = L10n.t("选择 Derived Data 根目录")
        panel.prompt = L10n.t("选择")
        NSApp.activate(ignoringOtherApps: true)
        guard panel.runModal() == .OK, let url = panel.url else { return }
        customRootPath = url.path
        location = .custom
    }
}

// MARK: - DiskUsage
//
// 体积计算已迁到 Core/Service/DerivedDataReaper.swift：回收器扫描时也要逐目录算大小，
// 两处各留一份实现迟早会分叉。
