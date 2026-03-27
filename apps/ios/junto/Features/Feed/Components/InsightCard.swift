//
//  InsightCard.swift
//  junto
//
//  AI-generated insight cards for the feed
//

import SwiftUI

// MARK: - Match Insight Card (the hero — most important card in the app)

struct InsightMatchCard: View {
    let userName: String
    let userHeadline: String?
    let userAvatarUrl: String?
    let matchReason: String
    var connectionStatus: ConnectionDisplayStatus = .none
    var onConnectTap: (() -> Void)? = nil
    var onDismissTap: (() -> Void)? = nil
    var onCardTap: (() -> Void)? = nil

    var body: some View {
        VStack(spacing: 0) {
            // Colored top accent bar
            LinearGradient(
                colors: [
                    Color(red: 50/255, green: 211/255, blue: 204/255),
                    Color(red: 50/255, green: 166/255, blue: 255/255),
                ],
                startPoint: .leading,
                endPoint: .trailing
            )
            .frame(height: 3)

            VStack(alignment: .leading, spacing: Spacing.lg) {
                // Header: badge + dismiss
                HStack {
                    HStack(spacing: Spacing.xs) {
                        Image(systemName: "sparkles")
                            .font(.system(size: 12))
                        Text("Suggested for you")
                            .font(.captionSemibold)
                    }
                    .foregroundColor(Color(red: 50/255, green: 166/255, blue: 255/255))

                    Spacer()

                    Button(action: { onDismissTap?() }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.appSecondary)
                            .padding(Spacing.sm)
                    }
                    .buttonStyle(.plain)
                }

                // User row: big avatar + name/headline
                HStack(spacing: Spacing.md) {
                    AvatarView(
                        avatarUrl: userAvatarUrl,
                        name: userName,
                        size: 56
                    )

                    VStack(alignment: .leading, spacing: Spacing.xxxs) {
                        Text(userName)
                            .font(.heading3)
                            .foregroundColor(.appPrimary)

                        if let headline = userHeadline {
                            Text(headline)
                                .font(.body14)
                                .foregroundColor(.appSecondary)
                                .lineLimit(1)
                        }
                    }

                    Spacer()
                }

                // Match reason — why this person
                Text(matchReason)
                    .font(.bodyLarge)
                    .foregroundColor(.appPrimary)
                    .lineSpacing(4)

                // Connect CTA — full width, prominent
                Button(action: { onConnectTap?() }) {
                    HStack(spacing: Spacing.sm) {
                        Image(systemName: connectionStatus == .none ? "person.badge.plus" : "checkmark")
                            .font(.system(size: 14))
                        Text(connectionStatus == .none ? "Connect" : connectionStatus == .pending ? "Pending" : "Connected")
                            .font(.bodyLargeSemibold)
                    }
                    .foregroundColor(connectionStatus == .none ? .white : .appSecondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, Spacing.md)
                    .background(
                        connectionStatus == .none
                            ? AnyShapeStyle(LinearGradient(
                                colors: [
                                    Color(red: 50/255, green: 211/255, blue: 204/255),
                                    Color(red: 50/255, green: 166/255, blue: 255/255),
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                              ))
                            : AnyShapeStyle(Color.appSurfaceSecondary)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: Radius.xxl))
                }
                .buttonStyle(.plain)
                .disabled(connectionStatus != .none)
            }
            .padding(Spacing.lg)
            .background(Color.appSurfaceSecondary.opacity(0.5))
        }
        .clipShape(RoundedRectangle(cornerRadius: Radius.xxxl))
        .overlay(
            RoundedRectangle(cornerRadius: Radius.xxxl)
                .stroke(Color.appBorder, lineWidth: 1)
        )
        .padding(.horizontal, Spacing.md)
        .padding(.vertical, Spacing.sm)
    }
}

// MARK: - Activity Cards (compact — vouch, new member, portfolio are lightweight)

struct VouchCard: View {
    let fromName: String
    let fromAvatarUrl: String?
    let toName: String
    let toAvatarUrl: String?
    let reason: String
    let timeAgo: String

