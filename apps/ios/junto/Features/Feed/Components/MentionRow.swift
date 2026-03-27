//
//  MentionRow.swift
//  mkrs-world
//
//  Avatar + name + headline row for mention picker results
//

import SwiftUI

struct MentionRow: View {
    let suggestion: MentionSuggestion

    private var displayName: String {
        suggestion.name.isEmpty ? "Unknown" : suggestion.name
    }

    var body: some View {
        HStack(spacing: 11) {
            AvatarView(
                avatarUrl: suggestion.avatarUrl,
                name: displayName,
                size: 36
            )

            VStack(alignment: .leading, spacing: Spacing.xxs) {
                Text(displayName)
                    .font(.bodyMedium)
                    .foregroundColor(.appPrimary)

                if let headline = suggestion.headline, !headline.isEmpty {
                    Text(headline)
                        .font(.body14)
                        .foregroundColor(.appSecondary)
                        .lineLimit(1)
                }
            }

            Spacer()
        }
        .padding(.horizontal, Spacing.sm)
        .padding(.vertical, Spacing.md)
    }
}
