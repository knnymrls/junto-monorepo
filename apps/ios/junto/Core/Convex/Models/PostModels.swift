//
//  PostModels.swift
//  mkrs-world
//
//  Post, comment, and unified feed model types (+ preview mocks).
//

import Foundation
import SwiftUI
import ConvexMobile
import Combine
import UIKit


// MARK: - Post Types

struct PostResponse: Codable, Identifiable, Hashable {
    let _id: String
    let authorId: String
    let content: String
    let category: String
    let topics: [String]?          // AI-assigned skill categories (feed tag pills)
    let imageUrl: String?
    let imageUrls: [String]?
    let linkUrl: String?
    let gifUrl: String?
    let createdAt: Double
    let updatedAt: Double
    let author: UserResponse?
    let commentCount: Int?
    let recentCommenters: [RecentCommenter]?

    var id: String { _id }

    struct RecentCommenter: Codable, Hashable {
        let _id: String
        let name: String
        let avatarUrl: String?
    }

    var createdDate: Date { Date(timeIntervalSince1970: createdAt / 1000) }
    var updatedDate: Date { Date(timeIntervalSince1970: updatedAt / 1000) }

    /// All image URLs (combines legacy imageUrl with imageUrls array)
    var allImageUrls: [String] {
        var urls: [String] = []
        if let imageUrls = imageUrls, !imageUrls.isEmpty {
            urls = imageUrls
        } else if let imageUrl = imageUrl {
            urls = [imageUrl]
        }
        return urls
    }

    var categoryType: PostCategory {
        PostCategory(rawValue: category) ?? .sharing
    }

    enum PostCategory: String, Codable, CaseIterable {
        case asking = "asking"
        case sharing = "sharing"
        case lookingFor = "looking_for"

        var displayName: String {
            switch self {
            case .asking: return "Asking"
            case .sharing: return "Update"
            case .lookingFor: return "Looking For"
            }
        }

        var iconName: String {
            switch self {
            case .asking: return "questionmark.circle"
            case .sharing: return "lightbulb"
            case .lookingFor: return "magnifyingglass"
            }
        }

        var customIconName: ImageResource {
            switch self {
            case .asking: return .contentAsking
            case .sharing: return .contentSharing
            case .lookingFor: return .contentLooking
            }
        }
    }
}


// MARK: - Unified Feed Item

/// One row in the unified feed. `feed:getFeed` returns an ordered list of these,
/// each specialized as a post, event, or match. `tags` carries skill categories
/// for post + match cards (the pill row); events use date/time/category instead.
struct FeedItemResponse: Codable, Identifiable, Hashable {
    let kind: String
    let key: String
    let tags: [String]?
    let post: PostResponse?
    let event: EventResponse?
    let match: SuggestedMatchResponse?
    // Manufactured "house" cards that keep a sparse feed full (see feed-spec.md).
    let digest: DigestFeedResponse?
    let vouch: VouchFeedResponse?
    let momentum: MomentumFeedResponse?
    let milestone: MilestoneFeedResponse?
    let prompt: PromptFeedResponse?

    var id: String { key }

    // Explicit init so existing call sites (previews) that pass only the
    // taxonomy payloads keep compiling; new house payloads default to nil.
    init(
        kind: String,
        key: String,
        tags: [String]?,
        post: PostResponse? = nil,
        event: EventResponse? = nil,
        match: SuggestedMatchResponse? = nil,
        digest: DigestFeedResponse? = nil,
        vouch: VouchFeedResponse? = nil,
        momentum: MomentumFeedResponse? = nil,
        milestone: MilestoneFeedResponse? = nil,
        prompt: PromptFeedResponse? = nil
    ) {
        self.kind = kind
        self.key = key
        self.tags = tags
        self.post = post
        self.event = event
        self.match = match
        self.digest = digest
        self.vouch = vouch
        self.momentum = momentum
        self.milestone = milestone
        self.prompt = prompt
    }

    enum Kind: String, Codable {
        case post, event, match
        case digest, vouch, momentum, milestone, prompt
        case caughtUp = "caught_up"
    }

    var kindType: Kind? { Kind(rawValue: kind) }

