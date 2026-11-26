//
//  SettingsTab.swift
//  XcodeControl
//

import Foundation

/// 设置页分栏。图标选接近 Xcode Settings 侧栏那一套 SF Symbol。
///
/// `allCases` 顺序即侧栏顺序：项目 → 通用 → 构建 → …
enum SettingsTab: String, CaseIterable, Identifiable, Hashable {
    case project
    case general
    case build
    case behavior
    case locations
    case about

    var id: String { rawValue }

    var title: String {
        switch self {
        case .general: L10n.t("通用")
        case .project: L10n.t("项目")
        case .build: L10n.t("构建")
        case .behavior: L10n.t("行为")
        case .locations: L10n.t("位置")
        case .about: L10n.t("关于")
        }
    }

    var systemImage: String {
        switch self {
        case .general: "gearshape"
        case .project: "folder"
        case .build: "hammer"
        case .behavior: "bell"
        case .locations: "internaldrive"
        case .about: "info.circle"
        }
    }
}
