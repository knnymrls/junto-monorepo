//
//  ConvexClient+Portfolio.swift
//  mkrs-world
//
//  Portfolio widgets.
//

import Foundation
import ConvexMobile
import Combine
import UIKit

extension ConvexClientManager {

    // MARK: Portfolio

    /// Subscribe to portfolio items for a user
    func subscribePortfolioItems(userId: String) -> AnyPublisher<[PortfolioItemResponse], ClientError> {
        return client.subscribe(to: "portfolio:list", with: ["userId": userId], yielding: [PortfolioItemResponse].self)
    }
}

extension ConvexClientManager {

    // MARK: Portfolio

    func createPortfolioItem(
        userId: String,
        type: String,
        title: String? = nil,
        url: String? = nil,
        description: String? = nil,
        imageUrls: [String]? = nil,
        organization: String? = nil,
        startDate: String? = nil,
        endDate: String? = nil,
        size: String? = nil
    ) async throws -> String {
        var args: [String: (any ConvexEncodable)?] = [
            "userId": userId,
            "type": type
        ]
        if let title { args["title"] = title }
        if let url { args["url"] = url }
        if let description { args["description"] = description }
        if let imageUrls, !imageUrls.isEmpty {
            let encodable: [ConvexEncodable?] = imageUrls.map { $0 as ConvexEncodable? }
            args["imageUrls"] = encodable
        }
        if let organization { args["organization"] = organization }
        if let startDate { args["startDate"] = startDate }
        if let endDate { args["endDate"] = endDate }
        if let size { args["size"] = size }
        return try await client.mutation("portfolio:create", with: args)
    }


    func deletePortfolioItem(id: String) async throws {
        let _: String? = try await client.mutation("portfolio:remove", with: ["id": id])
    }


    func updatePortfolioItem(
        id: String,
        title: String? = nil,
        url: String? = nil,
        description: String? = nil,
        size: String? = nil,
        order: Int? = nil
    ) async throws {
        var args: [String: (any ConvexEncodable)?] = ["id": id]
        if let title { args["title"] = title }
        if let url { args["url"] = url }
        if let description { args["description"] = description }
        if let size { args["size"] = size }
        if let order { args["order"] = Double(order) }
        let _: String? = try await client.mutation("portfolio:update", with: args)
    }


    func reorderPortfolioItems(items: [(id: String, order: Int, size: String?)]) async throws {
        let encodableItems: [ConvexEncodable?] = items.map { item in
            var dict: [String: (any ConvexEncodable)?] = [
                "id": item.id,
                "order": Double(item.order)
            ]
            if let size = item.size {
                dict["size"] = size
            }
            return dict as ConvexEncodable?
        }
        let _: String? = try await client.mutation("portfolio:reorder", with: ["items": encodableItems])
    }
}

extension ConvexClientManager {

    // MARK: Portfolio

    /// Fetch portfolio items once
    func fetchPortfolioItems(userId: String) async throws -> [PortfolioItemResponse] {
        return try await queryOnce(subscribePortfolioItems(userId: userId))
    }
}
