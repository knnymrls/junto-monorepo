//
//  MentionManager.swift
//  mkrs-world
//
//  Shared mention logic for post composer and reply composer
//

import SwiftUI

@MainActor
class MentionManager: ObservableObject {
    @Published var showPicker = false
    @Published var suggestions: [MentionSuggestion] = []
    @Published var isLoading = false
    @Published var selectedMentionIds: [String] = []

    /// When set, uses smart suggestions (post participants first) with fallback
    var postId: String?

    private let convex = ConvexClientManager.shared

    init(postId: String? = nil) {
        self.postId = postId
    }

    func togglePicker(text: inout String) {
        if showPicker {
            showPicker = false
        } else {
            text += "@"
            showPicker = true
            loadSuggestions(searchText: "")
        }
    }

    func handleTextChange(_ text: String) {
        if let atIndex = text.lastIndex(of: "@") {
            let searchText = String(text[text.index(after: atIndex)...])
            if searchText.contains(" ") {
                if showPicker { showPicker = false }
            } else {
                if !showPicker { showPicker = true }
                loadSuggestions(searchText: searchText)
            }
        } else if showPicker {
            showPicker = false
        }
    }

    func selectMention(_ suggestion: MentionSuggestion, text: inout String) {
        if let atIndex = text.lastIndex(of: "@") {
            text = String(text[..<atIndex]) + "@\(suggestion.name) "
        } else {
            text += "@\(suggestion.name) "
        }
        if !selectedMentionIds.contains(suggestion._id) {
            selectedMentionIds.append(suggestion._id)
        }
        showPicker = false
    }

    func reset() {
        showPicker = false
        suggestions = []
        isLoading = false
        selectedMentionIds = []
    }

    // MARK: - Private

    private func loadSuggestions(searchText: String) {
        isLoading = true
        Task { @MainActor in
            defer { isLoading = false }

            if let postId {
                // Smart suggestions: post participants first, then fallback
                do {
                    let results = try await convex.fetchSmartMentionSuggestions(
                        postId: postId,
                        searchText: searchText
                    )
                    suggestions = Array(results.prefix(5))
                    return
                } catch {
                    // Fall through to basic suggestions
                }
            }

            // Basic suggestions
            do {
                let results = try await convex.fetchMentionSuggestions(searchText: searchText)
                suggestions = Array(results.prefix(5))
                if !suggestions.isEmpty && postId == nil {
                    showPicker = true
                }
            } catch {
                print("Failed to load mention suggestions: \(error)")
                suggestions = []
                if postId == nil { showPicker = false }
            }
        }
    }
}
