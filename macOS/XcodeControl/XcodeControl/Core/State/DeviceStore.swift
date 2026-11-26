//
//  DeviceStore.swift
//  XcodeControl
//

import Foundation
import Observation

/// 设备列表与当前选中的运行目标。
///
/// 启动时全量拉取一次，打开设备面板时按需刷新。
@MainActor
@Observable
final class DeviceStore {

    private(set) var destinations: [RunDestination] = []
    private(set) var isRefreshing = false
    private(set) var lastError: String?

    var selectedID: String?
    var searchText: String = ""

    var selected: RunDestination? {
        guard let selectedID else { return nil }
        return destinations.first { $0.id == selectedID }
    }

    /// 列表中超过 12 项时才显示搜索框
    var showsSearchField: Bool { destinations.count > 12 }

    var filtered: [RunDestination] {
        let keyword = searchText.trimmingCharacters(in: .whitespaces)
        guard !keyword.isEmpty else { return destinations }
        return destinations.filter {
            $0.name.localizedCaseInsensitiveContains(keyword)
                || $0.osVersion.localizedCaseInsensitiveContains(keyword)
        }
    }

    var groupedSections: [(source: RunDestination.Source, groups: [DeviceService.Group])] {
        DeviceService.grouped(filtered)
    }

    // MARK: - 刷新

    func refresh(includeMac: Bool = true) async {
        guard !isRefreshing else { return }
        isRefreshing = true
        defer { isRefreshing = false }

        let (loaded, error) = await DeviceService.loadAll(includeMac: includeMac)
        destinations = loaded.sorted(by: RunDestination.displayOrder)
        lastError = error

        // 选中的设备消失了：回落到第一个可用目标
        if let selectedID, !destinations.contains(where: { $0.id == selectedID }) {
            self.selectedID = defaultSelection()?.id
        } else if selectedID == nil {
            selectedID = defaultSelection()?.id
        }
    }

    /// 优先已启动的模拟器 / 已连接的真机，其次任意 iPhone 模拟器。
    private func defaultSelection() -> RunDestination? {
        destinations.first { $0.source == .device && $0.state == .connected }
            ?? destinations.first { $0.source == .simulator && $0.state == .booted }
            ?? destinations.first { $0.source == .simulator && $0.deviceFamily == .phone }
            ?? destinations.first { $0.source == .simulator }
            ?? destinations.first
    }

    /// 恢复项目记住的设备；若已不存在则保持当前选择。
    func restoreSelection(_ destinationID: String?) {
        guard let destinationID, destinations.contains(where: { $0.id == destinationID }) else {
            if selectedID == nil { selectedID = defaultSelection()?.id }
            return
        }
        selectedID = destinationID
    }
}
