//
//  XcodeControlApp.swift
//  XcodeControl
//

import SwiftUI

@main
struct XcodeControlApp: App {

    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        // 菜单栏标题不进译表：它是产品名，各语言都写 XcodeControl。
        MenuBarExtra("XcodeControl", systemImage: "hammer.fill") {
            MenuBarMenu()
                .environment(appDelegate.state)
                .localized(appDelegate.state.language)
        }
        .menuBarExtraStyle(.menu)
        .commands {
            CommandGroup(replacing: .appSettings) {
                Button(L10n.t("设置")) { appDelegate.state.openSettings() }
                    .keyboardShortcut(",", modifiers: .command)
            }
        }
    }
}
