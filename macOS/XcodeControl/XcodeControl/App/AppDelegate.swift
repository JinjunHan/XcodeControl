//
//  AppDelegate.swift
//  XcodeControl
//

import AppKit
import Sparkle
import SwiftUI

/// 悬浮窗的生命周期宿主。
///
/// 静态 `instance` 让设置页的 BehaviorPane 能触发 `hotKeys?.reload`。
/// 这是在一个 SwiftUI `@Environment` 只能注入 `Observable`、而
/// `HotKeyCenter` 不应该是 `@Observable` 的前提下的折中。
@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {

    static private(set) weak var instance: AppDelegate?

    private(set) var panel: FloatingPanel?
    private(set) var hotKeys: HotKeyCenter?
    let state = AppState()
    private let updaterController = SPUStandardUpdaterController(
        startingUpdater: true,
        updaterDelegate: nil,
        userDriverDelegate: nil
    )
    private lazy var settingsWindow = SettingsWindowController(state: state)
    private var frameObserver: NSObjectProtocol?
    private var resizeObserver: NSObjectProtocol?
    private var keyObservers: [NSObjectProtocol] = []

    func applicationDidFinishLaunching(_ notification: Notification) {
        Self.instance = self

        NSApp.setActivationPolicy(.regular)
        state.showSettingsHandler = { [weak self] in self?.settingsWindow.present() }

        let initialSize = NSSize(
            width: Theme.Metrics.panelWidth,
            height: Theme.Metrics.onboardingHeight
        )
        let panel = FloatingPanel(contentRect: PanelPosition.restore(size: initialSize))

        // 绝不用 `.preferredContentSize`：它会在 windowDidLayout 里同步
        // updateAnimatedWindowSize → 与 Auto Layout 无限递归栈溢出。
        // 改由根视图量理想尺寸，再走 FloatingPanel.applyContentSize。
        // 浮窗的语言跟随：把 state.language 读在这里会把 AppDelegate 也拖进
        // observation，因此交给一个小包装视图在 SwiftUI 内部读。
        let root = LocalizedFloatingRoot(state: state) { [weak panel] size in
            panel?.applyContentSize(NSSize(width: size.width, height: size.height))
        }
        .environment(state)

        // AppKit owns the window size. The host fills its bounds; the SwiftUI
        // content reports its ideal height independently inside that space.
        let host = NSHostingView(rootView: root)
        host.sizingOptions = []
        if let container = panel.contentView {
            host.frame = container.bounds
            host.autoresizingMask = [.width, .height]
            container.addSubview(host)
        }
        panel.onEscape = { [weak self] in
            withAnimation(Motion.panel) { self?.state.openPanel = .none }
        }

        // 浮窗可见性由用户配置决定
        if state.prefs.showPanelOnLaunch {
            panel.orderFrontRegardless()
        }
        self.panel = panel

        // 菜单栏镜像通过 AppState 显隐浮窗，不直接持有 panel。
        state.showFloatingPanelHandler = { [weak self] in
            self?.panel?.orderFrontRegardless()
        }
        state.hideFloatingPanelHandler = { [weak self] in
            self?.panel?.orderOut(nil)
        }
        state.checkForUpdatesHandler = { [weak self] in
            self?.updaterController.checkForUpdates(nil)
        }

        // 全局快捷键：注册完成后注入 state，设置页据此显示占用状态。
        let hotKeys = HotKeyCenter(state: state)
        hotKeys.reload(prefs: state.prefs)
        self.hotKeys = hotKeys
        state.hotKeys = hotKeys

        observeWindow(panel)
        Task { await state.bootstrap() }

        if state.prefs.showSettingsOnLaunch {
            state.openSettings()
        }
    }

    func applicationWillTerminate(_ notification: Notification) {
        if let panel { PanelPosition.save(panel.frame) }
        state.shutdown()
        if let frameObserver { NotificationCenter.default.removeObserver(frameObserver) }
        if let resizeObserver { NotificationCenter.default.removeObserver(resizeObserver) }
        for observer in keyObservers { NotificationCenter.default.removeObserver(observer) }
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        state.openSettings()
        return false
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool { false }

    // MARK: - 私有

    private func observeWindow(_ panel: FloatingPanel) {
        // 移动与改变尺寸都要记：内容高度变化时窗口可能被挤离屏幕边缘而上移，
        // 只监听 didMove 会漏掉这次调整。
        frameObserver = NotificationCenter.default.addObserver(
            forName: NSWindow.didMoveNotification,
            object: panel,
            queue: .main
        ) { note in
            guard let window = note.object as? NSWindow else { return }
            MainActor.assumeIsolated { PanelPosition.save(window.frame) }
        }
        resizeObserver = NotificationCenter.default.addObserver(
            forName: NSWindow.didResizeNotification,
            object: panel,
            queue: .main
        ) { note in
            guard let window = note.object as? NSWindow else { return }
            MainActor.assumeIsolated { PanelPosition.save(window.frame) }
        }

        let becameKey = NotificationCenter.default.addObserver(
            forName: NSWindow.didBecomeKeyNotification,
            object: panel,
            queue: .main
        ) { [weak self] _ in
            MainActor.assumeIsolated { self?.state.isKeyWindow = true }
        }
        let resignedKey = NotificationCenter.default.addObserver(
            forName: NSWindow.didResignKeyNotification,
            object: panel,
            queue: .main
        ) { [weak self] _ in
            MainActor.assumeIsolated {
                self?.state.isKeyWindow = false
                withAnimation(Motion.panel) { self?.state.openPanel = .none }
            }
        }
        keyObservers = [becameKey, resignedKey]
    }
}
