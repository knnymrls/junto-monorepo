//
//  DiscoverEventCard.swift
//  junto
//
//  Compact event row for Discover (landing "Upcoming Events" + the events
//  list). Square thumbnail (left) + host · Opportunity label, title, a
//  date/time meta row, and category tags. Matches the Discover artboard's
//  event card (Paper node 7E7-0) — more compact than the Feed's banner card.
//

import SwiftUI

struct DiscoverEventCard: View {
    let event: EventResponse
    var onCardTap: (() -> Void)? = nil
    /// Shows a Luma-style "Going" badge over the thumbnail (Your Events strip).
    var goingBadge: Bool = false

    /// The maker categories the event touches (icon'd tags).
    private var makerCategories: [SkillCategory] {
        (event.categories ?? []).compactMap { SkillCategory.match($0) }
    }

    var body: some View {
        HStack(alignment: .top, spacing: Spacing.md) {
            thumbnail
                .frame(width: 80, height: 80)
                .clipShape(RoundedRectangle(cornerRadius: Radius.xl))
                .overlay(alignment: .bottom) {
                    if goingBadge { goingPill }
                }

            VStack(alignment: .leading, spacing: Spacing.sm) {
                // Host · Opportunity
                HStack(spacing: Spacing.lg) {
                    HStack(spacing: Spacing.xxs) {
                        AvatarView(
                            avatarUrl: event.host?.avatarUrl,
                            name: event.displayHostName ?? event.title,
                            size: 14
                        )
                        Text(event.displayHostName ?? "Event")
                            .font(.caption12)
                            .foregroundColor(.appSecondary)
                            .lineLimit(1)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    FeedTypeLabel(kind: .opportunity)
                }

                Text(event.title)
                    .font(.bodyLargeSemibold)
                    .foregroundColor(.appPrimary)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, alignment: .leading)

                // Meta: date/time row + category tags
                VStack(alignment: .leading, spacing: Spacing.xxs) {
                    HStack(spacing: Spacing.sm) {
                        metaItem(icon: "feed.calendar", text: eventDateString(event.dateValue))
                        metaItem(icon: "event.clock", text: eventTimeString(start: event.dateValue, end: event.endDateValue))
                    }

                    if !makerCategories.isEmpty || !(event.category ?? "").isEmpty {
                        FlowLayout(spacing: Spacing.xs) {
                            ForEach(makerCategories, id: \.self) { cat in
                                TopicTag(category: cat.label, iconCategory: cat)
                            }
                            // The event type (e.g. "Pitch") borrows the primary
                            // category's icon so it reads as part of the set.
                            if let type = event.category, !type.isEmpty {
                                TopicTag(category: type, iconCategory: makerCategories.first)
                            }
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal, Spacing.lg)
        .padding(.vertical, Spacing.md)
        .background(Color.appSurface)
        .contentShape(Rectangle())
        .onTapGesture { onCardTap?() }
    }

    // MARK: - Going badge

    private var goingPill: some View {
        Text("Going")
            .font(.system(size: 11, weight: .semibold))
            .foregroundColor(Color(hex: 0x2B8A3E))
            .padding(.horizontal, Spacing.sm)
            .padding(.vertical, 3)
            .background(Color(hex: 0xD3F9D8), in: Capsule())
            .overlay(Capsule().stroke(Color.appSurface, lineWidth: 2))
            .offset(y: Spacing.sm)
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
            .fill(Color.appSurfaceSecondary)
            .overlay(
                Image(systemName: event.eventType.iconName)
                    .font(.system(size: 22))
                    .foregroundColor(.appSecondary)
            )
    }

    // MARK: - Meta item (icon + text) — secondary color, per design

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

    // MARK: - Date / time formatting (matches FeedEventCard)

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
