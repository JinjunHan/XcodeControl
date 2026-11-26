//
//  LaunchAtLogin.swift
//  XcodeControl
//

import AppKit
import Foundation
import ServiceManagement

/// 开机自启动：以 `SMAppService` 为准，不另存 UserDefaults。
///
/// 注册失败常见原因是系统「登录项」权限未批——此时 `status == .requiresApproval`，
/// 需要引导用户去系统设置里打开。
enum LaunchAtLogin {

    static var isEnabled: Bool {
        SMAppService.mainApp.status == .enabled
    }

    /// `.requiresApproval` 表示已申请、等用户在系统设置里确认。
    static var needsApproval: Bool {
        SMAppService.mainApp.status == .requiresApproval
    }

    /// - Returns: 是否已真正启用（`.requiresApproval` 时返回 false）。
    @discardableResult
    static func setEnabled(_ enabled: Bool) throws -> Bool {
        if enabled {
            if SMAppService.mainApp.status == .enabled { return true }
            try SMAppService.mainApp.register()
        } else {
            if SMAppService.mainApp.status == .notRegistered { return false }
            try SMAppService.mainApp.unregister()
        }
        return SMAppService.mainApp.status == .enabled
    }

    static func openLoginItemsSettings() {
        SMAppService.openSystemSettingsLoginItems()
    }
}
