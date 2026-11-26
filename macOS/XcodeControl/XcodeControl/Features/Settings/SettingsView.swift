//
//  SettingsView.swift
//  XcodeControl
//

import SwiftUI

/// 设置窗口：自定义侧栏 + 内容区，不用系统的 `TabView.sidebarAdaptable`。
///
/// 换掉系统侧栏的原因写在 `SettingsSidebar` 里：它强制附带一个删不掉的折叠钮，
/// 而六个分页固定可见，折叠没有使用场景，却要为它常年空出一格工具栏。
///
/// **没有分隔线。** macOS 26 的侧栏是一张浮在内容之上的玻璃卡片，
/// 靠材质与投影和背景分开，再画一道 `Divider` 会把「浮起来」压回「切两半」。
///
/// **配色约束：本窗口不用 `Theme.Palette`。** 那一整套是「白字压深色玻璃」，
/// 且只对 `FloatingPanel` 成立——那个窗口把外观钉死在 `darkAqua`。
/// 设置窗口跟随系统外观，必须用 SwiftUI 语义色与标准 `Form` 控件，
/// 否则浅色模式下白字压白底直接看不见。
struct SettingsView: View {

    @Environment(AppState.self) private var state

    @State private var tab: SettingsTab = .project

    var body: some View {
        // GeometryReader 只为量一个数：标题栏带的高度（安全区顶部）。
        // 侧栏要从这条带底下穿过去顶到窗口左上角，行又得让开红绿灯，
        // 两件事都需要这个值，而它会随工具栏样式与工具栏项的有无变化。
        GeometryReader { proxy in
            HStack(spacing: 0) {
                SettingsSidebar(selection: $tab, topInset: proxy.safeAreaInsets.top)
                    .padding(SettingsSidebar.inset)
                    // 内容视图本来就是全窗口高的（SwiftUI 已开 fullSizeContentView），
                    // 顶部那段是以安全区让出来的——忽略它，卡片就落到窗口左上角。
                    .ignoresSafeArea(.container, edges: .top)

                VStack(spacing: 0) {
                    if tab != .project {
                        Text(tab.title)
                            .font(.title2.bold())
                            .accessibilityAddTraits(.isHeader)
                            .frame(maxWidth: .infinity, minHeight: 24, alignment: .leading)
                            .padding(.horizontal, 16)
                            .padding(.bottom, 12)
                    }
                    pane(for: tab)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        // `Form(.grouped)` 默认给内容区铺一层灰底（分组卡片压在灰面上），
                        // 而「项目」页用的是 List、观感是白的——切页时背景会一灰一白地跳。
                        // 关掉滚动视图自带的底色，统一按下面那层铺。
                        .scrollContentBackground(.hidden)
                }
                .padding(.top, 16)
                .ignoresSafeArea(.container, edges: .top)

            }
        }
        // 整窗铺同一个底色：连侧栏背后与标题栏一起，中间不留断层。
        // 不写死 `.white`：设置窗口跟随系统外观（见上方配色约束），
        // `textBackgroundColor` 在浅色下就是纯白，深色下是对应的深底。
        .background(Color(nsColor: .textBackgroundColor).ignoresSafeArea())
        .frame(minWidth: 720, minHeight: 460)
        // 外部指定分页（浮窗的「管理项目…」直落「项目」页）。
        //
        // 两个入口都要挂：窗口这次是新建的，`@State` 刚初始化、不会触发 onChange，
        // 只有 onAppear 跑得到；窗口已经开着时视图不再 appear，就靠 onChange。
        .onAppear { consumeTabRequest() }
        .onChange(of: state.requestedSettingsTab) { _, _ in consumeTabRequest() }
    }

    /// 读走并清空分页请求，理由见 `AppState.requestedSettingsTab`。
    private func consumeTabRequest() {
        guard let requested = state.requestedSettingsTab else { return }
        tab = requested
        state.requestedSettingsTab = nil
    }

    @ViewBuilder
    private func pane(for tab: SettingsTab) -> some View {
        switch tab {
        case .general: GeneralPane()
        case .project: ProjectPane()
        case .build: BuildPane()
        case .behavior: BehaviorPane()
        case .locations: LocationsPane()
        case .about: AboutPane()
        }
    }
}
