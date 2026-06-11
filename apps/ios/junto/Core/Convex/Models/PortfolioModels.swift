//
//  PortfolioModels.swift
//  mkrs-world
//
//  Portfolio item model types.
//

import Foundation
import ConvexMobile
import Combine
import UIKit


// MARK: - Portfolio Item Response

struct PortfolioItemResponse: Codable, Identifiable, Hashable {
    let _id: String
    let userId: String
    let type: String
    let title: String?
    let url: String?
    let description: String?
    let imageUrls: [String]?
    let organization: String?
    let startDate: String?
    let endDate: String?
    let size: String?
    let order: Double
    let createdAt: Double
    let updatedAt: Double

    var id: String { _id }

    enum PortfolioType: String {
        case github
        case gallery
        case link
        case experience
    }

    var portfolioType: PortfolioType {
        PortfolioType(rawValue: type) ?? .link
    }

    enum PortfolioSize: String {
        case small
        case medium
        case large
    }

    var effectiveSize: PortfolioSize {
        PortfolioSize(rawValue: size ?? "medium") ?? .medium
    }
}
