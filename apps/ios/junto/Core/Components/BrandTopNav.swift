//
//  BrandTopNav.swift
//  junto
//
//  Centralized brand top nav: leading avatar + center (wordmark OR title) +
//  optional trailing icon action. Shared across tabs so Feed and Discover
//  read as the same surface — Feed shows the "Junto" wordmark + menu, Discover
//  shows the "Discover" title + search. Matches Figma node 1:147 (Feed) and the
//  Discover artboard's Top Nav.
//

import SwiftUI

struct BrandTopNav: View {
    /// The center treatment next to the avatar.
    enum Center {
        /// Brand wordmark — Bricolage Grotesque (headings only). Used on Feed.
        case wordmark(String)
        /// Plain screen title — SF Pro semibold 24 (`heading1`). Used elsewhere.
        case title(String)
    }

    var avatarUrl: String? = nil
    var name: String = "?"
    var center: Center
    var onAvatarTap: (() -> Void)? = nil

    /// Trailing icon button (asset name). Feed → .navMenu, Discover → search.
    var trailingIcon: ImageResource? = nil
    var onTrailingTap: (() -> Void)? = nil

    /// When set, the avatar acts as the source of a zoom transition into the
    /// current user's profile.
    var profileZoomID: AnyHashable? = nil
    var profileZoomNamespace: Namespace.ID? = nil

    var body: some View {
        HStack(spacing: Spacing.sm) {
            // Leading: avatar + wordmark/title
            HStack(spacing: Spacing.sm) {
                avatar
                centerLabel
            }

            Spacer()

            // Trailing action — 28pt icon centered in a 40pt tap target (Figma 140:412)
            if let trailingIcon, let onTrailingTap {
                Button(action: onTrailingTap) {
                    Image(trailingIcon)
                        .renderingMode(.template)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 28, height: 28)
                        .foregroundColor(.appPrimary)
                        .frame(width: 40, height: 40)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.pressableScale(0.9))
            }
        }
        .padding(.horizontal, Spacing.lg)
        .padding(.bottom, Spacing.sm)
        // White bar fills up through the status bar so it reads as one solid
        // surface from the screen's top edge (Figma bg-white spans pt-56).
        .background(Color.appSurface.ignoresSafeArea(edges: .top))
    }

    @ViewBuilder
    private var centerLabel: some View {
        switch center {
        case .wordmark(let text):
            Text(text)
                .font(.juntoHeadingExtraBold)
                .foregroundColor(.appPrimary)
        case .title(let text):
            Text(text)
                .font(.heading1)
                .foregroundColor(.appPrimary)
        }
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
        BrandTopNav(name: "Kenny", center: .wordmark("Junto"),
                    onAvatarTap: {}, trailingIcon: .navMenu, onTrailingTap: {})
        Divider()
        BrandTopNav(name: "Kenny", center: .title("Discover"),
                    onAvatarTap: {}, trailingIcon: .navSearch, onTrailingTap: {})
        Divider()
        Spacer()
    }
    .background(Color.appBackground)
}
