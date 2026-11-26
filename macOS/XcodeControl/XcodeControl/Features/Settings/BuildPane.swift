//
//  BuildPane.swift
//  XcodeControl
//

import SwiftUI

/// 构建：控制台附着、失败时自动展开日志。
///
/// DerivedData 位置已迁到「位置」页（对齐 Xcode Locations）。
struct BuildPane: View {

    @Environment(AppState.self) private var state

    var body: some View {
        let prefs = state.prefs

        Form {
            Section(L10n.t("构建")) {
                Toggle(L10n.t("附着控制台输出"), isOn: Binding(
                    get: { prefs.attachConsole },
                    set: { prefs.attachConsole = $0 }
                ))
                Text(L10n.t("附着后可在日志面板看到 App 的实时输出，代价是拿不到进程 PID。关闭则以分离方式启动。"))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section(L10n.t("失败处理")) {
                Toggle(L10n.t("构建失败时自动展开日志"), isOn: Binding(
                    get: { prefs.autoExpandLogOnFailure },
                    set: { prefs.autoExpandLogOnFailure = $0 }
                ))
                Text(L10n.t("失败后日志面板自动弹出，方便立刻看到错误。"))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
    }
}
