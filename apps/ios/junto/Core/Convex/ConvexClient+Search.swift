//
//  ConvexClient+Search.swift
//  mkrs-world
//
//  Quick/vector/AI search and streaming search sessions.
//

import Foundation
import ConvexMobile
import Combine
import UIKit

extension ConvexClientManager {

    // MARK: Search

    /// Quick search — fast name + vector search, no AI
    func quickSearch(query: String, currentUserId: String) async throws -> QuickSearchResponse {
        let args: [String: (any ConvexEncodable)?] = [
            "query": query,
            "currentUserId": currentUserId
        ]
        return try await client.action("search:quickSearch", with: args)
    }


    /// AI search — full LLM-powered search with reasoning
    func searchPeople(query: String, currentUserId: String) async throws -> AISearchResponse {
        let args: [String: (any ConvexEncodable)?] = [
            "query": query,
            "currentUserId": currentUserId
        ]
        return try await client.action("search:searchPeople", with: args)
    }


    /// Vector search — fast retrieval with auto-explanations, no LLM
    func vectorSearch(query: String, currentUserId: String) async throws -> VectorSearchResponse {
        let args: [String: (any ConvexEncodable)?] = [
            "query": query,
            "currentUserId": currentUserId
        ]
        return try await client.action("search:vectorSearch", with: args)
    }


    /// LLM enhancement — takes user IDs from vector search and adds AI reasoning
    func enhanceWithLLM(query: String, userIds: [String], currentUserId: String) async throws -> AISearchResponse {
        let userIdsEncodable: [ConvexEncodable?] = userIds.map { $0 as ConvexEncodable? }
        let args: [String: (any ConvexEncodable)?] = [
            "query": query,
            "userIds": userIdsEncodable,
            "currentUserId": currentUserId
        ]
        return try await client.action("search:enhanceWithLLM", with: args)
    }


    /// Name autocomplete — lightweight name search for autocomplete
    func nameAutocomplete(query: String, currentUserId: String) async throws -> [NameAutocompleteResult] {
        let args: [String: (any ConvexEncodable)?] = [
            "query": query,
            "currentUserId": currentUserId
        ]
        return try await client.action("users:searchByName", with: args)
    }


    // MARK: Search Sessions (Streaming)

    /// Create a search session — returns session ID
    func createSearchSession(query: String, currentUserId: String) async throws -> String {
        return try await client.mutation("searchSessions:createSession", with: [
            "userId": currentUserId,
            "query": query
        ])
    }


    /// Subscribe to search session for real-time streaming updates
    func subscribeSearchSession(sessionId: String) -> AnyPublisher<SearchSessionResponse?, ClientError> {
        return client.subscribe(to: "searchSessions:getSession", with: ["sessionId": sessionId], yielding: SearchSessionResponse?.self)
    }


    // MARK: Search Chats

    /// Subscribe to search chat list for a user
    func subscribeSearchChats(userId: String) -> AnyPublisher<[SearchChatResponse], ClientError> {
        return client.subscribe(to: "searchChats:listChats", with: ["userId": userId], yielding: [SearchChatResponse].self)
    }


    /// Delete a search chat
    func deleteSearchChat(chatId: String) async throws {
        let _: String? = try await client.mutation("searchChats:deleteChat", with: ["chatId": chatId])
    }
}

extension ConvexClientManager {

    /// Fast name search for cards (typing phase — no embedding, no action overhead)
    func fetchNameSearchResults(query: String, currentUserId: String) async throws -> [UserResponse] {
        return try await queryOnce("users:searchForCards", with: [
                "query": query,
                "currentUserId": currentUserId,
                // Double, not Int: convex-swift encodes Int as int64, which the
                // backend's v.number() (float64) validator rejects.
                "limit": Double(8),
            ], yielding: [UserResponse].self)
    }

    /// Fire the streaming LLM enhancement action (returns when complete)
    func streamEnhanceWithLLM(sessionId: String, query: String, userIds: [String], currentUserId: String) async throws {
        let userIdsEncodable: [ConvexEncodable?] = userIds.map { $0 as ConvexEncodable? }
        let args: [String: (any ConvexEncodable)?] = [
            "sessionId": sessionId,
            "query": query,
            "userIds": userIdsEncodable,
            "currentUserId": currentUserId
        ]
        let _: String? = try await client.action("search:streamEnhanceWithLLM", with: args)
    }
}
