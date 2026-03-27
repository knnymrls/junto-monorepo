//
//  SuggestedMessageRow.swift
//  mkrs-world
//
//  Suggested connection to message row
//

import SwiftUI

struct SuggestedMessageRow: View {
    let user: UserResponse
    let onMessageTap: () -> Void
    let onDismiss: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: Spacing.sm) {
                AvatarView(
                    avatarUrl: user.avatarUrl,
                    name: user.name,
                    size: 40
                )

                VStack(alignment: .leading, spacing: Spacing.xxxs) {
                    Text(user.name)
                        .font(.bodyMedium)
                        .foregroundColor(.appPrimary)
                        .lineLimit(1)

                    if let headline = user.headline {
                        Text(headline)
                            .font(.caption12)
                            .foregroundColor(.appSecondary)
                            .lineLimit(1)
                    }
                }

                Spacer(minLength: 0)

                Button(action: onMessageTap) {
                    Text("Message")
                        .font(.bodyMedium)
                        .foregroundColor(.appPrimary)
                        .padding(.horizontal, Spacing.lg)
                        .padding(.vertical, Spacing.xs)
                        .overlay(
                            RoundedRectangle(cornerRadius: Radius.md)
                                .stroke(Color.appDivider, lineWidth: 1)
                        )
                }
                .buttonStyle(.plain)

                Button(action: onDismiss) {
                    Image(systemName: "xmark")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.appSecondary)
                        .frame(width: 28, height: 28)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, Spacing.md)
            .padding(.vertical, Spacing.sm)

            Rectangle()
                .fill(Color.appDivider)
                .frame(height: 1 / UIScreen.main.scale)
        }
    }
}
