//
//  SettingsSidebar.swift
//  XcodeControl
//

import SwiftUI

/// 设置窗口的自定义侧栏（macOS 26 Liquid Glass 风格）。
///
/// **为什么不用系统的 `TabView.sidebarAdaptable`：** 那套侧栏强制附带一个折叠钮，
/// 而折叠钮是删不掉的——`.toolbar(removing: .sidebarToggle)` 只对 `NavigationSplitView`
/// 生效，AppKit 强行隐藏也会在切 tab 后被系统重新插入。六个分页固定可见，
/// 折叠本身没有使用场景，却要为它常年空出一格工具栏。自己画一个就没有这个包袱。
///
/// **同心圆角是这里唯一需要算的东西。** 圆角要看起来「套得住」，
/// 内层半径必须等于外层半径减去两者的间距，否则内外弧线不平行，视觉上会发胀或发瘪。
/// `ConcentricRectangle(corners: .concentric(...))` 让系统替我们做这次减法：
/// 卡片相对窗口圆角减 `inset`，行相对卡片圆角减 `rowInset`。
/// 中间那道 `.containerShape` 不能省——它声明「行的外层是这张卡片」，
/// 没有它行会拿窗口去算，减错一层。
///
/// 注意 `minimum:` 是**下限而非半径**：系统算出的同心值小于它时才会被顶到这个数。
/// 因此 `cardRadius` 取的是 Tahoe 窗口圆角减去 `inset` 的实测量级，
/// 与 `containerShape` 声明的值刻意保持一致——两者一致，行才真的与卡片同心。
/// 换 inset 或换系统窗口圆角时，这两个数要一起改。
///
/// **配色沿用系统语义色，不碰 `Theme.Palette`。** 那一整套是「白字压深色玻璃」，
/// 只对钉死 `darkAqua` 的 `FloatingPanel` 成立；设置窗口跟随系统外观，
/// 用在这里浅色模式下会白字压白底。
///
/// **卡片顶到窗口左上角，靠的是内容视图本来就是全窗口高的。** 实测 SwiftUI 已经给
/// 设置窗口开了 `fullSizeContentView`：`contentView` 比 `contentLayoutRect` 高出
/// 一整条标题栏带，那段差额是以安全区的形式让出来的。所以侧栏不需要动 AppKit，
/// `.ignoresSafeArea(.container, edges: .top)`（在 `SettingsView` 里加）就够了。
/// 代价是红绿灯会压在卡片上，因此行要靠 `topInset` 让开那条带——见下。
struct SettingsSidebar: View {

    @Binding var selection: SettingsTab

    /// 标题栏带的高度，由 `SettingsView` 从安全区量出来传进来。
    ///
    /// 不写成常量：这个值随工具栏样式与工具栏项的有无而变（实测同一个窗口
    /// 在 88 / 40 之间跳过），钉死一个数就会在某些分页上把行顶进红绿灯，
    /// 或者反过来多留一条空带。
    let topInset: CGFloat

    /// 容纳最长的一条译文（德语 "Verhalten"、俄语 "Расположение"）而不换行。
    static let width: CGFloat = 176

    /// 卡片与窗口边缘的留白，同时是「卡片圆角 = 窗口圆角 − inset」里的减数。
    static let inset: CGFloat = 10

    /// 行与卡片边缘的留白，同时是「行圆角 = 卡片圆角 − rowInset」里的减数。
    private let rowInset: CGFloat = 6

    /// 卡片圆角。给 `containerShape` 用——行要拿一个具体数值去做同心换算。
    private let cardRadius: CGFloat = 14

    @State private var hovered: SettingsTab?

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            ForEach(SettingsTab.allCases) { tab in
                row(tab)
            }
            Spacer(minLength: 0)
        }
        // 卡片本身顶到窗口顶端，行却不能——红绿灯就在那条带里。
        // 减 inset 是因为卡片已经比窗口低了 inset，第一行的顶边正好落在
        // 标题栏带的下沿，与右侧内容区的起点齐平。
        .padding(.horizontal, rowInset)
        .padding(.bottom, rowInset)
        .padding(.top, max(rowInset, topInset - Self.inset))
        .frame(width: Self.width, alignment: .leading)
        .frame(maxHeight: .infinity)
        .glassEffect(
            .regular,
            in: ConcentricRectangle(corners: .concentric(minimum: .fixed(cardRadius)), isUniform: true)
        )
        .containerShape(RoundedRectangle(cornerRadius: cardRadius, style: .continuous))
        // 方向键切换分页；侧栏可聚焦，Tab 键能从内容区走回来。
        // 但要关掉聚焦光环：系统会沿整张卡片外沿描一圈蓝框，
        // 那圈框比选中行的蓝底更抢眼，看起来像是侧栏本身被选中了。
        .focusable()
        .focusEffectDisabled()
        .onMoveCommand(perform: move)
        .accessibilityElement(children: .contain)
    }

    @ViewBuilder
    private func row(_ tab: SettingsTab) -> some View {
        let isSelected = tab == selection
        let isHovered = tab == hovered

        Button {
            selection = tab
        } label: {
            HStack(spacing: 10) {
                // 固定图标栏宽：六个 SF Symbol 实际宽度不一，不固定的话文字左边缘会参差
                Image(systemName: tab.systemImage)
                    .font(.system(size: 16))
                    .frame(width: 20, alignment: .center)
                Text(tab.title)
                    .font(.system(size: 15, weight: isSelected ? .semibold : .regular))
                    .lineLimit(1)
                Spacer(minLength: 0)
            }
            .foregroundStyle(isSelected ? Color.accentColor : Color.primary)
            .padding(.horizontal, 8)
            .frame(maxWidth: .infinity, minHeight: 36, alignment: .leading)
            .background {
                let shape = ConcentricRectangle(
                    corners: .concentric(minimum: 6),
                    isUniform: true
                )
                if isSelected {
                    shape.fill(Color.accentColor.opacity(0.13))
                } else {
                    shape.fill(Color.primary.opacity(isHovered ? 0.07 : 0))
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .onHover { inside in
            if inside { hovered = tab } else if hovered == tab { hovered = nil }
        }
        .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
    }

    /// 上下键在列表内移动，到头即停——不做循环，避免按住方向键时反复绕圈。
    private func move(_ direction: MoveCommandDirection) {
        let all = SettingsTab.allCases
        guard let index = all.firstIndex(of: selection) else { return }
        switch direction {
        case .up where index > 0:
            selection = all[index - 1]
        case .down where index < all.count - 1:
            selection = all[index + 1]
        default:
            break
        }
    }
}
