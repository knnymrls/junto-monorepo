//
//  ConvexClient+Events.swift
//  mkrs-world
//
//  Events, RSVPs, and event feedback.
//

import Foundation
import ConvexMobile
import Combine
import UIKit

extension ConvexClientManager {

    // MARK: Events

    /// Subscribe to upcoming events
    func subscribeUpcomingEvents(universityId: String? = nil, limit: Int? = nil) -> AnyPublisher<[EventResponse], ClientError> {
        var args: [String: (any ConvexEncodable)?] = [:]
        if let universityId = universityId {
            args["universityId"] = universityId
        }
        if let limit = limit {
            args["limit"] = Double(limit)
        }

        if args.isEmpty {
            return client.subscribe(to: "events:listUpcoming", yielding: [EventResponse].self)
        } else {
            return client.subscribe(to: "events:listUpcoming", with: args, yielding: [EventResponse].self)
        }
    }


    /// Upcoming events the user has RSVP'd "going" to (Discover "Your Events").
    func subscribeGoingUpcomingEvents(userId: String, limit: Int? = nil) -> AnyPublisher<[EventResponse], ClientError> {
        var args: [String: (any ConvexEncodable)?] = ["userId": userId]
        if let limit = limit {
            args["limit"] = Double(limit)
        }
        return client.subscribe(to: "events:listGoingUpcoming", with: args, yielding: [EventResponse].self)
    }


    /// Subscribe to past events (most recent first)
    func subscribePastEvents(universityId: String? = nil, limit: Int? = nil) -> AnyPublisher<[EventResponse], ClientError> {
        var args: [String: (any ConvexEncodable)?] = [:]
        if let universityId = universityId {
            args["universityId"] = universityId
        }
        if let limit = limit {
            args["limit"] = Double(limit)
        }

        if args.isEmpty {
            return client.subscribe(to: "events:listPast", yielding: [EventResponse].self)
        } else {
            return client.subscribe(to: "events:listPast", with: args, yielding: [EventResponse].self)
        }
    }


    /// Subscribe to a single event with RSVP counts
    func subscribeEvent(id: String, userId: String? = nil) -> AnyPublisher<EventWithRsvpResponse?, ClientError> {
        var args: [String: (any ConvexEncodable)?] = ["id": id]
        if let userId = userId { args["userId"] = userId }
        return client.subscribe(to: "events:get", with: args, yielding: EventWithRsvpResponse?.self)
    }


    /// Subscribe to event attendees
    func subscribeEventAttendees(eventId: String) -> AnyPublisher<[EventAttendee], ClientError> {
        return client.subscribe(to: "events:getAttendees", with: ["eventId": eventId], yielding: [EventAttendee].self)
    }


    /// Get user's RSVP status for an event
    func subscribeUserRsvp(eventId: String, userId: String) -> AnyPublisher<EventRsvpResponse?, ClientError> {
        return client.subscribe(to: "events:getUserRsvp", with: [
            "eventId": eventId,
            "userId": userId
        ], yielding: EventRsvpResponse?.self)
    }


    /// Subscribe to events needing feedback (ended events user attended but hasn't reviewed)
    func subscribeEventsNeedingFeedback(userId: String) -> AnyPublisher<[EventWithRsvpResponse], ClientError> {
        return client.subscribe(to: "events:getEventsNeedingFeedback", with: [
            "userId": userId
        ], yielding: [EventWithRsvpResponse].self)
    }


    // MARK: Events Attended

    /// Subscribe to events a user has attended (full event shape — renders
    /// with the Discover event card)
    func subscribeEventsAttended(userId: String) -> AnyPublisher<[EventResponse], ClientError> {
        return client.subscribe(to: "events:listAttendedByUser", with: ["userId": userId], yielding: [EventResponse].self)
    }
}

extension ConvexClientManager {

    // MARK: Events

    /// RSVP to an event
    func rsvpToEvent(eventId: String, userId: String, status: String) async throws -> String {
        return try await client.mutation("events:rsvp", with: [
            "eventId": eventId,
            "userId": userId,
            "status": status
        ])
    }


    func markCalendarAdded(eventId: String, userId: String) async throws {
        let _: String? = try await client.mutation("events:markCalendarAdded", with: [
            "eventId": eventId,
            "userId": userId
        ])
    }


    // MARK: Event Feedback

    /// Submit feedback for an event
    func submitEventFeedback(eventId: String, userId: String, rating: Int, improvements: [String], wantToConnectWith: [String]) async throws -> String {
        let encodableImprovements: [ConvexEncodable?] = improvements.map { $0 as ConvexEncodable? }
        let encodableConnections: [ConvexEncodable?] = wantToConnectWith.map { $0 as ConvexEncodable? }
        return try await client.mutation("events:submitFeedback", with: [
            "eventId": eventId,
            "userId": userId,
            "rating": Double(rating),
            "improvements": encodableImprovements,
            "wantToConnectWith": encodableConnections
        ] as [String: (any ConvexEncodable)?])
    }


    // MARK: Events

    func createEvent(
        title: String,
        description: String?,
        date: Double,
        endDate: Double? = nil,
        location: String? = nil,
        type: String,
        category: String? = nil,
        categories: [String]? = nil,
        imageUrl: String? = nil,
        createdBy: String,
        universityId: String?
    ) async throws {
        var args: [String: (any ConvexEncodable)?] = [
            "title": title,
            "date": date,
            "type": type,
            "createdBy": createdBy,
        ]
        if let description { args["description"] = description }
        if let endDate { args["endDate"] = endDate }
        if let location { args["location"] = location }
        if let category { args["category"] = category }
        if let categories, !categories.isEmpty {
            args["categories"] = categories.map { $0 as ConvexEncodable? }
        }
        if let imageUrl { args["imageUrl"] = imageUrl }
        if let universityId { args["universityId"] = universityId }

        let _: String? = try await client.mutation("events:create", with: args)
    }
}

extension ConvexClientManager {

    // MARK: Events Attended

    /// Fetch events attended by a user once
    func fetchEventsAttended(userId: String) async throws -> [EventResponse] {
        return try await queryOnce(subscribeEventsAttended(userId: userId))
    }


    // MARK: Events

    /// Fetch a single event once. Pass `userId` so the response includes the
    /// caller's RSVP state (`myStatus`) — omitting it renders stale RSVP UI.
    func fetchEvent(id: String, userId: String? = nil) async throws -> EventWithRsvpResponse? {
        return try await queryOnce(subscribeEvent(id: id, userId: userId))
    }


    // MARK: Event Feedback

    /// Fetch events needing feedback once
    func fetchEventsNeedingFeedback(userId: String) async throws -> [EventWithRsvpResponse] {
        return try await queryOnce(subscribeEventsNeedingFeedback(userId: userId))
    }
}
