//
//  AskJuntoEventCard.swift
//  junto
//
//  Compact event card for an Ask Junto `opportunities` block — a fixed-width
//  tile in a horizontal strip (Figma node 148-31). Square thumbnail, title, and
//  a date + time meta row. Reuses CachedAsyncImage + the shared icon assets.
//

import SwiftUI

struct AskJuntoEventCard: View {
    let event: EventWithRsvpResponse
    var onTap: (() -> Void)? = nil
    /// Shows the green "Going" badge when the user is already going.
    var isGoing: Bool = false

    private let cardWidth: CGFloat = 260

    var body: some View {
        HStack(alignment: .top, spacing: Spacing.md) {
            thumbnail
                .frame(width: 72, height: 72)
                .clipShape(RoundedRectangle(cornerRadius: Radius.xl))
                .overlay(alignment: .bottom) {
                    // "Going" badge — same green pill as the Discover event card.
                    if isGoing {
                        AskJuntoConfirmedPill(text: "Going", bordered: true)
                            .offset(y: Spacing.sm)
                    }
                }

            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text(event.title)
                    .font(.bodyLargeSemibold)
                    .foregroundColor(.appPrimary)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)

                metaItem(icon: "feed.calendar", text: eventDateString(event.dateValue))
                metaItem(icon: "event.clock", text: eventTimeString(start: event.dateValue, end: event.endDateValue))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(Spacing.md)
        .frame(width: cardWidth, alignment: .leading)
        .background(Color.appSurfaceSecondary, in: RoundedRectangle(cornerRadius: Radius.xxl))
        .contentShape(RoundedRectangle(cornerRadius: Radius.xxl))
        .onTapGesture { onTap?() }
    }

    // MARK: - Thumbnail

    @ViewBuilder
    private var thumbnail: some View {
        if let urlString = event.imageUrl, let url = URL(string: urlString) {
            CachedAsyncImage(url: url) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                thumbnailPlaceholder
            }
        } else {
            thumbnailPlaceholder
        }
    }

    private var thumbnailPlaceholder: some View {
        Rectangle()
            .fill(Color.appSurface)
            .overlay(
                Image(systemName: event.eventType.iconName)
                    .font(.system(size: 22))
                    .foregroundColor(.appSecondary)
            )
    }

    // MARK: - Meta row (icon + text)

    private func metaItem(icon: String, text: String) -> some View {
        HStack(spacing: Spacing.xxs) {
            Image(icon)
                .renderingMode(.template)
                .resizable()
                .scaledToFit()
                .frame(width: 14, height: 14)
            Text(text)
                .font(.body14)
                .lineLimit(1)
        }
        .foregroundColor(.appSecondary)
    }

    // MARK: - Date / time formatting (matches DiscoverEventCard)

    private func eventDateString(_ date: Date) -> String {
        let day = Calendar.current.component(.day, from: date)
        let month = DateFormatter().monthSymbols[Calendar.current.component(.month, from: date) - 1]
        return "\(month) \(day)\(ordinalSuffix(day))"
    }

    private func ordinalSuffix(_ n: Int) -> String {
        switch n % 100 {
        case 11, 12, 13: return "th"
        default:
            switch n % 10 {
            case 1: return "st"
            case 2: return "nd"
            case 3: return "rd"
            default: return "th"
            }
        }
    }

    private func eventTimeString(start: Date, end: Date?) -> String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.dateFormat = "h:mma"
        f.amSymbol = "AM"
        f.pmSymbol = "PM"
        let startStr = f.string(from: start)
        if let end {
            return "\(startStr) - \(f.string(from: end))"
        }
        return startStr
    }
}

/// Shimmer placeholder shown in an events strip while an event is loading.
struct AskJuntoEventCardSkeleton: View {
    var body: some View {
        HStack(alignment: .top, spacing: Spacing.md) {
            SkeletonShape(width: 72, height: 72, cornerRadius: Radius.xl)

            VStack(alignment: .leading, spacing: Spacing.xs) {
                SkeletonShape(width: 150, height: 16)
                SkeletonShape(width: 90, height: 14)
                SkeletonShape(width: 110, height: 14)
            }
        }
        .padding(Spacing.md)
        .frame(width: 260, alignment: .leading)
        .background(Color.appSurfaceSecondary, in: RoundedRectangle(cornerRadius: Radius.xxl))
    }
}
