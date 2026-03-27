//
//  MessagesView.swift
//  mkrs-world
//
//  Conversation list screen (presented as sheet from top nav bar)
//

import SwiftUI
import Clerk
import Combine

struct MessagesView: View {
    @Environment(\.clerk) private var clerk
    @EnvironmentObject private var currentUser: CurrentUserManager
    @StateObject private var viewModel = MessagesListViewModel()
    @State private var selectedConversation: ConversationResponse?
    @State private var showNewConversation = false
    @State private var chatParticipant: UserResponse?
    @State private var chatConversationId: String?

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            VStack(spacing: 0) {
                searchBar
                filterTabs

                ZStack {
                    Color.appBackground.ignoresSafeArea()

                    if viewModel.isLoading && viewModel.conversations.isEmpty {
                        loadingState
                    } else {
                        mainList
                    }
                }
            }

            Button(action: { showNewConversation = true }) {
                Image(systemName: "plus")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(.white)
                    .frame(width: 48, height: 48)
                    .background(Color.appPrimary)
                    .clipShape(Circle())
                    .shadow(color: .black.opacity(0.15), radius: 8, x: 0, y: 4)
            }
            .padding(.trailing, Spacing.lg)
            .padding(.bottom, Spacing.xl)
        }
        .background(Color.appBackground)
        .sheet(item: $selectedConversation) { conversation in
            if let otherParticipant = conversation.otherParticipant,
               let userId = currentUser.userId {
                ChatDetailView(
                    conversationId: conversation._id,
                    otherParticipant: otherParticipant,
                    currentUserId: userId,
                    isRequest: conversation.isRequest == true
                )
                .presentationDragIndicator(.visible)
            }
        }
        .sheet(isPresented: $showNewConversation) {
            if let userId = currentUser.userId {
                NewConversationSheet(currentUserId: userId) { user in
                    showNewConversation = false
                    Task {
                        let conv = try? await ConvexClientManager.shared.fetchConversationBetween(
                            userId1: userId,
                            userId2: user._id
                        )
                        chatConversationId = conv?._id
                        chatParticipant = user
                    }
                }
            }
        }
        .sheet(item: $chatParticipant) { participant in
            if let userId = currentUser.userId {
                ChatDetailView(
                    conversationId: chatConversationId,
                    otherParticipant: participant,
                    currentUserId: userId
                )
                .presentationDragIndicator(.visible)
            }
        }
        .task {
            if let userId = currentUser.userId {
                viewModel.subscribe(userId: userId)
            }
            AnalyticsService.shared.track(.messagesViewed)
        }
    }

    // MARK: - Search Bar

    private var searchBar: some View {
        HStack(spacing: Spacing.sm) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 16))
                .foregroundColor(.appSecondary)

            TextField("Search conversations...", text: $viewModel.searchText)
                .font(.body14)
                .foregroundColor(.appPrimary)

            if !viewModel.searchText.isEmpty {
                Button(action: { viewModel.searchText = "" }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 14))
                        .foregroundColor(.appSecondary)
                }
            }
        }
        .padding(.horizontal, Spacing.md)
        .padding(.vertical, Spacing.sm)
        .background(Color.appSurfaceSecondary)
        .clipShape(Capsule())
        .padding(.horizontal, Spacing.md)
        .padding(.vertical, Spacing.sm)
        .background(Color.appSurface)
    }

    // MARK: - Filter Tabs

    private var filterTabs: some View {
        HStack(spacing: Spacing.sm) {
            ForEach(MessagesFilter.allCases, id: \.self) { tab in
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.15)) {
                        viewModel.filter = tab
                    }
                }) {
                    HStack(spacing: Spacing.xxs) {
                        Text(tab.rawValue)
                            .font(.bodyMedium)

                        if tab == .requests && viewModel.requestCount > 0 {
                            Text("\(viewModel.requestCount)")
                                .font(.captionSmallSemibold)
                                .foregroundColor(viewModel.filter == tab ? .appSurface : .white)
                                .padding(.horizontal, 5)
                                .padding(.vertical, 1)
                                .background(viewModel.filter == tab ? .appPrimary : Color.appSecondary)
                                .clipShape(Capsule())
                        }
                    }
                    .foregroundColor(.appPrimary)
                    .padding(.horizontal, 14)
                    .padding(.vertical, Spacing.xs)
                    .background(viewModel.filter == tab ? Color.appSurfaceSecondary : Color.appSurface)
                    .clipShape(Capsule())
                    .overlay(Capsule().stroke(Color.appDivider, lineWidth: 1))
                }
                .buttonStyle(.plain)
            }

            Spacer()
        }
        .padding(.horizontal, Spacing.md)
        .padding(.vertical, Spacing.xs)
        .background(Color.appSurface)
    }

    // MARK: - Main List

    private var mainList: some View {
        ScrollView(showsIndicators: false) {
            LazyVStack(spacing: 0) {
                let conversations = viewModel.filteredConversations
                let suggested = viewModel.suggestedUsers

                if conversations.isEmpty && suggested.isEmpty {
                    emptyState
                        .padding(.top, 80)
                } else {
                    if !conversations.isEmpty {
                        ForEach(conversations) { conversation in
                            ConversationRow(
                                conversation: conversation,
                                currentUserId: currentUser.userId
                            )
                            .contentShape(Rectangle())
                            .onTapGesture {
                                selectedConversation = conversation
                            }
                        }
                    }

                    if !suggested.isEmpty {
                        suggestedSection(users: suggested)
                    }
                }

                Color.clear.frame(height: 80)
            }
        }
    }

    // MARK: - Suggested Section

    private func suggestedSection(users: [UserResponse]) -> some View {
        VStack(alignment: .leading, spacing: Spacing.lg) {
            Text("Suggested")
                .font(.bodySemibold)
                .foregroundColor(.appPrimary)
                .padding(.horizontal, Spacing.md)
                .padding(.top, Spacing.xl)
                .padding(.bottom, Spacing.md)

            ForEach(users) { user in
                SuggestedMessageRow(
                    user: user,
                    onMessageTap: {
                        guard let userId = currentUser.userId else { return }
                        Task {
                            let conv = try? await ConvexClientManager.shared.fetchConversationBetween(
                                userId1: userId,
                                userId2: user._id
                            )
                            chatConversationId = conv?._id
                            chatParticipant = user
                        }
                    },
                    onDismiss: {
                        withAnimation(.easeOut(duration: 0.2)) {
                            viewModel.dismissSuggestion(user._id)
                        }
                    }
                )
            }
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        EmptyStateView(
            icon: viewModel.filter == .requests ? "tray" : "bubble.left.and.bubble.right",
            title: viewModel.filter == .requests ? "No message requests" : "No messages yet",
            subtitle: viewModel.filter == .requests
                ? "Message requests from other users will appear here"
                : "Connect with users to start chatting"
        )
    }

    // MARK: - Loading State

    private var loadingState: some View {
        VStack {
            Spacer()
            ProgressView()
                .tint(.appSecondary)
            Spacer()
        }
    }
}

#Preview {
    MessagesView()
        .environmentObject(CurrentUserManager.shared)
}
