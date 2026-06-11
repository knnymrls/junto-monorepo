//
//  EventModels.swift
//  mkrs-world
//
//  Event model types (+ preview mocks).
//

import Foundation
import ConvexMobile
import Combine
import UIKit


struct EventResponse: Codable, Identifiable, Hashable {
    let _id: String
    let title: String
    let description: String?
    let date: Double
    let endDate: Double?
    let location: String?
    let type: String
    let hostName: String?          // Display host (e.g. "Center of Entrepreneurship") — feed card name
    let category: String?          // Event type chip (e.g. "Pitch")
    var categories: [String]? = nil  // Maker categories the event is relevant to (skill taxonomy)
    let imageUrl: String?
    let createdBy: String
    let createdAt: Double
    // Preview fields from listUpcoming
    let host: EventHost?
    let goingCount: Int?
    let attendeePreviews: [AttendeePreview]?

    var id: String { _id }

    /// Best display name for the event's host (explicit hostName, else the creator's name).
    var displayHostName: String? { hostName ?? host?.name }

    /// Tags shown on event cards: the maker categories it touches (icon'd) plus
    /// the event-type word (e.g. "Pitch", "Workshop") — type renders label-only.
    var displayTags: [String] {
        (categories ?? []) + ([category].compactMap { $0 })
    }

    var dateValue: Date { Date(timeIntervalSince1970: date / 1000) }
    var endDateValue: Date? { endDate.map { Date(timeIntervalSince1970: $0 / 1000) } }

    var eventType: EventType {
        EventType(rawValue: type) ?? .inPerson
    }

    struct EventHost: Codable, Hashable {
        let id: String
        let name: String
        let avatarUrl: String?
    }

    struct AttendeePreview: Codable, Hashable, Identifiable {
        let id: String
        let name: String
        let avatarUrl: String?
    }

    enum EventType: String, Codable {
        case inPerson = "in_person"
        case online = "online"
        case hybrid = "hybrid"

        var displayName: String {
            switch self {
            case .inPerson: return "In Person"
            case .online: return "Online"
            case .hybrid: return "Hybrid"
            }
        }

        var iconName: String {
            switch self {
            case .inPerson: return "person.2.fill"
            case .online: return "video.fill"
            case .hybrid: return "person.2.wave.2.fill"
            }
        }
    }
}


// MARK: - Mock Data for Events

extension EventResponse {
    static let mockList: [EventResponse] = [
        EventResponse(
            _id: "event_1",
            title: "JUNTO SPEED NETWORKING",
            description: "Meet other users in quick 5-minute conversations. Rotate through and connect with founders, designers, and developers building cool stuff in Lincoln.\n\nExact location will be shared after you RSVP.",
            date: Date().addingTimeInterval(86400 * 3).timeIntervalSince1970 * 1000,
            endDate: Date().addingTimeInterval(86400 * 3 + 7200).timeIntervalSince1970 * 1000,
            location: "Lincoln, NE",
            type: "in_person",
            hostName: "Junto",
            category: "Networking",
            imageUrl: "https://images.unsplash.com/photo-1540575467063-178a50c2df87?w=800&h=600&fit=crop",
            createdBy: "mock_1",
            createdAt: Date().timeIntervalSince1970 * 1000,
            host: EventHost(id: "mock_1", name: "Kenny Morales", avatarUrl: nil),
            goingCount: 5,
            attendeePreviews: [
                AttendeePreview(id: "mock_2", name: "Sarah Chen", avatarUrl: nil),
                AttendeePreview(id: "mock_3", name: "Marcus Williams", avatarUrl: nil),
                AttendeePreview(id: "mock_4", name: "Wilson Overfield", avatarUrl: nil)
            ]
        ),
        EventResponse(
            _id: "event_2",
            title: "Weekly User Standup",
            description: "30 minutes every Saturday. Share what you shipped this week, what you're working on next, and where you're stuck.",
            date: Date().addingTimeInterval(86400 * 7).timeIntervalSince1970 * 1000,
            endDate: nil,
            location: nil,
            type: "online",
            hostName: nil,
            category: "Standup",
            imageUrl: nil,
            createdBy: "mock_1",
            createdAt: Date().timeIntervalSince1970 * 1000,
            host: EventHost(id: "mock_1", name: "Kenny Morales", avatarUrl: nil),
            goingCount: 12,
            attendeePreviews: nil
        )
    ]
}


struct EventWithRsvpResponse: Codable, Identifiable {
    let _id: String
    let title: String
    let description: String?
    let date: Double
    let endDate: Double?
    let location: String?
    let fullAddress: String?
    let type: String
    let category: String?
    var categories: [String]? = nil
    let imageUrl: String?
    let createdBy: String
    let createdAt: Double
    let goingCount: Int
    let interestedCount: Int
    let host: EventHost?
    let attendeePreviews: [AttendeePreview]?
    var myStatus: String? = nil   // current user's RSVP status ("going", etc.)

    var id: String { _id }

    var dateValue: Date { Date(timeIntervalSince1970: date / 1000) }
    var endDateValue: Date? { endDate.map { Date(timeIntervalSince1970: $0 / 1000) } }

    var eventType: EventResponse.EventType {
        EventResponse.EventType(rawValue: type) ?? .inPerson
    }

    struct EventHost: Codable, Hashable {
        let id: String
        let name: String
        let avatarUrl: String?
        let headline: String?
    }

    struct AttendeePreview: Codable, Hashable, Identifiable {
        let id: String
        let name: String
        let avatarUrl: String?
    }
}


struct EventAttendee: Codable, Identifiable, Hashable {
    let id: String
    let name: String
    let avatarUrl: String?
    let headline: String?
    let status: String

    var isGoing: Bool { status == "going" }
}


struct EventRsvpResponse: Codable {
    let _id: String
    let eventId: String
    let userId: String
    let status: String
    let createdAt: Double

    var rsvpStatus: RsvpStatus {
        RsvpStatus(rawValue: status) ?? .notGoing
    }

    enum RsvpStatus: String {
        case going = "going"
        case interested = "interested"
        case notGoing = "not_going"
    }
}


struct EventFeedbackResponse: Codable {
    let _id: String
    let eventId: String
    let userId: String
    let rating: Int
    let improvements: [String]
    let wantToConnectWith: [String]
    let createdAt: Double
}
