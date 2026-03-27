//
//  PortfolioTabView.swift
//  mkrs-world
//
//  Portfolio tab — list of portfolio widgets with add/delete
//

import SwiftUI
import Combine

struct PortfolioTabView: View {
    let userId: String
    let isSelf: Bool
    @State private var items: [PortfolioItemResponse] = []
    @State private var isLoading = true
    @State private var showAddSheet = false
    @State private var cancellable: AnyCancellable?

    var body: some View {
        VStack(spacing: 0) {
            if isSelf {
                Button(action: { showAddSheet = true }) {
                    HStack(spacing: Spacing.xs) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 16))
                        Text("Add to Portfolio")
                            .font(.bodyMedium)
                    }
                    .foregroundColor(.appPrimary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, Spacing.xs + Spacing.xxs)
                    .overlay(
                        RoundedRectangle(cornerRadius: Radius.md)
                            .stroke(Color.appDivider, lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)
                .padding(.horizontal, Spacing.lg)
                .padding(.bottom, Spacing.md)
            }

            if isLoading {
                ProgressView()
                    .padding(.top, Spacing.huge)
            } else if items.isEmpty {
                emptyState
            } else {
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
            }
        }
        .padding(.bottom, Spacing.xxxl)
        .sheet(isPresented: $showAddSheet) {
            AddPortfolioItemSheet(userId: userId)
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

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: Spacing.md) {
            Image(systemName: "square.grid.2x2")
                .font(.system(size: 32))
                .foregroundColor(.appSecondary)

            Text("Showcase your work")
                .font(.bodyLargeMedium)
                .foregroundColor(.appSecondary)

            if isSelf {
                VStack(spacing: Spacing.xxs) {
                    Text("Add GitHub repos, images, links, or experiences")
                        .font(.body14)
                        .foregroundColor(.appSecondary)
                }
            } else {
                Text("No portfolio items yet.")
                    .font(.body14)
                    .foregroundColor(.appSecondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Spacing.huge)
    }

    // MARK: - Subscription

    private func startSubscription() {
        cancellable = ConvexClientManager.shared.subscribePortfolioItems(userId: userId)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        print("PortfolioTabView: subscription error: \(error)")
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
