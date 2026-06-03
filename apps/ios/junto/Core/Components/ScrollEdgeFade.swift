//
//  ScrollEdgeFade.swift
//  junto
//
//  Reusable soft gradient fade at the top and/or bottom edge of a scroll
//  container, so content dissolves into the background instead of clipping
//  hard. Used by the feed and the post detail.
//

import SwiftUI

extension View {
    func scrollEdgeFade(
        top: Bool = true,
        bottom: Bool = true,
        height: CGFloat = 24,
        color: Color = .appBackground
    ) -> some View {
        self
            .overlay(alignment: .top) {
                if top {
                    LinearGradient(
                        colors: [color, color.opacity(0)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .frame(height: height)
                    .allowsHitTesting(false)
                }
            }
            .overlay(alignment: .bottom) {
                if bottom {
                    LinearGradient(
                        colors: [color.opacity(0), color],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .frame(height: height)
                    .allowsHitTesting(false)
                }
            }
    }
}