    var body: some View {
        HStack(alignment: .top, spacing: Spacing.md) {
            // Stacked avatars
            ZStack(alignment: .bottomTrailing) {
                AvatarView(avatarUrl: fromAvatarUrl, name: fromName, size: 36)
                AvatarView(avatarUrl: toAvatarUrl, name: toName, size: 20)
                    .overlay(Circle().stroke(Color.appSurface, lineWidth: 2))
                    .offset(x: 6, y: 6)
            }
            .frame(width: 44, height: 44)

            VStack(alignment: .leading, spacing: Spacing.xxs) {
                HStack(spacing: 0) {
                    Text(fromName)
                        .font(.bodySemibold)
                        .foregroundColor(.appPrimary)
                    Text(" vouched for ")
                        .font(.body14)
                        .foregroundColor(.appSecondary)
                    Text(toName)
                        .font(.bodySemibold)
                        .foregroundColor(.appPrimary)
                }
                .lineLimit(1)

                Text("\"\(reason)\"")
                    .font(.body14)
                    .foregroundColor(.appPrimary)
                    .italic()
                    .lineLimit(2)

                Text(timeAgo)
                    .font(.caption12)
                    .foregroundColor(.appTertiary)
                    .padding(.top, Spacing.xxxs)
            }

            Spacer()
        }
        .padding(.horizontal, Spacing.md)
        .padding(.vertical, Spacing.lg)
        .background(Color.appSurface)
    }
}

struct NewMemberCard: View {
    let name: String
    let avatarUrl: String?
    let headline: String?
    let interests: [String]
    let timeAgo: String
    var onTap: (() -> Void)? = nil

    var body: some View {
        Button(action: { onTap?() }) {
            HStack(spacing: Spacing.md) {
                AvatarView(avatarUrl: avatarUrl, name: name, size: 40)

                VStack(alignment: .leading, spacing: Spacing.xxxs) {
                    HStack(spacing: 0) {
                        Text(name)
                            .font(.bodySemibold)
                            .foregroundColor(.appPrimary)
                        Text(" just joined")
                            .font(.body14)
                            .foregroundColor(.appSecondary)
                    }
                    .lineLimit(1)

                    if let headline = headline {
                        Text(headline)
                            .font(.caption12)
                            .foregroundColor(.appSecondary)
                            .lineLimit(1)
                    }

                    if !interests.isEmpty {
                        HStack(spacing: Spacing.xxs) {
                            ForEach(interests.prefix(3), id: \.self) { interest in
                                Text(interest)
                                    .font(.captionSmall)
                                    .foregroundColor(.appSecondary)
                                    .padding(.horizontal, Spacing.sm)
                                    .padding(.vertical, Spacing.xxxs)
                                    .background(Color.appSurfaceSecondary)
                                    .clipShape(Capsule())
                            }
                        }
                        .padding(.top, Spacing.xxxs)
                    }
                }

                Spacer()

                Text(timeAgo)
                    .font(.caption12)
                    .foregroundColor(.appTertiary)
            }
            .padding(.horizontal, Spacing.md)
            .padding(.vertical, Spacing.md)
            .background(Color.appSurface)
        }
        .buttonStyle(.plain)
    }
}

struct PortfolioEntryCard: View {
    let userName: String
    let userAvatarUrl: String?
    let projectTitle: String
    let projectDescription: String?
    let timeAgo: String

    var body: some View {
        HStack(alignment: .top, spacing: Spacing.md) {
            AvatarView(avatarUrl: userAvatarUrl, name: userName, size: 36)

            VStack(alignment: .leading, spacing: Spacing.xxs) {
                HStack(spacing: 0) {
                    Text(userName)
                        .font(.bodySemibold)
                        .foregroundColor(.appPrimary)
                    Text(" added to portfolio")
                        .font(.body14)
                        .foregroundColor(.appSecondary)
                }
                .lineLimit(1)

                VStack(alignment: .leading, spacing: Spacing.xxs) {
                    Text(projectTitle)
                        .font(.bodySemibold)
                        .foregroundColor(.appPrimary)

                    if let desc = projectDescription {
                        Text(desc)
                            .font(.caption12)
                            .foregroundColor(.appSecondary)
                            .lineLimit(2)
                    }
                }
                .padding(Spacing.md)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.appSurfaceSecondary)
                .clipShape(RoundedRectangle(cornerRadius: Radius.xxl))

                Text(timeAgo)
                    .font(.caption12)
                    .foregroundColor(.appTertiary)
                    .padding(.top, Spacing.xxxs)
            }

            Spacer()
        }
        .padding(.horizontal, Spacing.md)
        .padding(.vertical, Spacing.lg)
        .background(Color.appSurface)
    }
}

