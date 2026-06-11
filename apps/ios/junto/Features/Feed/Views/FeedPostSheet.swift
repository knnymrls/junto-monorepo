//
//  FeedPostSheet.swift
//  mkrs-world
//
//  Post detail as a sheet with comments
//

import SwiftUI
import UIKit

struct FeedPostSheet: View {
    let post: PostResponse
    let currentUserId: String?
    let connectedUserIds: Set<String>
    let connectionStatus: ConnectionDisplayStatus
    var onConnectTap: (() -> Void)? = nil
    var onDisconnectTap: (() -> Void)? = nil
    var onEditPostTap: (() -> Void)? = nil

    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var currentUser: CurrentUserManager
    @StateObject private var viewModel: PostDetailViewModel
    @State private var replyText = ""
    @State private var isReplyFocused = false
    @State private var editingCommentId: String? = nil
    @State private var selectedMentionUser: UserResponse? = nil
    @State private var replyTextHeight: CGFloat = 28
    @StateObject private var mentionManager: MentionManager

    // Comment media state
    @State private var commentImage: UIImage?
    @State private var showGifPicker = false
    @State private var selectedGifUrl: URL?
    @State private var showReplyError = false

    // Zoom transition namespace: author/commenter avatar → profile
    @Namespace private var profileZoom

    private var hairline: CGFloat {
        1 / UIScreen.main.scale
    }

    init(post: PostResponse, currentUserId: String?, connectedUserIds: Set<String> = [], connectionStatus: ConnectionDisplayStatus = .none, onConnectTap: (() -> Void)? = nil, onDisconnectTap: (() -> Void)? = nil, onEditPostTap: (() -> Void)? = nil) {
        self.post = post
        self.currentUserId = currentUserId
        self.connectedUserIds = connectedUserIds
        self.connectionStatus = connectionStatus
        self.onConnectTap = onConnectTap
        self.onDisconnectTap = onDisconnectTap
        self.onEditPostTap = onEditPostTap
        _viewModel = StateObject(wrappedValue: PostDetailViewModel(postId: post._id))
        _mentionManager = StateObject(wrappedValue: MentionManager(postId: post._id))
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            VStack(spacing: 0) {
                PostDetailTopNav(
                    onBack: { dismiss() },
                    onShare: { /* TODO: share post */ }
                )

                ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    originalPost

                    Rectangle()
                        .fill(Color.appDivider)
                        .frame(height: hairline)

                    repliesHeader

                    Rectangle()
                        .fill(Color.appDivider)
                        .frame(height: hairline)

                    if viewModel.isLoading && viewModel.comments.isEmpty {
                        loadingState
                    } else if viewModel.comments.isEmpty {
                        FeedMessageState(
                            icon: .feedRepliesEmpty,
                            title: "No Replies",
                            subtitle: "Be the first to reply"
                        )
                    } else {
                        commentsList
                    }
                }
            }
            .scrollEdgeFade()

