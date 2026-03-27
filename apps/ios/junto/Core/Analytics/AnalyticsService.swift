//
//  AnalyticsService.swift
//  mkrs-world
//
//  Singleton wrapper around PostHog for analytics tracking
//

import Foundation
import PostHog

final class AnalyticsService {
    static let shared = AnalyticsService()

    private var isConfigured = false
    private var sessionNumber: Int = 0
    private var eventsSessionNumber: Int = 0

    private init() {
        sessionNumber = UserDefaults.standard.integer(forKey: "analytics_session_number")
        eventsSessionNumber = UserDefaults.standard.integer(forKey: "analytics_events_session_number")
    }

    // MARK: - Configuration

    func configure() {
        guard !isConfigured else { return }

        let config = PostHogConfig(
            apiKey: "phc_eVSQDUvXGMJBq2gg4R8RTggeMUWfDxpoOyMNeI6FAyf",
            host: "https://us.i.posthog.com"
        )
        config.sessionReplay = true
        config.sessionReplayConfig.maskAllTextInputs = true
        config.sessionReplayConfig.maskAllImages = false

        PostHogSDK.shared.setup(config)
        isConfigured = true

        trackAppOpened()
    }

    // MARK: - User Identification

    func identify(userId: String, properties: [String: Any] = [:]) {
        guard isConfigured else { return }

        PostHogSDK.shared.identify(userId, userProperties: properties)
    }

    func setUserProperties(_ properties: [String: Any]) {
        guard isConfigured else { return }

        PostHogSDK.shared.capture("$set", properties: ["$set": properties])
    }

    func reset() {
        guard isConfigured else { return }

        PostHogSDK.shared.reset()
    }

    // MARK: - Event Tracking

    func track(_ event: AnalyticsEvent) {
        guard isConfigured else { return }

        PostHogSDK.shared.capture(event.name, properties: event.properties)
    }

    func track(_ event: AnalyticsEvent, extraProperties: [String: Any]) {
        guard isConfigured else { return }

        var merged = event.properties
        for (key, value) in extraProperties { merged[key] = value }
        PostHogSDK.shared.capture(event.name, properties: merged)
    }

    // MARK: - Session Management

    func trackFeedSession() {
        sessionNumber += 1
        UserDefaults.standard.set(sessionNumber, forKey: "analytics_session_number")
        track(.feedSession(sessionNumber: sessionNumber))
    }

    func trackEventsSession() {
        eventsSessionNumber += 1
        UserDefaults.standard.set(eventsSessionNumber, forKey: "analytics_events_session_number")
        track(.eventsSession(sessionNumber: eventsSessionNumber))
    }

    // MARK: - App Lifecycle

    private func trackAppOpened() {
        let lastOpenKey = "analytics_last_open_date"
        let lastOpen = UserDefaults.standard.object(forKey: lastOpenKey) as? Date

        var daysSinceLastOpen: Int? = nil
        if let lastOpen = lastOpen {
            let calendar = Calendar.current
            daysSinceLastOpen = calendar.dateComponents([.day], from: lastOpen, to: Date()).day
        }

        UserDefaults.standard.set(Date(), forKey: lastOpenKey)

        track(.appOpened(daysSinceLastOpen: daysSinceLastOpen))
    }
}
