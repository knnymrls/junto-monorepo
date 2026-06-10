//
//  ChatDetailView.swift
//  mkrs-world
//
//  Individual chat conversation screen
//

import SwiftUI

struct ChatDetailView: View {
    @StateObject private var viewModel: ChatViewModel
    @EnvironmentObject private var currentUser: CurrentUserManager
    @Environment(\.dismiss) private var dismiss
    @State private var showProfile = false
    @State private var showReportConfirmation = false
    @State private var replyTextHeight: CGFloat = 28
    @State private var chatImage: UIImage?
    @State private var chatLinkUrl: String?
    @State private var showLinkInput = false
    @State private var isInputFocused = false
    @State private var showMentionPicker = false
    @State private var mentionSuggestions: [MentionSuggestion] = []
    @State private var isLoadingMentions = false
    @State private var showGifPicker = false
    @State private var selectedGifUrl: URL?

    // Zoom transition namespace: chat header avatar → profile
    @Namespace private var profileZoom

    init(conversationId: String?, otherParticipant: UserResponse, currentUserId: String, isRequest: Bool = false) {
        _viewModel = StateObject(wrappedValue: ChatViewModel(
            conversationId: conversationId,
            otherParticipant: otherParticipant,
            currentUserId: currentUserId,
            isRequest: isRequest
        ))
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            VStack(spacing: 0) {
                chatHeader
                messagesList
                if viewModel.isOtherTyping {
                    typingIndicator
                }
                if viewModel.isRequest {
                    requestBanner
                } else {
                    VStack(spacing: 0) {
                        if viewModel.replyingTo != nil || viewModel.editingMessage != nil {
                            composerContextBar
                        }
                        inputBar
                    }
                }
            }
            .background(Color.appBackground)

            if showMentionPicker {
                MentionPicker(
                    suggestions: mentionSuggestions,
                    isLoading: isLoadingMentions,
                    onSelect: { selectMention($0) },
                    onClose: { showMentionPicker = false }
                )
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.easeInOut(duration: 0.2), value: showMentionPicker)
        .onAppear {
            viewModel.subscribe()
            viewModel.markAsRead()
            if let conversationId = viewModel.conversationId {
                AnalyticsService.shared.track(.conversationOpened(conversationId: conversationId))
            }
        }
        .onDisappear {
            viewModel.stopTyping()
        }
        .alert("Report this conversation?", isPresented: $showReportConfirmation) {
            Button("Cancel", role: .cancel) {}
            Button("Report", role: .destructive) {}
        } message: {
            Text("This will flag the conversation for review.")
        }
    }

    // MARK: - Chat Header

