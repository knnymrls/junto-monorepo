//
//  ProfileView.swift
//  mkrs-world
//
//  Tabbed profile view — Portfolio | Posts | About
//

import SwiftUI
import Combine

enum ProfileTab: String, CaseIterable {
    case portfolio = "Portfolio"
    case posts = "Posts"
    case about = "About"
}

struct ProfileView: View {
    let user: UserResponse
    @EnvironmentObject private var currentUser: CurrentUserManager
    @State private var selectedTab: ProfileTab = .portfolio
    @State private var connectionStatus: ConnectionStatus = .none
    @State private var isLoadingStatus = true
    @State private var connectionCount: Int = 0
    @State private var isActioning = false
    @State private var hasVouched = false
    @State private var showVouchSheet = false
    @State private var vouches: [VouchResponse] = []
    @Environment(\.dismiss) private var dismiss

    var isSelf: Bool {
        currentUser.userId == user._id
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    ProfileHeaderView(
                        user: user,
                        connectionStatus: connectionStatus,
                        connectionCount: connectionCount,
                        vouchCount: vouches.count,
                        hasVouched: hasVouched,
                        isSelf: isSelf,
                        isLoadingStatus: isLoadingStatus,
                        isActioning: $isActioning,
                        showVouchSheet: $showVouchSheet,
                        onConnect: sendRequest,
                        onAccept: acceptRequest
                    )

                    profileTabBar
                        .padding(.top, Spacing.lg)

                    Divider()
                        .foregroundColor(.appDivider)

                    tabContent
                        .padding(.top, Spacing.md)
                }
            }
            .background(Color.appBackground)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark")
                            .font(.bodyLargeMedium)
                            .foregroundColor(.appPrimary)
                    }
                }
            }
        }
        .presentationDragIndicator(.visible)
        .sheet(isPresented: $showVouchSheet) {
            VouchSheet(
                userName: user.name,
                fromUserId: currentUser.userId ?? "",
                toUserId: user._id,
                onVouched: {
                    hasVouched = true
                    Task { await loadVouches() }
                }
            )
        }
        .task {
            AnalyticsService.shared.track(.profileViewed(userId: user._id))
            await loadConnectionData()
            await loadVouches()
        }
    }

    // MARK: - Tab Bar

    private var profileTabBar: some View {
        HStack(spacing: 0) {
            ForEach(ProfileTab.allCases, id: \.self) { tab in
                Button(action: { withAnimation(.easeInOut(duration: 0.2)) { selectedTab = tab } }) {
                    VStack(spacing: Spacing.sm) {
                        Text(tab.rawValue)
                            .font(selectedTab == tab ? .bodySemibold : .body14)
                            .foregroundColor(selectedTab == tab ? .appPrimary : .appSecondary)

                        Rectangle()
                            .fill(selectedTab == tab ? Color.appPrimary : Color.clear)
                            .frame(height: 2)
                    }
                }
                .frame(maxWidth: .infinity)
            }
        }
        .padding(.horizontal, Spacing.lg)
    }

    // MARK: - Tab Content

    @ViewBuilder
    private var tabContent: some View {
        switch selectedTab {
        case .portfolio:
            PortfolioTabView(userId: user._id, isSelf: isSelf)
        case .posts:
            PostsTabView(authorId: user._id, authorName: user.name, isSelf: isSelf)
        case .about:
            AboutTabView(user: user, vouches: vouches)
        }
    }

    // MARK: - Data Loading

    private func loadConnectionData() async {
        // Load connection count
        do {
            let connections = try await ConvexClientManager.shared.fetchConnections(userId: user._id)
            connectionCount = connections.count
        } catch {
            print("ProfileView: Failed to fetch connections: \(error)")
        }

        // Load connection status if not self
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
            print("ProfileView: Connection status error: \(error)")
        }
        // Load vouch status if connected and not self
        if connectionStatus == .connected {
            do {
                hasVouched = try await ConvexClientManager.shared.hasVouched(
                    fromUserId: userId,
                    toUserId: user._id
                )
            } catch {
                print("ProfileView: Has vouched check error: \(error)")
            }
        }

        isLoadingStatus = false
    }

    private func loadVouches() async {
        do {
            vouches = try await ConvexClientManager.shared.fetchVouches(userId: user._id)
        } catch {
            print("ProfileView: Failed to fetch vouches: \(error)")
        }
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
