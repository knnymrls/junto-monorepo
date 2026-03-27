//
//  EventDetailView.swift
//  mkrs-world
//
//  Event detail sheet with hero, details, and RSVP
//

import SwiftUI
import Combine
import UIKit
import EventKit

struct EventDetailView: View {
    let event: EventWithRsvpResponse
    var onRsvp: ((String) -> Void)?
    var onAttendeeTap: ((String) -> Void)?

    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var currentUser: CurrentUserManager
    @State private var userRsvpStatus: String?
    @State private var isRsvping = false
    @State private var attendees: [EventAttendee] = []
    @State private var cancellables = Set<AnyCancellable>()
    @State private var showCalendarPrompt = false
    @State private var showCalendarConfirmation = false
    @State private var showAttendeesList = false
    @State private var showFeedbackSheet = false
    @State private var selectedUserProfile: UserResponse?
    @State private var connectedIds: Set<String> = []
    @State private var pendingConnectionIds: Set<String> = []

    private let convex = ConvexClientManager.shared

    private var eventHasEnded: Bool {
        let endTime = event.endDateValue ?? event.dateValue.addingTimeInterval(2 * 3600)
        return endTime < Date()
    }

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    EventHeroSection(event: event)

                    contentSection
                        .padding(.bottom, 80)
                }
            }

            // Floating RSVP button
            rsvpButton
                .padding(.trailing, Spacing.lg)
                .padding(.bottom, Spacing.xxl)
        }
        .background(Color.appBackground)
        .alert("Add to Calendar?", isPresented: $showCalendarPrompt) {
            Button("Add to Calendar") {
                Task { await addToCalendar() }
            }
            Button("No Thanks", role: .cancel) {}
        } message: {
            Text("Want to add \"\(event.title)\" to your calendar?")
        }
        .alert("Added to Calendar", isPresented: $showCalendarConfirmation) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("\"\(event.title)\" has been added to your calendar.")
        }
        .sheet(isPresented: $showAttendeesList) {
            AttendeesListView(
                event: event,
                userRsvpStatus: userRsvpStatus
            )
            .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showFeedbackSheet) {
            EventFeedbackSheet(event: event)
                .presentationDragIndicator(.visible)
        }
        .sheet(item: $selectedUserProfile) { user in
            ProfileView(user: user)
        }
        .task {
            AnalyticsService.shared.track(.eventViewed(
                eventId: event._id,
                eventType: event.eventType.rawValue,
                hostId: event.createdBy
            ))
            await loadUserRsvp()
            await loadAttendees()
            await loadConnectionState()
        }
    }

    // MARK: - Content Section

    private var contentSection: some View {
        VStack(alignment: .leading, spacing: Spacing.lg) {
            Text("Event Details")
                .font(.bodyLargeBold)
                .foregroundColor(.appPrimary)

            VStack(spacing: 0) {
                EventDetailRow(
                    icon: "person.2",
                    title: "\(event.goingCount) participants",
                    subtitle: attendeeNames
                )

                EventDetailRow(
                    icon: "calendar",
                    title: formattedDateRange,
                    subtitle: formattedDayAndTimezone
                )

                if let location = event.location {
                    let isGoing = userRsvpStatus == "going"
                    let displayAddress = isGoing ? (event.fullAddress ?? location) : location
                    EventDetailRow(
                        icon: "mappin",
                        title: displayAddress,
                        subtitle: isGoing ? "Tap for directions" : "Location will be sent after confirmation"
                    ) {
                        if isGoing, let address = event.fullAddress ?? event.location {
                            openInMaps(address: address)
                        }
                    }
                } else if event.eventType == .online {
                    EventDetailRow(
                        icon: "video",
                        title: "Online",
                        subtitle: "Link will be shared before the event"
                    )
                }
            }
            .background(Color.appSurface)

            // About section
            if let description = event.description, !description.isEmpty {
                Divider()
                    .padding(.vertical, Spacing.sm)

                Text("About")
                    .font(.bodyLargeBold)
                    .foregroundColor(.appPrimary)

                Text(description)
                    .font(.body14)
                    .foregroundColor(.appPrimary)
                    .lineSpacing(Spacing.xxs)
            }

            // Host section
            if let host = event.host {
                Divider()
                    .padding(.vertical, Spacing.sm)

                Text("Hosted by")
                    .font(.bodyLargeBold)
                    .foregroundColor(.appPrimary)

                HStack(spacing: Spacing.md) {
                    Button(action: { openProfile(id: host.id) }) {
                        HStack(spacing: Spacing.md) {
                            AvatarView(
                                avatarUrl: host.avatarUrl,
                                name: host.name,
                                size: 44
                            )

                            VStack(alignment: .leading, spacing: Spacing.xxxs) {
                                Text(host.name)
                                    .font(.bodyLargeMedium)
                                    .foregroundColor(.appPrimary)

                                if let headline = host.headline {
                                    Text(headline)
                                        .font(.body14)
                                        .foregroundColor(.appSecondary)
                                        .lineLimit(1)
                                }
                            }
                        }
                    }
                    .buttonStyle(.plain)

                    Spacer()

                    if host.id != currentUser.userId {
                        connectionButton(for: host.id)
                    }
                }
                .padding(.vertical, Spacing.sm)
            }

            // Attendees section
            if !attendees.isEmpty {
                attendeesSection
            }

            // Leave Feedback button (only for past events where user was going)
            if eventHasEnded && userRsvpStatus == "going" {
                Divider()
                    .padding(.vertical, Spacing.sm)

                Button(action: { showFeedbackSheet = true }) {
                    HStack(spacing: Spacing.sm) {
                        Image(systemName: "star.bubble")
                            .font(.system(size: 16))
                        Text("Leave Feedback")
                            .font(.bodyLargeMedium)
                    }
                    .foregroundColor(.appPrimary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, Spacing.md)
                    .background(Color.appSurfaceSecondary)
                    .cornerRadius(Radius.lg)
                }
                .buttonStyle(.plain)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, Spacing.lg)
        .padding(.top, Spacing.xxxl)
        .background(
            Color.appSurface
                .clipShape(
                    UnevenRoundedRectangle(
                        topLeadingRadius: 24,
                        bottomLeadingRadius: 0,
                        bottomTrailingRadius: 0,
                        topTrailingRadius: 24
                    )
                )
        )
        .offset(y: -24)
    }

    // MARK: - Attendees Section

    private var attendeesSection: some View {
        Group {
            Divider()
                .padding(.vertical, Spacing.sm)

            Text("Attendees")
                .font(.bodyLargeBold)
                .foregroundColor(.appPrimary)

            let displayAttendees = attendees.filter { $0.id != currentUser.userId }.prefix(5)

            ForEach(Array(displayAttendees), id: \.id) { attendee in
                AttendeeRow(
                    attendee: attendee,
                    connectionState: connectionState(for: attendee.id),
                    onProfileTap: { openProfile(id: attendee.id) },
                    onConnectTap: { connectWith(attendee.id) }
                )
                .padding(.vertical, Spacing.xxs)
            }

            if attendees.count > 1 {
                Button(action: { showAttendeesList = true }) {
                    Text("View all attendees")
                        .font(.bodyMedium)
                        .foregroundColor(.appSecondary)
                }
                .buttonStyle(.plain)
                .padding(.top, Spacing.xxs)
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

    private var formattedDateRange: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, h:mm"
        var result = formatter.string(from: event.dateValue)

        if let endDate = event.endDateValue {
            let endFormatter = DateFormatter()
            endFormatter.dateFormat = "-h:mma"
            result += endFormatter.string(from: endDate)
        } else {
            let ampm = DateFormatter()
            ampm.dateFormat = "a"
            result += ampm.string(from: event.dateValue)
        }

        return result
    }

    private var formattedDayAndTimezone: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE"
        let day = formatter.string(from: event.dateValue)

        let tz = TimeZone.current.abbreviation() ?? "CT"
        return "\(day) - \(tz)"
    }

    private func connectionState(for userId: String) -> AttendeeRow.AttendeeConnectionState {
        if connectedIds.contains(userId) { return .connected }
        if pendingConnectionIds.contains(userId) { return .pending }
        return .none
    }

    // MARK: - RSVP Button (floating pill)

    private var rsvpButton: some View {
        Button(action: {
            if userRsvpStatus == "going" {
                rsvp(status: "not_going")
            } else {
                rsvp(status: "going")
            }
        }) {
            HStack(spacing: Spacing.sm) {
                if userRsvpStatus == "going" {
                    Image(systemName: "checkmark")
                        .font(.system(size: 14, weight: .bold))
                    Text("Going")
                        .font(.bodyLargeSemibold)
                } else {
                    Image(systemName: "plus")
                        .font(.system(size: 14, weight: .bold))
                    Text("Join")
                        .font(.bodyLargeSemibold)
                }
            }
            .foregroundColor(.white)
            .padding(.horizontal, Spacing.xl)
            .padding(.vertical, Spacing.lg)
            .background(userRsvpStatus == "going" ? Color.appSuccess : Color.appPrimary)
            .clipShape(Capsule())
            .shadow(color: .black.opacity(0.15), radius: 8, x: 0, y: 4)
        }
        .disabled(isRsvping)
    }

    // MARK: - Connection Button (inline, used for host)

    @ViewBuilder
    private func connectionButton(for userId: String) -> some View {
        switch connectionState(for: userId) {
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
            Button(action: { connectWith(userId) }) {
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

    // MARK: - Data Loading

    private func loadUserRsvp() async {
        guard let userId = currentUser.userId else { return }

        convex.subscribeUserRsvp(eventId: event._id, userId: userId)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { _ in },
                receiveValue: { rsvp in
                    userRsvpStatus = rsvp?.status
                }
            )
            .store(in: &cancellables)
    }

    private func loadAttendees() async {
        convex.subscribeEventAttendees(eventId: event._id)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { _ in },
                receiveValue: { attendees in
                    self.attendees = attendees
                }
            )
            .store(in: &cancellables)
    }

    private func openProfile(id: String) {
        Task {
            do {
                if let user = try await convex.fetchUser(id: id) {
                    await MainActor.run {
                        selectedUserProfile = user
                    }
                }
            } catch {
                print("Failed to load profile: \(error)")
            }
        }
    }

    private func connectWith(_ userId: String) {
        guard let myId = currentUser.userId else { return }
        pendingConnectionIds.insert(userId)

        AnalyticsService.shared.track(.connectFromEvent(eventId: event._id, toUserId: userId))
        AnalyticsService.shared.track(.connectionSent(toUserId: userId, source: .eventAttendees))

        Task {
            do {
                _ = try await convex.sendConnectionRequest(requesterId: myId, accepterId: userId)
            } catch {
                print("Connection request failed: \(error)")
                await MainActor.run {
                    pendingConnectionIds.remove(userId)
                }
            }
        }
    }

    private func loadConnectionState() async {
        guard let userId = currentUser.userId else { return }
        do {
            let connections = try await convex.fetchConnections(userId: userId)
            connectedIds = Set(connections.map { $0._id })

            let pending = try await convex.fetchPendingSentIds(userId: userId)
            pendingConnectionIds = Set(pending)
        } catch {
            print("Failed to load connection state: \(error)")
        }
    }

    private func rsvp(status: String) {
        guard let userId = currentUser.userId else { return }
        isRsvping = true

        Task {
            do {
                _ = try await convex.rsvpToEvent(eventId: event._id, userId: userId, status: status)
                AnalyticsService.shared.track(.eventRsvp(eventId: event._id, status: status))
                await MainActor.run {
                    userRsvpStatus = status
                    isRsvping = false
                    onRsvp?(status)

                    if status == "going" {
                        showCalendarPrompt = true
                    }
                }
            } catch {
                print("RSVP failed: \(error)")
                await MainActor.run {
                    isRsvping = false
                }
            }
        }
    }

    private func addToCalendar() async {
        let store = EKEventStore()

        do {
            let granted = try await store.requestFullAccessToEvents()
            guard granted else { return }

            let calendarEvent = EKEvent(eventStore: store)
            calendarEvent.title = event.title
            calendarEvent.startDate = event.dateValue
            calendarEvent.endDate = event.endDateValue ?? event.dateValue.addingTimeInterval(3600)
            calendarEvent.location = event.fullAddress ?? event.location
            if let description = event.description {
                calendarEvent.notes = description
            }
            calendarEvent.calendar = store.defaultCalendarForNewEvents

            try store.save(calendarEvent, span: .thisEvent)

            AnalyticsService.shared.track(.eventCalendarAdded(eventId: event._id))

            // Track in Convex
            if let userId = currentUser.userId {
                try? await convex.markCalendarAdded(eventId: event._id, userId: userId)
            }

            await MainActor.run {
                showCalendarConfirmation = true
            }
        } catch {
            print("Calendar error: \(error)")
        }
    }

    private func openInMaps(address: String) {
        AnalyticsService.shared.track(.eventDirectionsOpened(eventId: event._id))
        let encoded = address.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        if let url = URL(string: "maps://?address=\(encoded)") {
            UIApplication.shared.open(url)
        }
    }
}

// MARK: - Preview

#Preview {
    EventDetailView(
        event: EventWithRsvpResponse(
            _id: "event_1",
            title: "JUNTO SPEED NETWORKING",
            description: "Meedont other users in quick 5-minute conversations. Rotate through and connect with founders, designers, and developers building cool stuff in Lincoln.\n\nExact location will be shared after you RSVP.",
            date: Date().addingTimeInterval(86400 * 3).timeIntervalSince1970 * 1000,
            endDate: Date().addingTimeInterval(86400 * 3 + 7200).timeIntervalSince1970 * 1000,
            location: "Lincoln, NE",
            fullAddress: "1234 Innovation Dr, Lincoln, NE 68508",
            type: "in_person",
            imageUrl: "https://images.unsplash.com/photo-1540575467063-178a50c2df87?w=800&h=600&fit=crop",
            createdBy: "mock_1",
            createdAt: Date().timeIntervalSince1970 * 1000,
            goingCount: 5,
            interestedCount: 3,
            host: EventWithRsvpResponse.EventHost(
                id: "mock_1",
                name: "Kenny Morales",
                avatarUrl: nil,
                headline: "Building FindU"
            ),
            attendeePreviews: [
                EventWithRsvpResponse.AttendeePreview(id: "mock_2", name: "Sarah Chen", avatarUrl: nil),
                EventWithRsvpResponse.AttendeePreview(id: "mock_3", name: "Marcus Williams", avatarUrl: nil),
                EventWithRsvpResponse.AttendeePreview(id: "mock_4", name: "Wilson Overfield", avatarUrl: nil)
            ]
        )
    )
    .environmentObject(CurrentUserManager.shared)
}
