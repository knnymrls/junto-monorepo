//
//  SearchViewModel.swift
//  mkrs-world
//
//  Two-tier typing (instant name → background vector) + streaming LLM enhancement
//

import SwiftUI
import Combine

enum SearchPhase: Equatable {
    case idle
    case typing
    case submitted
    case streaming
    case enhanced
}

@MainActor
class SearchViewModel: ObservableObject {
    // MARK: - Published State

    @Published var searchText: String = ""
    @Published var searchPhase: SearchPhase = .idle
    @Published var nameResults: [SearchResultItem] = []
    @Published var vectorResults: [SearchResultItem] = []
    @Published var enhancedResults: [SearchResultItem]? = nil
    @Published var aiThinking: String? = nil

    // Streaming state
    @Published var streamingThinking: String = ""
    @Published var streamingResults: [SearchResultItem] = []

    // User profiles cache
    @Published var userProfiles: [String: UserResponse] = [:]

    // Connection state
    @Published var connectedUserIds: Set<String> = []
    @Published var pendingConnectionIds: Set<String> = []

    // Current user
    var currentUserId: String?

    /// Results to display — depends on phase, excludes current user
    var displayResults: [SearchResultItem] {
        let raw: [SearchResultItem]
        switch searchPhase {
        case .typing, .submitted:
            // Merge: vector results take priority, then name results fill gaps
            if vectorResults.isEmpty {
                raw = nameResults
            } else {
                var merged: [SearchResultItem] = []
                let vectorIds = Set(vectorResults.map(\.userId))
                merged.append(contentsOf: vectorResults)
                for result in nameResults where !vectorIds.contains(result.userId) {
                    merged.append(result)
                }
                raw = merged
            }
        case .streaming:
            // During streaming, merge streaming AI results with vector results
            if !streamingResults.isEmpty {
                var merged: [SearchResultItem] = []
                let streamingIds = Set(streamingResults.map(\.userId))
                merged.append(contentsOf: streamingResults)
                for result in vectorResults where !streamingIds.contains(result.userId) {
                    merged.append(result)
                }
                raw = merged
            } else {
                raw = vectorResults
            }
        case .enhanced:
            raw = enhancedResults ?? vectorResults
        case .idle:
            raw = []
        }
        // Filter out the current user from results
        if let myId = currentUserId {
            return raw.filter { $0.userId != myId }
        }
        return raw
    }

    var hasResults: Bool {
        !displayResults.isEmpty
    }

    /// User IDs currently waiting for AI enhancement (shimmer state)
    var enhancingUserIds: Set<String> {
        guard searchPhase == .streaming else { return [] }
        let streamedIds = Set(streamingResults.map(\.userId))
        return Set(vectorResults.prefix(10).map(\.userId)).subtracting(streamedIds)
    }

    // MARK: - Private

    private let convex = ConvexClientManager.shared
    private var nameSearchCancellable: AnyCancellable?
    private var vectorSearchCancellable: AnyCancellable?
    private var nameSearchTask: Task<Void, Never>?
    private var quickSearchTask: Task<Void, Never>?
    private var vectorSearchTask: Task<Void, Never>?
    private var streamTask: Task<Void, Never>?
    private var sessionCancellable: AnyCancellable?
    private var sessionId: String?
    private var hasSubmitted = false

    // MARK: - Start Listening

    func startListening() {
        // Tier 1: Fast name search — 150ms debounce, instant results
        nameSearchCancellable = $searchText
            .debounce(for: .milliseconds(150), scheduler: DispatchQueue.main)
            .removeDuplicates()
            .sink { [weak self] query in
                guard let self else { return }
                if !self.hasSubmitted {
                    self.performNameSearch(query: query)
                }
            }

        // Tier 2: Full vector search — 400ms debounce, enriches name results
        vectorSearchCancellable = $searchText
            .debounce(for: .milliseconds(400), scheduler: DispatchQueue.main)
            .removeDuplicates()
            .sink { [weak self] query in
                guard let self else { return }
                if !self.hasSubmitted {
                    self.performQuickSearch(query: query)
                }
            }
    }

    // MARK: - Tier 1: Fast Name Search (~50ms)

