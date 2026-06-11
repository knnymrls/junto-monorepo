//
//  DiscoverView.swift
//  junto
//
//  Discover landing page. Owns the Discover tab's NavigationStack: the brand
//  top nav ("Discover" + search) sits at the root, and the section headers
//  push the Events / People lists in from the right (native swipe-back). The
//  scrolling content is a curated "Upcoming Events" strip, a "Browse By
//  Category" chip grid, and a "People you should know" list.
//  Matches the Discover artboard (Paper 7E1-0).
//

import SwiftUI
import Combine

struct DiscoverView: View {
    @EnvironmentObject private var currentUser: CurrentUserManager
    @Environment(\.tabBarVisible) private var tabBarVisible

    /// Avatar tap is owned by TabBarView (→ my profile). The header search
    /// pushes the maker search page onto this stack.
    var onAvatarTap: () -> Void = {}
    var profileZoomNamespace: Namespace.ID? = nil

    @StateObject private var viewModel = SearchViewModel()

    @State private var events: [EventResponse] = []
    @State private var eventsLoaded = false
    @State private var myEvents: [EventResponse] = []
    @State private var selectedEvent: EventWithRsvpResponse?
    @State private var selectedUserProfile: UserResponse?
    @State private var showCreateEvent = false
    @State private var path: [DiscoverRoute] = []
    @State private var cancellables = Set<AnyCancellable>()

    @Namespace private var eventZoom
    @Namespace private var profileZoom

    private let convex = ConvexClientManager.shared

    private var people: [UserResponse] { viewModel.liveResults }

    /// Drill-in destinations pushed onto the Discover stack.
    enum DiscoverRoute: Hashable { case events, people, search, category(SkillCategory) }

    /// Split the categories into two even rows so the chips pack cleanly across
    /// a two-line horizontal scroll.
    private var categoryRows: [[SkillCategory]] {
        let all = SkillCategory.allCases
        let mid = (all.count + 1) / 2
        return [Array(all[..<mid]), Array(all[mid...])]
    }

