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
    @Environment(\.tabBarVisible) private var tabBarVisible
    @EnvironmentObject private var currentUser: CurrentUserManager
    @StateObject private var viewModel = MessagesListViewModel()
    @State private var selectedConversation: ConversationResponse?
    @State private var showNewConversation = false
    @State private var chatParticipant: UserResponse?
    @State private var chatConversationId: String?

    var body: some View {
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
        .background(Color.appBackground)
        .onReceive(NotificationCenter.default.publisher(for: .composeFABTapped)) { notif in
            if notif.object as? String == Tab.messages.rawValue {
                showNewConversation = true
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillShowNotification)) { _ in
            withAnimation(.easeOut(duration: 0.25)) {
                tabBarVisible.wrappedValue = false
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)) { _ in
            withAnimation(.easeOut(duration: 0.25)) {
                tabBarVisible.wrappedValue = true
            }
        }
        .onDisappear {
            tabBarVisible.wrappedValue = true
        }
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
        .padding(Spacing.md)
        .background(Color.appSurfaceSecondary)
        .clipShape(RoundedRectangle(cornerRadius: Radius.xxl))
        .padding(.horizontal, Spacing.lg)
        .padding(.vertical, Spacing.sm)
        .background(Color.appSurface)
    }

    // MARK: - Filter Tabs

    private var filterTabs: some View {
        HStack(spacing: Spacing.sm) {
            ForEach(MessagesFilter.allCases, id: \.self) { tab in
                let isSelected = viewModel.filter == tab
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.15)) {
                        viewModel.filter = tab
                    }
                }) {
                    HStack(spacing: Spacing.xxs) {
                        Text(tab.rawValue)
                            .font(isSelected ? .bodySemibold : .bodyMedium)
                            .foregroundColor(isSelected ? .appOnAccent : .appSecondary)

                        if tab == .requests && viewModel.requestCount > 0 {
                            Text("\(viewModel.requestCount)")
                                .font(.captionSmallSemibold)
                                .foregroundColor(isSelected ? .appPrimary : .appOnAccent)
                                .padding(.horizontal, 5)
                                .padding(.vertical, 1)
                                .background(isSelected ? Color.appOnAccent : Color.appSecondary)
                                .clipShape(Capsule())
                        }
                    }
                    .padding(.horizontal, 13)
                    .frame(height: 32)
                    .background(isSelected ? Color.appPrimary : Color.appSurfaceSecondary)
                    .clipShape(RoundedRectangle(cornerRadius: Radius.xl))
                }
                .buttonStyle(.plain)
            }

            Spacer()
        }
        .padding(.horizontal, Spacing.lg)
        .padding(.bottom, Spacing.sm)
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
