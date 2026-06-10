//
//  AttendeesListView.swift
//  mkrs-world
//
//  Attendees list sheet with connection state and connect actions
//

import SwiftUI
import Combine

struct AttendeesListView: View {
    let event: EventWithRsvpResponse
    let userRsvpStatus: String?

    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var currentUser: CurrentUserManager
    @State private var attendees: [EventAttendee] = []
    @State private var connectedIds: Set<String> = []
    @State private var pendingConnectionIds: Set<String> = []
    @State private var selectedUserProfile: UserResponse?
    @State private var cancellables = Set<AnyCancellable>()

    // Zoom transition namespace: attendee avatar → profile
    @Namespace private var profileZoom

    private let convex = ConvexClientManager.shared

    private var eventHasEnded: Bool {
        let endTime = event.endDateValue ?? event.dateValue.addingTimeInterval(2 * 3600)
        return endTime < Date()
    }

    private var canViewAttendees: Bool {
        userRsvpStatus == "going" || eventHasEnded
    }

    var body: some View {
        NavigationStack {
            Group {
                if canViewAttendees {
                    attendeesList
                } else {
                    lockedState
                }
            }
            .background(Color.appBackground)
            .navigationTitle("Attendees")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundColor(.appPrimary)
                }
            }
        }
        .fullScreenCover(item: $selectedUserProfile) { user in
            ProfileView(user: user)
                .zoomDestination(id: user._id, in: profileZoom)
        }
        .task {
            let timing = eventHasEnded ? "post_event" : "pre_event"
            AnalyticsService.shared.track(.attendeesListViewed(eventId: event._id, timing: timing))
            await loadData()
        }
        .onReceive(NotificationCenter.default.publisher(for: .connectionStatusChanged)) { note in
            guard let change = ConnectionEvents.decode(note) else { return }
            applyConnectionChange(userId: change.userId, status: change.status)
        }
    }

    /// Apply an externally-broadcast connection change to the cached sets
    /// (e.g. when the user connects from a profile sheet opened from this list).
    private func applyConnectionChange(userId: String, status: ConnectionStatus) {
        switch status {
        case .connected:
            pendingConnectionIds.remove(userId)
            connectedIds.insert(userId)
        case .pendingSent:
            connectedIds.remove(userId)
            pendingConnectionIds.insert(userId)
        case .pendingReceived:
            break
        case .none:
            connectedIds.remove(userId)
            pendingConnectionIds.remove(userId)
        }
    }

    // MARK: - Attendees List

    private var attendeesList: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(filteredAttendees) { attendee in
                    AttendeeRow(
                        attendee: attendee,
                        connectionState: connectionState(for: attendee.id),
                        eventTitle: event.title,
                        eventHasEnded: eventHasEnded,
                        onProfileTap: { openProfile(id: attendee.id) },
                        onConnectTap: { connectWith(attendee) },
                        profileZoomID: AnyHashable(attendee.id),
                        profileZoomNamespace: profileZoom
                    )
                    .padding(.horizontal, Spacing.lg)
                    .padding(.vertical, Spacing.xs)

                    if attendee.id != filteredAttendees.last?.id {
                        Divider()
                            .padding(.leading, 68)
                    }
                }
            }
            .padding(.top, Spacing.sm)
        }
    }

    private var filteredAttendees: [EventAttendee] {
        guard let myId = currentUser.userId else { return attendees }
        return attendees.filter { $0.id != myId }
    }

    private func connectionState(for id: String) -> AttendeeRow.AttendeeConnectionState {
        if connectedIds.contains(id) { return .connected }
        if pendingConnectionIds.contains(id) { return .pending }
        return .none
    }

    // MARK: - Locked State

    private var lockedState: some View {
        VStack(spacing: Spacing.lg) {
            Image(systemName: "lock.fill")
                .font(.system(size: 40))
                .foregroundColor(.appSecondary)

            Text("RSVP to see attendees")
                .font(.heading3)
                .foregroundColor(.appPrimary)

            Text("Join this event to see who else is going")
                .font(.body14)
                .foregroundColor(.appSecondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Data Loading

    private func loadData() async {
        guard let userId = currentUser.userId else { return }

        convex.subscribeEventAttendees(eventId: event._id)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { _ in },
                receiveValue: { self.attendees = $0 }
            )
            .store(in: &cancellables)

        do {
            let connections = try await convex.fetchConnections(userId: userId)
            connectedIds = Set(connections.map { $0._id })

            let pending = try await convex.fetchPendingSentIds(userId: userId)
            pendingConnectionIds = Set(pending)
        } catch {
            print("Failed to load connection state: \(error)")
        }
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

    private func connectWith(_ attendee: EventAttendee) {
        guard let userId = currentUser.userId else { return }

        // Optimistic update
        pendingConnectionIds.insert(attendee.id)

        AnalyticsService.shared.track(.connectFromEvent(eventId: event._id, toUserId: attendee.id))
        AnalyticsService.shared.track(.connectionSent(toUserId: attendee.id, source: .eventAttendees))

        Task {
            do {
                _ = try await convex.sendConnectionRequest(requesterId: userId, accepterId: attendee.id)
                ConnectionEvents.post(userId: attendee.id, status: .pendingSent)
            } catch {
                print("Connection request failed: \(error)")
                await MainActor.run {
                    pendingConnectionIds.remove(attendee.id)
                }
            }
        }
    }
}
