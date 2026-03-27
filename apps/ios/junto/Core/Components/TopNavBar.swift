//
//  TopNavBar.swift
//  mkrs-world
//
//  Global top navigation bar: title left, profile avatar right
//

import SwiftUI

struct TopNavBar: View {
    let title: String
    var avatarUrl: String? = nil
    var avatarName: String = "?"
    var onProfileTap: (() -> Void)? = nil

    var body: some View {
        HStack(spacing: Spacing.md) {
            // TODO: Add the font I've been using for brand
            Text(title)
                .font(.heading1)
                .foregroundColor(.appPrimary)

            Spacer()

            if let onProfileTap {
                Button(action: onProfileTap) {
                    AvatarView(
                        avatarUrl: avatarUrl,
                        name: avatarName,
                        size: 32
                    )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, Spacing.md)
        .padding(.top, Spacing.md)
        .padding(.bottom, Spacing.sm)
        .background(Color.appSurface)
    }
}

#Preview {
    VStack(spacing: 0) {
        TopNavBar(
            title: "Feed",
            avatarUrl: nil,
            avatarName: "Kenny",
            onProfileTap: {}
        )
        Spacer()
    }
}