    /// Ergonomic switch target for views — `switch item.content { case .post(let p): ... }`.
    enum Content {
        case post(PostResponse)
        case event(EventResponse)
        case match(SuggestedMatchResponse)
        case digest(DigestFeedResponse)
        case vouch(VouchFeedResponse)
        case momentum(MomentumFeedResponse)
        case milestone(MilestoneFeedResponse)
        case prompt(PromptFeedResponse)
        case caughtUp
    }

    var content: Content? {
        switch kindType {
        case .post:      return post.map(Content.post)
        case .event:     return event.map(Content.event)
        case .match:     return match.map(Content.match)
        case .digest:    return digest.map(Content.digest)
        case .vouch:     return vouch.map(Content.vouch)
        case .momentum:  return momentum.map(Content.momentum)
        case .milestone: return milestone.map(Content.milestone)
        case .prompt:    return prompt.map(Content.prompt)
        case .caughtUp:  return .caughtUp
        case .none:      return nil
        }
    }

    /// Skill-category tag pills (post topics / match person's skill categories).
    var displayTags: [String] { tags ?? [] }
}


// MARK: - Manufactured "house" card payloads

/// "This week: N makers, N asks, N events."
struct DigestFeedResponse: Codable, Hashable {
    let newMakers: Int
    let newAsks: Int
    let upcomingEvents: Int
}


/// "Builders made N connections this week."
struct MomentumFeedResponse: Codable, Hashable {
    let connectionsThisWeek: Int
}


/// "You hit N connections."
struct MilestoneFeedResponse: Codable, Hashable {
    let count: Int
}


/// "What do you need right now?" — nudge to post.
struct PromptFeedResponse: Codable, Hashable {
    let text: String
}


// MARK: - Mock Data for Posts

extension PostResponse {
    static let mock = PostResponse(
        _id: "post_1",
        authorId: "mock_1",
        content: "Looking for feedback on my pitch deck for FindU. Anyone have experience with EdTech fundraising?",
        category: "asking",
        topics: ["Business", "Design"],
        imageUrl: nil,
        imageUrls: nil,
        linkUrl: nil,
        gifUrl: nil,
        createdAt: Date().timeIntervalSince1970 * 1000,
        updatedAt: Date().timeIntervalSince1970 * 1000,
        author: UserResponse.mock,
        commentCount: 3,
        recentCommenters: [
            RecentCommenter(_id: "mock_2", name: "Sarah Chen", avatarUrl: nil),
            RecentCommenter(_id: "mock_3", name: "Marcus Williams", avatarUrl: nil)
        ]
    )

    static let mockList: [PostResponse] = [
        mock,
        PostResponse(
            _id: "post_2",
            authorId: "mock_2",
            content: "Just shipped v2 of our recipe AI! Now with meal planning and grocery lists. Would love beta testers.",
            category: "sharing",
            topics: ["Software Development"],
            imageUrl: nil,
            imageUrls: nil,
            linkUrl: "https://recipeai.app",
            gifUrl: nil,
            createdAt: Date().addingTimeInterval(-3600).timeIntervalSince1970 * 1000,
            updatedAt: Date().addingTimeInterval(-3600).timeIntervalSince1970 * 1000,
            author: UserResponse.mockList[1],
            commentCount: 5,
            recentCommenters: [
                RecentCommenter(_id: "mock_1", name: "Kenny Morales", avatarUrl: nil)
            ]
        ),
        PostResponse(
            _id: "post_3",
            authorId: "mock_3",
            content: "Looking for a technical co-founder for a design tools startup. Need someone strong in React and real-time collaboration.",
            category: "looking_for",
            topics: ["Software Development", "Design"],
            imageUrl: nil,
            imageUrls: nil,
            linkUrl: nil,
            gifUrl: nil,
            createdAt: Date().addingTimeInterval(-7200).timeIntervalSince1970 * 1000,
            updatedAt: Date().addingTimeInterval(-7200).timeIntervalSince1970 * 1000,
            author: UserResponse.mockList[2],
            commentCount: 8,
            recentCommenters: [
                RecentCommenter(_id: "mock_1", name: "Kenny Morales", avatarUrl: nil),
                RecentCommenter(_id: "mock_2", name: "Sarah Chen", avatarUrl: nil)
            ]
        )
    ]
}


