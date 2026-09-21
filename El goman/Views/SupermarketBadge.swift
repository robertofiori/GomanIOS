//
//  SupermarketBadge.swift
//  El goman
//
//  Created by Roberto Fiori.
//

import SwiftUI

public struct SupermarketBadge: View {
    let name: String
    let style: BadgeStyle

    public enum BadgeStyle {
        case compact
        case regular
    }

    public init(_ name: String, style: BadgeStyle = .regular) {
        self.name = name
        self.style = style
    }

    public var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(badgeColor)
                .frame(width: style == .compact ? 6 : 8, height: style == .compact ? 6 : 8)
            
            Text(formattedName)
                .font(.system(size: style == .compact ? 11 : 12, weight: .bold))
                .foregroundColor(badgeColor)
        }
        .padding(.horizontal, style == .compact ? 6 : 8)
        .padding(.vertical, style == .compact ? 3 : 5)
        .background(badgeColor.opacity(0.12))
        .clipShape(Capsule())
    }

    private var formattedName: String {
        let lower = name.lowercased()
        if lower.contains("vea") { return "Vea" }
        if lower.contains("carrefour") { return "Carrefour" }
        if lower.contains("chango") || lower.contains("masonline") { return "ChangoMás" }
        if lower.contains("cooperativa") || lower.contains("coope") { return "La Coope" }
        if lower.contains("coto") { return "Coto" }
        if lower.contains("dia") { return "Día" }
        return name
    }

    private var badgeColor: Color {
        let lower = name.lowercased()
        if lower.contains("vea") { return Color.green }
        if lower.contains("carrefour") { return Color.blue }
        if lower.contains("chango") || lower.contains("masonline") { return Color.orange }
        if lower.contains("cooperativa") || lower.contains("coope") { return Color.teal }
        if lower.contains("coto") { return Color.red }
        return Color.secondary
    }
}
