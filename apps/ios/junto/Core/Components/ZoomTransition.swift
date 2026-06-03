//
//  ZoomTransition.swift
//  junto
//
//  Helpers wrapping the iOS 18 "container zoom" transition. A source view
//  calls `.zoomSource(id:in:)`, the presented destination calls
//  `.zoomDestination(id:in:)` — the pair makes a tapped card visually grow
//  into the detail screen. No-op pre-iOS 18 (destination still presents
//  normally, just without the zoom).
//

import SwiftUI

extension View {
    /// Marks this view as the source for a zoom transition into a
    /// `fullScreenCover` / `navigationDestination`. Pair with
    /// `zoomDestination(id:in:)` on the presented view.
    @ViewBuilder
    func zoomSource(id: some Hashable, in namespace: Namespace.ID?) -> some View {
        if #available(iOS 18.0, *), let namespace {
            self.matchedTransitionSource(id: AnyHashable(id), in: namespace)
        } else {
            self
        }
    }

    /// Marks this view as the destination of a zoom transition from a
    /// source tagged with `zoomSource(id:in:)`.
    @ViewBuilder
    func zoomDestination(id: some Hashable, in namespace: Namespace.ID?) -> some View {
        if #available(iOS 18.0, *), let namespace {
            self.navigationTransition(.zoom(sourceID: AnyHashable(id), in: namespace))
        } else {
            self
        }
    }
}
