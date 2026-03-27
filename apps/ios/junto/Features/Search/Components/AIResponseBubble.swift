//
//  AIResponseBubble.swift
//  mkrs-world
//
//  Left-aligned AI response bubble with thinking text and result cards
//

import SwiftUI

struct AIResponseBubble: View {
    let thinking: String
    let results: [SearchResultItem]
    let userProfiles: [String: UserResponse]
    let connectionStatus: (String) -> ConnectionStatus
    let onViewProfile: (UserResponse) -> Void
    let onConnect: (String) -> Void

    var body: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: Spacing.sm) {
                // Thinking text with sparkle
                HStack(alignment: .top, spacing: Spacing.xs) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 12))
                        .foregroundColor(.appSecondary)

                    Text(thinking)
                        .font(.body14)
                        .foregroundColor(.appPrimary)
                }

                // Result cards
                if !results.isEmpty {
                    VStack(spacing: Spacing.xs) {
                        ForEach(results) { result in
                            if let user = userProfiles[result.userId] {
                                SearchResultCard(
                                    result: result,
                                    user: user,
                                    connectionStatus: connectionStatus(result.userId),
                                    onViewProfile: { onViewProfile(user) },
                                    onConnect: { onConnect(result.userId) }
                                )
                            }
                        }
                    }
                }
            }
            .padding(Spacing.md)
            .background(Color.appSurfaceSecondary)
            .clipShape(RoundedRectangle(cornerRadius: Radius.xxl))

            Spacer(minLength: 40)
        }
    }
}
