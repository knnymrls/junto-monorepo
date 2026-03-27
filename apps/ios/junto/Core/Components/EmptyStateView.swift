//
//  EmptyStateView.swift
//  mkrs-world
//
//  Reusable empty state with icon, title, and optional subtitle
//

import SwiftUI

struct EmptyStateView: View {
    let icon: String
    let title: String
    var subtitle: String? = nil
    var iconSize: CGFloat = 48
    var isSystemIcon: Bool = true

    var body: some View {
        VStack(spacing: Spacing.lg) {
            if isSystemIcon {
                Image(systemName: icon)
                    .font(.system(size: iconSize))
                    .foregroundColor(.appSecondary)
            } else {
                Image(icon)
                    .resizable()
                    .frame(width: iconSize, height: iconSize)
                    .foregroundColor(.appSecondary)
            }

            Text(title)
                .font(.heading3Regular)
                .foregroundColor(.appPrimary)

            if let subtitle {
                Text(subtitle)
                    .font(.body14)
                    .foregroundColor(.appSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, Spacing.huge)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Spacing.huge)
    }
}
