//
//  EventDetailRow.swift
//  mkrs-world
//
//  Icon + label + value row for event details
//

import SwiftUI

struct EventDetailRow: View {
    let icon: String
    let title: String
    let subtitle: String?
    var action: (() -> Void)? = nil

    var body: some View {
        let content = HStack(spacing: Spacing.lg) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(.appSecondary)
                .frame(width: 24, height: 24)

            VStack(alignment: .leading, spacing: Spacing.xxs) {
                Text(title)
                    .font(.bodyLargeMedium)
                    .foregroundColor(.appPrimary)

                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(.body14)
                        .foregroundColor(.appSecondary)
                }
            }

            Spacer()
        }
        .padding(.vertical, Spacing.md)

        if let action = action {
            Button(action: action) {
                content
            }
            .buttonStyle(.plain)
        } else {
            content
        }
    }
}
