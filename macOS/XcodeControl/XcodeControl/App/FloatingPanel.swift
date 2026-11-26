//
//  FloatingPanel.swift
//  XcodeControl
//

import AppKit

/// 悬浮窗本体。
///
/// 用 `NSPanel` 而非 `NSWindow`，关键在于 `.nonactivatingPanel`：点击窗口时不会把
/// XcodeControl 激活为前台应用，从而不打断用户当前正在使用的编辑器或模拟器。
final class FloatingPanel: NSPanel {

    init(contentRect: NSRect) {
        super.init(
            contentRect: contentRect,
            styleMask: [.borderless, .nonactivatingPanel, .fullSizeContentView, .utilityWindow],
            backing: .buffered,
            defer: false
        )
        level = .floating                       // 高于普通窗口，低于系统 UI
        isFloatingPanel = true
        hidesOnDeactivate = false
        isMovableByWindowBackground = true
        backgroundColor = .clear
        isOpaque = false
        hasShadow = true
        isReleasedWhenClosed = false
        animationBehavior = .utilityWindow
        collectionBehavior = [
            .canJoinAllSpaces,                  // 跨 Space 常驻
            .fullScreenAuxiliary,               // 全屏应用之上仍可见
            .stationary,                        // Exposé 时不参与排布
        ]

        // 外观钉死在深色，不跟随系统。
        //
        // 整套配色是「白字压在深色玻璃上」（见 Theme.Palette），而
        // NSVisualEffectView 的 material 是随外观解析的：浅色模式下 `.hudWindow`
        // 会解析成浅色变体，于是 100% 白的主文本压在近白的底上——文字直接消失。
        // 同理 ProgressView / 文本选中高亮 / 滚动条这些 AppKit 背景的控件也会
        // 跟着渲染成浅色版，在深色内容里格外突兀。
        //
        // 这不是「不支持浅色模式」，而是这个浮窗本身就是一块 HUD：
        // 系统自己的音量、亮度 HUD 同样不跟随外观。真正需要防的是背景亮度
        // （浅色壁纸、白底网页），那由 `Palette.glassScrim` 负责。
        appearance = NSAppearance(named: .darkAqua)
    }

    override var canBecomeKey: Bool { true }    // 允许下拉菜单接收键盘
    override var canBecomeMain: Bool { false }

    /// 按内容尺寸调整窗口：保持顶边不动，并钳制在屏幕可见区域内。
    ///
    /// **不要**再用 `NSHostingController.sizingOptions = [.preferredContentSize]`。
    /// 那条路径会在 `windowDidLayout` → `updateAnimatedWindowSize` → `_setFrameCommon`
    /// 里同步改 frame，与 Auto Layout 形成无限递归，最终在
    /// `NSISEngine._flushPendingRemovals` / `___chkstk_darwin` 栈溢出
    ///（崩溃信息：Thread stack size exceeded due to excessive recursion）。
    /// 点击项目/设备/运行都会改变内容高度，必现。
    ///
    /// 正确做法：SwiftUI 侧用 `fixedSize` + GeometryReader 量理想高度，再调本方法；
    /// 本方法把真正的 `setFrame` 推迟到下一轮 runloop，彻底离开布局栈。
    private var isApplyingSize = false
    private var pendingContentSize: NSSize?

    func applyContentSize(_ size: NSSize) {
        let integral = NSSize(width: size.width.rounded(), height: size.height.rounded())
        guard integral.width > 0, integral.height > 0 else { return }

        let current = contentRect(forFrameRect: frame).size
        if abs(current.width - integral.width) < 0.5,
           abs(current.height - integral.height) < 0.5 {
            return
        }

        pendingContentSize = integral
        guard !isApplyingSize else { return }
        isApplyingSize = true

        DispatchQueue.main.async { [weak self] in
            self?.flushPendingContentSize()
        }
    }

