//
//  FeedPreviewData.swift
//  junto
//
//  Mock feed items for the JUNTO_PREVIEW_FEED simulator rig. DEBUG only.
//

#if DEBUG
import Foundation

extension FeedItemResponse {
    static var previewItems: [FeedItemResponse] {
        [
            FeedItemResponse(
                kind: "post",
                key: "preview_post_1",
                tags: ["Software Development", "Design"],
                post: PostResponse(
                    _id: "preview_post_1",
                    authorId: "mock_2",
                    content: "Need someone to help out with development and coding a new suite of features.",
                    category: "asking",
                    topics: ["Software Development", "Design"],
                    imageUrl: nil, imageUrls: nil, linkUrl: nil, gifUrl: nil,
                    createdAt: Date().addingTimeInterval(-7200).timeIntervalSince1970 * 1000,
                    updatedAt: Date().addingTimeInterval(-7200).timeIntervalSince1970 * 1000,
                    author: UserResponse.previewMock,
                    commentCount: 0,
                    recentCommenters: nil
                ),
                event: nil, match: nil
            ),
            FeedItemResponse(
                kind: "event",
                key: "preview_event_1",
                tags: ["Software Development", "Design"],
                post: nil,
                event: previewEvent,
                match: nil
            ),
            FeedItemResponse(
                kind: "match",
                key: "preview_match_1",
                tags: ["Software Development", "Design"],
                post: nil, event: nil,
                match: .mock
            ),
            FeedItemResponse(
                kind: "post",
                key: "preview_post_2",
                tags: ["Design"],
                post: PostResponse(
                    _id: "preview_post_2",
                    authorId: "mock_3",
                    content: "Just shipped a new onboarding flow — would love feedback from any designers here.",
                    category: "sharing",
                    topics: ["Design"],
                    imageUrl: nil, imageUrls: nil, linkUrl: nil, gifUrl: nil,
                    createdAt: Date().addingTimeInterval(-18000).timeIntervalSince1970 * 1000,
                    updatedAt: Date().addingTimeInterval(-18000).timeIntervalSince1970 * 1000,
                    author: UserResponse.mockList.count > 1 ? UserResponse.mockList[1] : UserResponse.mock,
                    commentCount: 0,
                    recentCommenters: nil
                ),
                event: nil, match: nil
            )
        ]
    }

    private static var previewEvent: EventResponse {
        var comps = DateComponents()
        comps.year = 2026; comps.month = 5; comps.day = 23; comps.hour = 19; comps.minute = 30
        let start = Calendar.current.date(from: comps) ?? Date()
        let end = start.addingTimeInterval(3 * 3600)
        return EventResponse(
            _id: "preview_event_1",
            title: "Open Pitch Night #3",
            description: nil,
            date: start.timeIntervalSince1970 * 1000,
            endDate: end.timeIntervalSince1970 * 1000,
            location: "Lincoln, NE",
            type: "in_person",
            hostName: "Center of Entrepreneurship",
            category: "Pitch",
            imageUrl: "https://images.unsplash.com/photo-1556761175-5973dc0f32e7?w=800&h=400&fit=crop",
            createdBy: "mock_1",
            createdAt: Date().timeIntervalSince1970 * 1000,
            host: EventResponse.EventHost(id: "mock_1", name: "Center of Entrepreneurship", avatarUrl: "https://i.pravatar.cc/200?img=52"),
            goingCount: 24,
            attendeePreviews: nil
        )
    }
}
#endif
