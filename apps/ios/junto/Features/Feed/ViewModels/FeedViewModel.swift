//
//  FeedViewModel.swift
//  mkrs-world
//
//  State management for the Feed
//

import SwiftUI
import Combine

@MainActor
class FeedViewModel: ObservableObject {
    // MARK: - Published State

    /// Source of truth: the unified feed (posts + injected events + matches as typed items).
    @Published var feedItems: [FeedItemResponse] = []
    @Published var suggestedMatches: [SuggestedMatchResponse] = []
    @Published var isLoading = false
    @Published var isLoadingMore = false
    @Published var error: String?
    @Published var hasMorePosts = true

    /// Derived view of just the post payloads. Bridges the current (pre-redesign)
    /// FeedView until it's rebuilt to consume `feedItems` directly.
    var posts: [PostResponse] {
        feedItems.compactMap { $0.post }
    }

    /// Number of post items currently loaded — the pagination offset (matches backend semantics).
    private var loadedPostCount: Int {
        feedItems.reduce(0) { $0 + ($1.kindType == .post ? 1 : 0) }
    }

    // Current user's user profile (set by FeedView from CurrentUserManager)
    @Published var currentUser: UserResponse?

    // Connected user IDs for quick lookup
    @Published var connectedUserIds: Set<String> = []

    // Pending connection request IDs (users we sent requests to)
    @Published var pendingConnectionIds: Set<String> = []

    // MARK: - Private

    private let convex = ConvexClientManager.shared
    private let initialBatchSize = 6
    private let loadMoreBatchSize = 10
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Init

    init() {
        // Keep avatar badges in sync when a connection changes from another
        // surface (e.g. tapping Connect inside a profile sheet over the feed).
        NotificationCenter.default.publisher(for: .connectionStatusChanged)
            .compactMap { ConnectionEvents.decode($0) }
            .sink { [weak self] change in
                guard let self else { return }
                Task { @MainActor in
                    self.applyConnectionChange(userId: change.userId, status: change.status)
                }
            }
            .store(in: &cancellables)
    }

    /// Apply an externally-broadcast connection change to the cached sets.
    private func applyConnectionChange(userId: String, status: ConnectionStatus) {
        switch status {
        case .connected:
            pendingConnectionIds.remove(userId)
            connectedUserIds.insert(userId)
        case .pendingSent:
            connectedUserIds.remove(userId)
            pendingConnectionIds.insert(userId)
        case .pendingReceived:
            break
        case .none:
            connectedUserIds.remove(userId)
            pendingConnectionIds.remove(userId)
        }
    }

    // MARK: - Public Methods

    /// Load initial feed (unified: posts + injected events + matches)
    func loadInitialFeed(userId: String) async {
        guard !isLoading else { return }

        isLoading = true
        hasMorePosts = true
        error = nil

        do {
            let items = try await convex.fetchUnifiedFeed(userId: userId, limit: initialBatchSize)
            feedItems = items
            let postCount = items.filter { $0.kindType == .post }.count
            hasMorePosts = postCount >= initialBatchSize
            print("FeedViewModel: Loaded \(items.count) initial feed items (\(postCount) posts)")
        } catch {
            self.error = error.localizedDescription
            print("FeedViewModel: Error loading feed: \(error)")
        }

        isLoading = false
    }

    /// Load more feed items (pagination). Pages after the first are posts-only.
    func loadMorePosts() async {
        guard !isLoadingMore, !isLoading, hasMorePosts, let userId = currentUser?._id else { return }

        isLoadingMore = true

        do {
            // Offset counts posts already loaded (matches backend semantics).
            let offset = loadedPostCount
            let fetched = try await convex.fetchUnifiedFeed(userId: userId, limit: loadMoreBatchSize, offset: offset)

            if fetched.isEmpty {
                hasMorePosts = false
            } else {
                let existingKeys = Set(feedItems.map { $0.key })
                let newItems = fetched.filter { !existingKeys.contains($0.key) }
                feedItems.append(contentsOf: newItems)
                let newPostCount = fetched.filter { $0.kindType == .post }.count
                hasMorePosts = newPostCount >= loadMoreBatchSize
            }
            print("FeedViewModel: Loaded \(fetched.count) more feed items, total: \(feedItems.count)")
        } catch {
            print("FeedViewModel: Error loading more feed items: \(error)")
        }

        isLoadingMore = false
    }

