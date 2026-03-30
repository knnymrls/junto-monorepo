//
//  EventsView.swift
//  mkrs-world
//
//  Main events list view
//

import SwiftUI
import Combine
import Clerk

struct EventsView: View {
    @Environment(\.clerk) private var clerk
    @EnvironmentObject private var currentUser: CurrentUserManager
    @State private var events: [EventResponse] = []
    @State private var isLoading = true
    @State private var selectedEvent: EventWithRsvpResponse?
    @State private var showCreateEvent = false
    @State private var cancellables = Set<AnyCancellable>()

    private let convex = ConvexClientManager.shared

    // Hairline thickness for consistent 1px dividers
    private var hairline: CGFloat {
        1 / UIScreen.main.scale
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.appBackground.ignoresSafeArea()

                if isLoading {
                    loadingState
                } else if events.isEmpty {
                    emptyState
                } else {
                    eventsList
                }
            }
            .navigationBarHidden(true)
            .overlay(alignment: .bottomTrailing) {
                Button {
                    showCreateEvent = true
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(width: 52, height: 52)
                        .background(Color.appAccent)
                        .clipShape(Circle())
                        .shadow(color: .black.opacity(0.2), radius: 8, y: 4)
                }
                .padding(.trailing, Spacing.xxl)
                .padding(.bottom, Spacing.xxl)
            }
            .sheet(isPresented: $showCreateEvent) {
                CreateEventSheet()
            }
        }
        .sheet(item: $selectedEvent) { event in
            EventDetailView(event: event)
                .presentationDragIndicator(.visible)
        }
        .task {
            loadEvents()
        }
        .onAppear {
            AnalyticsService.shared.trackEventsSession()
        }
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

                    if event.id != events.last?.id {
                        Rectangle()
                            .fill(Color.appDivider)
                            .frame(height: hairline)
                    }
                }

                // Bottom padding for tab bar
                Color.clear.frame(height: 80)
            }
            .padding(.horizontal, Spacing.md)
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

            Text("No upcoming events")
                .font(.heading3)
                .foregroundColor(.appPrimary)

            Text("Check back soon for user meetups")
                .font(.body14)
                .foregroundColor(.appSecondary)
        }
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
        convex.subscribeUpcomingEvents()
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
                let fullEvent = try await fetchFullEvent(id: event._id)
                await MainActor.run {
                    selectedEvent = fullEvent
                }
            } catch {
                print("Failed to fetch event: \(error)")
            }
        }
    }

    private func fetchFullEvent(id: String) async throws -> EventWithRsvpResponse? {
        try await withCheckedThrowingContinuation { continuation in
            var cancellable: AnyCancellable?
            cancellable = convex.subscribeEvent(id: id)
                .first()
                .sink(
                    receiveCompletion: { completion in
                        if case .failure(let error) = completion {
                            continuation.resume(throwing: error)
                        }
                        cancellable?.cancel()
                    },
                    receiveValue: { event in
                        continuation.resume(returning: event)
                    }
                )
        }
    }
}

#Preview {
    EventsView()
        .environmentObject(CurrentUserManager.shared)
}