// MARK: - Event Feed Card

struct EventFeedCard: View {
    let title: String
    let date: String
    let location: String?
    let attendeeCount: Int
    let imageUrl: String?
    var onRSVPTap: (() -> Void)? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Gradient header
            ZStack(alignment: .bottomLeading) {
                LinearGradient(
                    colors: [
                        Color(red: 50/255, green: 166/255, blue: 255/255),
                        Color(red: 136/255, green: 159/255, blue: 255/255),
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .frame(height: 100)

                Text(date)
                    .font(.captionSemibold)
                    .foregroundColor(.white)
                    .padding(.horizontal, Spacing.md)
                    .padding(.vertical, Spacing.xs)
                    .background(.ultraThinMaterial)
                    .clipShape(Capsule())
                    .padding(Spacing.md)
            }

            VStack(alignment: .leading, spacing: Spacing.sm) {
                Text(title)
                    .font(.bodyLargeSemibold)
                    .foregroundColor(.appPrimary)
                    .lineLimit(2)

                HStack(spacing: Spacing.lg) {
                    if let location = location {
                        HStack(spacing: Spacing.xxs) {
                            Image(systemName: "mappin")
                                .font(.caption12)
                            Text(location)
                                .font(.caption12)
                        }
                        .foregroundColor(.appSecondary)
                    }

                    HStack(spacing: Spacing.xxs) {
                        Image(systemName: "person.2")
                            .font(.caption12)
                        Text("\(attendeeCount) going")
                            .font(.caption12)
                    }
                    .foregroundColor(.appSecondary)
                }

                Button(action: { onRSVPTap?() }) {
                    Text("RSVP")
                        .font(.bodySemibold)
                        .foregroundColor(.appOnAccent)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, Spacing.md)
                        .background(Color.appAccent)
                        .clipShape(RoundedRectangle(cornerRadius: Radius.xxl))
                }
                .buttonStyle(.plain)
            }
            .padding(Spacing.lg)
        }
        .background(Color.appSurface)
        .clipShape(RoundedRectangle(cornerRadius: Radius.xxxl))
        .overlay(
            RoundedRectangle(cornerRadius: Radius.xxxl)
                .stroke(Color.appBorder, lineWidth: 1)
        )
        .padding(.horizontal, Spacing.md)
        .padding(.vertical, Spacing.sm)
    }
}

// MARK: - Feed States

struct EmptyFeedView: View {
    var onPostTap: (() -> Void)? = nil

