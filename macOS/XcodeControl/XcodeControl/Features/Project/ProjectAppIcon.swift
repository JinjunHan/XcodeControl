//
//  ProjectAppIcon.swift
//  XcodeControl
//

import AppKit
import SwiftUI

/// 工程 AppIcon；尚未解析到时回退到 kind 对应的 SF Symbol。
struct ProjectAppIcon: View {

    let project: XcodeProject
    let image: NSImage?
    var size: CGFloat = 16
    var fallbackForeground: Color = Theme.Palette.textSecondary

    var body: some View {
        Group {
            if let image {
                Image(nsImage: image)
                    .resizable()
                    .interpolation(.high)
                    .aspectRatio(contentMode: .fit)
                    .frame(width: size, height: size)
                    .clipShape(RoundedRectangle(cornerRadius: size * 0.22, style: .continuous))
            } else {
                Image(systemName: project.kind == .workspace ? "square.grid.2x2" : "hammer")
                    .font(.system(size: size * 0.7, weight: .medium))
                    .foregroundStyle(fallbackForeground)
                    .frame(width: size, height: size)
            }
        }
        .accessibilityHidden(true)
    }
}
