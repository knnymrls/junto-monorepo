//
//  EventsView.swift
//  mkrs-world
//
//  Main events list view
//

import SwiftUI
import Combine
import Clerk

enum EventsFilter: CaseIterable {
    case upcoming
    case past

    var title: String {
        switch self {
        case .upcoming: return "Upcoming"
        case .past: return "Past"
        }
    }
}

struct EventsView: View {
    @Environment(\.clerk) private var clerk
    @EnvironmentObject private var currentUser: CurrentUserManager
    @State private var events: [EventResponse] = []
    @State private var isLoading = true
    @State private var selectedEvent: EventWithRsvpResponse?
    @State private var showCreateEvent = false
    @State private var selectedFilter: EventsFilter = .upcoming
    @State private var cancellables = Set<AnyCancellable>()

    // Zoom transition namespace: event card → event detail
    @Namespace private var eventZoom

    private let convex = ConvexClientManager.shared

    // Hairline thickness for consistent 1px dividers
    private var hairline: CGFloat {
        1 / UIScreen.main.scale
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.appBackground.ignoresSafeArea()

                VStack(spacing: 0) {
                    filterTabs

                    if isLoading {
                        loadingState
                    } else if events.isEmpty {
                        emptyState
                    } else {
                        eventsList
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $showCreateEvent) {
                CreateEventSheet()
            }
            .onReceive(NotificationCenter.default.publisher(for: .composeFABTapped)) { notif in
                if notif.object as? String == Tab.discover.rawValue {
                    showCreateEvent = true
                }
            }
        }
        .fullScreenCover(item: $selectedEvent) { event in
            EventDetailView(event: event)
                .zoomDestination(id: event._id, in: eventZoom)
        }
        .task {
            loadEvents()
        }
        .onChange(of: selectedFilter) { _, _ in
            loadEvents()
        }
        .onAppear {
            AnalyticsService.shared.trackEventsSession()
        }
    }

    // MARK: - Filter Tabs

    private var filterTabs: some View {
        HStack(spacing: Spacing.sm) {
            ForEach(EventsFilter.allCases, id: \.self) { filter in
                let isSelected = filter == selectedFilter
                Button(action: { selectedFilter = filter }) {
                    Text(filter.title)
                        .font(isSelected ? .bodySemibold : .bodyMedium)
                        .foregroundColor(isSelected ? .appOnAccent : .appSecondary)
                        .padding(.horizontal, 13)
                        .frame(height: 32)
                        .background(isSelected ? Color.appPrimary : Color.appSurfaceSecondary)
                        .clipShape(RoundedRectangle(cornerRadius: Radius.xl))
                }
                .buttonStyle(.plain)
            }
            Spacer()
        }
        .padding(.horizontal, Spacing.lg)
        .padding(.vertical, Spacing.sm)
    }

    // MARK: - Events List

    private var eventsList: some View {
        ScrollView(showsIndicators: false) {
            LazyVStack(spacing: 0) {
                ForEach(events) { event in
                    Button(action: { selectEvent(event) }) {
                        EventCardView(
                            event: event,
                            isGoing: isUserGoing(event)
                        )
                    }
                    .buttonStyle(.plain)
                    .zoomSource(id: event._id, in: eventZoom)

                    if event.id != events.last?.id {
                        Rectangle()
                            .fill(Color.appDivider)
                            .frame(height: hairline)
                    }
                }

                // Bottom padding for tab bar
                Color.clear.frame(height: 80)
            }
            .padding(.top, Spacing.sm)
        }
        .refreshable {
            loadEvents()
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: Spacing.lg) {
            Image(systemName: "calendar.badge.plus")
                .font(.displayLarge)
                .foregroundColor(.appSecondary)

            Text(selectedFilter == .upcoming ? "No upcoming events" : "No past events")
                .font(.heading3)
                .foregroundColor(.appPrimary)

            Text("Check back soon for user meetups")
                .font(.body14)
                .foregroundColor(.appSecondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Loading State

    private var loadingState: some View {
        VStack(spacing: 0) {
            ForEach(0..<3, id: \.self) { i in
                HStack(spacing: Spacing.md) {
                    RoundedRectangle(cornerRadius: Radius.md)
                        .fill(Color.appSurfaceSecondary)
                        .frame(width: 80, height: 107)

                    VStack(alignment: .leading, spacing: Spacing.sm) {
                        RoundedRectangle(cornerRadius: Radius.xs)
                            .fill(Color.appSurfaceSecondary)
                            .frame(width: 100, height: 12)
                        RoundedRectangle(cornerRadius: Radius.xs)
                            .fill(Color.appSurfaceSecondary)
                            .frame(width: 160, height: 16)
                        RoundedRectangle(cornerRadius: Radius.xs)
                            .fill(Color.appSurfaceSecondary)
                            .frame(width: 120, height: 14)
                    }
                    Spacer()
                }
                .padding(.vertical, Spacing.lg)

                if i < 2 {
                    Rectangle()
                        .fill(Color.appDivider)
                        .frame(height: hairline)
                }
            }
        }
        .padding(.horizontal, Spacing.md)
        .padding(.top, Spacing.sm)
    }

    // MARK: - Helpers

    private func isUserGoing(_ event: EventResponse) -> Bool {
        guard let userId = currentUser.userId else { return false }
        return event.attendeePreviews?.contains(where: { $0.id == userId }) == true
    }

    // MARK: - Data Loading

    private func loadEvents() {
        cancellables.removeAll()

        let publisher = selectedFilter == .upcoming
            ? convex.subscribeUpcomingEvents()
            : convex.subscribePastEvents()

        publisher
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        print("Events subscription error: \(error)")
                    }
                },
                receiveValue: { events in
                    self.events = events
                    self.isLoading = false
                }
            )
            .store(in: &cancellables)
    }

    private func selectEvent(_ event: EventResponse) {
        Task {
            do {
                // Pass userId so the detail view opens with the correct RSVP state.
                selectedEvent = try await convex.fetchEvent(id: event._id, userId: currentUser.userId)
            } catch {
                print("Failed to fetch event: \(error)")
            }
        }
    }
}

#Preview {
    EventsView()
        .environmentObject(CurrentUserManager.shared)
}
