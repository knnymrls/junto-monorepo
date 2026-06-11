//
//  PortfolioTabView.swift
//  junto
//
//  Work tab — the maker's portfolio widget grid, plus vocation-aware
//  starter ideas: suggestion cards keyed to the person's major (business
//  majors get pitch decks and case comps, engineers get repos and builds…)
//  that deep-link into the add-item form with the right type preselected.
//

import SwiftUI
import Combine

struct PortfolioTabView: View {
    let userId: String
    let isSelf: Bool
    /// Vocation bucket derived from the user's major — drives the starter ideas.
    var vocation: SkillCategory? = nil

    @State private var items: [PortfolioItemResponse] = []
    @State private var isLoading = true
    @State private var showAddSheet = false
    @State private var activeSuggestion: VocationSuggestion?
    @State private var cancellable: AnyCancellable?

    var body: some View {
        VStack(spacing: 0) {
            if isLoading {
                ProgressView()
                    .tint(.appSecondary)
                    .padding(.top, Spacing.huge)
            } else {
                if !items.isEmpty {
                    WidgetGridLayout(spacing: Spacing.md) {
                        ForEach(items) { item in
                            portfolioCard(item)
                                .widgetSize(item.effectiveSize.toWidgetSize)
                                .contextMenu {
                                    if isSelf {
                                        Button(role: .destructive) {
                                            deleteItem(item)
                                        } label: {
                                            Label("Delete", systemImage: "trash")
                                        }
                                    }
                                }
                        }
                    }
                    .padding(.horizontal, Spacing.lg)
                } else if !isSelf {
                    EmptyStateView(
                        icon: "square.grid.2x2",
                        title: "No work yet",
                        subtitle: "This maker hasn't showcased anything.",
                        iconSize: 32
                    )
                }

                if isSelf {
                    suggestionsSection
                        .padding(.top, items.isEmpty ? 0 : Spacing.xl)
                }
            }
        }
        .padding(.bottom, Spacing.xxxl)
        .sheet(isPresented: $showAddSheet) {
            AddPortfolioItemSheet(userId: userId)
        }
        .sheet(item: $activeSuggestion) { suggestion in
            AddPortfolioItemSheet(
                userId: userId,
                initialType: suggestion.type,
                suggestedTitle: suggestion.prefillTitle
            )
        }
        .onAppear { startSubscription() }
        .onDisappear { cancellable?.cancel() }
    }

    // MARK: - Widget Card Router

    @ViewBuilder
    private func portfolioCard(_ item: PortfolioItemResponse) -> some View {
        switch item.portfolioType {
        case .github:
            GitHubRepoCard(item: item)
        case .gallery:
            ImageGalleryCard(item: item)
        case .link:
            LinkCard(item: item)
        case .experience:
            ExperienceCard(item: item)
        }
    }

    // MARK: - Vocation Suggestions

