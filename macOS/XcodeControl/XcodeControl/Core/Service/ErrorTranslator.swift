//
//  ErrorTranslator.swift
//  XcodeControl
//

import Foundation

/// 把工具链的原始报错映射为一眼可读的中文提示。
///
/// 再好的摘要也会有失效的情况，因此调用方在无法翻译时应保留原文，
/// 并始终提供「查看完整日志」入口。
enum ErrorTranslator {

    /// `all` 中的片段必须全部出现，`any` 中只要命中一个即可。
    /// 两者分开是必要的——"Scheme" + "not currently configured" 是合取，
    /// 而同一种错误在不同工具下的措辞则是析取。
    private struct Rule {
        var all: [String] = []
        var any: [String] = []
        let message: String
    }

    private static let rules: [Rule] = [
        .init(any: ["The device is locked", "device was not, or could not be, unlocked", "passcode"],
              message: "设备已锁屏，请解锁后重试"),
        .init(any: ["ApplicationVerificationFailed", "Unable to install"],
              message: "安装被拒绝：签名与设备不匹配，检查 provisioning profile 是否包含该设备"),
        .init(any: ["This provisioning profile does not have devices"],
              message: "provisioning profile 未包含任何设备，请在开发者后台添加该设备"),
        .init(any: ["No profiles for", "requires a provisioning profile"],
              message: "缺少可用的 provisioning profile，请在 Xcode 中打开 Signing & Capabilities 配置自动签名"),
        .init(any: ["Code Signing Error", "code signing is required"],
              message: "签名失败：真机构建必须配置有效的签名证书与描述文件"),
        .init(any: ["No signing certificate", "no valid signing identity"],
              message: "找不到签名证书，请在 Xcode 的账户设置中登录并下载证书"),
        .init(any: ["The developer disk image could not be mounted", "DeveloperDiskImage"],
              message: "设备的开发者磁盘映像未挂载，通常重新插拔或重启设备可恢复"),
        .init(any: ["Developer Mode disabled", "developerModeStatus", "developer mode is not enabled"],
              message: "设备未开启「开发者模式」，请在 设置 › 隐私与安全性 › 开发者模式 中打开"),
        .init(any: ["device is not connected", "Could not find device", "no matching device", "tunnel"],
              message: "设备未连接或未信任本机，请检查连接后重试"),
        .init(any: ["cannot be located on disk", "is no longer present at"],
              message: "该模拟器的数据已丢失，请在 Xcode › Devices and Simulators 中删除后重建"),
        .init(any: ["Unable to boot device"],
              message: "模拟器无法启动，尝试在 Simulator 中执行 Device › Erase All Content and Settings"),
        .init(any: ["is not installed on", "Unable to lookup app"],
              message: "App 尚未安装到该设备，请重新运行一次"),
        .init(all: ["Scheme", "not currently configured for the"],
              message: "该 scheme 未配置当前 action，请检查 scheme 的 Build/Run 设置"),
        .init(any: ["does not contain a scheme named"],
              message: "工程中找不到该 scheme，可能已被重命名或未勾选 Shared"),
        .init(any: ["Unable to find a destination matching"],
              message: "找不到匹配的运行目标，设备可能已断开或模拟器已被删除"),
        .init(all: ["xcodebuild: error: The directory", "does not contain"],
              message: "工程路径无效，文件可能已被移动或删除"),
        .init(any: ["No such file or directory"],
              message: "找不到构建产物，请重新构建"),
    ]

    /// 返回翻译后的提示；无法识别时返回 nil，由调用方保留原文。
    static func translate(_ raw: String) -> String? {
        guard !raw.isEmpty else { return nil }
        for rule in rules {
            let allHit = rule.all.allSatisfy { raw.localizedCaseInsensitiveContains($0) }
            let anyHit = rule.any.isEmpty || rule.any.contains { raw.localizedCaseInsensitiveContains($0) }
            if allHit, anyHit, !(rule.all.isEmpty && rule.any.isEmpty) {
                // 规则表里存的是中文原文，同时充当查表 key，在返回处才落到界面语言
                return L10n.t(rule.message)
            }
        }
        return nil
    }

    /// 翻译失败时退回到原文的首行，避免把整段 xcodebuild 输出甩给用户。
    static func summarize(_ raw: String) -> String {
        if let translated = translate(raw) { return translated }
        let firstMeaningfulLine = raw
            .split(separator: "\n")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .first { !$0.isEmpty }
        return firstMeaningfulLine ?? L10n.t("未知错误")
    }
}
