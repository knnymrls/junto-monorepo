//
//  SuggestedMatchCarousel.swift
//  mkrs-world
//
//  Horizontal scrolling carousel of suggested match cards
//

import SwiftUI

struct SuggestedMatchCarousel: View {
    let matches: [SuggestedMatchResponse]
    var connectionStatusFor: (String) -> ConnectionDisplayStatus = { _ in .none }
    var onConnectTap: ((SuggestedMatchResponse) -> Void)? = nil
    var onWithdrawTap: ((SuggestedMatchResponse) -> Void)? = nil
    var onCardTap: ((SuggestedMatchResponse) -> Void)? = nil

    var body: some View {
        if !matches.isEmpty {
            VStack(alignment: .leading, spacing: Spacing.sm) {
                Text("Suggested Matches")
                    .font(.bodySemibold)
                    .foregroundColor(.appSecondary)
                    .padding(.horizontal, Spacing.md)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(alignment: .top, spacing: Spacing.sm) {
                        ForEach(matches) { match in
                            SuggestedMatchCarouselCard(
                                match: match,
                                connectionStatus: connectionStatusFor(match._id),
                                onConnectTap: { onConnectTap?(match) },
                                onWithdrawTap: { onWithdrawTap?(match) },
                                onCardTap: { onCardTap?(match) }
                            )
                        }
                    }
                    .padding(.horizontal, Spacing.md)
                }
            }
            .padding(.vertical, Spacing.lg)
        }
    }
}

#Preview {
    SuggestedMatchCarousel(
        matches: [
            .mock,
            SuggestedMatchResponse(
                _id: "match_2",
                clerkId: "clerk_2",
                email: "wilson@example.com",
                name: "Wilson Overfield",
                headline: "Co-founder @ FindU",
                avatarUrl: nil,
                universityId: nil,
                currentProject: "FindU",
                lookingFor: "iOS developers",
                canHelpWith: "Fundraising, product strategy",
                skills: ["Product", "Strategy"],
                interests: ["EdTech", "Startups"],
                role: "student",
                isOnboarded: true,
                createdAt: Date().timeIntervalSince1970 * 1000,
                updatedAt: Date().timeIntervalSince1970 * 1000,
                matchReason: "Wilson can help with fundraising"
            ),
            SuggestedMatchResponse(
                _id: "match_3",
                clerkId: "clerk_3",
                email: "alex@example.com",
                name: "Alex Rivera",
                headline: "Designer @ Startup",
                avatarUrl: nil,
                universityId: nil,
                currentProject: "DesignCo",
                lookingFor: "Engineers",
                canHelpWith: "UI/UX, Branding",
                skills: ["Figma", "Swift"],
                interests: ["Design", "Mobile"],
                role: "student",
                isOnboarded: true,
                createdAt: Date().timeIntervalSince1970 * 1000,
                updatedAt: Date().timeIntervalSince1970 * 1000,
                matchReason: "Alex is looking for an engineer to build an iOS app"
            )
        ]
    )
    .background(Color.appBackground)
}
