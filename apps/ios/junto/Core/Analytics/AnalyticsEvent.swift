//
//  AnalyticsEvent.swift
//  mkrs-world
//
//  Type-safe analytics event definitions
//

import Foundation

enum AnalyticsEvent {
    // MARK: - App Lifecycle
    case appOpened(daysSinceLastOpen: Int?)

    // MARK: - Auth & Onboarding
    case authStarted(method: AuthMethod)
    case authCompleted(method: AuthMethod)
    case onboardingStarted
    case onboardingStepViewed(step: Int, stepName: String)
    case onboardingStepCompleted(step: Int, stepName: String)
    case onboardingCompleted
    case onboardingConnectionSent(targetUserId: String)

    // MARK: - Feed & Sessions
    case feedSession(sessionNumber: Int)

    // MARK: - Posts
    case postCreated(category: String)
    case postViewed(postId: String, category: String, authorId: String)

    // MARK: - Comments
    case commentCreated(postId: String)

    // MARK: - Connections
    case connectionSent(toUserId: String, source: ConnectionSource)
    case connectFromPost(postId: String, category: String)
    case connectionAccepted(fromUserId: String)

    // MARK: - Profiles
    case profileViewed(userId: String)

    // MARK: - Composer
    case composerOpened

    // MARK: - Events
    case eventsSession(sessionNumber: Int)
    case eventViewed(eventId: String, eventType: String, hostId: String)
    case eventRsvp(eventId: String, status: String)
    case eventCalendarAdded(eventId: String)
    case eventDirectionsOpened(eventId: String)
    case attendeesListViewed(eventId: String, timing: String)
    case connectFromEvent(eventId: String, toUserId: String)
    case feedbackSubmitted(eventId: String, rating: Int)
    case feedbackSkipped(eventId: String)

    // MARK: - GIFs
    case gifSent(conversationId: String)
    case gifCommented(postId: String)

    // MARK: - Messages
    case messagesViewed
    case conversationOpened(conversationId: String)
    case messageSent(conversationId: String)

    // MARK: - Search
    case searchViewed
    case searchPerformed(query: String, resultCount: Int)
    case searchResultTapped(userId: String, rank: Int)
    case connectFromSearch(toUserId: String)

    // MARK: - Notifications
    case notificationsViewed
    case notificationTapped(type: String)
    case notificationsPushEnabled
    case notificationsPushDenied

    var name: String {
        switch self {
        case .appOpened: return "app_opened"
        case .authStarted: return "auth_started"
        case .authCompleted: return "auth_completed"
        case .onboardingStarted: return "onboarding_started"
        case .onboardingStepViewed: return "onboarding_step_viewed"
        case .onboardingStepCompleted: return "onboarding_step_completed"
        case .onboardingCompleted: return "onboarding_completed"
        case .onboardingConnectionSent: return "onboarding_connection_sent"
        case .feedSession: return "feed_session"
        case .postCreated: return "post_created"
        case .postViewed: return "post_viewed"
        case .commentCreated: return "comment_created"
        case .gifSent: return "gif_sent"
        case .gifCommented: return "gif_commented"
        case .connectionSent: return "connection_sent"
        case .connectFromPost: return "connect_from_post"
        case .connectionAccepted: return "connection_accepted"
        case .profileViewed: return "profile_viewed"
        case .composerOpened: return "composer_opened"
        case .eventsSession: return "events_session"
        case .eventViewed: return "event_viewed"
        case .eventRsvp: return "event_rsvp"
        case .eventCalendarAdded: return "event_calendar_added"
        case .eventDirectionsOpened: return "event_directions_opened"
        case .attendeesListViewed: return "attendees_list_viewed"
        case .connectFromEvent: return "connect_from_event"
        case .feedbackSubmitted: return "feedback_submitted"
        case .feedbackSkipped: return "feedback_skipped"
        case .messagesViewed: return "messages_viewed"
        case .conversationOpened: return "conversation_opened"
        case .messageSent: return "message_sent"
        case .searchViewed: return "search_viewed"
        case .searchPerformed: return "search_performed"
        case .searchResultTapped: return "search_result_tapped"
        case .connectFromSearch: return "connect_from_search"
        case .notificationsViewed: return "notifications_viewed"
        case .notificationTapped: return "notification_tapped"
        case .notificationsPushEnabled: return "notifications_push_enabled"
        case .notificationsPushDenied: return "notifications_push_denied"
        }
    }

