//
//  DeviceService.swift
//  XcodeControl
//

import Foundation

/// 设备枚举：合并模拟器、真机与本机 Mac。
enum DeviceService {

    /// 全量拉取。真机枚举失败不应影响模拟器列表——例如未安装 devicectl 的旧环境。
    static func loadAll(includeMac: Bool) async -> (destinations: [RunDestination], deviceError: String?) {
        async let simulators = loadSimulators()
        async let devices = loadDevices()

        let (sims, simError) = await simulators
        let (physical, deviceError) = await devices

        var all = physical + sims
        if includeMac {
            all.append(.localMac())
        }
        return (all, deviceError ?? simError)
    }

    private static func loadSimulators() async -> ([RunDestination], String?) {
        do {
            return (try await SimctlAdapter.listDevices(), nil)
        } catch {
            return ([], error.localizedDescription)
        }
    }

    private static func loadDevices() async -> ([RunDestination], String?) {
        do {
            return (try await DevicectlAdapter.listDevices(), nil)
        } catch {
            // devicectl 不可用不是致命错误，静默降级为「没有真机」
            return ([], nil)
        }
    }

    /// 按 (来源, 设备族) 分组，用于下拉面板。
    struct Group: Identifiable {
        let source: RunDestination.Source
        let family: RunDestination.Family
        let destinations: [RunDestination]

        var id: String { "\(source.rawValue)-\(family.rawValue)" }
        var title: String { family.sectionTitle }
    }

    static func grouped(_ destinations: [RunDestination]) -> [(source: RunDestination.Source, groups: [Group])] {
        let bySource = Dictionary(grouping: destinations, by: \.source)
        return bySource.keys
            .sorted { $0.sortOrder < $1.sortOrder }
            .compactMap { source in
                guard let items = bySource[source], !items.isEmpty else { return nil }
                let byFamily = Dictionary(grouping: items, by: \.deviceFamily)
                let groups = byFamily.keys
                    .sorted { $0.sortOrder < $1.sortOrder }
                    .map { family in
                        Group(
                            source: source,
                            family: family,
                            destinations: (byFamily[family] ?? []).sorted(by: RunDestination.displayOrder)
                        )
                    }
                return (source, groups)
            }
    }
}
