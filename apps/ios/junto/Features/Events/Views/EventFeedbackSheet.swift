//
//  EventFeedbackSheet.swift
//  mkrs-world
//
//  Multi-step post-event feedback collection sheet
//

import SwiftUI
import Combine

struct EventFeedbackSheet: View {
    let event: EventWithRsvpResponse
    var onComplete: (() -> Void)?
    var onSkip: (() -> Void)?

    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var currentUser: CurrentUserManager
    @State private var currentStep = 0
    @State private var selectedRating: Int = 0
    @State private var selectedImprovements: Set<String> = []
    @State private var additionalFeedback: String = ""
    @State private var selectedAttendees: Set<String> = []
    @State private var attendees: [EventAttendee] = []
    @ObservedObject private var connections = ConnectionStore.shared
    @State private var isSubmitting = false
    @State private var submitError: String?
    @State private var cancellables = Set<AnyCancellable>()

    private let convex = ConvexClientManager.shared

    private let improvementOptions = [
        "More time",
        "Different venue",
        "Themed topics",
        "Smaller group",
        "Larger group",
        "Better networking format"
    ]

    private let ratingEmojis = ["😞", "😕", "😐", "🙂", "🤩"]
    private let ratingLabels = ["Terrible", "Bad", "Okay", "Good", "Amazing"]

    private var totalSteps: Int {
        filteredAttendees.isEmpty ? 2 : 3
    }

