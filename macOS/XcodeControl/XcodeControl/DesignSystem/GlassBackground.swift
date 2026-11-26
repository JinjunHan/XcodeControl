//
//  GlassBackground.swift
//  XcodeControl
//

import SwiftUI

/// `NSVisualEffectView` 的 SwiftUI 包装。
struct VisualEffectBackground: NSViewRepresentable {
    var material: NSVisualEffectView.Material = .hudWindow
    var blendingMode: NSVisualEffectView.BlendingMode = .behindWindow

    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = material
        view.blendingMode = blendingMode
        view.state = .active
        view.isEmphasized = false
        return view
    }

    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {
        nsView.material = material
        nsView.blendingMode = blendingMode
    }
}

/// 浮层本体的玻璃底：毛玻璃 + 暗场兜底 + 顶部提亮渐变 + 明暗双描边 + 运行中的边缘辉光。
///
/// 层序是有讲究的，自下而上：
/// 毛玻璃 → 暗场（`Palette.glassScrim`，保证对比度下限）→ 顶部高光 → 暗描边 → 亮描边。
/// 暗场必须压在毛玻璃之上而不是之下，压在下面会被 `.behindWindow` 的采样忽略，等于没画。
struct GlassBackground: View {
    var cornerRadius: CGFloat = Theme.Metrics.cornerRadius
    /// 运行中时窗口边缘出现一圈极淡的强调色发光
    var isGlowing: Bool = false

    @State private var glowPhase = false

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)

        shape
            .fill(Theme.Palette.glassScrim)
            .background {
                VisualEffectBackground()
                    .clipShape(shape)
            }
            .overlay {
                // 8% 白的渐变高光作顶部提亮，模拟真实玻璃的边缘折射
                shape.fill(
                    LinearGradient(
                        colors: [Theme.Palette.glassHighlight, .clear],
                        startPoint: .top,
                        endPoint: .center
                    )
                )
            }
            .overlay {
                // 外暗内亮的双描边：浅色背景下暗边把浮层切出来，深色背景下亮边勾出玻璃缘
                shape.strokeBorder(Theme.Palette.hairlineOuter, lineWidth: 1)
            }
            .overlay {
                shape.inset(by: 1).strokeBorder(Theme.Palette.hairline, lineWidth: 1)
            }
            .overlay {
                shape
                    .strokeBorder(Theme.Palette.accent.opacity(isGlowing ? (glowPhase ? 0.5 : 0.24) : 0), lineWidth: 1.5)
                    .blur(radius: 2.5)
                    .allowsHitTesting(false)
            }
            .shadow(
                color: Theme.Palette.accent.opacity(isGlowing ? (glowPhase ? 0.22 : 0.1) : 0),
                radius: 12
            )
            .onChange(of: isGlowing, initial: true) { _, glowing in
                if glowing {
                    withAnimation(Motion.glow) { glowPhase = true }
                } else {
                    withAnimation(.easeOut(duration: 0.25)) { glowPhase = false }
                }
            }
    }
}

/// 下拉面板的底：比主浮层更实一点，避免叠加后内容发虚。
///
/// 这里的 0.28 是**叠加在主浮层暗场之上**的增量，不是绝对值——下拉面板画在
/// `GlassBackground` 的内容层里，两层暗场相乘后实际约 0.5，天然比主浮层深。
/// 主浮层的 `glassScrim` 若调整，这里不必跟着调。
struct DropdownBackground: View {
    var cornerRadius: CGFloat = 12

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
        shape
            .fill(Color.black.opacity(0.28))
            .background {
                VisualEffectBackground(material: .hudWindow, blendingMode: .withinWindow)
                    .clipShape(shape)
            }
            .overlay { shape.strokeBorder(Theme.Palette.hairline, lineWidth: 1) }
            .shadow(color: .black.opacity(0.35), radius: 18, y: 8)
    }
}
