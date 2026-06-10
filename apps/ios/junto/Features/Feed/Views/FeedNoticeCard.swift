//
//  FeedNoticeCard.swift
//  junto
//
//  System / "house" feed card — digest, momentum, milestone, prompt. These are
//  NOT taxonomy cards (Ask/Opportunity/Match/Update), so they read quieter and
//  carry no FeedTypeLabel. Mirrors FeedCard's container (44pt leading slot +
//  text column, same padding / fonts / colors) with the avatar swapped for a
//  tinted system-icon chip. First pass — easy to restyle once designed.
//

import SwiftUI

struct FeedNoticeCard: View {
    let icon: String          // SF Symbol name
    let title: String
    var subtitle: String? = nil
    var onTap: (() -> Void)? = nil

    var body: some View {
        HStack(alignment: .top, spacing: Spacing.md) {
            ZStack {
                Circle().fill(Color.appSurfaceSecondary)
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(.appSecondary)
            }
            .frame(width: 44, height: 44)
            .frame(height: 48, alignment: .top)

            VStack(alignment: .leading, spacing: Spacing.xxs) {
                Text(title)
                    .font(.bodyLargeMedium)
                    .foregroundColor(.appPrimary)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, alignment: .leading)

                if let subtitle {
                    Text(subtitle)
                        .font(.body14)
                        .foregroundColor(.appSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal, Spacing.md)
        .padding(.vertical, Spacing.lg)
        .background(Color.appSurface)
        .contentShape(Rectangle())
        .onTapGesture { onTap?() }
    }
}

/// End-of-feed sentinel for the finite "you're all caught up" surface.
struct FeedCaughtUpCard: View {
    var body: some View {
        VStack(spacing: Spacing.sm) {
            Image(systemName: "checkmark.circle")
                .font(.system(size: 22, weight: .regular))
                .foregroundColor(.appSecondary)
            Text("You're all caught up")
                .font(.body14)
                .foregroundColor(.appSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Spacing.xl)
    }
}

#Preview {
    VStack(spacing: 0) {
        FeedNoticeCard(
            icon: "sparkles",
            title: "This week on campus",
            subtitle: "5 new makers · 4 asks · 2 events"
        )
        Divider()
        FeedNoticeCard(
            icon: "square.and.pencil",
            title: "What do you need right now?",
            subtitle: "Tap to post"
        )
        Divider()
        FeedCaughtUpCard()
    }
    .background(Color.appBackground)
}