    private var suggestionsSection: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text(items.isEmpty ? "Build your portfolio".uppercased() : "Ideas for you".uppercased())
                .font(.captionSmallSemibold)
                .foregroundColor(.appSecondary)
                .padding(.horizontal, Spacing.lg)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: Spacing.sm) {
                    ForEach(suggestions) { suggestion in
                        suggestionCard(suggestion)
                    }

                    // Free-form fallback — the full type picker.
                    Button(action: { showAddSheet = true }) {
                        VStack(alignment: .leading, spacing: Spacing.sm) {
                            Image("action.add")
                                .renderingMode(.template)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 16, height: 16)
                                .foregroundColor(.appPrimary)
                                .frame(width: 32, height: 32)
                                .background(Color.appSurfaceSecondary)
                                .clipShape(Circle())

                            Text("Something else")
                                .font(.bodySemibold)
                                .foregroundColor(.appPrimary)

                            Text("Repos, photos, links, roles")
                                .font(.caption12)
                                .foregroundColor(.appSecondary)
                                .lineLimit(2)
                        }
                        .frame(width: 150, alignment: .leading)
                        .padding(Spacing.md)
                        .background(Color.appSurface)
                        .clipShape(RoundedRectangle(cornerRadius: Radius.xxl, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: Radius.xxl, style: .continuous)
                                .strokeBorder(Color.appBorder, lineWidth: 1)
                        )
                        .contentShape(RoundedRectangle(cornerRadius: Radius.xxl, style: .continuous))
                    }
                    .buttonStyle(.pressableScale(0.97))
                }
                .padding(.horizontal, Spacing.lg)
            }
        }
    }

    private func suggestionCard(_ suggestion: VocationSuggestion) -> some View {
        Button(action: { activeSuggestion = suggestion }) {
            VStack(alignment: .leading, spacing: Spacing.sm) {
                Image(suggestion.icon)
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 16, height: 16)
                    .foregroundColor(.appPrimary)
                    .frame(width: 32, height: 32)
                    .background(Color.appSurfaceSecondary)
                    .clipShape(Circle())

                Text(suggestion.title)
                    .font(.bodySemibold)
                    .foregroundColor(.appPrimary)
                    .lineLimit(1)

                Text(suggestion.subtitle)
                    .font(.caption12)
                    .foregroundColor(.appSecondary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
            }
            .frame(width: 150, alignment: .leading)
            .padding(Spacing.md)
            .background(Color.appSurface)
            .clipShape(RoundedRectangle(cornerRadius: Radius.xxl, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: Radius.xxl, style: .continuous)
                    .strokeBorder(Color.appBorder, lineWidth: 1)
            )
            .contentShape(RoundedRectangle(cornerRadius: Radius.xxl, style: .continuous))
        }
        .buttonStyle(.pressableScale(0.97))
    }

    /// Starter ideas keyed to the maker's vocation.
    private var suggestions: [VocationSuggestion] {
        switch vocation {
        case .software, .ai, .data:
            return [
                VocationSuggestion(icon: "topic.code", title: "GitHub", subtitle: "Pull in your repos", type: .github),
                VocationSuggestion(icon: "content.update", title: "Side project", subtitle: "Shipped something? Link it", type: .link, prefillTitle: "Side project"),
                VocationSuggestion(icon: "action.image", title: "Hackathon build", subtitle: "Screenshots of the demo", type: .gallery, prefillTitle: "Hackathon build"),
            ]
        case .design, .content:
            return [
                VocationSuggestion(icon: "topic.design", title: "Case study", subtitle: "Show the work, not just links", type: .gallery, prefillTitle: "Case study"),
                VocationSuggestion(icon: "action.arrow", title: "Portfolio site", subtitle: "Behance, Dribbble, your own", type: .link, prefillTitle: "Portfolio"),
                VocationSuggestion(icon: "feed.opportunity", title: "Client work", subtitle: "Freelance or org projects", type: .experience, prefillTitle: "Client work"),
            ]
        case .business, .finance, .marketing, .leadership, .impact:
            return [
                VocationSuggestion(icon: "topic.business", title: "Pitch deck", subtitle: "Link the deck you pitched", type: .link, prefillTitle: "Pitch deck"),
                VocationSuggestion(icon: "feed.opportunity", title: "Venture", subtitle: "Startups, internships, roles", type: .experience),
                VocationSuggestion(icon: "topic.analytics", title: "Case competition", subtitle: "Slides and results", type: .gallery, prefillTitle: "Case competition"),
            ]
        case .science, .health, .hardware:
            return [
                VocationSuggestion(icon: "topic.sciences", title: "Research", subtitle: "Lab work and projects", type: .experience, prefillTitle: "Research project"),
                VocationSuggestion(icon: "action.image", title: "Build photos", subtitle: "Prototypes, posters, labs", type: .gallery),
                VocationSuggestion(icon: "action.arrow", title: "Publication", subtitle: "Papers and posters", type: .link, prefillTitle: "Publication"),
            ]
        default:
            return [
                VocationSuggestion(icon: "action.arrow", title: "Project link", subtitle: "Anything you've made", type: .link),
                VocationSuggestion(icon: "feed.opportunity", title: "Experience", subtitle: "Jobs, clubs, programs", type: .experience),
                VocationSuggestion(icon: "action.image", title: "Photo gallery", subtitle: "Show what you work on", type: .gallery),
            ]
        }
    }

    // MARK: - Subscription

    private func startSubscription() {
        cancellable = ConvexClientManager.shared.subscribePortfolioItems(userId: userId)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        print("PortfolioTabView: subscription error: \(error)")
                        isLoading = false
                    }
                },
                receiveValue: { newItems in
                    items = newItems
                    isLoading = false
                }
            )
    }

    private func deleteItem(_ item: PortfolioItemResponse) {
        Task {
            do {
                try await ConvexClientManager.shared.deletePortfolioItem(id: item._id)
            } catch {
                print("PortfolioTabView: delete error: \(error)")
            }
        }
    }
}

// MARK: - Vocation Suggestion

struct VocationSuggestion: Identifiable {
    var id: String { title }
    let icon: String
    let title: String
    let subtitle: String
    let type: PortfolioItemResponse.PortfolioType
    var prefillTitle: String? = nil
}