    private func performNameSearch(query: String) {
        nameSearchTask?.cancel()

        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, let userId = currentUserId else {
            if trimmed.isEmpty {
                searchPhase = .idle
                hasSubmitted = false
                nameResults = []
                vectorResults = []
                enhancedResults = nil
                aiThinking = nil
                streamingThinking = ""
                streamingResults = []
            }
            return
        }

        searchPhase = .typing

        nameSearchTask = Task {
            do {
                let users = try await convex.fetchNameSearchResults(
                    query: trimmed,
                    currentUserId: userId
                )
                guard !Task.isCancelled else { return }

                // Convert UserResponse → SearchResultItem with smart explanation
                nameResults = users.map { user in
                    SearchResultItem(
                        userId: user._id,
                        explanation: Self.buildAutoExplanation(user),
                        relevanceScore: 0.8,
                        mutualConnectionCount: nil,
                        mutualConnectionNames: nil,
                        connectionStatus: nil,
                        isAIEnhanced: nil
                    )
                }

                // Cache profiles so cards render immediately
                for user in users {
                    userProfiles[user._id] = user
                }
            } catch {
                guard !Task.isCancelled else { return }
                print("SearchViewModel: Name search error: \(error)")
            }
        }
    }

    // MARK: - Tier 2: Full Quick Search (~500ms)

    private func performQuickSearch(query: String) {
        quickSearchTask?.cancel()

        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, let userId = currentUserId else { return }

        quickSearchTask = Task {
            do {
                let response = try await convex.quickSearch(
                    query: trimmed,
                    currentUserId: userId
                )
                guard !Task.isCancelled else { return }
                vectorResults = response.results

                // Fetch user profiles for results
                for result in response.results {
                    await fetchUserProfile(userId: result.userId)
                }
            } catch {
                guard !Task.isCancelled else { return }
                print("SearchViewModel: Quick search error: \(error)")
            }
        }
    }

    // MARK: - Auto Explanation (client-side, for name search results)

    static func buildAutoExplanation(_ user: UserResponse) -> String {
        func truncate(_ s: String) -> String {
            s.count > 60 ? String(s.prefix(57)) + "..." : s
        }
        if let project = user.currentProject, !project.isEmpty { return truncate(project) }
        if let lookingFor = user.lookingFor, !lookingFor.isEmpty { return truncate(lookingFor) }
        if let canHelpWith = user.canHelpWith, !canHelpWith.isEmpty { return truncate("Can help with \(canHelpWith)") }
        if let skills = user.skills, !skills.isEmpty { return skills.prefix(4).joined(separator: ", ") }
        if let headline = user.headline, !headline.isEmpty { return headline }
        return user.name
    }

    // MARK: - Submit Search (enter key)

    func submitSearch() {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty, let userId = currentUserId else { return }

        // Mark as submitted — keep existing typing results visible while we search deeper
        hasSubmitted = true
        searchPhase = .submitted
        enhancedResults = nil
        aiThinking = nil
        streamingThinking = ""
        streamingResults = []

        // Cancel typing-phase listeners (but keep existing results visible)
        nameSearchTask?.cancel()
        quickSearchTask?.cancel()
        vectorSearchTask?.cancel()
        streamTask?.cancel()
        sessionCancellable?.cancel()

        // Phase 1: Vector search — runs while user sees typing-phase results
        vectorSearchTask = Task {
            do {
                let response = try await convex.vectorSearch(
                    query: query,
                    currentUserId: userId
                )

                guard !Task.isCancelled else { return }

                // Upgrade results (typing results → vector results)
                vectorResults = response.results

                // Fetch user profiles for any new results
                for result in response.results {
                    await fetchUserProfile(userId: result.userId)
                }

                AnalyticsService.shared.track(.searchPerformed(query: query, resultCount: response.results.count))

                // Phase 2: Start LLM streaming — only top 10 candidates
                if !response.results.isEmpty {
                    let topUserIds = Array(response.results.prefix(10).map(\.userId))
                    await startStreamingEnhancement(query: query, userIds: topUserIds, currentUserId: userId)
                } else {
                    // No results — go straight to enhanced (empty)
                    searchPhase = .enhanced
                }
            } catch {
                guard !Task.isCancelled else { return }
                print("SearchViewModel: Vector search error: \(error)")
            }
        }
    }

    // MARK: - Streaming LLM Enhancement

