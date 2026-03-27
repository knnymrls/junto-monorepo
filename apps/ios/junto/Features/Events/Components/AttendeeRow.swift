//
//  AttendeeRow.swift
//  mkrs-world
//
//  Attendee row with avatar, name, headline, and connection action
//

import SwiftUI

struct AttendeeRow: View {
    let attendee: EventAttendee
    let connectionState: AttendeeConnectionState
    var eventTitle: String? = nil
    var eventHasEnded: Bool = false
    let onProfileTap: () -> Void
    let onConnectTap: () -> Void

    enum AttendeeConnectionState {
        case none
        case pending
        case connected
    }

    var body: some View {
        HStack(spacing: Spacing.md) {
            Button(action: onProfileTap) {
                HStack(spacing: Spacing.md) {
                    AvatarView(
                        avatarUrl: attendee.avatarUrl,
                        name: attendee.name,
                        size: 44
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
                        } else if eventHasEnded, let title = eventTitle {
                            Text("You met at \(title)")
                                .font(.body14)
                                .foregroundColor(.appSecondary)
                                .lineLimit(1)
                        }
                    }
                }
            }
            .buttonStyle(.plain)

            Spacer()

            switch connectionState {
            case .connected:
                Text("Connected")
                    .font(.bodySmallMedium)
                    .foregroundColor(.appSecondary)
                    .padding(.horizontal, Spacing.md)
                    .padding(.vertical, Spacing.xs)
                    .background(Color.appSurfaceSecondary)
                    .clipShape(Capsule())
            case .pending:
                Text("Pending")
                    .font(.bodySmallMedium)
                    .foregroundColor(.appSecondary)
                    .padding(.horizontal, Spacing.md)
                    .padding(.vertical, Spacing.xs)
                    .background(Color.appSurfaceSecondary)
                    .clipShape(Capsule())
            case .none:
                Button(action: onConnectTap) {
                    Text("Connect")
                        .font(.bodySmallSemibold)
                        .foregroundColor(.white)
                        .padding(.horizontal, Spacing.md)
                        .padding(.vertical, Spacing.xs)
                        .background(Color.appPrimary)
                        .clipShape(Capsule())
                }
            }
        }
    }
}
