//
//  SettingsView.swift
//  junto
//
//  Settings screen: notifications, appearance, support, sign out, delete account
//

import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL
    @EnvironmentObject private var currentUser: CurrentUserManager
    @EnvironmentObject private var themeManager: ThemeManager
    @StateObject private var viewModel = SettingsViewModel()

    private var hairline: CGFloat { 1 / UIScreen.main.scale }

    var body: some View {
        NavigationStack {
            GeometryReader { geo in
            ScrollView {
                VStack(spacing: 0) {

                    // MARK: - Account

                    sectionHeader("Account")

                    NavigationLink {
                        NotificationSettingsView()
                    } label: {
                        settingsRow(
                            icon: "bell",
                            title: "Notifications",
                            trailing: viewModel.isCheckingNotifications
                                ? nil
                                : (viewModel.notificationsEnabled ? "On" : "Off"),
                            showChevron: true
                        )
                    }
                    .buttonStyle(.plain)

                    divider

                    HStack(spacing: Spacing.md) {
                        Image(systemName: "moon")
                            .font(.system(size: 16))
                            .foregroundColor(.appPrimary)
                            .frame(width: 24)

                        Text("Appearance")
                            .font(.bodyLarge)
                            .foregroundColor(.appPrimary)

                        Spacer()

                        Menu {
                            ForEach(AppearanceTheme.allCases) { theme in
                                Button {
                                    themeManager.selectedTheme = theme
                                } label: {
                                    if theme == themeManager.selectedTheme {
                                        Label(theme.displayName, systemImage: "checkmark")
                                    } else {
                                        Text(theme.displayName)
                                    }
                                }
                            }
                        } label: {
                            HStack(spacing: Spacing.xxs) {
                                Text(themeManager.selectedTheme.displayName)
                                    .font(.body14)
                                    .foregroundColor(.appSecondary)
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundColor(.appTertiary)
                            }
                        }
                    }
                    .padding(.horizontal, Spacing.lg)
                    .padding(.vertical, Spacing.md)

                    // MARK: - Support

                    sectionHeader("Support")

                    settingsButton(icon: "envelope", title: "Contact Support") {
                        openURL(URL(string: "mailto:support@onjunto.com")!)
                    }

                    divider

                    settingsButton(icon: "doc.text", title: "Privacy Policy") {
                        openURL(URL(string: "https://onjunto.com/privacy")!)
                    }

                    divider

                    settingsButton(icon: "doc.text", title: "Terms of Service") {
                        openURL(URL(string: "https://onjunto.com/terms")!)
                    }

                    Spacer(minLength: Spacing.xxxl)

                    // MARK: - Actions

                    VStack(spacing: Spacing.md) {
                        PrimaryButton(title: "Sign Out", variant: .outlined) {
                            dismiss()
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                viewModel.signOut()
                            }
                        }

                        Button {
                            viewModel.showDeleteConfirmation = true
                        } label: {
                            if viewModel.isDeleting {
                                ProgressView()
                                    .tint(.appError)
                            } else {
                                Text("Delete Account")
                                    .font(.bodySemibold)
                                    .foregroundColor(.appError)
                            }
                        }
                        .buttonStyle(.plain)
                        .disabled(viewModel.isDeleting)
                        .padding(.top, Spacing.xs)

                        // App Info
                        VStack(spacing: Spacing.xxs) {
                            Text("Junto")
                                .font(.captionSemibold)
                                .foregroundColor(.appSecondary)
                            Text("v\(appVersion)")
                                .font(.caption12)
                                .foregroundColor(.appTertiary)
                        }
                        .padding(.top, Spacing.lg)
                    }
                    .padding(.horizontal, Spacing.lg)
                    .padding(.bottom, Spacing.xxl)
                }
                .frame(minHeight: geo.size.height)
            }
            }
            .background(Color.appBackground)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.appPrimary)
                    }
                }

                ToolbarItem(placement: .principal) {
                    Text("Settings")
                        .font(.heading3)
                        .foregroundColor(.appPrimary)
                }
            }
            .alert("Delete Account?", isPresented: $viewModel.showDeleteConfirmation) {
                Button("Cancel", role: .cancel) {}
                Button("Delete", role: .destructive) {
                    Task { await viewModel.deleteAccount() }
                }
            } message: {
                Text("This cannot be undone. All your posts, connections, and profile data will be permanently removed.")
            }
        }
        .presentationDragIndicator(.visible)
        .task {
            await viewModel.checkNotificationStatus()
        }
    }

    // MARK: - Helpers

    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    }

    private var divider: some View {
        Rectangle()
            .fill(Color.appDivider)
            .frame(height: hairline)
            .padding(.leading, Spacing.lg + 24 + Spacing.md) // Align with text, past icon
    }

    private var sectionDivider: some View {
        Rectangle()
            .fill(Color.appDivider)
            .frame(height: hairline)
    }

    private func sectionHeader(_ title: String) -> some View {
        Text(title.uppercased())
            .font(.captionSemibold)
            .foregroundColor(.appSecondary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, Spacing.lg)
            .padding(.top, Spacing.xxl)
            .padding(.bottom, Spacing.sm)
    }

    private func settingsButton(icon: String, title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            settingsRow(icon: icon, title: title)
        }
        .buttonStyle(.plain)
    }

    private func settingsRow(icon: String, title: String, trailing: String? = nil, showChevron: Bool = false) -> some View {
        HStack(spacing: Spacing.md) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(.appPrimary)
                .frame(width: 24)

            Text(title)
                .font(.bodyLarge)
                .foregroundColor(.appPrimary)

            Spacer()

            if let trailing {
                Text(trailing)
                    .font(.body14)
                    .foregroundColor(.appSecondary)
            }

            if showChevron {
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.appTertiary)
            }
        }
        .padding(.horizontal, Spacing.lg)
        .padding(.vertical, Spacing.md)
    }
}

#Preview("Settings") {
    let userManager = CurrentUserManager.shared
    let _ = { userManager.user = .mock }()
    SettingsView()
        .environmentObject(ThemeManager.shared)
        .environmentObject(userManager)
}

#Preview("Settings - Dark") {
    let userManager = CurrentUserManager.shared
    let _ = { userManager.user = .mock }()
    SettingsView()
        .environmentObject(ThemeManager.shared)
        .environmentObject(userManager)
        .preferredColorScheme(.dark)
}
