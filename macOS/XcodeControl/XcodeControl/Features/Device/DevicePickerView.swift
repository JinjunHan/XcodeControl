//
//  DevicePickerView.swift
//  XcodeControl
//

import SwiftUI

/// 设备下拉面板：按来源分组，模拟器组内再按设备族分节。
struct DevicePickerView: View {

    @Environment(AppState.self) private var state

    var body: some View {
        @Bindable var devices = state.devices

        VStack(spacing: 0) {
            if devices.showsSearchField {
                SearchField(text: $devices.searchText, placeholder: L10n.t("搜索设备"))
                    .padding(.horizontal, 6)
                    .padding(.top, 6)
                Divider().overlay(Theme.Palette.separator).padding(.top, 6)
            }

            ScrollView {
                LazyVStack(alignment: .leading, spacing: 1, pinnedViews: []) {
                    ForEach(devices.groupedSections, id: \.source) { section in
                        SectionHeader(title: section.source.groupTitle)

                        ForEach(section.groups) { group in
                            // 模拟器条目多，才需要再按设备族分节
                            if section.source == .simulator && section.groups.count > 1 {
                                Text(group.title)
                                    .font(Theme.Font.tertiary)
                                    .foregroundStyle(Theme.Palette.textTertiary.opacity(0.8))
                                    .padding(.horizontal, 10)
                                    .padding(.top, 4)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                            ForEach(group.destinations) { destination in
                                DeviceRow(
                                    destination: destination,
                                    isSelected: destination.id == devices.selectedID
                                ) {
                                    withAnimation(Motion.panel) {
                                        state.selectDestination(destination)
                                    }
                                }
                            }
                        }
                    }

                    if devices.filtered.isEmpty {
                        EmptyHint(
                            text: devices.searchText.isEmpty ? L10n.t("没有可用设备") : L10n.t("没有匹配的设备")
                        )
                    }
                }
                .padding(.horizontal, 4)
                .padding(.vertical, 4)
            }
            .frame(maxHeight: Theme.Metrics.dropdownMaxHeight)

            Divider().overlay(Theme.Palette.separator)

            FooterButton(symbol: "arrow.clockwise", title: L10n.t("刷新设备列表")) {
                Task { await state.devices.refresh() }
            }
        }
        .background { DropdownBackground() }
    }
}

/// 下拉面板顶部的搜索框
struct SearchField: View {
    @Binding var text: String
    var placeholder: String

    var body: some View {
        HStack(spacing: 5) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 9.5, weight: .medium))
                .foregroundStyle(Theme.Palette.textTertiary)
            TextField(placeholder, text: $text)
                .textFieldStyle(.plain)
                .font(Theme.Font.secondary)
                .foregroundStyle(Theme.Palette.textPrimary)
            if !text.isEmpty {
                IconButton(symbol: "xmark.circle.fill", help: L10n.t("清除")) { text = "" }
            }
        }
        .padding(.horizontal, 7)
        .padding(.vertical, 4)
        .background {
            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .fill(Theme.Palette.controlFill)
        }
    }
}

/// 下拉面板底部固定的一条操作
struct FooterButton: View {
    let symbol: String
    let title: String
    let action: () -> Void

    @State private var isHovering = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: symbol)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(Theme.Palette.textSecondary)
                    .frame(width: 14)
                Text(title)
                    .font(Theme.Font.secondary)
                    .foregroundStyle(Theme.Palette.textSecondary)
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .background(isHovering ? Theme.Palette.controlFillHover : .clear)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .onHover { isHovering = $0 }
    }
}

struct EmptyHint: View {
    let text: String

    var body: some View {
        Text(text)
            .font(Theme.Font.secondary)
            .foregroundStyle(Theme.Palette.textTertiary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 18)
    }
}
