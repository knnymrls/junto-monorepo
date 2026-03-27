//
//  EventHeroSection.swift
//  mkrs-world
//
//  Hero image with blur, stacked avatars, title, date/location
//

import SwiftUI

struct EventHeroSection: View {
    let event: EventWithRsvpResponse

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .bottom) {
                // Background image
                if let imageUrl = event.imageUrl, let url = URL(string: imageUrl) {
                    CachedAsyncImage(url: url) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: geo.size.width, height: 500)
                            .clipped()
                    } placeholder: {
                        Rectangle()
                            .fill(Color.appSurfaceSecondary)
                    }
                } else {
                    Rectangle()
                        .fill(Color.appSurfaceSecondary)
                }

                // Gradient overlay
                LinearGradient(
                    colors: [.clear, .black.opacity(0.8)],
                    startPoint: .center,
                    endPoint: .bottom
                )

                // Hero content with true blur from bottom (colors bleed through)
                ZStack(alignment: .bottom) {
                    // Blurred copy of the image that fades in at bottom
                    if let imageUrl = event.imageUrl, let url = URL(string: imageUrl) {
                        CachedAsyncImage(url: url) { image in
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: geo.size.width, height: 500)
                                .clipped()
                                .blur(radius: 50)
                        } placeholder: {
                            Color.clear
                        }
                        .mask(
                            LinearGradient(
                                stops: [
                                    .init(color: .white, location: 0),
                                    .init(color: .white, location: 0.25),
                                    .init(color: .clear, location: 0.5)
                                ],
                                startPoint: .bottom,
                                endPoint: .top
                            )
                        )
                        .drawingGroup() // Rasterize to contain blur
                    }

                    // Content
                    VStack(spacing: Spacing.sm) {
                        // Stacked avatars
                        if let previews = event.attendeePreviews, !previews.isEmpty {
                            stackedAvatars(previews: previews)
                        }

                        // Attendee count
                        if event.goingCount > 0 {
                            Text(attendeeNames)
                                .font(.bodyMedium)
                                .foregroundColor(.appSecondaryOnDark)
                        }

                        // Title
                        Text(event.title)
                            .font(.displayMedium)
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)

                        // Date and location
                        HStack(spacing: Spacing.sm) {
                            Text(formattedDate)
                                .font(.bodyMedium)
                                .foregroundColor(.appSecondaryOnDark)

                            if event.location != nil {
                                Circle()
                                    .fill(Color.appSecondaryOnDark)
                                    .frame(width: 4, height: 4)

                                Text(event.location ?? "")
                                    .font(.bodyMedium)
                                    .foregroundColor(.appSecondaryOnDark)
                            }
                        }
                    }
                    .padding(.horizontal, Spacing.xxl)
                    .padding(.bottom, Spacing.huge)
                }
                .frame(maxWidth: .infinity)
            }
        }
        .frame(height: 500)
        .clipped()
    }

    // MARK: - Stacked Avatars

    private func stackedAvatars(previews: [EventWithRsvpResponse.AttendeePreview]) -> some View {
        // Max 7 avatars: 3 left + center + 3 right
        let maxAvatars = min(previews.count, 7)
        let avatars = Array(previews.prefix(maxAvatars))
        let centerIndex = avatars.count / 2

        return HStack(spacing: -14) {
            ForEach(Array(avatars.enumerated()), id: \.element.id) { index, preview in
                let distanceFromCenter = abs(index - centerIndex)

                // Size: center is largest, decreases outward
                let size: CGFloat = {
                    switch distanceFromCenter {
                    case 0: return 56
                    case 1: return 48
                    case 2: return 40
                    default: return 32
                    }
                }()

                // Y offset: center at top (0), drops by 4 each step
                let yOffset: CGFloat = CGFloat(distanceFromCenter * 4)

                AvatarView(
                    avatarUrl: preview.avatarUrl,
                    name: preview.name,
                    size: size
                )
                .overlay(
                    Circle()
                        .stroke(Color.white, lineWidth: 2)
                )
                .offset(y: yOffset)
                .zIndex(Double(10 - distanceFromCenter))
            }
        }
    }

    // MARK: - Helpers

    private var attendeeNames: String {
        guard let previews = event.attendeePreviews, !previews.isEmpty else {
            return "\(event.goingCount) going"
        }

        let names = previews.prefix(2).map { $0.name.components(separatedBy: " ").first ?? $0.name }
        let remaining = event.goingCount - names.count

        if remaining > 0 {
            return "\(names.joined(separator: ", ")) and \(remaining) more"
        } else {
            return names.joined(separator: " and ")
        }
    }

    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, h:mma"
        return formatter.string(from: event.dateValue)
    }
}