    private func flushPendingContentSize() {
        guard let integral = pendingContentSize else {
            isApplyingSize = false
            return
        }
        pendingContentSize = nil

        let current = contentRect(forFrameRect: frame).size
        if abs(current.width - integral.width) >= 0.5
            || abs(current.height - integral.height) >= 0.5 {
            let frameSize = frameRect(forContentRect: NSRect(origin: .zero, size: integral)).size
            var newFrame = NSRect(
                x: frame.minX,
                y: frame.maxY - frameSize.height,
                width: frameSize.width,
                height: frameSize.height
            )

            // 只保顶边的代价：用户把窗口拖到屏幕下缘后再展开日志，下半截会出屏。
            // 默认位置在右上角（见 defaultFrame）时长不出屏，这里是为拖动过的位置兜底。
            if let visible = (screen ?? NSScreen.main)?.visibleFrame {
                if newFrame.minY < visible.minY {
                    newFrame.origin.y = visible.minY
                }
                if newFrame.maxY > visible.maxY {
                    newFrame.origin.y = max(visible.minY, visible.maxY - newFrame.height)
                }
            }

            setFrame(newFrame, display: true)
        }

        if pendingContentSize != nil {
            DispatchQueue.main.async { [weak self] in
                self?.flushPendingContentSize()
            }
        } else {
            isApplyingSize = false
        }
    }

    /// Esc 收起当前展开的下拉面板
    var onEscape: (() -> Void)?

    override func cancelOperation(_ sender: Any?) {
        onEscape?()
    }
}

// MARK: - 位置持久化

/// 只持久化左上角，不持久化整个 frame。
///
/// 悬浮窗的高度是内容驱动的（展开日志、弹出下拉都会变），而窗口在 Cocoa 里
/// 是以左下角定位的。若存整个 frame，下次启动就得拿「上次的底边」去配「这次的
/// 占位高度」，窗口会一次比一次高地往上爬——实测每次启动上移几十点。
/// 存左上角则天然与高度无关：改内容尺寸时保持左上角不动，
/// 于是保存与恢复对同一个点收敛，怎么变高都不漂移。
enum PanelPosition {

    /// 保存窗口左上角。窗口移动与内容改变尺寸时都会调用。
    static func save(_ frame: NSRect) {
        let topLeft = NSPoint(x: frame.minX, y: frame.maxY)
        UserDefaults.standard.set(NSStringFromPoint(topLeft), forKey: DefaultsKey.panelTopLeft)
    }

    /// 恢复窗口位置；若坐标已不在任何屏幕范围内（外接显示器被拔掉），
    /// 回落到主屏右下角。
    static func restore(size: NSSize) -> NSRect {
        guard let raw = UserDefaults.standard.string(forKey: DefaultsKey.panelTopLeft) else {
            return defaultFrame(size: size)
        }
        let topLeft = NSPointFromString(raw)
        let frame = NSRect(
            x: topLeft.x,
            y: topLeft.y - size.height,
            width: size.width,
            height: size.height
        )
        return isVisible(frame) ? frame : defaultFrame(size: size)
    }

    /// 默认位置：右上角。
    ///
    /// **不要改回贴底。** `visibleFrame` 只在 Dock 常显时才扣掉 Dock 的高度；
    /// 设为自动隐藏后它一路延伸到屏幕底部，于是「底边 + 24」正好落在 Dock 弹出的
    /// 那条带里——而 Dock 的窗口层级（20）高于本窗口的 `.floating`（3），
    /// 浮窗启动后就被压在 Dock 后面。
    ///
    /// 贴顶还顺带和「只存左上角」对上了：窗口以左上角为锚点，
    /// 内容变高是往下长进空白区，不会像贴底时那样把下半截顶出屏幕再被钳回来。
    static func defaultFrame(size: NSSize) -> NSRect {
        let screen = NSScreen.main ?? NSScreen.screens.first
        guard let visible = screen?.visibleFrame else {
            return NSRect(origin: .zero, size: size)
        }
        let margin: CGFloat = 24
        return NSRect(
            x: visible.maxX - size.width - margin,
            y: visible.maxY - size.height - margin,
            width: size.width,
            height: size.height
        )
    }

    /// 窗口至少要有一角落在某块屏幕的可见区域内
    private static func isVisible(_ frame: NSRect) -> Bool {
        NSScreen.screens.contains { screen in
            screen.visibleFrame.intersects(frame.insetBy(dx: -1, dy: -1))
        }
    }
}
