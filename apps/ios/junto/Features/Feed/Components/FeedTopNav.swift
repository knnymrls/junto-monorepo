//
//  FeedTopNav.swift
//  junto
//
//  Feed's brand top nav: user avatar + Junto wordmark (left), menu (right).
//  Matches Figma node 1:147. Other tabs keep the title-based TopNavBar.
//

import SwiftUI

struct FeedTopNav: View {
    var avatarUrl: String? = nil
    var name: String = "?"
    var onAvatarTap: (() -> Void)? = nil
    var onMenuTap: (() -> Void)? = nil
    /// When set, the user avatar acts as the source of a zoom transition into
    /// the current user's profile.
    var profileZoomID: AnyHashable? = nil
    var profileZoomNamespace: Namespace.ID? = nil

    var body: some View {
        HStack(spacing: Spacing.sm) {
            // User avatar + wordmark
            HStack(spacing: Spacing.sm) {
                avatar

                Text("Junto")
                    .font(.juntoHeadingExtraBold)
                    .foregroundColor(.appPrimary)
            }

            Spacer()

            // Menu
            if let onMenuTap {
                Button(action: onMenuTap) {
                    Image("nav.menu")
                        .renderingMode(.template)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 28, height: 28)
                        .foregroundColor(.appPrimary)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.pressableScale(0.9))
            }
        }
        .padding(.horizontal, Spacing.lg)
        .padding(.bottom, Spacing.sm)
        .background(Color.appSurface)
    }

    @ViewBuilder
    private var avatar: some View {
        let image = AvatarView(
            avatarUrl: avatarUrl,
            name: name,
            size: 40,
            zoomID: profileZoomID,
            zoomNamespace: profileZoomNamespace
        )
        if let onAvatarTap {
            Button(action: onAvatarTap) { image }
                .buttonStyle(.pressableScale(0.9))
        } else {
            image
        }
    }
}

#Preview {
    VStack(spacing: 0) {
        FeedTopNav(avatarUrl: nil, name: "Kenny", onAvatarTap: {}, onMenuTap: {})
        Divider()
        Spacer()
    }
    .background(Color.appBackground)
}