    private func startStreamingEnhancement(query: String, userIds: [String], currentUserId: String) async {
        do {
            // 1. Create session
            let sid = try await convex.createSearchSession(query: query, currentUserId: currentUserId)
            self.sessionId = sid
            self.searchPhase = .streaming

            // 2. Subscribe to session updates
            sessionCancellable = convex.subscribeSearchSession(sessionId: sid)
                .receive(on: DispatchQueue.main)
                .sink(
                    receiveCompletion: { completion in
                        if case .failure(let error) = completion {
                            print("SearchViewModel: Session subscription error: \(error)")
                        }
                    },
                    receiveValue: { [weak self] session in
                        guard let self, let session else { return }
                        Task { @MainActor in
                            self.handleSessionUpdate(session)
                        }
                    }
                )

            // 3. Fire streaming action in background (don't await — subscription handles updates)
            streamTask = Task {
                do {
                    try await convex.streamEnhanceWithLLM(
                        sessionId: sid,
                        query: query,
                        userIds: userIds,
                        currentUserId: currentUserId
                    )
                } catch {
                    guard !Task.isCancelled else { return }
                    print("SearchViewModel: Stream enhance error: \(error)")
                }
            }
        } catch {
            print("SearchViewModel: Failed to create search session: \(error)")
        }
    }

    private func handleSessionUpdate(_ session: SearchSessionResponse) {
        // Update thinking text
        if let thinking = session.thinkingText {
            streamingThinking = thinking
        }

        // Update streaming results
        let parsed = session.parsedResults
        if !parsed.isEmpty {
            streamingResults = parsed.map { $0.toSearchResultItem() }
            // Fetch profiles for any new results
            for result in streamingResults {
                Task {
                    await fetchUserProfile(userId: result.userId)
                }
            }
        }

        // Check for completion
        if session.status == "complete" {
            enhancedResults = streamingResults.isEmpty ? nil : streamingResults
            aiThinking = session.thinkingText
            searchPhase = .enhanced
            sessionCancellable?.cancel()
            sessionCancellable = nil
            sessionId = nil
        } else if session.status == "error" {
            // Stay on vector results
            searchPhase = .enhanced
            sessionCancellable?.cancel()
            sessionCancellable = nil
            sessionId = nil
        }
    }

    // MARK: - Clear Search

    func clearSearch() {
        searchText = ""
        searchPhase = .idle
        hasSubmitted = false
        nameResults = []
        vectorResults = []
        enhancedResults = nil
        aiThinking = nil
        streamingThinking = ""
        streamingResults = []
        nameSearchTask?.cancel()
        quickSearchTask?.cancel()
        vectorSearchTask?.cancel()
        streamTask?.cancel()
        sessionCancellable?.cancel()
        sessionCancellable = nil
        sessionId = nil
    }

    // MARK: - User Profiles

    private func fetchUserProfile(userId: String) async {
        guard userProfiles[userId] == nil else { return }
        do {
            let user = try await convex.fetchUser(id: userId)
            if let user = user {
                userProfiles[userId] = user
            }
        } catch {
            print("SearchViewModel: Error fetching user \(userId): \(error)")
        }
    }

    // MARK: - Connections

    func loadConnections(userId: String) async {
        do {
            let connections = try await convex.fetchConnections(userId: userId)
            connectedUserIds = Set(connections.map { $0._id })

            let pendingIds = try await convex.fetchPendingSentIds(userId: userId)
            pendingConnectionIds = Set(pendingIds)
        } catch {
            print("SearchViewModel: Error loading connections: \(error)")
        }
    }

    func connectionStatus(for result: SearchResultItem) -> ConnectionStatus {
        if let status = result.connectionStatus {
            return ConnectionStatus(rawValue: status) ?? fallbackConnectionStatus(userId: result.userId)
        }
        return fallbackConnectionStatus(userId: result.userId)
    }

    private func fallbackConnectionStatus(userId: String) -> ConnectionStatus {
        if connectedUserIds.contains(userId) {
            return .connected
        } else if pendingConnectionIds.contains(userId) {
            return .pendingSent
        } else {
            return .none
        }
    }

    func sendConnectionRequest(toUserId: String) async -> Bool {
        guard let myUserId = currentUserId else { return false }

        pendingConnectionIds.insert(toUserId)

        do {
            _ = try await convex.sendConnectionRequest(requesterId: myUserId, accepterId: toUserId)
            AnalyticsService.shared.track(.connectionSent(toUserId: toUserId, source: .search))
            await loadConnections(userId: myUserId)
            return true
        } catch {
            pendingConnectionIds.remove(toUserId)
            print("SearchViewModel: Error sending connection: \(error)")
            return false
        }
    }
}