    var body: some View {
        NavigationStack(path: $path) {
            VStack(spacing: 0) {
                BrandTopNav(
                    avatarUrl: currentUser.user?.avatarUrl,
                    name: currentUser.user?.name ?? "?",
                    center: .title("Discover"),
                    onAvatarTap: onAvatarTap,
                    trailingIcon: .navSearch,
                    onTrailingTap: { path.append(.search) },
                    profileZoomID: currentUser.user.map { AnyHashable($0._id) },
                    profileZoomNamespace: profileZoomNamespace
                )

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: Spacing.xxl) {
                        if !myEvents.isEmpty {
                            yourEventsSection
                        }
                        upcomingEventsSection
                        browseByCategorySection
                        peopleSection

                        Color.clear.frame(height: 96) // clear the tab bar + FAB
                    }
                    .padding(.top, Spacing.lg)
                }
                .scrollEdgeFade(top: true, bottom: false)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.appBackground)
            .toolbar(.hidden, for: .navigationBar)
            .navigationDestination(for: DiscoverRoute.self) { route in
                switch route {
                case .events:
                    EventsListView()
                        .environmentObject(currentUser)
                        .toolbar(.hidden, for: .navigationBar)
                        .navigationBarBackButtonHidden(true)
                case .people:
                    PeopleListView(onSearchTap: { path.append(.search) })
                        .environmentObject(currentUser)
                        .toolbar(.hidden, for: .navigationBar)
                        .navigationBarBackButtonHidden(true)
                case .search:
                    MakerSearchView()
                        .environmentObject(currentUser)
                        .toolbar(.hidden, for: .navigationBar)
                        .navigationBarBackButtonHidden(true)
                case .category(let category):
                    PeopleListView(onSearchTap: { path.append(.search) }, category: category)
                        .environmentObject(currentUser)
                        .toolbar(.hidden, for: .navigationBar)
                        .navigationBarBackButtonHidden(true)
                }
            }
        }
        .fullScreenCover(item: $selectedEvent) { event in
            EventDetailView(event: event)
                .zoomDestination(id: event._id, in: eventZoom)
        }
        .fullScreenCover(item: $selectedUserProfile) { user in
            ProfileView(user: user)
                .zoomDestination(id: user._id, in: profileZoom)
        }
        .sheet(isPresented: $showCreateEvent) {
            CreateEventSheet()
        }
        .onReceive(NotificationCenter.default.publisher(for: .composeFABTapped)) { notif in
            if notif.object as? String == Tab.discover.rawValue {
                showCreateEvent = true
            }
        }
        // Hide the tab bar + FAB whenever a drill-in page is on the stack.
        .onChange(of: path) { _, newPath in
            tabBarVisible.wrappedValue = newPath.isEmpty
        }
        .task {
            if let userId = currentUser.userId {
                viewModel.currentUserId = userId
                viewModel.startListening()
                viewModel.loadDefaultUsers()
                await viewModel.loadConnections(userId: userId)
            }
            loadEvents()
            loadMyEvents()
        }
    }

    // MARK: - Your Events (events the user RSVP'd to)

    private var yourEventsSection: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            SectionHeader(title: "Your Events")

            VStack(spacing: 0) {
                ForEach(myEvents.prefix(3)) { event in
                    DiscoverEventCard(
                        event: event,
                        onCardTap: { selectEvent(event) },
                        goingBadge: true
                    )
                }
            }
        }
    }

    // MARK: - Upcoming Events

    private var upcomingEventsSection: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            SectionHeader(title: "Upcoming Events", showsChevron: true) {
                path.append(.events)
            }

            if !eventsLoaded {
                VStack(spacing: 0) {
                    ForEach(0..<2, id: \.self) { _ in DiscoverEventCardSkeleton() }
                }
            } else if events.isEmpty {
                sectionPlaceholder(text: "No upcoming events yet")
            } else {
                VStack(spacing: 0) {
                    ForEach(events.prefix(3)) { event in
                        DiscoverEventCard(
                            event: event,
                            onCardTap: { selectEvent(event) }
                        )
                        .zoomSource(id: event._id, in: eventZoom)
                    }
                }
            }
        }
    }

    // MARK: - Browse By Category

    private var browseByCategorySection: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            SectionHeader(title: "Browse By Category")

            // Two clean, packed rows that scroll horizontally together.
            ScrollView(.horizontal, showsIndicators: false) {
                VStack(alignment: .leading, spacing: Spacing.sm) {
                    ForEach(categoryRows, id: \.self) { row in
                        HStack(spacing: Spacing.sm) {
                            ForEach(row, id: \.self) { category in
                                CategoryChip(category: category) {
                                    path.append(.category(category))
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal, Spacing.lg)
            }
        }
    }

    // MARK: - People You Should Know

    private var peopleSection: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            SectionHeader(title: "People you should know", showsChevron: true) {
                path.append(.people)
            }

            if !viewModel.hasLoadedDefaults {
                VStack(spacing: 0) {
                    ForEach(0..<3, id: \.self) { _ in DiscoverPersonCardSkeleton() }
                }
            } else if people.isEmpty {
                sectionPlaceholder(text: "No makers yet")
            } else {
                VStack(spacing: 0) {
                    ForEach(people.prefix(3)) { user in
                        DiscoverPersonCard(
                            user: user,
                            connectionStatus: viewModel.connectionStatus(forUserId: user._id),
                            isSelf: user._id == currentUser.userId,
                            onTap: { selectedUserProfile = user },
                            onConnect: {
                                Task {
                                    AnalyticsService.shared.track(.connectFromSearch(toUserId: user._id))
                                    _ = await viewModel.sendConnectionRequest(toUserId: user._id)
                                }
                            },
                            profileZoomID: AnyHashable(user._id),
                            profileZoomNamespace: profileZoom
                        )
                        .zoomSource(id: user._id, in: profileZoom)
                    }
                }
            }
        }
    }

    private func sectionPlaceholder(text: String) -> some View {
        Text(text)
            .font(.body14)
            .foregroundColor(.appSecondary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, Spacing.lg)
            .padding(.vertical, Spacing.xl)
    }

    // MARK: - Data

    private func loadEvents() {
        convex.subscribeUpcomingEvents()
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { _ in },
                receiveValue: { events in
                    self.events = events
                    self.eventsLoaded = true
                }
            )
            .store(in: &cancellables)
    }

    private func loadMyEvents() {
        guard let userId = currentUser.userId else { return }
        convex.subscribeGoingUpcomingEvents(userId: userId)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { _ in },
                receiveValue: { events in self.myEvents = events }
            )
            .store(in: &cancellables)
    }

    private func selectEvent(_ event: EventResponse) {
        Task {
            do {
                if let full = try await convex.fetchEvent(id: event._id, userId: currentUser.userId) {
                    selectedEvent = full
                }
            } catch {
                print("Failed to fetch event: \(error)")
            }
        }
    }
}


