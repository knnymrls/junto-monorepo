//
//  ConvexClient.swift
//  mkrs-world
//
//  Convex client singleton + the one-shot query helper. Domain APIs live in
//  ConvexClient+<Domain>.swift; model types live in Models/.
//

import Foundation
import ConvexMobile
import Combine
import UIKit

@MainActor
class ConvexClientManager: ObservableObject {
    static let shared = ConvexClientManager()

    let client: ConvexClient

    private init() {
        client = ConvexClient(deploymentUrl: "https://avid-chicken-478.convex.cloud")
    }
}


// MARK: - One-shot queries

/// Errors thrown by `queryOnce` when a one-shot read cannot complete.
enum ConvexQueryError: Error, LocalizedError {
    case timedOut
    case noValue

    var errorDescription: String? {
        switch self {
        case .timedOut: return "The request timed out. Check your connection and try again."
        case .noValue: return "The server returned no data."
        }
    }
}


extension ConvexClientManager {

    /// One-shot read of a Convex query: resolves with the first value or throws.
    /// A publisher that completes without emitting throws instead of hanging,
    /// and the timeout covers the offline case where the socket never errors.
    func queryOnce<T: Decodable>(
        _ name: String,
        with args: [String: (any ConvexEncodable)?] = [:],
        yielding type: T.Type = T.self,
        timeout: TimeInterval = 15
    ) async throws -> T {
        let publisher = args.isEmpty
            ? client.subscribe(to: name, yielding: T.self)
            : client.subscribe(to: name, with: args, yielding: T.self)
        return try await queryOnce(publisher, timeout: timeout)
    }

    /// One-shot read of an existing subscription publisher (first value or throw).
    func queryOnce<T>(
        _ publisher: AnyPublisher<T, ClientError>,
        timeout: TimeInterval = 15
    ) async throws -> T {
        try await withThrowingTaskGroup(of: T?.self) { group in
            group.addTask {
                for try await value in publisher.values {
                    return value
                }
                return nil // publisher completed without emitting
            }
            group.addTask {
                try await Task.sleep(nanoseconds: UInt64(timeout * 1_000_000_000))
                throw ConvexQueryError.timedOut
            }
            defer { group.cancelAll() }
            guard let first = try await group.next(), let value = first else {
                throw ConvexQueryError.noValue
            }
            return value
        }
    }
}
