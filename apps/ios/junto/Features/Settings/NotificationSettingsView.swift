//
//  NotificationSettingsView.swift
//  junto
//
//  Notification preferences — directs users to system settings if denied
//

import SwiftUI
import UserNotifications

struct NotificationSettingsView: View {
    @Environment(\.openURL) private var openURL
    @State private var authStatus: UNAuthorizationStatus = .notDetermined
    @State private var isLoading = true

    private var hairline: CGFloat { 1 / UIScreen.main.scale }

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {

                // Status row
                HStack {
                    VStack(alignment: .leading, spacing: Spacing.xxs) {
                        Text("Push Notifications")
                            .font(.bodyLarge)
                            .foregroundColor(.appPrimary)
                        Text(statusDescription)
                            .font(.body14)
                            .foregroundColor(.appSecondary)
                    }

                    Spacer()

                    if isLoading {
                        ProgressView()
                    } else {
                        statusBadge
                    }
                }
                .padding(.horizontal, Spacing.lg)
                .padding(.vertical, Spacing.lg)

                Rectangle()
                    .fill(Color.appDivider)
                    .frame(height: hairline)

                // Open settings button if denied
                if authStatus == .denied {
                    Button {
                        if let url = URL(string: UIApplication.openSettingsURLString) {
                            openURL(url)
                        }
                    } label: {
                        Text("Open Settings to Enable")
                            .font(.bodyLargeMedium)
                            .foregroundColor(.appTint)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, Spacing.lg)
                    }
                    .buttonStyle(.plain)

                    Rectangle()
                        .fill(Color.appDivider)
                        .frame(height: hairline)
                }

                // What you'll receive
                VStack(alignment: .leading, spacing: Spacing.md) {
                    Text("You'll receive notifications for:")
                        .font(.bodySemibold)
                        .foregroundColor(.appPrimary)

                    notificationItem("New connection requests")
                    notificationItem("Messages from connections")
                    notificationItem("Event updates and reminders")
                    notificationItem("Comments and mentions")
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, Spacing.lg)
                .padding(.vertical, Spacing.xxl)
            }
        }
        .background(Color.appBackground)
        .navigationTitle("Notifications")
        .navigationBarTitleDisplayMode(.inline)
        .task { await checkStatus() }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
            Task { await checkStatus() }
        }
    }

    private var statusDescription: String {
        switch authStatus {
        case .authorized: return "Enabled"
        case .denied: return "Disabled"
        case .provisional: return "Provisional"
        case .notDetermined: return "Not set up"
        default: return "Unknown"
        }
    }

    @ViewBuilder
    private var statusBadge: some View {
        switch authStatus {
        case .authorized:
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(.appSuccess)
                .font(.system(size: 20))
        case .denied:
            Image(systemName: "xmark.circle.fill")
                .foregroundColor(.appError)
                .font(.system(size: 20))
        default:
            Image(systemName: "minus.circle")
                .foregroundColor(.appSecondary)
                .font(.system(size: 20))
        }
    }

    private func notificationItem(_ text: String) -> some View {
        HStack(spacing: Spacing.sm) {
            Circle()
                .fill(Color.appSecondary)
                .frame(width: 4, height: 4)
            Text(text)
                .font(.body14)
                .foregroundColor(.appSecondary)
        }
    }

    private func checkStatus() async {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        authStatus = settings.authorizationStatus
        isLoading = false
    }
}

#Preview {
    NavigationStack {
        NotificationSettingsView()
    }
}
