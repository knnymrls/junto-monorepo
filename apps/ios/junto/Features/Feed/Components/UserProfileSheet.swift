//
//  UserProfileSheet.swift
//  mkrs-world
//
//  Quick profile sheet for viewing a user from feed context
//

import SwiftUI

struct UserProfileSheet: View {
    let user: UserResponse
    @EnvironmentObject private var currentUser: CurrentUserManager
    @State private var connectionStatus: ConnectionStatus = .none
    @State private var isLoadingStatus = true
    @State private var isActioning = false

    var body: some View {
        VStack(spacing: Spacing.lg) {
            // Avatar and name
            AvatarView(
                avatarUrl: user.avatarUrl,
                name: user.name,
                size: 80
            )
            .padding(.top, Spacing.xxl)

            Text(user.name)
                .font(.heading2)
                .foregroundColor(.appPrimary)

            Text(user.headline ?? "")
                .font(.body14)
                .foregroundColor(.appSecondary)
                .multilineTextAlignment(.center)

            if !isLoadingStatus && !isSelf {
                ConnectionButton(
                    status: connectionStatus,
                    isLoading: isActioning,
                    onConnect: sendRequest,
                    onAccept: acceptRequest
                )
                .padding(.horizontal, Spacing.xxl)
                .padding(.top, Spacing.xxs)
            }

            Spacer()
        }
        .frame(maxWidth: .infinity)
        .background(Color.appBackground)
        .presentationDragIndicator(.visible)
        .task {
            AnalyticsService.shared.track(.profileViewed(userId: user._id))
            guard let userId = currentUser.userId, userId != user._id else {
                isLoadingStatus = false
                return
            }
            do {
                connectionStatus = try await ConvexClientManager.shared.getConnectionStatus(
                    fromUserId: userId,
                    toUserId: user._id
                )
            } catch {
                print("Connection status error: \(error)")
            }
            isLoadingStatus = false
        }
    }

    private var isSelf: Bool {
        currentUser.userId == user._id
    }

    private func sendRequest() {
        guard let userId = currentUser.userId else { return }
        isActioning = true
        Task {
            do {
                _ = try await ConvexClientManager.shared.sendConnectionRequest(
                    requesterId: userId,
                    accepterId: user._id
                )
                connectionStatus = .pendingSent
            } catch {
                print("Send connection request error: \(error)")
            }
            isActioning = false
        }
    }

    private func acceptRequest() {
        guard let userId = currentUser.userId else { return }
        isActioning = true
        Task {
            do {
                _ = try await ConvexClientManager.shared.acceptConnectionRequestByUsers(
                    currentUserId: userId,
                    otherUserId: user._id
                )
                connectionStatus = .connected
            } catch {
                print("Accept connection request error: \(error)")
            }
            isActioning = false
        }
    }
}
