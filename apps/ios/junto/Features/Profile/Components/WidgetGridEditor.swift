//
//  WidgetGridEditor.swift
//  mkrs-world
//
//  Drag-and-drop grid editor for portfolio widgets.
//

import SwiftUI

struct WidgetGridEditor: View {
    @Binding var items: [PortfolioItemResponse]
    @State private var draggingItem: PortfolioItemResponse?

    var body: some View {
        ScrollView {
            WidgetGridLayout(spacing: Spacing.md) {
                ForEach(items) { item in
                    widgetCard(item)
                        .widgetSize(item.effectiveSize.toWidgetSize)
                        .opacity(draggingItem?.id == item.id ? 0.4 : 1.0)
                        .onDrag {
                            draggingItem = item
                            return NSItemProvider(object: item.id as NSString)
                        }
                        .onDrop(
                            of: [.text],
                            delegate: WidgetDropDelegate(
                                item: item,
                                items: $items,
                                draggingItem: $draggingItem
                            )
                        )
                }
            }
            .padding(.horizontal, Spacing.lg)
            .padding(.top, Spacing.md)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: items.map(\.id))
        }
    }

    // MARK: - Widget Card Router

    @ViewBuilder
    private func widgetCard(_ item: PortfolioItemResponse) -> some View {
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
}

// MARK: - Size Conversion

extension PortfolioItemResponse.PortfolioSize {
    var toWidgetSize: WidgetSize {
        switch self {
        case .small: return .small
        case .medium: return .medium
        case .large: return .large
        }
    }
}
