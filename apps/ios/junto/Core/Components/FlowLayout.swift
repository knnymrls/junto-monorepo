//
//  FlowLayout.swift
//  mkrs-world
//
//  Flow layout for wrapping skill/interest pills
//

import SwiftUI

struct FlowLayout: Layout {
    var spacing: CGFloat = 8
    var centered: Bool = false

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = FlowResult(
            in: proposal.replacingUnspecifiedDimensions().width,
            subviews: subviews,
            spacing: spacing,
            centered: centered
        )
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = FlowResult(
            in: bounds.width,
            subviews: subviews,
            spacing: spacing,
            centered: centered
        )
        for (index, subview) in subviews.enumerated() {
            subview.place(
                at: CGPoint(x: bounds.minX + result.positions[index].x, y: bounds.minY + result.positions[index].y),
                proposal: .unspecified
            )
        }
    }

    struct FlowResult {
        var size: CGSize
        var positions: [CGPoint]

        init(in maxWidth: CGFloat, subviews: Subviews, spacing: CGFloat, centered: Bool) {
            var positions: [CGPoint] = []

            guard !subviews.isEmpty else {
                self.positions = []
                self.size = .zero
                return
            }

            var currentX: CGFloat = 0
            var currentY: CGFloat = 0
            var lineHeight: CGFloat = 0
            var rowStartIndex = 0
            var rows: [(startIndex: Int, endIndex: Int, width: CGFloat, y: CGFloat)] = []

            for (index, subview) in subviews.enumerated() {
                let size = subview.sizeThatFits(.unspecified)

                if currentX + size.width > maxWidth && currentX > 0 {
                    rows.append((rowStartIndex, index - 1, currentX - spacing, currentY))
                    currentX = 0
                    currentY += lineHeight + spacing
                    lineHeight = 0
                    rowStartIndex = index
                }

                positions.append(CGPoint(x: currentX, y: currentY))
                lineHeight = max(lineHeight, size.height)
                currentX += size.width + spacing
            }

            rows.append((rowStartIndex, subviews.count - 1, currentX - spacing, currentY))

            if centered {
                for row in rows {
                    let offset = (maxWidth - row.width) / 2
                    for i in row.startIndex...row.endIndex {
                        positions[i].x += offset
                    }
                }
            }

            self.positions = positions
            self.size = CGSize(width: maxWidth, height: currentY + lineHeight)
        }
    }
}
