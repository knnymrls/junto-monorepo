//
//  NewConversationSheet.swift
//  mkrs-world
//
//  Sheet for starting new conversation from connections list
//

import SwiftUI

struct NewConversationSheet: View {
    let currentUserId: String
    let onSelect: (UserResponse) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var connections: [UserResponse] = []
    @State private var isLoading = true

    var body: some View {
        NavigationStack {
            ZStack {
                Color.appBackground.ignoresSafeArea()

                if isLoading {
                    ProgressView()
                        .tint(.appSecondary)
                } else if connections.isEmpty {
                    EmptyStateView(
                        icon: "person.2",
                        title: "No connections yet",
                        subtitle: "Connect with users first to start chatting"
                    )
                } else {
                    ScrollView(showsIndicators: false) {
                        LazyVStack(spacing: 0) {
                            ForEach(connections) { user in
                                Button(action: { onSelect(user) }) {
                                    HStack(spacing: Spacing.md) {
                                        AvatarView(
                                            avatarUrl: user.avatarUrl,
                                            name: user.name,
                                            size: 40
                                        )

                                        VStack(alignment: .leading, spacing: Spacing.xxxs) {
                                            Text(user.name)
                                                .font(.bodyLargeMedium)
                                                .foregroundColor(.appPrimary)

                                            if let headline = user.headline {
                                                Text(headline)
                                                    .font(.bodySmall)
                                                    .foregroundColor(.appSecondary)
                                                    .lineLimit(1)
                                            }
                                        }

                                        Spacer()
                                    }
                                    .padding(.horizontal, Spacing.lg)
                                    .padding(.vertical, Spacing.md - 2)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
            }
            .navigationTitle("New Message")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(.appPrimary)
                }
            }
        }
        .task {
            do {
                connections = try await ConvexClientManager.shared.fetchConnections(userId: currentUserId)
            } catch {
                print("Fetch connections error: \(error)")
            }
            isLoading = false
        }
    }
}
