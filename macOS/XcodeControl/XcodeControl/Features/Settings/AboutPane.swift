//
//  AboutPane.swift
//  XcodeControl
//

import AppKit
import SwiftUI

/// 关于：版本号、Xcode 信息、链接。
///
/// `unverifiedXcodeNotice` 非空时在这里也显示一次——
/// 浮窗里它只在悬停时闪现（`FloatingRootView`），容易被错过。
struct AboutPane: View {

    @Environment(AppState.self) private var state

    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "—"
    }

    private var buildNumber: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "—"
    }

    var body: some View {
        Form {
            Section {
                VStack(spacing: 12) {
                    // AppIcon.appiconset 不能当普通命名图片用；另备小尺寸 AppLogo
                    Image("AppLogo")
                        .resizable()
                        .interpolation(.high)
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 48, height: 48)
                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

                    Text("XcodeControl")
                        .font(.title2)
                        .fontWeight(.semibold)

                    Text("\(appVersion) (Build \(buildNumber))")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
            }

            Section("Xcode") {
                if case .ready(let env) = state.environment {
                    HStack {
                        Text(L10n.t("版本"))
                        Spacer()
                        Text("\(env.xcodeVersion) (\(env.xcodeBuildNumber))")
                            .foregroundStyle(.secondary)
                            .textSelection(.enabled)
                    }
                    HStack {
                        Text(L10n.t("路径"))
                        Spacer()
                        Text(env.developerDir)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .textSelection(.enabled)
                    }
                } else {
                    Text(L10n.t("启动后获取"))
                        .foregroundStyle(.secondary)
                }

                if let notice = state.unverifiedXcodeNotice {
                    Text(notice)
                        .font(.caption)
                        .foregroundStyle(.orange)
                }
            }

            Section {
                HStack(spacing: 8) {
                    Spacer()

                    Button(L10n.t("检查更新…")) {
                        state.checkForUpdates()
                    }

                    Button(L10n.t("反馈问题")) {
                        NSWorkspace.shared.open(
                            URL(string: "https://github.com/JinjunHan/XcodeControl/issues")!
                        )
                    }
                }
            }
        }
        .formStyle(.grouped)
    }
}
