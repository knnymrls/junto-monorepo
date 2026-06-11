//
//  ConvexClient+Posts.swift
//  mkrs-world
//
//  Posts, comments, mentions, and the unified feed.
//

import Foundation
import ConvexMobile
import Combine
import UIKit

extension ConvexClientManager {

    // MARK: Posts

    /// Subscribe to feed for a user (connections first, then recent)
    func subscribeFeed(userId: String, limit: Int? = nil, offset: Int? = nil) -> AnyPublisher<[PostResponse], ClientError> {
        var args: [String: (any ConvexEncodable)?] = ["userId": userId]
        if let limit = limit {
            args["limit"] = Double(limit)
        }
        if let offset = offset {
            args["offset"] = Double(offset)
        }
        return client.subscribe(to: "posts:getFeed", with: args, yielding: [PostResponse].self)
    }


    /// Subscribe to the unified feed (posts + injected events + matches as typed items).
    /// `offset` counts POSTS already loaded; pages after the first are posts-only.
    func subscribeUnifiedFeed(userId: String, limit: Int? = nil, offset: Int? = nil) -> AnyPublisher<[FeedItemResponse], ClientError> {
        var args: [String: (any ConvexEncodable)?] = ["userId": userId]
        if let limit = limit {
            args["limit"] = Double(limit)
        }
        if let offset = offset {
            args["offset"] = Double(offset)
        }
        return client.subscribe(to: "feed:getFeed", with: args, yielding: [FeedItemResponse].self)
    }


    /// Subscribe to posts list
    func subscribePosts(authorId: String? = nil, limit: Int? = nil) -> AnyPublisher<[PostResponse], ClientError> {
        var args: [String: (any ConvexEncodable)?] = [:]
        if let authorId = authorId {
            args["authorId"] = authorId
        }
        if let limit = limit {
            args["limit"] = Double(limit)
        }

        if args.isEmpty {
            return client.subscribe(to: "posts:list", yielding: [PostResponse].self)
        } else {
            return client.subscribe(to: "posts:list", with: args, yielding: [PostResponse].self)
        }
    }


    /// Subscribe to a single post
    func subscribePost(postId: String) -> AnyPublisher<PostResponse?, ClientError> {
        return client.subscribe(to: "posts:get", with: ["postId": postId], yielding: PostResponse?.self)
    }


    /// Subscribe to posts by author
    func subscribePostsByAuthor(authorId: String, limit: Int? = nil) -> AnyPublisher<[PostResponse], ClientError> {
        var args: [String: (any ConvexEncodable)?] = ["authorId": authorId]
        if let limit = limit {
            args["limit"] = Double(limit)
        }
        return client.subscribe(to: "posts:getByAuthor", with: args, yielding: [PostResponse].self)
    }


    // MARK: Comments

    /// Subscribe to comments for a post
    func subscribeComments(postId: String, limit: Int? = nil) -> AnyPublisher<[CommentResponse], ClientError> {
        var args: [String: (any ConvexEncodable)?] = ["postId": postId]
        if let limit = limit {
            args["limit"] = Double(limit)
        }
        return client.subscribe(to: "comments:listByPost", with: args, yielding: [CommentResponse].self)
    }
}

extension ConvexClientManager {

    // MARK: Posts

    /// Create a new post
    func createPost(_ input: PostInput, authorId: String) async throws -> String {
        return try await client.mutation("posts:create", with: input.toArgs(authorId: authorId))
    }


    /// Update a post
    func updatePost(postId: String, content: String? = nil, category: PostResponse.PostCategory? = nil, imageUrls: [String]? = nil, linkUrl: String? = nil) async throws -> String {
        var args: [String: (any ConvexEncodable)?] = ["postId": postId]
        if let content = content { args["content"] = content }
        if let category = category { args["category"] = category.rawValue }
        // Always the full array — pass [] to clear removed images.
        if let imageUrls = imageUrls { args["imageUrls"] = imageUrls.map { $0 as ConvexEncodable? } }
        if let linkUrl = linkUrl { args["linkUrl"] = linkUrl }
        return try await client.mutation("posts:update", with: args)
    }


    /// Delete a post
    func deletePost(postId: String) async throws -> String {
        return try await client.mutation("posts:remove", with: ["postId": postId])
    }


    // MARK: Comments

    /// Create a comment on a post
    func createComment(_ input: CommentInput, authorId: String) async throws -> String {
        return try await client.mutation("comments:create", with: input.toArgs(authorId: authorId))
    }


    /// Delete a comment
    func deleteComment(commentId: String) async throws -> String {
        return try await client.mutation("comments:remove", with: ["commentId": commentId])
    }


    /// Update a comment
    func updateComment(commentId: String, content: String) async throws -> String {
        return try await client.mutation("comments:update", with: ["commentId": commentId, "content": content])
    }


    // MARK: Reports

    func reportPost(reporterId: String, postId: String, reason: String, details: String? = nil) async throws -> String {
        var args: [String: (any ConvexEncodable)?] = [
            "reporterId": reporterId,
            "postId": postId,
            "reason": reason
        ]
        if let details = details, !details.isEmpty {
            args["details"] = details
        }
        return try await client.mutation("reports:create", with: args)
    }
}

extension ConvexClientManager {

    // MARK: Posts

    /// Fetch feed once
    func fetchFeed(userId: String, limit: Int? = nil, offset: Int? = nil) async throws -> [PostResponse] {
        return try await queryOnce(subscribeFeed(userId: userId, limit: limit, offset: offset))
    }


    /// Fetch the unified feed once (posts + injected events + matches as typed items)
    func fetchUnifiedFeed(userId: String, limit: Int? = nil, offset: Int? = nil) async throws -> [FeedItemResponse] {
        return try await queryOnce(subscribeUnifiedFeed(userId: userId, limit: limit, offset: offset))
    }


    /// Fetch a single post once
    func fetchPost(postId: String) async throws -> PostResponse? {
        return try await queryOnce(subscribePost(postId: postId))
    }


    /// Fetch posts by author once
    func fetchPostsByAuthor(authorId: String, limit: Int? = nil) async throws -> [PostResponse] {
        return try await queryOnce(subscribePostsByAuthor(authorId: authorId, limit: limit))
    }


    // MARK: Comments

    /// Fetch comments for a post once
    func fetchComments(postId: String, limit: Int? = nil) async throws -> [CommentResponse] {
        return try await queryOnce(subscribeComments(postId: postId, limit: limit))
    }


    // MARK: Mentions

    /// Fetch mention suggestions by text search
    func fetchMentionSuggestions(searchText: String) async throws -> [MentionSuggestion] {
        return try await queryOnce("mentions:getSuggestions", with: ["searchText": searchText], yielding: [MentionSuggestion].self)
    }


    /// Fetch smart mention suggestions using vector search (relevance to post content)
    func fetchSmartMentionSuggestions(postId: String, searchText: String) async throws -> [MentionSuggestion] {
        return try await client.action("mentions:getSmartSuggestions", with: [
            "postId": postId,
            "searchText": searchText
        ])
    }
}
