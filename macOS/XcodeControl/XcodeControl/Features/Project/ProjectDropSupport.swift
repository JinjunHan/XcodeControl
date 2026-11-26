//
//  ProjectDropSupport.swift
//  XcodeControl
//

import AppKit
import SwiftUI
import UniformTypeIdentifiers

/// 从 Finder 拖入的 fileURL 解析与接入。
///
/// 浮窗引导、主界面、设置 › 项目共用这一套，避免各处各写一份 `loadObject`。
enum ProjectDropSupport {

    /// 同步返回是否接受拖放；实际导入在后台 Task 里完成。
    @MainActor
    static func handle(_ providers: [NSItemProvider], state: AppState) -> Bool {
        let usable = providers.filter {
            $0.hasItemConformingToTypeIdentifier(UTType.fileURL.identifier)
        }
        guard !usable.isEmpty else { return false }

        Task { @MainActor in
            var urls: [URL] = []
            for provider in usable {
                if let url = await loadFileURL(from: provider) {
                    urls.append(url)
                }
            }
            guard !urls.isEmpty else { return }
            _ = await state.importDroppedURLs(urls)
        }
        return true
    }

    /// 设置页等需要知道导入结果时用。
    @MainActor
    static func importURLs(from providers: [NSItemProvider], state: AppState) async -> (added: Int, activated: Bool) {
        var urls: [URL] = []
        for provider in providers where provider.hasItemConformingToTypeIdentifier(UTType.fileURL.identifier) {
            if let url = await loadFileURL(from: provider) {
                urls.append(url)
            }
        }
        guard !urls.isEmpty else { return (0, false) }
        return await state.importDroppedURLs(urls)
    }

    private static func loadFileURL(from provider: NSItemProvider) async -> URL? {
        await withCheckedContinuation { continuation in
            _ = provider.loadObject(ofClass: URL.self) { object, _ in
                continuation.resume(returning: object)
            }
        }
    }
}

/// 接受工程文件 / 文件夹拖放，悬停时可选高亮。
struct ProjectFileDropArea: ViewModifier {

    @Environment(AppState.self) private var state
    @Binding var isTargeted: Bool
    var onImported: ((Int) -> Void)? = nil

    func body(content: Content) -> some View {
        content
            .onDrop(of: [.fileURL], isTargeted: $isTargeted) { providers in
                if let onImported {
                    Task { @MainActor in
                        let result = await ProjectDropSupport.importURLs(from: providers, state: state)
                        onImported(result.added)
                    }
                    return providers.contains {
                        $0.hasItemConformingToTypeIdentifier(UTType.fileURL.identifier)
                    }
                }
                return ProjectDropSupport.handle(providers, state: state)
            }
    }
}

extension View {
    func projectFileDrop(isTargeted: Binding<Bool>, onImported: ((Int) -> Void)? = nil) -> some View {
        modifier(ProjectFileDropArea(isTargeted: isTargeted, onImported: onImported))
    }
}