    private var filteredAttendees: [EventAttendee] {
        guard let myId = currentUser.userId else { return attendees }
        return attendees.filter { $0.id != myId }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Step content
                TabView(selection: $currentStep) {
                    ratingStep.tag(0)
                    improvementsStep.tag(1)
                    if !filteredAttendees.isEmpty {
                        connectStep.tag(2)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.easeInOut(duration: 0.25), value: currentStep)

                // Bottom button
                bottomButton
            }
            .background(Color.appBackground)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Skip") {
                        AnalyticsService.shared.track(.feedbackSkipped(eventId: event._id))
                        onSkip?()
                        dismiss()
                    }
                    .foregroundColor(.appSecondary)
                }
            }
        }
        .interactiveDismissDisabled()
        .errorAlert($submitError, title: "Couldn't Submit Feedback")
        .task {
            await loadAttendees()
        }
    }

    // MARK: - Step 1: Rating

    private var ratingStep: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: Spacing.xxxl) {
                VStack(spacing: Spacing.xxs) {
                    Text("How was")
                        .font(.displayMedium)
                        .foregroundColor(.appPrimary)
                    Text(event.title + "?")
                        .font(.displayMedium)
                        .foregroundColor(.appPrimary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, Spacing.huge)

                HStack(spacing: 0) {
                    ForEach(1...5, id: \.self) { rating in
                        Button(action: {
                            withAnimation(.spring(response: 0.3)) {
                                selectedRating = rating
                            }
                        }) {
                            VStack(spacing: Spacing.xs) {
                                Text(ratingEmojis[rating - 1])
                                    .font(.system(size: selectedRating == rating ? 44 : 34))
                                    .scaleEffect(selectedRating == rating ? 1.15 : 1.0)

                                Text(ratingLabels[rating - 1])
                                    .font(.captionSmallMedium)
                                    .foregroundColor(selectedRating == rating ? .appPrimary : .appSecondary)
                            }
                            .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, Spacing.sm)
            }
            .padding(.horizontal, Spacing.lg)
        }
    }

    // MARK: - Step 2: Improvements + Free Text

    private var improvementsStep: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: Spacing.xxl) {
                Text("What could be better?")
                    .font(.displayMedium)
                    .foregroundColor(.appPrimary)
                    .padding(.top, Spacing.huge)

                FlowLayout(spacing: Spacing.sm) {
                    ForEach(improvementOptions, id: \.self) { option in
                        FeedbackImprovementChip(
                            title: option,
                            isSelected: selectedImprovements.contains(option)
                        ) {
                            if selectedImprovements.contains(option) {
                                selectedImprovements.remove(option)
                            } else {
                                selectedImprovements.insert(option)
                            }
                        }
                    }
                }

                VStack(alignment: .leading, spacing: Spacing.sm) {
                    Text("Anything else?")
                        .font(.bodyLargeSemibold)
                        .foregroundColor(.appPrimary)

                    TextField("Share your thoughts...", text: $additionalFeedback, axis: .vertical)
                        .font(.bodyLarge)
                        .foregroundColor(.appPrimary)
                        .lineLimit(3...6)
                        .padding(Spacing.md)
                        .background(Color.appSurfaceSecondary)
                        .cornerRadius(Radius.lg)
                }
            }
            .padding(.horizontal, Spacing.lg)
            .padding(.bottom, 100)
        }
    }

    // MARK: - Step 3: Connect

    private var connectStep: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: Spacing.lg) {
                Text("Stay connected?")
                    .font(.displayMedium)
                    .foregroundColor(.appPrimary)
                    .padding(.top, Spacing.huge)

                Text("Connect with people you met")
                    .font(.bodyLarge)
                    .foregroundColor(.appSecondary)

                ForEach(filteredAttendees) { attendee in
                    HStack(spacing: Spacing.md) {
                        AvatarView(
                            avatarUrl: attendee.avatarUrl,
                            name: attendee.name,
                            size: 44
                        )

                        VStack(alignment: .leading, spacing: Spacing.xxxs) {
                            Text(attendee.name)
                                .font(.bodyLargeMedium)
                                .foregroundColor(.appPrimary)

                            if let headline = attendee.headline, !headline.isEmpty {
                                Text(headline)
                                    .font(.body14)
                                    .foregroundColor(.appSecondary)
                                    .lineLimit(1)
                            }
                        }

                        Spacer()

                        if connections.isConnected(attendee.id) {
                            Text("Connected")
                                .font(.bodySmallMedium)
                                .foregroundColor(.appSecondary)
                                .padding(.horizontal, Spacing.md)
                                .padding(.vertical, Spacing.xs)
                                .background(Color.appSurfaceSecondary)
                                .clipShape(Capsule())
                        } else if connections.isPending(attendee.id) || selectedAttendees.contains(attendee.id) {
                            Text("Pending")
                                .font(.bodySmallMedium)
                                .foregroundColor(.appSecondary)
                                .padding(.horizontal, Spacing.md)
                                .padding(.vertical, Spacing.xs)
                                .background(Color.appSurfaceSecondary)
                                .clipShape(Capsule())
                        } else {
                            Button(action: { selectedAttendees.insert(attendee.id) }) {
                                Text("Connect")
                                    .font(.bodySmallSemibold)
                                    .foregroundColor(.white)
                                    .padding(.horizontal, Spacing.md)
                                    .padding(.vertical, Spacing.xs)
                                    .background(Color.appPrimary)
                                    .clipShape(Capsule())
                            }
                        }
                    }
                    .padding(.vertical, Spacing.xxs)
                }
            }
            .padding(.horizontal, Spacing.lg)
        }
    }

    // MARK: - Bottom Button

    private var bottomButton: some View {
        let isLastStep = currentStep == totalSteps - 1
        let canProceed: Bool = {
            switch currentStep {
            case 0: return selectedRating > 0
            default: return true
            }
        }()

        return Button(action: {
            if isLastStep {
                submitFeedback()
            } else {
                withAnimation {
                    currentStep += 1
                }
            }
        }) {
            if isSubmitting {
                ProgressView()
                    .tint(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
            } else {
                Text(isLastStep ? "Submit" : "Next")
                    .font(.bodyLargeSemibold)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
            }
        }
        .background(canProceed ? Color.appPrimary : Color.appSecondary)
        .cornerRadius(Radius.xl)
        .padding(.horizontal, Spacing.lg)
        .padding(.bottom, Spacing.sm)
        .disabled(!canProceed || isSubmitting)
    }

    // MARK: - Data

    private func loadAttendees() async {
        convex.subscribeEventAttendees(eventId: event._id)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { _ in },
                receiveValue: { self.attendees = $0 }
            )
            .store(in: &cancellables)

        if let userId = currentUser.userId {
            connections.start(userId: userId)
        }
    }

    private func submitFeedback() {
        guard let userId = currentUser.userId, selectedRating > 0 else { return }
        isSubmitting = true

        // Combine chip selections + free text into improvements array
        var allImprovements = Array(selectedImprovements)
        let trimmed = additionalFeedback.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmed.isEmpty {
            allImprovements.append(trimmed)
        }

        Task {
            do {
                _ = try await convex.submitEventFeedback(
                    eventId: event._id,
                    userId: userId,
                    rating: selectedRating,
                    improvements: allImprovements,
                    wantToConnectWith: Array(selectedAttendees)
                )

                for attendeeId in selectedAttendees {
                    await ConnectionStore.shared.sendRequest(to: attendeeId, source: .eventAttendees)
                }

                AnalyticsService.shared.track(.feedbackSubmitted(eventId: event._id, rating: selectedRating))

                await MainActor.run {
                    isSubmitting = false
                    onComplete?()
                    dismiss()
                }
            } catch {
                print("Feedback submission failed: \(error)")
                await MainActor.run {
                    submitError = "Couldn't submit your feedback. Check your connection and try again."
                    isSubmitting = false
                }
            }
        }
    }
}
