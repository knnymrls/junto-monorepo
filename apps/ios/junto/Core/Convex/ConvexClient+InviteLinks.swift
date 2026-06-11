//
//  ConvexClient+InviteLinks.swift
//  mkrs-world
//
//  Invite links.
//

import Foundation
import ConvexMobile
import Combine
import UIKit


// MARK: - Invite Links

struct InviteLinkResponse: Codable {
    let _id: String
    let code: String
    let universityId: String
    let universityName: String
    let universityShortName: String?
    let universityCity: String
    let universityState: String
    let universityLogoUrl: String?
    let program: String?
    let role: String?
    let label: String?
}


struct InviteRedeemResponse: Codable {
    let alreadyRedeemed: Bool
}

extension ConvexClientManager {

    /// Resolve an invite code to its university + program details
    func getInviteLinkByCode(code: String) async throws -> InviteLinkResponse? {
        return try await queryOnce("inviteLinks:getByCode", with: ["code": code], yielding: InviteLinkResponse?.self)
    }


    /// Redeem an invite link for a user
    func redeemInviteLink(code: String, userId: String) async throws -> InviteRedeemResponse {
        return try await client.mutation(
            "inviteLinks:redeem",
            with: ["code": code, "userId": userId]
        )
    }
}
