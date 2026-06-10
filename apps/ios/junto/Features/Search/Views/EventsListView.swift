//
//  EventsListView.swift
//  junto
//
//  Discover's "Upcoming Events" drill-in: a back button + Upcoming/Past
//  segmented control + filter, over a list of compact event cards.
//  Matches the Discover events artboard (Paper 7OI-0).
//

import SwiftUI
import Combine

struct EventsListView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var currentUser: CurrentUserManager

    @State private var events: [EventResponse] = []
    @State private var isLoading = true
    @State private var selectedFilter: EventsFilter = .upcoming
    @State private var selectedEvent: EventWithRsvpResponse?
    @State private var cancellables = Set<AnyCancellable>()

    @Namespace private var eventZoom

    private let convex = ConvexClientManager.shared

    var body: some View {
        VStack(spacing: 0) {
            DiscoverListTopBar(onBack: { dismiss() }, onFilter: {}) {
                DiscoverSegmentedControl(
                    options: EventsFilter.allCases,
                    title: { $0.title },
                    selection: $selectedFilter
                )
            }

            if isLoading {
                ScrollView(showsIndicators: false) {
                    LazyVStack(spacing: 0) {
                        ForEach(0..<6, id: \.self) { _ in DiscoverEventCardSkeleton() }
                    }
                    .padding(.top, Spacing.sm)
                }
                .scrollEdgeFade(top: true, bottom: false)
            } else if events.isEmpty {
                emptyState
            } else {
                ScrollView(showsIndicators: false) {
                    LazyVStack(spacing: 0) {
                        ForEach(events) { event in
                            DiscoverEventCard(
                                event: event,
                                onCardTap: { selectEvent(event) }
                            )
                            .zoomSource(id: event._id, in: eventZoom)
                        }
                        Color.clear.frame(height: 32)
                    }
                    .padding(.top, Spacing.sm)
                }
                .refreshable { loadEvents() }
                .scrollEdgeFade(top: true, bottom: false)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.appBackground)
        .fullScreenCover(item: $selectedEvent) { event in
            EventDetailView(event: event)
                .zoomDestination(id: event._id, in: eventZoom)
        }
        .task { loadEvents() }
        .onChange(of: selectedFilter) { _, _ in loadEvents() }
    }

    private var emptyState: some View {
        VStack(spacing: Spacing.md) {
            Spacer()
            Image(systemName: "calendar.badge.plus")
                .font(.system(size: 40))
                .foregroundColor(.appSecondary)
            Text(selectedFilter == .upcoming ? "No upcoming events" : "No past events")
                .font(.heading3)
                .foregroundColor(.appPrimary)
            Text("Check back soon for meetups")
                .font(.body14)
                .foregroundColor(.appSecondary)
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Data

    private func loadEvents() {
        cancellables.removeAll()
        let publisher = selectedFilter == .upcoming
            ? convex.subscribeUpcomingEvents()
            : convex.subscribePastEvents()
        publisher
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { _ in },
                receiveValue: { events in
                    self.events = events
                    self.isLoading = false
                }
            )
            .store(in: &cancellables)
    }

    private func selectEvent(_ event: EventResponse) {
        Task {
            var cancellable: AnyCancellable?
            cancellable = convex.subscribeEvent(id: event._id, userId: currentUser.userId)
                .first()
                .receive(on: DispatchQueue.main)
                .sink(
                    receiveCompletion: { _ in cancellable?.cancel() },
                    receiveValue: { full in selectedEvent = full }
                )
        }
    }
}
