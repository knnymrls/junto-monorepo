//
//  StaggeredAppear.swift
//  junto
//
//  Reusable modifier for staggered fade + slide entrance animations
//

import SwiftUI

struct StaggeredAppear: ViewModifier {
    let delay: Double

    @State private var appeared = false

    func body(content: Content) -> some View {
        content
            .offset(y: appeared ? 0 : 20)
            .opacity(appeared ? 1 : 0)
            .onAppear {
                withAnimation(.easeOut(duration: 0.4).delay(delay)) {
                    appeared = true
                }
            }
    }
}

extension View {
    func staggeredAppear(delay: Double = 0) -> some View {
        modifier(StaggeredAppear(delay: delay))
    }
}
