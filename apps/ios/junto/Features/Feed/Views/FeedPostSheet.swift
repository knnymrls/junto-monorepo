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
                    } else {
                        commentsList
                    }
                }
            }

                replyComposer
            }
            .padding(.top, Spacing.xxl)
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
        .sheet(item: $selectedMentionUser) { user in
            ProfileView(user: user)
        }
        .sheet(isPresented: $showGifPicker) {
            GifPickerSheet { gif in
                selectedGifUrl = gif.mp4Url
                commentImage = nil
            }
            .presentationDetents([.large])
        }
        .task {
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
        OriginalPostSection(
            post: post,
            connectionStatus: connectionStatus,
            currentUserId: currentUserId,
            onAuthorTap: { if let author = post.author { selectedMentionUser = author } },
            onConnectTap: { onConnectTap?() },
            onDisconnectTap: { onDisconnectTap?() },
            onEditTap: {
                dismiss()
                onEditPostTap?()
            },
            onDeleteTap: {
                Task {
                    await viewModel.deletePost(postId: post._id)
                    dismiss()
                }
            },
            onMentionTap: { name in
                Task {
                    if let user = await viewModel.fetchUserByName(name) {
                        selectedMentionUser = user
                    }
                }
            }
        )
    }

    // MARK: - Replies Header

    private var repliesHeader: some View {
        HStack {
            Text("Replies")
                .font(.bodySemibold)
                .foregroundColor(.appPrimary)

            Spacer()

            Menu {
                Button(action: { viewModel.sortOrder = .recent }) {
                    Label("Recent", systemImage: viewModel.sortOrder == .recent ? "checkmark" : "")
                }
                Button(action: { viewModel.sortOrder = .oldest }) {
                    Label("Oldest", systemImage: viewModel.sortOrder == .oldest ? "checkmark" : "")
                }
            } label: {
                HStack(spacing: Spacing.xxs) {
                    Text(viewModel.sortOrder.displayName)
                        .font(.body14)
                    Image(systemName: "chevron.down")
                        .font(.system(size: 10, weight: .medium))
                }
                .foregroundColor(.appSecondary)
            }
        }
        .padding(.horizontal, Spacing.md)
        .padding(.vertical, 10)
        .background(Color.appSurface)
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
                    }
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
                avatarUrl: viewModel.currentUserAvatar,
                avatarName: viewModel.currentUserName,
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

        // Reset local UI state immediately
        replyText = ""
        isReplyFocused = false
        editingCommentId = nil
        commentImage = nil
        selectedGifUrl = nil
        mentionManager.reset()

        Task {
            await viewModel.submitReply(
                authorId: authorId,
                content: content,
                editingCommentId: commentIdToEdit,
                mentionIds: mentionIds,
                image: imageToUpload,
                gifUrl: gifUrlToSend
            )
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
}
