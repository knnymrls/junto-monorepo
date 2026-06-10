//
//  SideMenuView.swift
//  mkrs-world
//
//  Right slide-out drawer menu for profile and settings access
//

import SwiftUI

struct SideMenuView: View {
    @Binding var isPresented: Bool
    let user: UserResponse?
    var onProfileTap: () -> Void
    var onSettingsTap: () -> Void
    var onSignOutTap: () -> Void = {}

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Profile header
            profileHeader

            Divider()
                .padding(.vertical, Spacing.lg)

            // Menu items
            menuItems

            Spacer()

            // App version
            Text("Junto v1.0")
                .font(.caption12)
                .foregroundColor(.appSecondary)
                .padding(.bottom, Spacing.xxl)
        }
        .padding(.horizontal, Spacing.xl)
        .padding(.top, 60)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.appDrawerBackground)
        .ignoresSafeArea()
    }

    // MARK: - Profile Header

    private var profileHeader: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            AvatarView(
                avatarUrl: user?.avatarUrl,
                name: user?.name ?? "?",
                size: 56
            )

            VStack(alignment: .leading, spacing: Spacing.xxs) {
                Text(user?.name ?? "")
                    .font(.heading3)
                    .foregroundColor(.appPrimary)

                if let headline = user?.headline, !headline.isEmpty {
                    Text(headline)
                        .font(.body14)
                        .foregroundColor(.appSecondary)
                        .lineLimit(2)
                }
            }
        }
    }

    // MARK: - Menu Items

    private var menuItems: some View {
        VStack(alignment: .leading, spacing: 0) {
            MenuRow(
                icon: "person",
                title: "View Profile",
                action: {
                    withAnimation(.easeInOut(duration: 0.25)) {
                        isPresented = false
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        onProfileTap()
                    }
                }
            )

            MenuRow(
                icon: "gearshape",
                title: "Settings",
                action: {
                    withAnimation(.easeInOut(duration: 0.25)) {
                        isPresented = false
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        onSettingsTap()
                    }
                }
            )

            MenuRow(
                icon: "rectangle.portrait.and.arrow.right",
                title: "Sign Out",
                action: {
                    withAnimation(.easeInOut(duration: 0.25)) {
                        isPresented = false
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        onSignOutTap()
                    }
                }
            )
        }
    }
}

// MARK: - Menu Row

struct MenuRow: View {
    let icon: String
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: Spacing.lg) {
                Image(systemName: icon)
                    .font(.heading2)
                    .foregroundColor(.appPrimary)
                    .frame(width: 24)

                Text(title)
                    .font(.bodyLargeMedium)
                    .foregroundColor(.appPrimary)

                Spacer()
            }
            .padding(.vertical, 14)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    HStack(spacing: 0) {
        // Simulated feed (pushed left)
        Color.appSurface
            .overlay(Text("Feed"))
            .shadow(color: .black.opacity(0.08), radius: 8, x: -4, y: 0)

        // Menu with dimmed background
        SideMenuView(
            isPresented: .constant(true),
            user: .mock,
            onProfileTap: {},
            onSettingsTap: {}
        )
        .frame(width: 280)
    }
}
