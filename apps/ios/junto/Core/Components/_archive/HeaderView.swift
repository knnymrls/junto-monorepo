//
//  HeaderView.swift
//  junto
//
//  Shared tab header: title on left, avatar menu button on right
//

import SwiftUI

struct HeaderView: View {
    let title: String
    let avatarUrl: String?
    let avatarName: String
    let onAvatarTap: () -> Void

    var body: some View {
        HStack(spacing: Spacing.sm) {
            Text(title)
                .font(.heading1)
                .foregroundColor(.appPrimary)

            Spacer()

            Button(action: onAvatarTap) {
                AvatarView(
                    avatarUrl: avatarUrl,
                    name: avatarName,
                    size: 36
                )
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, Spacing.md)
        .padding(.vertical, Spacing.md)
        .background(Color.appSurface)
    }
}
