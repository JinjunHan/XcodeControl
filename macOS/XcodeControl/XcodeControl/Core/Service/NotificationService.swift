//
//  NotificationService.swift
//  XcodeControl
//

import AppKit
import UserNotifications

/// 构建结果通知。
///
/// 权限**不在启动时申请**——没开通知的用户不该一上来就被弹权限框。
/// 只有用户在设置页第一次打开任一通知开关时才 requestAuthorization。
@MainActor
final class NotificationService {

    private var didRequestAuthorization = false
    private var isAuthorized = false

    /// 用户打开开关时调用。已申请过则直接返回缓存结果。
    ///
    /// 返回值用于设置页：被拒时把开关拨回去并提示去系统设置里开，
    /// 否则开关看起来是开的但永远不响。
    @discardableResult
    func requestAuthorizationIfNeeded() async -> Bool {
        if didRequestAuthorization { return isAuthorized }
        didRequestAuthorization = true

        let center = UNUserNotificationCenter.current()
        do {
            isAuthorized = try await center.requestAuthorization(options: [.alert, .sound])
        } catch {
            // 常见成因是 app 未签名或 bundle id 无效——此时通知不可用但不该崩
            isAuthorized = false
        }
        return isAuthorized
    }

    // MARK: - 发送

    func notifyBuildSucceeded(scheme: String, duration: Int, playSound: Bool) {
        deliver(
            title: L10n.t("构建成功"),
            body: "\(scheme) · \(duration)s",
            playSound: playSound,
            identifier: "xcc.build.success"
        )
    }

    /// summary 已经过 ErrorTranslator 翻译，直接用——不要在这里二次加工。
    func notifyBuildFailed(summary: String, playSound: Bool) {
        deliver(
            title: L10n.t("构建失败"),
            body: summary,
            playSound: playSound,
            identifier: "xcc.build.failure"
        )
    }

    /// 只播声音不弹通知的场景（用户开了声音、关了通知）。
    func playSoundOnly() {
        NSSound.beep()
    }

    private func deliver(title: String, body: String, playSound: Bool, identifier: String) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        if playSound { content.sound = .default }

        // trigger 为 nil = 立即投递
        let request = UNNotificationRequest(
            identifier: "\(identifier).\(UUID().uuidString)",
            content: content,
            trigger: nil
        )
        UNUserNotificationCenter.current().add(request)
    }
}
