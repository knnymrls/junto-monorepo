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

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            Button(action: { onAvatarTap?() }) {
                AvatarView(
                    avatarUrl: avatarUrl,
                    name: name,
                    size: size
                )
            }
            .buttonStyle(.plain)

            if !isOwnPost {
                badge
            }
        }
    }

    @ViewBuilder
    private var badge: some View {
        switch connectionStatus {
        case .connected:
            Menu {
                Button(action: { onAvatarTap?() }) {
                    Label("View Profile", systemImage: "person")
                }
                Button(role: .destructive, action: { onDisconnectTap?() }) {
                    Label("Remove Connection", systemImage: "person.badge.minus")
                }
            } label: {
                badgeIcon("status.connection.fill")
            }
            .offset(x: Spacing.xxs, y: Spacing.xxs)

        case .pending:
            Menu {
                Button(action: { onAvatarTap?() }) {
                    Label("View Profile", systemImage: "person")
                }
                Button(role: .destructive, action: { onDisconnectTap?() }) {
                    Label("Cancel Request", systemImage: "xmark")
                }
            } label: {
                badgeIcon("status.waiting.fill")
            }
            .offset(x: Spacing.xxs, y: Spacing.xxs)

        case .none:
            Menu {
                Button(action: { onAvatarTap?() }) {
                    Label("View Profile", systemImage: "person")
                }
                Button(action: { onConnectTap?() }) {
                    Label("Connect", systemImage: "plus")
                }
            } label: {
                badgeIcon("status.add.fill")
                    .frame(width: 30, height: 30)
                    .contentShape(Circle())
            }
            .offset(x: 10, y: 10)
        }
    }

    private func badgeIcon(_ imageName: String) -> some View {
        ZStack {
            Circle()
                .fill(Color.appSurface)
                .frame(width: 22, height: 22)
            Image(imageName)
                .resizable()
                .frame(width: 18, height: 18)
                .foregroundColor(.appPrimary)
        }
    }
}
