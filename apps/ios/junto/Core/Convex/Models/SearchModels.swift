//
//  SearchModels.swift
//  mkrs-world
//
//  Search and search-session model types.
//

import Foundation
import ConvexMobile
import Combine
import UIKit


// MARK: - Search Response

struct SearchResultItem: Codable, Identifiable {
    let userId: String
    let explanation: String
    let relevanceScore: Double
    let mutualConnectionCount: Int?
    let mutualConnectionNames: [String]?
    let connectionStatus: String?
    let isAIEnhanced: Bool?

    var id: String { userId }

    var parsedConnectionStatus: ConnectionStatus {
        guard let status = connectionStatus else { return .none }
        return ConnectionStatus(rawValue: status) ?? .none
    }
}


struct QuickSearchResponse: Codable {
    let results: [SearchResultItem]
}


struct AISearchResponse: Codable {
    let thinking: String
    let results: [SearchResultItem]
}


struct VectorSearchResponse: Codable {
    let results: [SearchResultItem]
}


// MARK: - Search Session Response (streaming)

struct SearchSessionResponse: Codable, Identifiable {
    let _id: String
    let userId: String
    let query: String
    let status: String
    let thinkingText: String?
    let results: String?       // JSON string of StreamingSearchResult[]
    let resultCount: Double?
    let createdAt: Double
    let updatedAt: Double

    var id: String { _id }

    var parsedResults: [StreamingSearchResult] {
        guard let results = results, !results.isEmpty else { return [] }
        do {
            return try JSONDecoder().decode([StreamingSearchResult].self, from: Data(results.utf8))
        } catch {
            return []
        }
    }
}


struct StreamingSearchResult: Codable, Identifiable {
    let userId: String
    let explanation: String
    let relevanceScore: Double
    let mutualConnectionCount: Int?
    let mutualConnectionNames: [String]?
    let connectionStatus: String?
    let isAIEnhanced: Bool?

    var id: String { userId }

    func toSearchResultItem() -> SearchResultItem {
        SearchResultItem(
            userId: userId,
            explanation: explanation,
            relevanceScore: relevanceScore,
            mutualConnectionCount: mutualConnectionCount,
            mutualConnectionNames: mutualConnectionNames,
            connectionStatus: connectionStatus,
            isAIEnhanced: isAIEnhanced
        )
    }
}


struct NameAutocompleteResult: Codable, Identifiable {
    let _id: String
    let name: String
    let headline: String?
    let avatarUrl: String?

    var id: String { _id }
}


struct SearchChatResponse: Codable, Identifiable {
    let _id: String
    let userId: String
    let title: String
    let lastQueryAt: Double
    let lastQueryPreview: String?
    let createdAt: Double
    var id: String { _id }
}
