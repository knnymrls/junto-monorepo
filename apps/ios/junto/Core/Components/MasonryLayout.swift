//
//  MasonryLayout.swift
//  mkrs-world
//
//  Two-column masonry layout — places each item in the shortest column
//

import SwiftUI

struct MasonryLayout: Layout {
    var columns: Int = 2
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = calculateLayout(
            in: proposal.replacingUnspecifiedDimensions().width,
            subviews: subviews
        )
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = calculateLayout(in: bounds.width, subviews: subviews)

        for (index, subview) in subviews.enumerated() {
            let position = result.positions[index]
            let width = result.columnWidth
            subview.place(
                at: CGPoint(x: bounds.minX + position.x, y: bounds.minY + position.y),
                proposal: ProposedViewSize(width: width, height: nil)
            )
        }
    }

    private struct LayoutResult {
        var size: CGSize
        var positions: [CGPoint]
        var columnWidth: CGFloat
    }

    private func calculateLayout(in maxWidth: CGFloat, subviews: Subviews) -> LayoutResult {
        let totalSpacing = spacing * CGFloat(columns - 1)
        let columnWidth = (maxWidth - totalSpacing) / CGFloat(columns)

        var columnHeights = Array(repeating: CGFloat.zero, count: columns)
        var positions: [CGPoint] = []

        for subview in subviews {
            // Find shortest column
            let shortestColumn = columnHeights.enumerated().min(by: { $0.element < $1.element })?.offset ?? 0

            let x = CGFloat(shortestColumn) * (columnWidth + spacing)
            let y = columnHeights[shortestColumn]

            positions.append(CGPoint(x: x, y: y))

            let size = subview.sizeThatFits(ProposedViewSize(width: columnWidth, height: nil))
            columnHeights[shortestColumn] += size.height + spacing
        }

        let maxHeight = columnHeights.max() ?? 0
        let finalHeight = max(0, maxHeight - spacing)

        return LayoutResult(
            size: CGSize(width: maxWidth, height: finalHeight),
            positions: positions,
            columnWidth: columnWidth
        )
    }
}
