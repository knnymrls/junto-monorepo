//
//  FeedEventCard.swift
//  junto
//
//  Event / Opportunity feed card. Matches Figma node 26:157:
//  host avatar (no connect badge) + Opportunity label, title, a date/time
//  meta row (primary color), topic tags (secondary), then a 208px banner.
//

import SwiftUI

struct FeedEventCard: View {
    let event: EventResponse
    let tags: [String]
    var onCardTap: (() -> Void)? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            HStack(alignment: .top, spacing: Spacing.md) {
                AvatarView(
                    avatarUrl: event.host?.avatarUrl,
                    name: event.displayHostName ?? event.title,
                    size: 44
                )

                VStack(alignment: .leading, spacing: Spacing.sm) {
                    VStack(alignment: .leading, spacing: Spacing.xxs) {
                        header
                        Text(event.title)
                            .font(.bodyLargeMedium)
                            .foregroundColor(.appPrimary)
                            .fixedSize(horizontal: false, vertical: true)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }

                    // Date / time — primary color (per Figma)
                    HStack(spacing: Spacing.sm) {
                        metaItem(icon: "feed.calendar", text: eventDateString(event.dateValue))
                        metaItem(icon: "feed.clock", text: eventTimeString(start: event.dateValue, end: event.endDateValue))
                    }

                    // Topic tags — secondary color
                    if !tags.isEmpty {
                        FlowLayout(spacing: Spacing.md) {
                            ForEach(tags, id: \.self) { tag in
                                TopicTag(category: tag)
                            }
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            // Banner — fixed-size box that the image fills into, so scaledToFill
            // overflow is clipped to the (padded) card width instead of expanding it.
            if let urlString = event.imageUrl, let url = URL(string: urlString) {
                Color.appSurfaceSecondary
                    .frame(maxWidth: .infinity)
                    .frame(height: 208)
                    .overlay(
                        CachedAsyncImage(url: url) { image in
                            image
                                .resizable()
                                .scaledToFill()
                        } placeholder: {
                            Color.clear
                        }
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }
        }
        .padding(.horizontal, Spacing.md)
        .padding(.vertical, Spacing.lg)
        .background(Color.appSurface)
        .contentShape(Rectangle())
        .onTapGesture { onCardTap?() }
    }

    // MARK: - Header (host name · Opportunity label)

    private var header: some View {
        HStack(alignment: .center) {
            Text(event.displayHostName ?? "Event")
                .font(.caption12)
                .foregroundColor(.appPrimary)

            Spacer(minLength: Spacing.sm)

            FeedTypeLabel(kind: .opportunity)
        }
    }

    // MARK: - Meta item (icon + text)

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
        .foregroundColor(.appPrimary)
    }

    // MARK: - Date / time formatting

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
