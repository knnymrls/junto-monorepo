//
//  PostDetailViewModel.swift
//  mkrs-world
//
//  View model for post detail with comments
//

import SwiftUI
import UIKit
import Combine

// MARK: - Sort Order

enum CommentSortOrder: String, CaseIterable {
    case recent
    case oldest

    var displayName: String {
        switch self {
        case .recent: return "Recent"
        case .oldest: return "Oldest"
        }
    }
}

// MARK: - View Model

@MainActor
class PostDetailViewModel: ObservableObject {
    @Published var comments: [CommentResponse] = []
    @Published var isLoading = false
    @Published var isSubmitting = false
    @Published var error: String?
    @Published var sortOrder: CommentSortOrder = .recent {
        didSet { sortComments() }
    }
    @Published var currentUserAvatar: String?
    @Published var currentUserName: String = "?"
    @Published var isUploadingCommentImage = false

    private let postId: String
    private var rawComments: [CommentResponse] = []
    private var cancellables = Set<AnyCancellable>()
    private let convex = ConvexClientManager.shared

    init(postId: String) {
        self.postId = postId
    }

    private func sortComments() {
        switch sortOrder {
        case .recent:
            comments = rawComments.sorted { $0.createdAt > $1.createdAt }
        case .oldest:
            comments = rawComments.sorted { $0.createdAt < $1.createdAt }
        }
    }

    func startSubscription() {
        isLoading = true

        convex.subscribeComments(postId: postId)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    self?.isLoading = false
                    if case .failure(let error) = completion {
                        self?.error = error.localizedDescription
                    }
                },
                receiveValue: { [weak self] comments in
                    self?.isLoading = false
                    self?.rawComments = comments
                    self?.sortComments()
                }
            )
            .store(in: &cancellables)
    }

    func stopSubscription() {
        cancellables.removeAll()
    }

    func createComment(content: String, authorId: String, mentions: [String]? = nil, imageUrl: String? = nil, linkUrl: String? = nil, gifUrl: String? = nil) async {
        isSubmitting = true
        let input = CommentInput(postId: postId, content: content, mentions: mentions, imageUrl: imageUrl, linkUrl: linkUrl, gifUrl: gifUrl)

        do {
            _ = try await convex.createComment(input, authorId: authorId)
        } catch {
            self.error = error.localizedDescription
        }
        isSubmitting = false
    }

    func deleteComment(commentId: String) async {
        do {
            _ = try await convex.deleteComment(commentId: commentId)
        } catch {
            self.error = error.localizedDescription
        }
    }

    func updateComment(commentId: String, content: String) async {
        do {
            _ = try await convex.updateComment(commentId: commentId, content: content)
        } catch {
            self.error = error.localizedDescription
        }
    }

    func loadCurrentUser(userId: String) async {
        do {
            if let user = try await convex.fetchUser(id: userId) {
                currentUserAvatar = user.avatarUrl
                currentUserName = user.name
            }
        } catch {
            print("PostDetailViewModel: Failed to load current user: \(error)")
        }
    }

    func fetchUserByName(_ name: String) async -> UserResponse? {
        do {
            return try await convex.fetchUserByName(name: name)
        } catch {
            print("PostDetailViewModel: Failed to fetch user by name: \(error)")
            return nil
        }
    }

    func submitReply(
        authorId: String,
        content: String,
        editingCommentId: String?,
        mentionIds: [String],
        image: UIImage?,
        gifUrl: String?
    ) async {
        if let commentId = editingCommentId {
            await updateComment(commentId: commentId, content: content)
        } else {
            var uploadedImageUrl: String?
            if let image {
                isUploadingCommentImage = true
                do {
                    uploadedImageUrl = try await ImageUploadService.shared.upload(image).url
                } catch {
                    // Abort: posting the comment without the photo the user
                    // attached is worse than failing visibly.
                    self.error = "Couldn't upload your image. Check your connection and try again."
                    isUploadingCommentImage = false
                    return
                }
                isUploadingCommentImage = false
            }

            await createComment(
                content: content.isEmpty ? " " : content,
                authorId: authorId,
                mentions: mentionIds.isEmpty ? nil : mentionIds,
                imageUrl: uploadedImageUrl,
                gifUrl: gifUrl
            )

            if gifUrl != nil {
                AnalyticsService.shared.track(.gifCommented(postId: postId))
            } else {
                AnalyticsService.shared.track(.commentCreated(postId: postId))
            }
        }
    }

    func deletePost(postId: String) async {
        do {
            _ = try await convex.deletePost(postId: postId)
        } catch {
            self.error = error.localizedDescription
        }
    }
}
