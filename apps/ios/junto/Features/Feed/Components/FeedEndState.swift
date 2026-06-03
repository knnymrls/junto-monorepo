//
//  FeedEndState.swift
//  junto
//
//  Reusable centered empty/end state — 64px icon + title + subtitle.
//  Matches Figma nodes 70:1614 (feed end) and 63:1042 (no replies).
//

import SwiftUI

struct FeedMessageState: View {
    let icon: String
    let title: String
    let subtitle: String

    var body: some View {
        VStack(spacing: Spacing.lg) {
            Image(icon)
                .renderingMode(.template)
                .resizable()
                .scaledToFit()
                .frame(width: 64, height: 64)
                .foregroundColor(.appSecondary)

            VStack(spacing: Spacing.xxs) {
                Text(title)
                    .font(.bodyLargeMedium)
                    .foregroundColor(.appPrimary)

                Text(subtitle)
                    .font(.body14)
                    .foregroundColor(.appSecondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, Spacing.md)
        .padding(.vertical, 64)
    }
}

/// Feed end-of-list / empty state.
struct FeedEndState: View {
    var body: some View {
        FeedMessageState(
            icon: "feed.empty",
            title: "You've reached the end",
            subtitle: "That's all the posts we have for now!"
        )
    }
}

#Preview {
    VStack(spacing: 0) {
        FeedEndState()
        FeedMessageState(icon: "feed.replies.empty", title: "No Replies", subtitle: "Be the first to reply")
    }
    .background(Color.appBackground)
}
