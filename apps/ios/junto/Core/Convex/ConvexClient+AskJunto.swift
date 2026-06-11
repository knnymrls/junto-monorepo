//
//  ConvexClient+AskJunto.swift
//  junto
//
//  Ask Junto — the AI assistant on the center tab. Data layer against the
//  deployed Convex backend:
//    - askJuntoData:createThread   (mutation) → threadId
//    - askJunto:run                (action)   runs the agent
//    - askJuntoData:getMessages    (query)    live message feed (SUBSCRIBE)
//    - askJuntoData:listThreads    (query)    past conversations
//
//  Assistant rows carry a `blocks` JSON string of shape {say, show, followUp}.
//  `show` is a single discriminated-union content block (or null). One message
//  does exactly one thing — never a stack. The backend's `intent` field is not
//  sent to the client; Codable ignores it.
//

import Foundation
import ConvexMobile
import Combine

// MARK: - Client methods

extension ConvexClientManager {

    /// Create a thread for a brand-new conversation. Returns the threadId.
    func createAskJuntoThread(userId: String, firstMessage: String) async throws -> String {
        return try await client.mutation("askJuntoData:createThread", with: [
            "userId": userId,
            "firstMessage": firstMessage
        ])
    }

    /// Run the agent. Inserts the user message + a pending assistant row
    /// immediately, then fills the placeholder when done — the UI observes
    /// this via `subscribeAskJuntoMessages`. The return value is ignored.
    func runAskJunto(threadId: String, message: String, currentUserId: String) async throws {
        let _: AskJuntoRunAck? = try await client.action("askJunto:run", with: [
            "threadId": threadId,
            "message": message,
            "currentUserId": currentUserId
        ])
    }

    /// Live message feed for a thread, ordered ascending. The UI binds to this.
    func subscribeAskJuntoMessages(threadId: String) -> AnyPublisher<[AskJuntoMessageResponse], ClientError> {
        return client.subscribe(
            to: "askJuntoData:getMessages",
            with: ["threadId": threadId],
            yielding: [AskJuntoMessageResponse].self
        )
    }

    /// Past conversations for a user, most recent first.
    func subscribeAskJuntoThreads(userId: String, limit: Int? = nil) -> AnyPublisher<[AskJuntoThreadResponse], ClientError> {
        var args: [String: (any ConvexEncodable)?] = ["userId": userId]
        if let limit { args["limit"] = Double(limit) }
        return client.subscribe(
            to: "askJuntoData:listThreads",
            with: args,
            yielding: [AskJuntoThreadResponse].self
        )
    }
}

/// The `askJunto:run` action returns a small status object we don't use. An
/// empty Decodable struct decodes from any JSON object (and `?` tolerates null).
struct AskJuntoRunAck: Decodable {}

// MARK: - Thread

struct AskJuntoThreadResponse: Decodable, Identifiable, Hashable {
    let _id: String
    let userId: String
    let title: String
    let lastMessageAt: Double
    let lastMessagePreview: String?
    let createdAt: Double

    var id: String { _id }

    var lastMessageDate: Date { Date(timeIntervalSince1970: lastMessageAt / 1000) }
}

// MARK: - Message row

enum AskJuntoMessageStatus: String {
    case pending
    case complete
    case error
}

struct AskJuntoMessageResponse: Decodable, Identifiable, Hashable {
    let _id: String
    let threadId: String
    let role: String              // "user" | "assistant"
    let text: String?
    let blocks: String?           // JSON string of {say, show, followUp} (assistant only)
    let status: String?           // "pending" | "complete" | "error"
    let step: String?             // live progress label while pending (assistant only)
    let createdAt: Double

    var id: String { _id }

    var isUser: Bool { role == "user" }
    var isAssistant: Bool { role == "assistant" }

    /// Assistant rows default to `.complete` when the field is absent.
    var messageStatus: AskJuntoMessageStatus {
        AskJuntoMessageStatus(rawValue: status ?? "complete") ?? .complete
    }

    /// Decoded {say, show, followUp}. Nil for user rows or unparsable payloads.
    var parsedBlocks: AskJuntoBlocks? {
        guard let blocks, !blocks.isEmpty, let data = blocks.data(using: .utf8) else { return nil }
        return try? JSONDecoder().decode(AskJuntoBlocks.self, from: data)
    }

    /// A client-only placeholder user bubble shown the instant a message is sent,
    /// before the server round-trip echoes it back over the subscription.
    static func optimisticUser(text: String, threadId: String?, createdAt: Double) -> AskJuntoMessageResponse {
        AskJuntoMessageResponse(
            _id: "optimistic-user",
            threadId: threadId ?? "",
            role: "user",
            text: text,
            blocks: nil,
            status: nil,
            step: nil,
            createdAt: createdAt
        )
    }
}

// MARK: - Blocks payload ({say, show, followUp})

struct AskJuntoBlocks: Decodable, Hashable {
    let say: String
    let show: AskJuntoBlock?
    let followUp: String?
}

// MARK: - Content block (discriminated union on `type`)

enum AskJuntoBlock: Hashable {
    case people(userIds: [String], note: String?)
    case opportunities(eventIds: [String], note: String?)
    case draftAsk(title: String, body: String)
    case draftIntro(targetUserId: String, message: String)
    case action(label: String, kind: AskJuntoActionKind)
    /// Forward-compatible fallback for any block type the client doesn't know.
    case unknown(type: String)
}

extension AskJuntoBlock: Decodable {
    private enum CodingKeys: String, CodingKey {
        case type, userIds, note, eventIds, title, body, targetUserId, message, label, kind
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        let type = try c.decode(String.self, forKey: .type)
        switch type {
        case "people":
            self = .people(
                userIds: try c.decode([String].self, forKey: .userIds),
                note: try c.decodeIfPresent(String.self, forKey: .note)
            )
        case "opportunities":
            self = .opportunities(
                eventIds: try c.decode([String].self, forKey: .eventIds),
                note: try c.decodeIfPresent(String.self, forKey: .note)
            )
        case "draftAsk":
            self = .draftAsk(
                title: try c.decode(String.self, forKey: .title),
                body: try c.decode(String.self, forKey: .body)
            )
        case "draftIntro":
            self = .draftIntro(
                targetUserId: try c.decode(String.self, forKey: .targetUserId),
                message: try c.decode(String.self, forKey: .message)
            )
        case "action":
            self = .action(
                label: try c.decode(String.self, forKey: .label),
                kind: try c.decodeIfPresent(AskJuntoActionKind.self, forKey: .kind) ?? .unknown
            )
        default:
            self = .unknown(type: type)
        }
    }
}

enum AskJuntoActionKind: String, Decodable, Hashable {
    case connect
    case postAsk = "post_ask"
    case rsvp
    case viewProfile = "view_profile"
    case unknown

    init(from decoder: Decoder) throws {
        let raw = try decoder.singleValueContainer().decode(String.self)
        self = AskJuntoActionKind(rawValue: raw) ?? .unknown
    }
}
