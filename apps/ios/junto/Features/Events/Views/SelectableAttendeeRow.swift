//
//  SelectableAttendeeRow.swift
//  mkrs-world
//
//  Reusable attendee row with checkbox for feedback connect suggestions
//

import SwiftUI

struct SelectableAttendeeRow: View {
    let attendee: EventAttendee
    let isSelected: Bool
    let onToggle: () -> Void

    var body: some View {
        Button(action: onToggle) {
            HStack(spacing: Spacing.md) {
                AvatarView(
                    avatarUrl: attendee.avatarUrl,
                    name: attendee.name,
                    size: 40
                )

                VStack(alignment: .leading, spacing: Spacing.xxxs) {
                    Text(attendee.name)
                        .font(.bodyLargeMedium)
                        .foregroundColor(.appPrimary)

                    if let headline = attendee.headline, !headline.isEmpty {
                        Text(headline)
                            .font(.body14)
                            .foregroundColor(.appSecondary)
                            .lineLimit(1)
                    }
                }

                Spacer()

                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 22))
                    .foregroundColor(isSelected ? .appPrimary : .appSecondary)
            }
            .padding(.vertical, Spacing.sm)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}
