//
//  PressableScaleStyle.swift
//  junto
//
//  Button style that gives a springy scale-down on press for a tactile tap feel.
//

import SwiftUI

struct PressableScaleStyle: ButtonStyle {
    var scale: CGFloat = 0.88

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? scale : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.55), value: configuration.isPressed)
    }
}

extension ButtonStyle where Self == PressableScaleStyle {
    /// Springy scale-down press feedback.
    static var pressableScale: PressableScaleStyle { PressableScaleStyle() }
    static func pressableScale(_ scale: CGFloat) -> PressableScaleStyle { PressableScaleStyle(scale: scale) }
}
