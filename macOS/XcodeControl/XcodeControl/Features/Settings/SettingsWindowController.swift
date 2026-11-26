import AppKit
import SwiftUI

@MainActor
final class SettingsWindowController: NSWindowController {
    init(state: AppState) {
        let host = NSHostingController(rootView: SettingsRoot(state: state))
        let window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 900, height: 548),
                              styleMask: [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView],
                              backing: .buffered, defer: false)
        window.title = "XcodeControl"
        window.titleVisibility = .hidden
        window.toolbarStyle = .unified
        window.toolbar = NSToolbar(identifier: "SettingsTitleBar")
        window.titlebarSeparatorStyle = .none
        window.titlebarAppearsTransparent = true
        window.contentViewController = host
        window.contentMinSize = NSSize(width: 720, height: 460)
        window.isReleasedWhenClosed = false
        window.center()
        window.setFrameAutosaveName("XcodeControlSettings")
        super.init(window: window)
    }

    required init?(coder: NSCoder) { nil }

    func present() {
        guard let window else { return }
        NSApp.unhide(nil)
        NSApp.activate(ignoringOtherApps: true)
        if window.isMiniaturized { window.deminiaturize(nil) }
        window.makeKeyAndOrderFront(nil)
    }
}

private struct SettingsRoot: View {
    let state: AppState

    var body: some View {
        SettingsView()
            .environment(state)
            .localized(state.language)
    }
}