    private var chatHeader: some View {
        HStack(spacing: Spacing.sm) {
            DiscoverCircleButton(icon: "nav.back", action: { dismiss() })

            Button(action: { showProfile = true }) {
                HStack(spacing: Spacing.sm) {
                    AvatarView(
                        avatarUrl: viewModel.otherParticipant.avatarUrl,
                        name: viewModel.otherParticipant.name,
                        size: 40,
                        zoomID: AnyHashable(viewModel.otherParticipant._id),
                        zoomNamespace: profileZoom
                    )

                    VStack(alignment: .leading, spacing: Spacing.xxs) {
                        Text(viewModel.otherParticipant.name)
                            .font(.bodyMedium)
                            .foregroundColor(.appPrimary)

                        if let headline = viewModel.otherParticipant.headline {
                            Text(headline)
                                .font(.caption12)
                                .foregroundColor(.appSecondary)
                                .lineLimit(1)
                        }
                    }
                }
            }
            .buttonStyle(.plain)

            Spacer()

            Menu {
                Button(action: { showProfile = true }) {
                    Label("View Profile", systemImage: "person")
                }
                Button(role: .destructive, action: {
                    showReportConfirmation = true
                }) {
                    Label("Report", systemImage: "exclamationmark.triangle")
                }
            } label: {
                Image("nav.more")
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 24, height: 24)
                    .foregroundColor(.appPrimary)
                    .frame(width: 40, height: 40)
                    .contentShape(Rectangle())
            }
        }
        .padding(.horizontal, Spacing.lg)
        .padding(.bottom, Spacing.sm)
        .background(Color.appSurface.ignoresSafeArea(edges: .top))
        .fullScreenCover(isPresented: $showProfile) {
            ProfileView(user: viewModel.otherParticipant)
                .zoomDestination(id: viewModel.otherParticipant._id, in: profileZoom)
        }
    }

    // MARK: - Messages List

    private var messagesList: some View {
        ScrollViewReader { proxy in
            ScrollView(showsIndicators: false) {
                LazyVStack(spacing: Spacing.xxs) {
                    if viewModel.isLoading {
                        ProgressView()
                            .tint(.appSecondary)
                            .padding(.top, Spacing.huge)
                    }

                    ForEach(viewModel.messages) { message in
                        let reply = replyContext(for: message)
                        MessageBubble(
                            message: message,
                            isSent: message.senderId == viewModel.currentUserId,
                            currentUserId: viewModel.currentUserId,
                            replyAuthor: reply?.author,
                            replyText: reply?.text,
                            onReply: {
                                viewModel.beginReply(to: message)
                                isInputFocused = true
                            },
                            onEdit: {
                                viewModel.beginEdit(message)
                                isInputFocused = true
                            },
                            onDelete: { viewModel.deleteMessage(message) },
                            onReact: { viewModel.toggleReaction(message, emoji: $0) }
                        )
                        .id("\(message._id)_\(message.readAt ?? 0)")
                    }
                }
                .padding(.horizontal, Spacing.md)
                .padding(.vertical, Spacing.sm)
            }
            .scrollEdgeFade(top: true, bottom: true)
            .onChange(of: viewModel.messages.count) { _, _ in
                if let lastMessage = viewModel.messages.last {
                    withAnimation(.easeOut(duration: 0.2)) {
                        proxy.scrollTo(lastMessage._id, anchor: .bottom)
                    }
                }
                viewModel.markAsRead()
            }
            .onAppear {
                if let lastMessage = viewModel.messages.last {
                    proxy.scrollTo(lastMessage._id, anchor: .bottom)
                }
            }
        }
    }

    // MARK: - Typing Indicator

    private var typingIndicator: some View {
        HStack(spacing: Spacing.xxs) {
            Text("\(viewModel.otherParticipant.name) is typing")
                .font(.caption12)
                .foregroundColor(.appSecondary)

            TypingDots()
        }
        .padding(.horizontal, Spacing.lg)
        .padding(.vertical, Spacing.xxs)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Input Bar

    private var inputBar: some View {
        ReplyComposerBar(
            text: $viewModel.messageText,
            textHeight: $replyTextHeight,
            selectedImage: $chatImage,
            selectedGifUrl: $selectedGifUrl,
            isFocused: $isInputFocused,
            avatarUrl: currentUser.user?.avatarUrl,
            avatarName: currentUser.user?.name ?? "?",
            showMentionPicker: showMentionPicker,
            onMentionTap: { toggleMentionPicker() },
            onGifTap: {
                showGifPicker = true
            },
            onTextChange: { newValue in
                if !newValue.isEmpty {
                    viewModel.startTyping()
                }
                handleMentionSearch(newValue)
            },
            onSubmit: {
                if !viewModel.messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    viewModel.submitComposer()
                }
            }
        )
        .sheet(isPresented: $showLinkInput) {
            LinkInputSheet(linkUrl: $chatLinkUrl)
        }
        .sheet(isPresented: $showGifPicker) {
            GifPickerSheet { gif in
                // Chat: GIF selection = immediate send
                let gifUrlString = gif.mp4Url.absoluteString
                viewModel.sendMessage(gifUrl: gifUrlString)
                AnalyticsService.shared.track(.gifSent(conversationId: viewModel.conversationId ?? "new"))
            }
            .presentationDetents([.large])
        }
    }

    // MARK: - Mention Logic

    private func toggleMentionPicker() {
        if showMentionPicker {
            showMentionPicker = false
        } else {
            viewModel.messageText += "@"
            isInputFocused = true
            showMentionPicker = true
            loadMentionSuggestions(searchText: "")
        }
    }

    private func handleMentionSearch(_ text: String) {
        if let atIndex = text.lastIndex(of: "@") {
            let searchText = String(text[text.index(after: atIndex)...])
            if searchText.contains(" ") {
                if showMentionPicker { showMentionPicker = false }
            } else {
                if !showMentionPicker { showMentionPicker = true }
                loadMentionSuggestions(searchText: searchText)
            }
        } else if showMentionPicker {
            showMentionPicker = false
        }
    }

    private func loadMentionSuggestions(searchText: String) {
        isLoadingMentions = true
        Task { @MainActor in
            do {
                let suggestions = try await ConvexClientManager.shared.fetchMentionSuggestions(searchText: searchText)
                mentionSuggestions = Array(suggestions.prefix(5))
            } catch {
                print("Failed to load mention suggestions: \(error)")
            }
            isLoadingMentions = false
        }
    }

    private func selectMention(_ suggestion: MentionSuggestion) {
        if let atIndex = viewModel.messageText.lastIndex(of: "@") {
            viewModel.messageText = String(viewModel.messageText[..<atIndex]) + "@\(suggestion.name) "
        } else {
            viewModel.messageText += "@\(suggestion.name) "
        }
        showMentionPicker = false
        isInputFocused = true
    }

    // MARK: - Composer context bar (reply / edit preview)

    private var composerContextBar: some View {
        let isEditing = viewModel.editingMessage != nil
        let title = isEditing ? "Editing message" : "Replying to \(replyingAuthorName)"
        let snippet = isEditing
            ? (viewModel.editingMessage?.content ?? "")
            : replySnippet(viewModel.replyingTo)

        return HStack(spacing: Spacing.sm) {
            Image(systemName: isEditing ? "pencil" : "arrowshape.turn.up.left")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.appSecondary)

            VStack(alignment: .leading, spacing: 1) {
                Text(title)
                    .font(.captionSmallSemibold)
                    .foregroundColor(.appPrimary)
                Text(snippet)
                    .font(.caption12)
                    .foregroundColor(.appSecondary)
                    .lineLimit(1)
            }

            Spacer()

            Button { viewModel.cancelComposerContext() } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 18))
                    .foregroundColor(.appSecondary)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, Spacing.lg)
        .padding(.vertical, Spacing.sm)
        .background(Color.appSurface)
    }

    private var replyingAuthorName: String {
        guard let replying = viewModel.replyingTo else { return "" }
        return replying.senderId == viewModel.currentUserId ? "yourself" : viewModel.otherParticipant.name
    }

    private func replySnippet(_ message: MessageResponse?) -> String {
        guard let message else { return "" }
        if message.isDeleted { return "Message deleted" }
        return message.gifUrl != nil ? "GIF" : message.content
    }

    /// The quoted reply shown above a message bubble, resolved from the thread.
    private func replyContext(for message: MessageResponse) -> (author: String, text: String)? {
        guard let replyToId = message.replyToId,
              let replied = viewModel.message(withId: replyToId) else { return nil }
        let author = replied.senderId == viewModel.currentUserId ? "You" : viewModel.otherParticipant.name
        return (author, replySnippet(replied))
    }

    // MARK: - Request Banner

    private var requestBanner: some View {
        VStack(spacing: Spacing.md) {
            Text("\(viewModel.otherParticipant.name) wants to message you")
                .font(.body14)
                .foregroundColor(.appSecondary)
                .multilineTextAlignment(.center)

            HStack(spacing: Spacing.md) {
                Button(action: {
                    viewModel.declineRequest { dismiss() }
                }) {
                    Text("Decline")
                        .font(.bodyLargeMedium)
                        .foregroundColor(.appPrimary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, Spacing.md - 2)
                        .overlay(
                            RoundedRectangle(cornerRadius: Radius.md)
                                .stroke(Color.appDivider, lineWidth: 1)
                        )
                }
                .buttonStyle(.plain)
                .disabled(viewModel.isDeclining || viewModel.isAccepting)

                Button(action: {
                    viewModel.acceptRequest()
                }) {
                    Text("Accept")
                        .font(.bodyLargeMedium)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, Spacing.md - 2)
                        .background(Color.appPrimary)
                        .cornerRadius(Radius.md)
                }
                .buttonStyle(.plain)
                .disabled(viewModel.isDeclining || viewModel.isAccepting)
            }
        }
        .padding(.horizontal, Spacing.lg)
        .padding(.vertical, Spacing.md)
        .background(Color.appSurface)
    }
}

// MARK: - Typing Dots Animation

struct TypingDots: View {
    @State private var dotOpacities: [Double] = [0.3, 0.3, 0.3]

    var body: some View {
        HStack(spacing: 3) {
            ForEach(0..<3, id: \.self) { index in
                Circle()
                    .fill(Color.appSecondary)
                    .frame(width: Spacing.xxs, height: Spacing.xxs)
                    .opacity(dotOpacities[index])
            }
        }
        .onAppear {
            animateDots()
        }
    }

    private func animateDots() {
        for i in 0..<3 {
            withAnimation(
                .easeInOut(duration: 0.5)
                .repeatForever(autoreverses: true)
                .delay(Double(i) * 0.2)
            ) {
                dotOpacities[i] = 1.0
            }
        }
    }
}

#Preview {
    ChatDetailView(
        conversationId: "conv_1",
        otherParticipant: UserResponse.mock,
        currentUserId: "mock_2"
    )
}
