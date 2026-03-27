//
//  EventCardView.swift
//  mkrs-world
//
//  Event row for the events list
//

import SwiftUI

struct EventCardView: View {
    let event: EventResponse
    var isGoing: Bool = false

    var body: some View {
        HStack(alignment: .top, spacing: Spacing.md) {
            // Thumbnail
            eventImage
                .frame(width: 80, height: 107)
                .cornerRadius(Radius.md)

            // Info
            VStack(alignment: .leading, spacing: Spacing.sm) {
                // Host
                if let host = event.host {
                    HStack(spacing: Spacing.xxs) {
                        AvatarView(
                            avatarUrl: host.avatarUrl,
                            name: host.name,
                            size: 14
                        )

                        Text(host.name)
                            .font(.caption12)
                            .foregroundColor(.appSecondary)
                            .lineLimit(1)
                    }
                }

                // Title
                Text(event.title)
                    .font(.bodyLargeSemibold)
                    .foregroundColor(.appPrimary)
                    .lineLimit(2)

                // Date
                HStack(spacing: Spacing.xxs) {
                    Image(systemName: "calendar")
                        .font(.system(size: 12))
                    Text(formattedDateTime)
                        .font(.body14)
                }
                .foregroundColor(.appSecondary)

                // Location
                if let location = event.location {
                    HStack(spacing: Spacing.xxs) {
                        Image(systemName: "mappin")
                            .font(.system(size: 12))
                        Text(location)
                            .font(.body14)
                            .lineLimit(1)
                    }
                    .foregroundColor(.appSecondary)
                } else if event.eventType == .online {
                    HStack(spacing: Spacing.xxs) {
                        Image(systemName: "video")
                            .font(.system(size: 12))
                        Text("Online")
                            .font(.body14)
                    }
                    .foregroundColor(.appSecondary)
                }

                // Going tag
                if isGoing {
                    Text("Going")
                        .font(.captionSmallSemibold)
                        .foregroundColor(.appSuccess)
                        .padding(.horizontal, Spacing.xs)
                        .padding(.vertical, Spacing.xxxs)
                        .background(Color.appSuccess.opacity(0.12))
                        .clipShape(Capsule())
                }
            }

            Spacer()
        }
        .padding(.vertical, Spacing.lg)
    }

    @ViewBuilder
    private var eventImage: some View {
        if let imageUrl = event.imageUrl, let url = URL(string: imageUrl) {
            CachedAsyncImage(url: url) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                imagePlaceholder
            }
        } else {
            imagePlaceholder
        }
    }

    private var imagePlaceholder: some View {
        Rectangle()
            .fill(Color.appSurfaceSecondary)
            .overlay(
                Image(systemName: event.eventType.iconName)
                    .font(.system(size: 24))
                    .foregroundColor(.appSecondary)
            )
    }

    private var formattedDateTime: String {
        let formatter = DateFormatter()
        let calendar = Calendar.current

        if calendar.isDateInToday(event.dateValue) {
            formatter.dateFormat = "'Today,' h:mma"
        } else if calendar.isDateInTomorrow(event.dateValue) {
            formatter.dateFormat = "'Tomorrow,' h:mma"
        } else {
            formatter.dateFormat = "MMM d, h:mma"
        }

        return formatter.string(from: event.dateValue)
    }
}

#Preview {
    VStack(spacing: 0) {
        EventCardView(event: EventResponse.mockList[0], isGoing: true)
        Divider()
        EventCardView(event: EventResponse.mockList[1])
    }
    .padding(.horizontal, Spacing.md)
    .background(Color.appBackground)
}
