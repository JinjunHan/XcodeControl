//
//  HotKeyCenter.swift
//  XcodeControl
//

import AppKit
import Carbon.HIToolbox

/// 全局快捷键注册。
///
/// 用 Carbon 的 `RegisterEventHotKey` 而不是 `NSEvent.addGlobalMonitorForEvents`
/// 或 `CGEventTap`：后两者要监听**所有**按键，因此系统要求辅助功能授权
/// （`AXIsProcessTrusted`）；而 `RegisterEventHotKey` 是把某一个组合注册给窗口
/// 服务器、只回投这一个组合的事件，不触碰其它按键，**无需任何授权**。
///
/// 设计文档第 10 节「若实现全局快捷键，需要辅助功能权限」是针对前两条路径的，
/// 对这条不成立——因此整套权限引导与拒绝后的降级路径都省掉了。
@MainActor
final class HotKeyCenter {

    /// 一个待注册的组合。keyCode 是 Carbon 虚拟键码，modifiers 是 Carbon 修饰键掩码。
    struct Combo: Equatable {
        var keyCode: UInt32
        var modifiers: UInt32

        var isEmpty: Bool { keyCode == 0 && modifiers == 0 }
    }

    enum Action: UInt32 {
        case run = 1
        case stop = 2
    }

    /// 注册失败的组合——设置页据此就地显示「已被占用」。
    private(set) var failedActions: Set<Action> = []

    private var handlers: [Action: EventHotKeyRef] = [:]
    private var eventHandler: EventHandlerRef?
    private weak var state: AppState?

    private static let signature: OSType = {
        // 'XCCH' —— 四字符码，用于区分本应用注册的热键
        let chars: [UInt8] = Array("XCCH".utf8)
        return (OSType(chars[0]) << 24) | (OSType(chars[1]) << 16)
            | (OSType(chars[2]) << 8) | OSType(chars[3])
    }()

    init(state: AppState) {
        self.state = state
        installEventHandler()
    }

    deinit {
        // deinit 不能跳 actor，Carbon 的注销是线程安全的 C 调用，直接做。
        for (_, ref) in handlers { UnregisterEventHotKey(ref) }
        if let eventHandler { RemoveEventHandler(eventHandler) }
    }

    // MARK: - 生命周期

    /// 按当前配置重新注册全部热键。开关或组合改变时调用。
    func reload(prefs: Preferences) {
        unregisterAll()
        guard prefs.hotKeysEnabled else { return }

        register(
            .run,
            combo: Combo(keyCode: prefs.hotKeyRunKeyCode, modifiers: prefs.hotKeyRunModifiers)
        )
        register(
            .stop,
            combo: Combo(keyCode: prefs.hotKeyStopKeyCode, modifiers: prefs.hotKeyStopModifiers)
        )
    }

    func unregisterAll() {
        for (_, ref) in handlers { UnregisterEventHotKey(ref) }
        handlers.removeAll()
        failedActions.removeAll()
    }

    func shutdown() {
        unregisterAll()
        if let eventHandler {
            RemoveEventHandler(eventHandler)
            self.eventHandler = nil
        }
    }

    // MARK: - 注册

    private func register(_ action: Action, combo: Combo) {
        guard !combo.isEmpty else { return }

        var ref: EventHotKeyRef?
        let hotKeyID = EventHotKeyID(signature: Self.signature, id: action.rawValue)
        let status = RegisterEventHotKey(
            combo.keyCode,
            combo.modifiers,
            hotKeyID,
            GetApplicationEventTarget(),
            0,
            &ref
        )

        // 组合被系统或其它应用占用时返回非 noErr——记下来让设置页给出可执行提示，
        // 而不是静默失败（用户会以为快捷键坏了）。
        if status == noErr, let ref {
            handlers[action] = ref
            failedActions.remove(action)
        } else {
            failedActions.insert(action)
        }
    }

