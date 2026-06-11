//
//  VouchModels.swift
//  mkrs-world
//
//  Vouch model types.
//

import Foundation
import ConvexMobile
import Combine
import UIKit


// MARK: - Vouches

struct VouchResponse: Codable, Identifiable {
    let _id: String
    let fromUserId: String
    let toUserId: String
    let reason: String
    let createdAt: Double
    let fromUser: VouchUserInfo?

    var id: String { _id }

    var createdDate: Date {
        Date(timeIntervalSince1970: createdAt / 1000)
    }

    struct VouchUserInfo: Codable {
        let _id: String
        let name: String
        let avatarUrl: String?
        let headline: String?
    }
}


/// "Alex vouched for you." Surfaced from a recent vouch you received.
struct VouchFeedResponse: Codable, Hashable {
    let _id: String
    let reason: String
    let createdAt: Double
    let fromUser: VouchFromUser

    struct VouchFromUser: Codable, Hashable {
        let _id: String
        let name: String
        let avatarUrl: String?
        let headline: String?
    }

    var createdDate: Date { Date(timeIntervalSince1970: createdAt / 1000) }
}