    /// Bootstrap feed from user profile (called by FeedView after setting currentUser)
    func bootstrap(userId: String) async {
        await loadInitialFeed(userId: userId)
        await loadSuggestedMatches(userId: userId)
        await loadConnections(userId: userId)
    }

    /// Load suggested matches (pre-computed weekly, with on-demand fallback)
    func loadSuggestedMatches(userId: String) async {
        do {
            let matches = try await convex.fetchSuggestedMatches(userId: userId)

            if matches.isEmpty {
                // No matches for this week yet — trigger on-demand generation
                print("FeedViewModel: No weekly matches yet, generating on-demand...")
                try await convex.generateWeeklyMatchesAction(userId: userId)
                // Re-fetch after generation
                suggestedMatches = try await convex.fetchSuggestedMatches(userId: userId)
            } else {
                suggestedMatches = matches
            }

            print("FeedViewModel: Loaded \(suggestedMatches.count) suggested matches")
        } catch {
            print("FeedViewModel: Error loading suggested matches: \(error)")
            // Don't set error - suggested matches are optional
        }
    }

    /// Create a new post
    func createPost(content: String, category: PostResponse.PostCategory, imageUrls: [String]? = nil, linkUrl: String? = nil, gifUrl: String? = nil, mentions: [String]? = nil) async -> Bool {
        guard let userId = currentUser?._id else {
            error = "Not signed in"
            return false
        }

        let input = PostInput(
            content: content,
            category: category,
            imageUrls: imageUrls,
            linkUrl: linkUrl,
            gifUrl: gifUrl,
            mentions: mentions
        )

        do {
            _ = try await convex.createPost(input, authorId: userId)

            // Track post creation
            AnalyticsService.shared.track(.postCreated(category: category.rawValue))

            return true
        } catch {
            self.error = error.localizedDescription
            return false
        }
    }

    /// Delete a post
    func deletePost(_ postId: String) async -> Bool {
        do {
            _ = try await convex.deletePost(postId: postId)
            return true
        } catch {
            self.error = error.localizedDescription
            return false
        }
    }

    /// Update a post. `imageUrls` is the post's full image set — pass an empty
    /// array to clear removed images (nil means "leave images untouched").
    func updatePost(postId: String, content: String, category: PostResponse.PostCategory, imageUrls: [String]? = nil, linkUrl: String? = nil) async -> Bool {
        do {
            _ = try await convex.updatePost(
                postId: postId,
                content: content,
                category: category,
                imageUrls: imageUrls,
                linkUrl: linkUrl
            )
            return true
        } catch {
            self.error = error.localizedDescription
            return false
        }
    }

    /// Refresh feed (pull to refresh)
    func refresh() async {
        guard let userId = currentUser?._id else { return }
        await loadInitialFeed(userId: userId)
    }

    /// Check if current user is author of post
    func isAuthor(of post: PostResponse) -> Bool {
        return post.authorId == currentUser?._id
    }

    /// Resolve an @mention name to a user profile (for tapping mentions in feed cards)
    func fetchUserByName(_ name: String) async -> UserResponse? {
        do {
            return try await convex.fetchUserByName(name: name)
        } catch {
            print("FeedViewModel: Error resolving mention '\(name)': \(error)")
            return nil
        }
    }