    private func installEventHandler() {
        var spec = EventTypeSpec(
            eventClass: OSType(kEventClassKeyboard),
            eventKind: UInt32(kEventHotKeyPressed)
        )
        let context = Unmanaged.passUnretained(self).toOpaque()

        InstallEventHandler(
            GetApplicationEventTarget(),
            { _, event, userData in
                guard let event, let userData else { return OSStatus(eventNotHandledErr) }

                var hotKeyID = EventHotKeyID()
                let status = GetEventParameter(
                    event,
                    EventParamName(kEventParamDirectObject),
                    EventParamType(typeEventHotKeyID),
                    nil,
                    MemoryLayout<EventHotKeyID>.size,
                    nil,
                    &hotKeyID
                )
                guard status == noErr, hotKeyID.signature == HotKeyCenter.signature else {
                    return OSStatus(eventNotHandledErr)
                }

                let center = Unmanaged<HotKeyCenter>.fromOpaque(userData).takeUnretainedValue()
                // Carbon 回调在主线程上跑，但编译器不知道——显式跳回 MainActor。
                MainActor.assumeIsolated {
                    center.handle(id: hotKeyID.id)
                }
                return noErr
            },
            1,
            &spec,
            context,
            &eventHandler
        )
    }

    private func handle(id: UInt32) {
        guard let action = Action(rawValue: id), let state else { return }
        switch action {
        case .run:
            // 与菜单栏「运行」一致：快捷键触发时把浮窗带回来，
            // 否则用户按下键却看不到任何反馈。
            state.showFloatingPanel()
            state.run.primaryAction()
        case .stop:
            state.run.stopAction()
        }
    }
}

// MARK: - 组合的显示与转换

extension HotKeyCenter.Combo {

    /// 「⌃⌥R」这样的可读文本
    var displayString: String {
        var result = ""
        if modifiers & UInt32(controlKey) != 0 { result += "⌃" }
        if modifiers & UInt32(optionKey) != 0 { result += "⌥" }
        if modifiers & UInt32(shiftKey) != 0 { result += "⇧" }
        if modifiers & UInt32(cmdKey) != 0 { result += "⌘" }
        result += Self.keyName(for: keyCode)
        return result
    }

    /// 从 NSEvent 转过来。Cocoa 与 Carbon 的修饰键掩码不是一套，要逐位翻译。
    init?(event: NSEvent) {
        var carbonModifiers: UInt32 = 0
        let flags = event.modifierFlags
        if flags.contains(.control) { carbonModifiers |= UInt32(controlKey) }
        if flags.contains(.option) { carbonModifiers |= UInt32(optionKey) }
        if flags.contains(.shift) { carbonModifiers |= UInt32(shiftKey) }
        if flags.contains(.command) { carbonModifiers |= UInt32(cmdKey) }

        // 不带修饰键的组合会把普通打字全部劫持，直接拒绝录制
        guard carbonModifiers != 0 else { return nil }

        self.init(keyCode: UInt32(event.keyCode), modifiers: carbonModifiers)
    }

    /// 虚拟键码 → 可读名。只覆盖录制得到的常见键，其余回落成十六进制。
    private static func keyName(for keyCode: UInt32) -> String {
        let map: [UInt32: String] = [
            0: "A", 11: "B", 8: "C", 2: "D", 14: "E", 3: "F", 5: "G", 4: "H",
            34: "I", 38: "J", 40: "K", 37: "L", 46: "M", 45: "N", 31: "O", 35: "P",
            12: "Q", 15: "R", 1: "S", 17: "T", 32: "U", 9: "V", 13: "W", 7: "X",
            16: "Y", 6: "Z",
            29: "0", 18: "1", 19: "2", 20: "3", 21: "4",
            23: "5", 22: "6", 26: "7", 28: "8", 25: "9",
            47: ".", 43: ",", 44: "/", 41: ";", 39: "'", 33: "[", 30: "]",
            42: "\\", 27: "-", 24: "=", 50: "`",
            49: L10n.t("空格"), 36: "↩", 48: "⇥", 51: "⌫", 53: "⎋",
            123: "←", 124: "→", 125: "↓", 126: "↑",
            122: "F1", 120: "F2", 99: "F3", 118: "F4", 96: "F5", 97: "F6",
            98: "F7", 100: "F8", 101: "F9", 109: "F10", 103: "F11", 111: "F12",
        ]
        return map[keyCode] ?? String(format: "0x%02X", keyCode)
    }
}
