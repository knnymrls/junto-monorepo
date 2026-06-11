//
//  Resubscribe.swift
//  mkrs-world
//
//  A Convex subscription publisher completes permanently when it fails — a
//  transient transport/decode error silently killed badges, lists, and live
//  state for the rest of the session. This operator resubscribes after a
//  short delay instead.
//

import Combine
import Foundation

extension Publisher {
    /// Re-establish the subscription after `delay` whenever the upstream
    /// fails. The returned publisher never fails; use it for always-on live
    /// state (badge counts, lists) where the right response to an error is
    /// "try again", not "go dark".
    func resubscribeOnFailure(
        after delay: TimeInterval = 3,
        scheduler: DispatchQueue = .main
    ) -> AnyPublisher<Output, Never> {
        self
            .catch { error -> AnyPublisher<Output, Never> in
                print("Convex subscription failed, resubscribing in \(delay)s: \(error)")
                return Just(())
                    .delay(for: .seconds(delay), scheduler: scheduler)
                    .flatMap { _ in self.resubscribeOnFailure(after: delay, scheduler: scheduler) }
                    .eraseToAnyPublisher()
            }
            .eraseToAnyPublisher()
    }
}