    var body: some View {
        VStack(spacing: Spacing.xxl) {
            Spacer()

            VStack(spacing: Spacing.lg) {
                Image(systemName: "sparkles")
                    .font(.system(size: 48))
                    .foregroundColor(.appSecondary)

                Text("Your feed is empty")
                    .font(.heading2)
                    .foregroundColor(.appPrimary)

                Text("Be the first to share something.\nPosts, questions, and updates show up here.")
                    .font(.body14)
                    .foregroundColor(.appSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, Spacing.xxl)
            }

            Button(action: { onPostTap?() }) {
                Text("Create a post")
                    .font(.bodySemibold)
                    .foregroundColor(.appOnAccent)
                    .padding(.horizontal, Spacing.xxxl)
                    .padding(.vertical, Spacing.md)
                    .background(Color.appAccent)
                    .clipShape(RoundedRectangle(cornerRadius: Radius.xxl))
            }
            .buttonStyle(.plain)

            Spacer()
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }
}

struct AllCaughtUpView: View {
    var body: some View {
        VStack(spacing: Spacing.md) {
            Image(systemName: "checkmark.circle")
                .font(.system(size: 32))
                .foregroundColor(.appSuccess)

            Text("You're all caught up")
                .font(.bodySemibold)
                .foregroundColor(.appPrimary)

            Text("Check back later for new updates")
                .font(.caption12)
                .foregroundColor(.appSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Spacing.huge)
    }
}

struct FeedShimmerView: View {
    var body: some View {
        VStack(spacing: 0) {
            ForEach(0..<4, id: \.self) { _ in
                HStack(alignment: .top, spacing: Spacing.md) {
                    Circle()
                        .fill(Color.appSurfaceSecondary)
                        .frame(width: 44, height: 44)

                    VStack(alignment: .leading, spacing: Spacing.sm) {
                        HStack(spacing: Spacing.sm) {
                            RoundedRectangle(cornerRadius: Radius.xs)
                                .fill(Color.appSurfaceSecondary)
                                .frame(width: 100, height: 14)
                            RoundedRectangle(cornerRadius: Radius.xs)
                                .fill(Color.appSurfaceSecondary)
                                .frame(width: 30, height: 14)
                        }

                        VStack(alignment: .leading, spacing: Spacing.xxs) {
                            RoundedRectangle(cornerRadius: Radius.xs)
                                .fill(Color.appSurfaceSecondary)
                                .frame(height: 14)
                            RoundedRectangle(cornerRadius: Radius.xs)
                                .fill(Color.appSurfaceSecondary)
                                .frame(width: 200, height: 14)
                        }
                    }
                }
                .padding(.horizontal, Spacing.md)
                .padding(.vertical, Spacing.lg)
                Divider()
            }
        }
    }
}

// MARK: - Previews

#Preview("Match Card") {
    ScrollView {
        InsightMatchCard(
            userName: "Elena Rodriguez",
            userHeadline: "UX Designer · Raikes School",
            userAvatarUrl: nil,
            matchReason: "She's a designer who's worked on 3 student projects. You said you're looking for design help."
        )
        .padding(.top, Spacing.md)
    }
    .background(Color.appBackground)
}

#Preview("All Cards") {
    ScrollView {
        VStack(spacing: 0) {
            InsightMatchCard(
                userName: "Elena Rodriguez",
                userHeadline: "UX Designer · Raikes School",
                userAvatarUrl: nil,
                matchReason: "She's a designer who's worked on 3 student projects. You said you're looking for design help."
            )

            Divider().padding(.vertical, Spacing.xxs)

            FeedPostCard(
                post: .mock,
                connectionStatus: .connected,
                isOwnPost: false
            )

            Divider()

            VouchCard(
                fromName: "Wilson",
                fromAvatarUrl: nil,
                toName: "Kenny",
                toAvatarUrl: nil,
                reason: "Built the entire matching algorithm from scratch",
                timeAgo: "2h"
            )

            Divider()

            NewMemberCard(
                name: "Jordan Chen",
                avatarUrl: nil,
                headline: "Computer Science · UNL",
                interests: ["AI", "Machine Learning", "Python"],
                timeAgo: "3h"
            )

            Divider()

            PortfolioEntryCard(
                userName: "Alex Kim",
                userAvatarUrl: nil,
                projectTitle: "CampusConnect — Event Discovery App",
                projectDescription: "Real-time campus event platform with social features",
                timeAgo: "4h"
            )

            Divider().padding(.vertical, Spacing.xxs)

            EventFeedCard(
                title: "Pitch Night — Show what you're building",
                date: "Thu, Mar 20 · 6:00 PM",
                location: "Raikes School, UNL",
                attendeeCount: 12,
                imageUrl: nil
            )

            Divider().padding(.vertical, Spacing.xxs)

            FeedPostCard(
                post: PostResponse.mockList[1],
                connectionStatus: .none,
                isOwnPost: false
            )

            Divider()

            AllCaughtUpView()
        }
    }
    .background(Color.appBackground)
}

#Preview("Empty") {
    EmptyFeedView()
        .background(Color.appBackground)
}

#Preview("Loading") {
    FeedShimmerView()
        .background(Color.appBackground)
}
