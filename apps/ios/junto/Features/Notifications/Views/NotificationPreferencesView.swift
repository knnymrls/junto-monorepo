//
//  NotificationPreferencesView.swift
//  junto
//
//  Lets people turn notification categories on/off. Toggling a category writes
//  the muted set back to the user; muted categories are suppressed server-side
//  (both the in-app row and the push) in notifications.notifyUser.
//

import SwiftUI

struct NotificationPreferencesView: View {
    @EnvironmentObject private var currentUser: CurrentUserManager
    @Environment(\.dismiss) private var dismiss

    /// Category keys must match the backend's TYPE_TO_CATEGORY values.
    private struct Category: Identifiable {
        let key: String
        let title: String
        let subtitle: String
        let icon: String
        var id: String { key }
    }

    private let categories: [Category] = [
        .init(key: "connections", title: "Connections", subtitle: "Requests and accepted connections", icon: "notif.connections"),
        .init(key: "messages", title: "Messages", subtitle: "New messages and message requests", icon: "notif.messages"),
        .init(key: "events", title: "Events", subtitle: "RSVPs, reminders, and new events", icon: "notif.events"),
        .init(key: "comments", title: "Comments & mentions", subtitle: "Replies and @mentions on your posts", icon: "notif.comments"),
        .init(key: "updates", title: "Updates", subtitle: "Prompts, weekly digests, and milestones", icon: "notif.updates"),
    ]

    @State private var muted: Set<String> = []
    @State private var loaded = false
    @State private var saveError: String?

    private var hairline: CGFloat { 1 / UIScreen.main.scale }

    var body: some View {
        VStack(spacing: 0) {
            header

            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    Text("Choose what you want to be notified about. This applies to push and in-app activity.")
                        .font(.body14)
                        .foregroundColor(.appSecondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, Spacing.lg)
                        .padding(.top, Spacing.md)
                        .padding(.bottom, Spacing.lg)

                    ForEach(categories) { category in
                        row(category)
                        if category.id != categories.last?.id {
                            Rectangle()
                                .fill(Color.appDivider)
                                .frame(height: hairline)
                                .padding(.leading, 68)
                        }
                    }
                }
            }
        }
        .background(Color.appBackground)
        .task {
            guard !loaded, let userId = currentUser.userId else { return }
            do {
                muted = Set(try await ConvexClientManager.shared.fetchNotificationPreferences(userId: userId))
                loaded = true
            } catch {
                // Don't render default-ON toggles over unknown real state.
                saveError = "Couldn't load your notification settings. Try again."
                dismiss()
            }
        }
        .errorAlert($saveError)
    }

    // MARK: - Header

    private var header: some View {
        HStack {
            Text("Notifications")
                .font(.heading1)
                .foregroundColor(.appPrimary)

            Spacer()

            Button { dismiss() } label: {
                Text("Done")
                    .font(.bodyLargeMedium)
                    .foregroundColor(.appAccent)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, Spacing.lg)
        .padding(.top, Spacing.xxl)
        .padding(.bottom, Spacing.sm)
        .background(Color.appSurface)
    }

    // MARK: - Row

    private func row(_ category: Category) -> some View {
        let isOn = Binding<Bool>(
            get: { !muted.contains(category.key) },
            set: { on in
                if on { muted.remove(category.key) } else { muted.insert(category.key) }
                persist()
            }
        )

        return HStack(spacing: Spacing.md) {
            ZStack {
                Circle()
                    .fill(Color.appSurfaceSecondary)
                    .frame(width: 40, height: 40)
                Image(category.icon)
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 18, height: 18)
                    .foregroundColor(.appPrimary)
            }

            VStack(alignment: .leading, spacing: Spacing.xxs) {
                Text(category.title)
                    .font(.bodyLargeMedium)
                    .foregroundColor(.appPrimary)
                Text(category.subtitle)
                    .font(.body14)
                    .foregroundColor(.appSecondary)
                    .lineLimit(1)
            }

            Spacer(minLength: Spacing.sm)

            Toggle("", isOn: isOn)
                .labelsHidden()
                .tint(.appAccent)
        }
        .padding(.horizontal, Spacing.lg)
        .padding(.vertical, Spacing.md)
    }

    private func persist() {
        guard let userId = currentUser.userId else { return }
        let categoriesToMute = Array(muted)
        Task {
            do {
                try await ConvexClientManager.shared.setNotificationPreferences(
                    userId: userId,
                    mutedCategories: categoriesToMute
                )
            } catch {
                // The toggle animated but nothing persisted — reload truth.
                saveError = "Couldn't save that change. Try again."
                if let prefs = try? await ConvexClientManager.shared.fetchNotificationPreferences(userId: userId) {
                    muted = Set(prefs)
                }
            }
        }
    }
}

#Preview {
    NotificationPreferencesView()
        .environmentObject(CurrentUserManager.shared)
}
