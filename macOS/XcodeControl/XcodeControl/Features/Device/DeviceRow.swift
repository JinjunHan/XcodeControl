//
//  DeviceRow.swift
//  XcodeControl
//

import SwiftUI

/// 设备下拉列表中的一行。
struct DeviceRow: View {

    let destination: RunDestination
    let isSelected: Bool
    let action: () -> Void

    @State private var isHovering = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: destination.symbolName)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(Theme.Palette.textSecondary)
                    .frame(width: 14)

                VStack(alignment: .leading, spacing: 1) {
                    Text(destination.name)
                        .font(Theme.Font.secondary)
                        .foregroundStyle(Theme.Palette.textPrimary)
                        .lineLimit(1)
                    Text(destination.subtitle)
                        .font(Theme.Font.tertiary)
                        .foregroundStyle(Theme.Palette.textTertiary)
                        .lineLimit(1)
                }

                Spacer(minLength: 6)

                if destination.isReady {
                    StatusDot(isOnline: true)
                }
                if isSelected {
                    Image(systemName: "checkmark")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(Theme.Palette.accent)
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 5)
            .background {
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .fill(isHovering ? Theme.Palette.controlFillHover : .clear)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .onHover { isHovering = $0 }
    }
}

/// 下拉面板中的分组标题
struct SectionHeader: View {
    let title: String

    var body: some View {
        Text(title.uppercased())
            .font(Theme.Font.sectionTitle)
            .foregroundStyle(Theme.Palette.textTertiary)
            .kerning(0.4)
            .padding(.horizontal, 8)
            .padding(.top, 6)
            .padding(.bottom, 2)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}
