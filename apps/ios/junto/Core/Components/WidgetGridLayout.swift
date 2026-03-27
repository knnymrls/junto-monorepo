//
//  WidgetGridLayout.swift
//  mkrs-world
//
//  2-column auto-flow grid for portfolio widgets.
//  Items flow left-to-right, top-to-bottom based on their size.
//  Small = 1 col (square), Medium = 2 cols (16:9), Large = 2 cols (tall)
//

import SwiftUI

struct WidgetGridLayout: Layout {
    var spacing: CGFloat = Spacing.md
    var columns: Int = 2

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let width = proposal.width ?? 300
        let placements = computePlacements(width: width, subviews: subviews)
        let maxY = placements.map { $0.origin.y + $0.size.height }.max() ?? 0
        return CGSize(width: width, height: maxY)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let placements = computePlacements(width: bounds.width, subviews: subviews)
        for (index, subview) in subviews.enumerated() {
            guard index < placements.count else { break }
            let placement = placements[index]
            subview.place(
                at: CGPoint(x: bounds.minX + placement.origin.x, y: bounds.minY + placement.origin.y),
                proposal: ProposedViewSize(placement.size)
            )
        }
    }

    // MARK: - Placement

    private struct Placement {
        var origin: CGPoint
        var size: CGSize
    }

    private func computePlacements(width: CGFloat, subviews: Subviews) -> [Placement] {
        let colWidth = (width - spacing * CGFloat(columns - 1)) / CGFloat(columns)
        var placements: [Placement] = []

        // Track the bottom Y of each column
        var columnBottoms = Array(repeating: CGFloat(0), count: columns)

        for subview in subviews {
            let widgetSize = subview[WidgetSizeKey.self]
            let colSpan: Int
            let aspectHeight: CGFloat

            switch widgetSize {
            case .small:
                colSpan = 1
                aspectHeight = colWidth // Square
            case .medium:
                colSpan = columns
                aspectHeight = colWidth * CGFloat(columns - 1) / (16.0 / 9.0) // ~16:9 across full width
            case .large:
                colSpan = columns
                aspectHeight = colWidth * CGFloat(columns) * 0.75 // Taller
            }

            let itemWidth: CGFloat
            let startCol: Int
            let y: CGFloat

            if colSpan >= columns {
                // Full width — place at the tallest column's bottom
                itemWidth = width
                startCol = 0
                y = columnBottoms.max() ?? 0
            } else {
                // Find the column with the smallest Y (shortest column)
                startCol = columnBottoms.enumerated().min(by: { $0.element < $1.element })?.offset ?? 0
                itemWidth = colWidth
                y = columnBottoms[startCol]
            }

            let origin = CGPoint(x: CGFloat(startCol) * (colWidth + spacing), y: y)
            let size = CGSize(width: itemWidth, height: aspectHeight)
            placements.append(Placement(origin: origin, size: size))

            // Update column bottoms
            let newBottom = y + aspectHeight + spacing
            if colSpan >= columns {
                for i in 0..<columns {
                    columnBottoms[i] = newBottom
                }
            } else {
                columnBottoms[startCol] = newBottom
            }
        }

        return placements
    }
}

// MARK: - Layout Value Key

enum WidgetSize: String {
    case small, medium, large
}

private struct WidgetSizeKey: LayoutValueKey {
    static let defaultValue: WidgetSize = .medium
}

extension View {
    func widgetSize(_ size: WidgetSize) -> some View {
        layoutValue(key: WidgetSizeKey.self, value: size)
    }
}
