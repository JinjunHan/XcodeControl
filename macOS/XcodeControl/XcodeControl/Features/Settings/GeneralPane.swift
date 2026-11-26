//
//  GeneralPane.swift
//  XcodeControl
//

import AppKit
import SwiftUI

/// 通用：启动、浮窗外观与日志缓冲。
///
/// 「重置窗口位置」删掉持久化的左上角后按默认位置重新摆放——
/// 外接屏拔掉后浮窗跑到不可见区域时的自救出口。
struct GeneralPane: View {

    @Environment(AppState.self) private var state
    @State private var dimmedOpacity: Double
    @State private var logCapacityText: String
    @State private var launchAtLogin = LaunchAtLogin.isEnabled
    @State private var launchAtLoginError: String?

    init() {
        // 用 @State 缓冲 Slider 的拖动值，否则 .onChange 背压不过来
        let prefs = Preferences()
        _dimmedOpacity = State(initialValue: prefs.dimmedOpacity)
        _logCapacityText = State(initialValue: String(prefs.logCapacity))
    }

    var body: some View {
        let prefs = state.prefs

        Form {
            Section(L10n.t("语言")) {
                Picker(L10n.t("界面语言"), selection: Binding<AppLanguage?>(
                    get: { prefs.appLanguage },
                    set: { state.setLanguage($0) }
                )) {
                    Text(L10n.t("跟随系统")).tag(nil as AppLanguage?)
                    ForEach(AppLanguage.allCases) { language in
                        Text(language.endonym).tag(Optional(language))
                    }
                }
            }

            Section {
                Toggle(L10n.t("开机自启动"), isOn: Binding(
                    get: { launchAtLogin },
                    set: { setLaunchAtLogin($0) }
                ))

                if LaunchAtLogin.needsApproval || launchAtLoginError != nil {
                    HStack(alignment: .top, spacing: 8) {
                        Text(launchAtLoginError ?? L10n.t("需要在系统设置中允许登录项。"))
                            .font(.caption)
                            .foregroundStyle(.orange)
                        Spacer(minLength: 8)
                        Button(L10n.t("打开系统设置")) {
                            LaunchAtLogin.openLoginItemsSettings()
                        }
                        .font(.caption)
                    }
                }

                Toggle(L10n.t("启动时显示浮窗"), isOn: Binding(
                    get: { prefs.showPanelOnLaunch },
                    set: { prefs.showPanelOnLaunch = $0 }
                ))

                Toggle(L10n.t("启动时打开设置"), isOn: Binding(
                    get: { prefs.showSettingsOnLaunch },
                    set: { prefs.showSettingsOnLaunch = $0 }
                ))
            } header: {
                Text(L10n.t("启动"))
            } footer: {
                Text(L10n.t("开机自启动由系统「登录项」管理；首次开启可能需要你在系统设置里确认。"))
            }

            Section(L10n.t("浮窗")) {
                Toggle(L10n.t("显示 Git 分支"), isOn: Binding(
                    get: { prefs.showGitBranch },
                    set: { state.setShowsGitBranch($0) }
                ))

                Toggle(L10n.t("失焦时降低不透明度"), isOn: Binding(
                    get: { prefs.dimOnResign },
                    set: { prefs.dimOnResign = $0 }
                ))

                LabeledContent(L10n.t("不透明度")) {
                    HStack(spacing: 10) {
                        Slider(value: $dimmedOpacity, in: 0.3...1.0, step: 0.01)
                            .frame(width: 160)
                        Text("\(Int((dimmedOpacity * 100).rounded()))%")
                            .font(.body.monospacedDigit())
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                            .fixedSize()
                    }
                }
                .onChange(of: dimmedOpacity) { _, newValue in
                    prefs.dimmedOpacity = newValue
                }

                Button(L10n.t("重置窗口位置")) {
                    let key = DefaultsKey.panelTopLeft
                    UserDefaults.standard.removeObject(forKey: key)
                    // 触发 FloatingPanel 用默认位置重建
                    if let panel = NSApp.windows.compactMap({ $0 as? FloatingPanel }).first {
                        let size = panel.contentRect(forFrameRect: panel.frame).size
                        let newFrame = PanelPosition.defaultFrame(size: size)
                        panel.setFrame(newFrame, display: true)
                    }
                }
            }

            Section(L10n.t("日志")) {
                LabeledContent(L10n.t("缓冲行数")) {
                    HStack(spacing: 6) {
                        TextField("", text: $logCapacityText)
                            .labelsHidden()
                            .textFieldStyle(.roundedBorder)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 72)
                        Stepper(
                            "",
                            value: Binding(
                                get: { prefs.logCapacity },
                                set: { prefs.logCapacity = $0; logCapacityText = String($0) }
                            ),
                            in: 100...50000,
                            step: 100
                        )
                        .labelsHidden()
                    }
                }
                .onChange(of: logCapacityText) { _, newValue in
                    if let v = Int(newValue), v >= 100 {
                        prefs.logCapacity = v
                    }
                }
                .onSubmit {
                    if let v = Int(logCapacityText), v >= 100 {
                        prefs.logCapacity = v
                    } else {
                        logCapacityText = String(prefs.logCapacity)
                    }
                }

                Text(L10n.t("超出后丢弃最旧的行。"))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

        }
        .formStyle(.grouped)
        .onAppear {
            launchAtLogin = LaunchAtLogin.isEnabled
            launchAtLoginError = nil
        }
    }

    private func setLaunchAtLogin(_ enabled: Bool) {
        do {
            launchAtLogin = try LaunchAtLogin.setEnabled(enabled)
            if enabled && !launchAtLogin {
                launchAtLoginError = L10n.t("已申请开机自启，请在系统设置 › 通用 › 登录项中允许。")
                LaunchAtLogin.openLoginItemsSettings()
            } else {
                launchAtLoginError = nil
            }
        } catch {
            launchAtLogin = LaunchAtLogin.isEnabled
            launchAtLoginError = error.localizedDescription
        }
    }
}
