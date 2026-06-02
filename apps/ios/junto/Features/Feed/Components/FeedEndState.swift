//
//  FeedEndState.swift
//  junto
//
//  Empty / end-of-feed state — smiley + "You've reached the end".
//  Matches Figma node 70:1614. Shown when the feed has no more items
//  (also serves as the empty state when there are none at all).
//

import SwiftUI

struct FeedEndState: View {
    var body: some View {
        VStack(spacing: Spacing.lg) {
            Image("feed.empty")
                .renderingMode(.template)
                .resizable()
                .scaledToFit()
                .frame(width: 64, height: 64)
                .foregroundColor(.appSecondary)

            VStack(spacing: Spacing.xxs) {
                Text("You've reached the end")
                    .font(.bodyLargeMedium)
                    .foregroundColor(.appPrimary)

                Text("That's all the posts we have for now!")
                    .font(.body14)
                    .foregroundColor(.appSecondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, Spacing.md)
        .padding(.vertical, 64)
    }
}

#Preview {
    VStack(spacing: 0) {
        FeedEndState()
        Spacer()
    }
    .background(Color.appBackground)
}