struct CommentResponse: Codable, Identifiable, Hashable {
    let _id: String
    let postId: String
    let authorId: String
    let content: String
    let mentions: [String]?
    let imageUrl: String?
    let linkUrl: String?
    let gifUrl: String?
    let createdAt: Double
    let author: UserResponse?
    let mentionedUsers: [UserResponse]?

    var id: String { _id }

    var createdDate: Date { Date(timeIntervalSince1970: createdAt / 1000) }
}


// MARK: - Mock Data for Comments

extension CommentResponse {
    static let mock = CommentResponse(
        _id: "comment_1",
        postId: "post_1",
        authorId: "mock_2",
        content: "Happy to help! DM me and I'll share some resources.",
        mentions: nil,
        imageUrl: nil,
        linkUrl: nil,
        gifUrl: nil,
        createdAt: Date().addingTimeInterval(-1800).timeIntervalSince1970 * 1000,
        author: UserResponse.mockList[1],
        mentionedUsers: nil
    )

    static let mockList: [CommentResponse] = [
        mock,
        CommentResponse(
            _id: "comment_2",
            postId: "post_1",
            authorId: "mock_3",
            content: "I know @Sarah Chen has done this before - might be worth connecting!",
            mentions: ["mock_2"],
            imageUrl: nil,
            linkUrl: nil,
            gifUrl: nil,
            createdAt: Date().addingTimeInterval(-900).timeIntervalSince1970 * 1000,
            author: UserResponse.mockList[2],
            mentionedUsers: [UserResponse.mockList[1]]
        ),
        CommentResponse(
            _id: "comment_3",
            postId: "post_1",
            authorId: "mock_2",
            content: "Sounds great — I'll reach out!",
            mentions: nil,
            imageUrl: nil,
            linkUrl: nil,
            gifUrl: nil,
            createdAt: Date().addingTimeInterval(-300).timeIntervalSince1970 * 1000,
            author: UserResponse.mockList[1],
            mentionedUsers: nil
        )
    ]
}


struct PostInput {
    let content: String
    let category: PostResponse.PostCategory
    var imageUrls: [String]?
    var linkUrl: String?
    var gifUrl: String?
    var mentions: [String]?

    func toArgs(authorId: String) -> [String: (any ConvexEncodable)?] {
        var args: [String: (any ConvexEncodable)?] = [
            "authorId": authorId,
            "content": content,
            "category": category.rawValue
        ]
        if let imageUrls = imageUrls, !imageUrls.isEmpty {
            // Cast [String] to [ConvexEncodable?] for proper encoding
            let encodableUrls: [ConvexEncodable?] = imageUrls.map { $0 as ConvexEncodable? }
            args["imageUrls"] = encodableUrls
        }
        if let linkUrl = linkUrl { args["linkUrl"] = linkUrl }
        if let gifUrl = gifUrl { args["gifUrl"] = gifUrl }
        if let mentions = mentions, !mentions.isEmpty {
            let encodableMentions: [ConvexEncodable?] = mentions.map { $0 as ConvexEncodable? }
            args["mentions"] = encodableMentions
        }
        return args
    }
}


struct CommentInput {
    let postId: String
    let content: String
    var mentions: [String]?
    var imageUrl: String?
    var linkUrl: String?
    var gifUrl: String?

    func toArgs(authorId: String) -> [String: (any ConvexEncodable)?] {
        var args: [String: (any ConvexEncodable)?] = [
            "postId": postId,
            "authorId": authorId,
            "content": content
        ]
        if let imageUrl = imageUrl { args["imageUrl"] = imageUrl }
        if let linkUrl = linkUrl { args["linkUrl"] = linkUrl }
        if let gifUrl = gifUrl { args["gifUrl"] = gifUrl }
        if let mentions = mentions, !mentions.isEmpty {
            let encodableMentions: [ConvexEncodable?] = mentions.map { $0 as ConvexEncodable? }
            args["mentions"] = encodableMentions
        }
        return args
    }
}


struct MentionSuggestion: Codable, Identifiable, Hashable {
    let _id: String
    let name: String
    let headline: String?
    let avatarUrl: String?

    var id: String { _id }
}