    /// Load user's connections
    func loadConnections(userId: String) async {
        do {
            let connections = try await convex.fetchConnections(userId: userId)
            connectedUserIds = Set(connections.map { $0._id })
            print("FeedViewModel: Loaded \(connectedUserIds.count) connections")

            // Also load pending sent requests
            let pendingIds = try await convex.fetchPendingSentIds(userId: userId)
            pendingConnectionIds = Set(pendingIds)
            print("FeedViewModel: Loaded \(pendingConnectionIds.count) pending requests")
        } catch {
            print("FeedViewModel: Error loading connections: \(error)")
        }
    }

    /// Check if a user is connected
    func isConnected(userId: String) -> Bool {
        return connectedUserIds.contains(userId)
    }

    /// Check if we have a pending request to this user
    func isPending(userId: String) -> Bool {
        return pendingConnectionIds.contains(userId)
    }

    /// Get connection status for a user
    func connectionStatus(userId: String) -> ConnectionDisplayStatus {
        if connectedUserIds.contains(userId) {
            return .connected
        } else if pendingConnectionIds.contains(userId) {
            return .pending
        } else {
            return .none
        }
    }

    /// Send a connection request
    func sendConnectionRequest(toUserId: String, source: ConnectionSource = .feed) async -> Bool {
        guard let myUserId = currentUser?._id else {
            error = "Not signed in"
            return false
        }

        // Optimistically add to pending
        pendingConnectionIds.insert(toUserId)

        do {
            _ = try await convex.sendConnectionRequest(requesterId: myUserId, accepterId: toUserId)
            print("FeedViewModel: Sent connection request to \(toUserId)")
            ConnectionEvents.post(userId: toUserId, status: .pendingSent)

            // Track connection request
            AnalyticsService.shared.track(.connectionSent(toUserId: toUserId, source: source))

            // Reload connections in case they had already sent us a request (auto-accept)
            await loadConnections(userId: myUserId)
            return true
        } catch {
            // Revert optimistic update
            pendingConnectionIds.remove(toUserId)
            self.error = error.localizedDescription
            print("FeedViewModel: Error sending connection request: \(error)")
            return false
        }
    }

    /// Withdraw a pending connection request
    func withdrawConnectionRequest(toUserId: String) async -> Bool {
        guard let myUserId = currentUser?._id else {
            error = "Not signed in"
            return false
        }

        // Optimistically remove from pending
        pendingConnectionIds.remove(toUserId)

        do {
            _ = try await convex.withdrawConnectionRequest(requesterId: myUserId, accepterId: toUserId)
            print("FeedViewModel: Withdrew connection request to \(toUserId)")
            ConnectionEvents.post(userId: toUserId, status: .none)
            await loadConnections(userId: myUserId)
            return true
        } catch {
            // Revert optimistic update
            pendingConnectionIds.insert(toUserId)
            self.error = error.localizedDescription
            print("FeedViewModel: Error withdrawing connection request: \(error)")
            return false
        }
    }

    /// Handle disconnect/withdraw based on current connection status
    @discardableResult
    func handleDisconnect(userId: String) async -> Bool {
        let status = connectionStatus(userId: userId)
        if status == .connected {
            return await removeConnection(withUserId: userId)
        } else if status == .pending {
            return await withdrawConnectionRequest(toUserId: userId)
        }
        return false
    }

    /// Remove an existing connection
    func removeConnection(withUserId: String) async -> Bool {
        guard let myUserId = currentUser?._id else {
            error = "Not signed in"
            return false
        }

        // Optimistically remove from connections
        connectedUserIds.remove(withUserId)

        do {
            _ = try await convex.removeConnection(userId1: myUserId, userId2: withUserId)
            print("FeedViewModel: Removed connection with \(withUserId)")
            ConnectionEvents.post(userId: withUserId, status: .none)
            // Reload to stay in sync with backend
            await loadConnections(userId: myUserId)
            return true
        } catch {
            // Revert optimistic update
            connectedUserIds.insert(withUserId)
            self.error = error.localizedDescription
            print("FeedViewModel: Error removing connection: \(error)")
            return false
        }
    }
}

// MARK: - Connection Display Status

enum ConnectionDisplayStatus {
    case none
    case pending
    case connected
}
