//
//  CardStyle.swift
//  mkrs-world
//
//  Shared card background + border + corner radius modifier
//

import SwiftUI

struct CardStyle: ViewModifier {
    var cornerRadius: CGFloat = Radius.xl

    func body(content: Content) -> some View {
        content
            .background(Color.appSurface)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(Color.appDivider, lineWidth: 1)
            )
    }
}

extension View {
    func cardStyle(cornerRadius: CGFloat = Radius.xl) -> some View {
        modifier(CardStyle(cornerRadius: cornerRadius))
    }
}
