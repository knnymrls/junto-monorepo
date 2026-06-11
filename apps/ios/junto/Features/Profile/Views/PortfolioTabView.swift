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
            if isSelf && !items.isEmpty {
                Button(action: { showAddSheet = true }) {
                    HStack(spacing: Spacing.xs) {
                        Image("action.add")
                            .renderingMode(.template)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 14, height: 14)
                        Text("Add Widget")
                            .font(.bodySemibold)
                    }
                    .foregroundColor(.appPrimary)
                    .frame(maxWidth: .infinity)
                    .frame(height: 42)
                    .background(Color.appSurfaceSecondary)
                    .clipShape(RoundedRectangle(cornerRadius: Radius.xl, style: .continuous))
                }
                .buttonStyle(.pressableScale(0.97))
                .padding(.horizontal, Spacing.lg)
                .padding(.bottom, Spacing.md)
            }

            if isLoading {
                ProgressView()
                    .tint(.appSecondary)
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
        VStack(spacing: Spacing.lg) {
            EmptyStateView(
                icon: "square.grid.2x2",
                title: "Showcase your work",
                subtitle: isSelf
                    ? "Add GitHub repos, images, links, or experiences."
                    : "No work added yet.",
                iconSize: 32
            )

            if isSelf {
                Button(action: { showAddSheet = true }) {
                    HStack(spacing: Spacing.xs) {
                        Image("action.add")
                            .renderingMode(.template)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 14, height: 14)
                        Text("Add Widget")
                            .font(.bodySemibold)
                    }
                    .foregroundColor(.appOnAccent)
                    .padding(.horizontal, Spacing.xxl)
                    .frame(height: 42)
                    .background(Color.appAccent)
                    .clipShape(RoundedRectangle(cornerRadius: Radius.xl, style: .continuous))
                }
                .buttonStyle(.pressableScale(0.97))
                .padding(.top, -Spacing.xl)
            }
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