                replyComposer
            }
            .background(Color.appSurface)

            if mentionManager.showPicker {
                MentionPicker(
                    suggestions: mentionManager.suggestions,
                    isLoading: mentionManager.isLoading,
                    onSelect: { mentionManager.selectMention($0, text: &replyText) },
                    onClose: { mentionManager.showPicker = false }
                )
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.easeInOut(duration: 0.2), value: mentionManager.showPicker)
        .presentationDragIndicator(.visible)
        .alert("Couldn't Post Reply", isPresented: $showReplyError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(viewModel.error ?? "Something went wrong. Please try again.")
        }
        .fullScreenCover(item: $selectedMentionUser) { user in
            ProfileView(user: user)
                .zoomDestination(id: user._id, in: profileZoom)
        }
        .sheet(isPresented: $showGifPicker) {
            GifPickerSheet { gif in
                selectedGifUrl = gif.mp4Url
                commentImage = nil
            }
            .presentationDetents([.large])
        }
        .task {
            #if DEBUG
            if ProcessInfo.processInfo.environment["JUNTO_PREVIEW_FEED"] == "1" {
                viewModel.comments = CommentResponse.mockList
                return
            }
            #endif
            viewModel.startSubscription()
            if let userId = currentUserId {
                await viewModel.loadCurrentUser(userId: userId)
            }

            AnalyticsService.shared.track(.postViewed(
                postId: post._id,
                category: post.categoryType.rawValue,
                authorId: post.authorId
            ))
        }
        .onDisappear {
            viewModel.stopSubscription()
        }
    }

    // MARK: - Original Post

    private var originalPost: some View {
        FeedCard(
            item: FeedItemResponse(
                kind: "post",
                key: "post:\(post._id)",
                tags: post.topics,
                post: post,
                event: nil,
                match: nil
            ),
            connectionStatus: connectionStatus,
            isOwnItem: post.authorId == currentUserId,
            onConnectTap: { onConnectTap?() },
            onDisconnectTap: { onDisconnectTap?() },
            onCardTap: nil,
            onAuthorTap: { if let author = post.author { selectedMentionUser = author } },
            onMentionTap: { name in
                Task {
                    if let user = await viewModel.fetchUserByName(name) {
                        selectedMentionUser = user
                    }
                }
            },
            profileZoomID: post.author.map { AnyHashable($0._id) },
            profileZoomNamespace: profileZoom
        )
    }

    // MARK: - Replies Header

    private var repliesHeader: some View {
        HStack(alignment: .top) {
            Text("Replies")
                .font(.bodyMedium)
                .foregroundColor(.appPrimary)

            Spacer()

            Text(replyCountText)
                .font(.body14)
                .foregroundColor(.appSecondary)
        }
        .padding(.horizontal, Spacing.md)
        .padding(.vertical, Spacing.sm)
        .background(Color.appSurface)
    }

    /// "1 Reply" / "N Replies" — Figma 78:1828.
    private var replyCountText: String {
        let count = viewModel.comments.count
        return "\(count) " + (count == 1 ? "Reply" : "Replies")
    }

    // MARK: - Comments List

    private var commentsList: some View {
        LazyVStack(spacing: 0) {
            ForEach(viewModel.comments) { comment in
                CommentCard(
                    comment: comment,
                    connectionStatus: connectedUserIds.contains(comment.authorId) ? .connected : .none,
                    currentUserId: currentUserId,
                    onEditTap: {
                        editingCommentId = comment._id
                        replyText = comment.content
                        isReplyFocused = true
                    },
                    onDeleteTap: {
                        Task {
                            await viewModel.deleteComment(commentId: comment._id)
                        }
                    },
                    onReportTap: {
                        // TODO: Report comment
                    },
                    onMentionTap: { name in
                        Task {
                            if let user = await viewModel.fetchUserByName(name) {
                                selectedMentionUser = user
                            }
                        }
                    },
                    onAuthorTap: {
                        if let author = comment.author {
                            selectedMentionUser = author
                        }
                    },
                    profileZoomID: comment.author.map { AnyHashable($0._id) },
                    profileZoomNamespace: profileZoom
                )

                Rectangle()
                    .fill(Color.appDivider)
                    .frame(height: hairline)
            }
        }
    }

    // MARK: - Loading State

    private var loadingState: some View {
        VStack {
            ProgressView()
                .tint(.appPrimary)
                .padding(.vertical, Spacing.huge)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Reply Composer

    private var replyComposer: some View {
        VStack(spacing: 0) {
            if editingCommentId != nil {
                VStack(spacing: 0) {
                    Rectangle()
                        .fill(Color.appDivider)
                        .frame(height: hairline)

                    HStack {
                        Text("Editing comment")
                            .font(.caption12)
                            .foregroundColor(.appSecondary)

                        Spacer()

                        Button(action: cancelEditing) {
                            Text("Cancel")
                                .font(.captionMedium)
                                .foregroundColor(.blue)
                        }
                    }
                    .padding(.horizontal, Spacing.md)
                    .padding(.vertical, Spacing.sm)
                }
                .background(Color.appSurface)
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }

            ReplyComposerBar(
                text: $replyText,
                textHeight: $replyTextHeight,
                selectedImage: $commentImage,
                selectedGifUrl: $selectedGifUrl,
                isFocused: $isReplyFocused,
                avatarUrl: currentUser.user?.avatarUrl ?? viewModel.currentUserAvatar,
                avatarName: currentUser.user?.name ?? viewModel.currentUserName,
                showMentionPicker: mentionManager.showPicker,
                onMentionTap: { mentionManager.togglePicker(text: &replyText) },
                onGifTap: {
                    showGifPicker = true
                },
                onTextChange: { newValue in
                    mentionManager.handleTextChange(newValue)
                },
                onSubmit: {
                    submitReply()
                }
            )
        }
        .animation(.easeInOut(duration: 0.2), value: editingCommentId != nil)
    }

    private func submitReply() {
        guard let authorId = currentUserId,
              !replyText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || selectedGifUrl != nil else { return }

        let content = replyText.trimmingCharacters(in: .whitespacesAndNewlines)
        let commentIdToEdit = editingCommentId
        let imageToUpload = commentImage
        let gifUrlToSend = selectedGifUrl?.absoluteString
        let mentionIds = mentionManager.selectedMentionIds

        // Reset local UI state immediately (restored below if the submit fails)
        replyText = ""
        isReplyFocused = false
        editingCommentId = nil
        commentImage = nil
        selectedGifUrl = nil
        mentionManager.reset()

        Task {
            viewModel.error = nil
            await viewModel.submitReply(
                authorId: authorId,
                content: content,
                editingCommentId: commentIdToEdit,
                mentionIds: mentionIds,
                image: imageToUpload,
                gifUrl: gifUrlToSend
            )
            if viewModel.error != nil {
                // Put the user's work back so a retry is one tap away.
                replyText = content
                editingCommentId = commentIdToEdit
                commentImage = imageToUpload
                if let gifUrlToSend { selectedGifUrl = URL(string: gifUrlToSend) }
                showReplyError = true
            }
        }
    }

    private func cancelEditing() {
        editingCommentId = nil
        replyText = ""
        isReplyFocused = false
    }
}

#Preview {
    FeedPostSheet(
        post: .mock,
        currentUserId: "mock_1"
    )
    .environmentObject(CurrentUserManager.shared)
}
