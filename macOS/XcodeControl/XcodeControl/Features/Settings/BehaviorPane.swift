//
//  BehaviorPane.swift
//  XcodeControl
//

import AppKit
import SwiftUI

/// 行为：构建结果通知、全局快捷键。
///
/// 通知与声音是两个正交开关：可以只响不弹。
/// 权限不在启动时申请——用户第一次打开任一通知开关时才 requestAuthorization。
///
/// 快捷键录制用 Carbon 虚拟键码；注册失败（组合被占用）时就地显示提示，
/// 不静默失败。
struct BehaviorPane: View {

    @Environment(AppState.self) private var state
    @Environment(\.openWindow) private var openWindow

    // 快捷键录制状态：非 nil 时正在录制某个 action
    @State private var recording: HotKeyCenter.Action?

    var body: some View {
        let prefs = state.prefs

        Form {
            Section(L10n.t("构建成功时")) {
                notifToggle(L10n.t("发送通知"),
                            get: { prefs.notifyOnSuccess },
                            set: { prefs.notifyOnSuccess = $0 })
                Toggle(L10n.t("播放声音"), isOn: Binding(
                    get: { prefs.soundOnSuccess },
                    set: { prefs.soundOnSuccess = $0 }
                ))
            }

            Section(L10n.t("构建失败时")) {
                notifToggle(L10n.t("发送通知"),
                            get: { prefs.notifyOnFailure },
                            set: { prefs.notifyOnFailure = $0 })
                Toggle(L10n.t("播放声音"), isOn: Binding(
                    get: { prefs.soundOnFailure },
                    set: { prefs.soundOnFailure = $0 }
                ))
            }

            Section(L10n.t("全局快捷键")) {
                Toggle(L10n.t("启用"), isOn: Binding(
                    get: { prefs.hotKeysEnabled },
                    set: {
                        prefs.hotKeysEnabled = $0
                    }
                ))
                .onChange(of: prefs.hotKeysEnabled) { _, _ in
                    AppDelegate.instance?.hotKeys?.reload(prefs: prefs)
                }

                hotKeyRow(
                    label: L10n.t("运行"),
                    keyCode: Binding(
                        get: { prefs.hotKeyRunKeyCode },
                        set: { prefs.hotKeyRunKeyCode = $0 }
                    ),
                    modifiers: Binding(
                        get: { prefs.hotKeyRunModifiers },
                        set: { prefs.hotKeyRunModifiers = $0 }
                    ),
                    action: .run,
                    failed: prefs.hotKeysEnabled && state.hotKeys?.failedActions.contains(.run) ?? false
                )

                hotKeyRow(
                    label: L10n.t("停止"),
                    keyCode: Binding(
                        get: { prefs.hotKeyStopKeyCode },
                        set: { prefs.hotKeyStopKeyCode = $0 }
                    ),
                    modifiers: Binding(
                        get: { prefs.hotKeyStopModifiers },
                        set: { prefs.hotKeyStopModifiers = $0 }
                    ),
                    action: .stop,
                    failed: prefs.hotKeysEnabled && state.hotKeys?.failedActions.contains(.stop) ?? false
                )

                Text(L10n.t("浮窗隐藏时同样生效。"))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
        // 录制快捷键时监听全局按键
        .onKeyDown(recording != nil) { event in
            handleRecording(event)
        }
    }

    // MARK: - 通知开关（含权限申请）

    private func notifToggle(_ label: String, get: @escaping () -> Bool, set: @escaping (Bool) -> Void) -> some View {
        Toggle(label, isOn: Binding(
            get: get,
            set: { newValue in
                if newValue {
                    Task {
                        let ok = await state.notifications.requestAuthorizationIfNeeded()
                        await MainActor.run {
                            if !ok {
                                // 用户拒绝授权——打开系统通知设置
                                showPermissionAlert()
                                set(false)
                            } else {
                                set(true)
                            }
                        }
                    }
                } else {
                    set(false)
                }
            }
        ))
    }

    private func showPermissionAlert() {
        let alert = NSAlert()
        alert.messageText = L10n.t("需要通知权限")
        alert.informativeText = L10n.t("系统拒绝了通知权限。请在系统设置中为 XcodeControl 开启通知，然后再试。")
        alert.alertStyle = .warning
        alert.addButton(withTitle: L10n.t("打开系统设置"))
        alert.addButton(withTitle: L10n.t("取消"))
        if alert.runModal() == .alertFirstButtonReturn {
            NSWorkspace.shared.open(
                URL(string: "x-apple.systempreferences:com.apple.preference.notifications")!
            )
        }
    }

    // MARK: - 快捷键行

    private func hotKeyRow(
        label: String,
        keyCode: Binding<UInt32>,
        modifiers: Binding<UInt32>,
        action: HotKeyCenter.Action,
        failed: Bool
    ) -> some View {
        HStack {
            Text(label)
                .frame(width: 40, alignment: .leading)

            let combo = HotKeyCenter.Combo(keyCode: keyCode.wrappedValue,
                                            modifiers: modifiers.wrappedValue)

            Button(combo.displayString) {
                startRecording(action)
            }
            .buttonStyle(.bordered)
            .overlay(
                // 录制中加蓝色边框
                Group {
                    if recording == action {
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(Color.accentColor, lineWidth: 2)
                    }
                }
            )

            // 组合已被占用，给可执行的下一步
            if failed {
                Text(L10n.t("已被占用"))
                    .foregroundStyle(.red)
                    .font(.caption)
                Button(L10n.t("清除")) {
                    keyCode.wrappedValue = 0
                    modifiers.wrappedValue = 0
                    AppDelegate.instance?.hotKeys?.reload(prefs: state.prefs)
                }
                .buttonStyle(.borderless)
                .font(.caption)
            }
        }
    }

    // MARK: - 录制

    private func startRecording(_ action: HotKeyCenter.Action) {
        // 已在录制同一个 action 则取消（相当于 Esc）
        if recording == action {
            recording = nil
            return
        }
        recording = action
    }

    private func handleRecording(_ event: NSEvent) {
        guard let action = recording else { return }
        let prefs = state.prefs

        // Esc 取消录制
        if event.keyCode == 53 {
            recording = nil
            return
        }

        guard let combo = HotKeyCenter.Combo(event: event) else {
            // 无修饰键的组合会把普通打字全部劫持——不录制
            return
        }

        // 写入配置
        switch action {
        case .run:
            prefs.hotKeyRunKeyCode = combo.keyCode
            prefs.hotKeyRunModifiers = combo.modifiers
        case .stop:
            prefs.hotKeyStopKeyCode = combo.keyCode
            prefs.hotKeyStopModifiers = combo.modifiers
        }

        // 重注册
        AppDelegate.instance?.hotKeys?.reload(prefs: prefs)
        recording = nil
    }
}

// MARK: - 按键监听

private struct KeyDownModifier: ViewModifier {

    let enabled: Bool
    let handler: (NSEvent) -> Void

    func body(content: Content) -> some View {
        content
            .onAppear {
                guard enabled else { return }
                installMonitor()
            }
            .onChange(of: enabled) { _, newValue in
                if newValue {
                    installMonitor()
                } else {
                    removeMonitor()
                }
            }
            .onDisappear { removeMonitor() }
    }

    @State private var monitor: Any?

    private func installMonitor() {
        removeMonitor()
        monitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            handler(event)
            // 吃掉事件，避免 Esc 或其它按键在设置窗口里产生副作用
            return nil
        }
    }

    private func removeMonitor() {
        if let monitor { NSEvent.removeMonitor(monitor); self.monitor = nil }
    }
}

extension View {
    func onKeyDown(_ enabled: Bool, handler: @escaping (NSEvent) -> Void) -> some View {
        modifier(KeyDownModifier(enabled: enabled, handler: handler))
    }
}