    var properties: [String: Any] {
        switch self {
        case .appOpened(let daysSinceLastOpen):
            if let days = daysSinceLastOpen {
                return ["days_since_last_open": days]
            }
            return [:]

        case .authStarted(let method):
            return ["method": method.rawValue]

        case .authCompleted(let method):
            return ["method": method.rawValue]

        case .onboardingStarted:
            return [:]

        case .onboardingStepViewed(let step, let stepName):
            return ["step": step, "step_name": stepName]

        case .onboardingStepCompleted(let step, let stepName):
            return ["step": step, "step_name": stepName]

        case .onboardingCompleted:
            return [:]

        case .onboardingConnectionSent(let targetUserId):
            return ["target_user_id": targetUserId]

        case .feedSession(let sessionNumber):
            return ["session_number": sessionNumber]

        case .postCreated(let category):
            return ["category": category]

        case .postViewed(let postId, let category, let authorId):
            return [
                "post_id": postId,
                "category": category,
                "author_id": authorId
            ]

        case .commentCreated(let postId):
            return ["post_id": postId]

        case .gifSent(let conversationId):
            return ["conversation_id": conversationId]

        case .gifCommented(let postId):
            return ["post_id": postId]

        case .connectionSent(let toUserId, let source):
            return [
                "to_user_id": toUserId,
                "source": source.rawValue
            ]

        case .connectFromPost(let postId, let category):
            return [
                "post_id": postId,
                "category": category
            ]

        case .connectionAccepted(let fromUserId):
            return ["from_user_id": fromUserId]

        case .profileViewed(let userId):
            return ["user_id": userId]

        case .composerOpened:
            return [:]

        case .eventsSession(let sessionNumber):
            return ["session_number": sessionNumber]

        case .eventViewed(let eventId, let eventType, let hostId):
            return [
                "event_id": eventId,
                "event_type": eventType,
                "host_id": hostId
            ]

        case .eventRsvp(let eventId, let status):
            return [
                "event_id": eventId,
                "status": status
            ]

        case .eventCalendarAdded(let eventId):
            return ["event_id": eventId]

        case .eventDirectionsOpened(let eventId):
            return ["event_id": eventId]

        case .attendeesListViewed(let eventId, let timing):
            return [
                "event_id": eventId,
                "timing": timing
            ]

        case .connectFromEvent(let eventId, let toUserId):
            return [
                "event_id": eventId,
                "to_user_id": toUserId
            ]

        case .feedbackSubmitted(let eventId, let rating):
            return [
                "event_id": eventId,
                "rating": rating
            ]

        case .feedbackSkipped(let eventId):
            return ["event_id": eventId]

        case .messagesViewed:
            return [:]

        case .conversationOpened(let conversationId):
            return ["conversation_id": conversationId]

        case .messageSent(let conversationId):
            return ["conversation_id": conversationId]

        case .searchViewed:
            return [:]

        case .searchPerformed(let query, let resultCount):
            return [
                "query": query,
                "result_count": resultCount
            ]

        case .searchResultTapped(let userId, let rank):
            return [
                "user_id": userId,
                "rank": rank
            ]

        case .connectFromSearch(let toUserId):
            return ["to_user_id": toUserId]

        case .notificationsViewed:
            return [:]

        case .notificationTapped(let type):
            return ["type": type]

        case .notificationsPushEnabled, .notificationsPushDenied:
            return [:]
        }
    }
}

enum ConnectionSource: String {
    case feed = "feed"
    case profile = "profile"
    case match = "match"
    case postDetail = "post_detail"
    case eventAttendees = "event_attendees"
    case search = "search"
}

enum AuthMethod: String {
    case apple = "apple"
    case google = "google"
    case email = "email"
    case phone = "phone"
}
