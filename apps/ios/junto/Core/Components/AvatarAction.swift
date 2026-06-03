//
//  AvatarAction.swift
//  mkrs-world
//
//  Reusable avatar with connection action badge overlay
//

import SwiftUI

struct AvatarAction: View {
    let avatarUrl: String?
    let name: String
    let size: CGFloat
    let connectionStatus: ConnectionDisplayStatus
    let isOwnPost: Bool
    var onAvatarTap: (() -> Void)? = nil
    var onConnectTap: (() -> Void)? = nil
    var onDisconnectTap: (() -> Void)? = nil
    /// Forwarded to the underlying `AvatarView` so the avatar can act as a
    /// zoom-transition source into a profile. No-op when either is nil.
    var zoomID: AnyHashable? = nil
    var zoomNamespace: Namespace.ID? = nil

    // One component, one tap target: the whole avatar (with its status badge)
    // is a single button that opens the profile.
    var body: some View {
        Button(action: { onAvatarTap?() }) {
            ZStack(alignment: .bottomTrailing) {
                AvatarView(
                    avatarUrl: avatarUrl,
                    name: name,
                    size: size,
                    zoomID: zoomID,
                    zoomNamespace: zoomNamespace
                )

                if !isOwnPost {
                    badgeIcon(badgeIconName)
                        .offset(x: 4, y: 4)
                }
            }
        }
        .buttonStyle(.pressableScale(0.9))
    }

    private var badgeIconName: String {
        switch connectionStatus {
        case .connected: return "feed.connected"
        case .pending:   return "feed.clock"
        case .none:      return "feed.connect"
        }
    }

    // Connect badge — Figma: 22px ring (surface) → 18px dark disc → 10px Flex line icon.
    private func badgeIcon(_ lineIcon: String) -> some View {
        ZStack {
            Circle()
                .fill(Color.appSurface)
                .frame(width: 22, height: 22)
            Circle()
                .fill(Color.appPrimary)
                .frame(width: 18, height: 18)
            Image(lineIcon)
                .renderingMode(.template)
                .resizable()
                .scaledToFit()
                .frame(width: 10, height: 10)
                .foregroundColor(.appSurface)
        }
        .contentShape(Circle())
    }
}
