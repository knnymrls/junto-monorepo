//
//  AskJuntoBlockViews.swift
//  junto
//
//  Renders the single `show` content block of an assistant message. One block
//  per message — never a stack.
//
//  `people` and `opportunities` match the Figma horizontal card strips
//  (node 148-31). `draftAsk` / `draftIntro` / `action` are part of the backend
//  contract but are NOT in the current Figma — they're rendered here from the
//  existing design system (tokens + PrimaryButton) as a sensible default,
//  ready to be re-designed.
//

import SwiftUI

struct AskJuntoShowBlockView: View {
    let block: AskJuntoBlock
    @ObservedObject var vm: AskJuntoViewModel
    var onOpenProfile: (UserResponse) -> Void
    var onOpenEvent: (EventWithRsvpResponse) -> Void
    var onOpenChat: (UserResponse) -> Void
    var onAction: (AskJuntoActionKind, String) -> Void
    var profileZoomNamespace: Namespace.ID

    var body: some View {
        switch block {
        case .people(let userIds, _):
            peopleStrip(userIds: userIds)
        case .opportunities(let eventIds, _):
            eventsStrip(eventIds: eventIds)
        case .draftAsk(let title, let body):
            AskJuntoDraftAskCard(
                title: title,
                bodyText: body,
                onPost: { await vm.postAsk(title: title, body: $0) }
            )
            .padding(.horizontal, Spacing.lg)
        case .draftIntro(let targetUserId, let message):
            Group {
                if let target = vm.userProfiles[targetUserId] {
                    AskJuntoDraftIntroCard(
                        target: target,
                        message: message,
                        onSend: { await vm.sendIntro(to: targetUserId, message: $0) },
                        onViewMessage: { onOpenChat(target) }
                    )
                } else {
                    // Still fetching the target's profile.
                    AskJuntoDraftIntroSkeleton()
                }
            }
            .padding(.horizontal, Spacing.lg)
        case .action(let label, let kind):
            AskJuntoActionButton(label: label, kind: kind) { onAction(kind, label) }
                .padding(.horizontal, Spacing.lg)
        case .unknown:
            EmptyView()
        }
    }

    // MARK: - People strip

    @ViewBuilder
    private func peopleStrip(userIds: [String]) -> some View {
        // Each id renders its real card once loaded, a shimmer skeleton until then.
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Spacing.md) {
                ForEach(userIds, id: \.self) { id in
                    if let user = vm.userProfiles[id] {
                        AskJuntoPersonCard(
                            user: user,
                            connectionStatus: vm.connectionStatus(for: user._id),
                            isSelf: user._id == vm.currentUserId,
                            onTap: { onOpenProfile(user) },
                            onConnect: { vm.sendConnectionRequest(toUserId: user._id) },
                            profileZoomID: AnyHashable(user._id),
                            profileZoomNamespace: profileZoomNamespace
                        )
                    } else {
                        AskJuntoPersonCardSkeleton()
                    }
                }
            }
            .padding(.horizontal, Spacing.lg)
        }
    }

    // MARK: - Events strip

    @ViewBuilder
    private func eventsStrip(eventIds: [String]) -> some View {
        // Each id renders its real card once loaded, a shimmer skeleton until then.
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Spacing.md) {
                ForEach(eventIds, id: \.self) { id in
                    if let event = vm.events[id] {
                        AskJuntoEventCard(
                            event: event,
                            onTap: { onOpenEvent(event) },
                            isGoing: event.myStatus == "going"
                        )
                    } else {
                        AskJuntoEventCardSkeleton()
                    }
                }
            }
            .padding(.horizontal, Spacing.lg)
        }
    }
}

// MARK: - Card button (matches the app's in-card primary button —
// RoundedRectangle radius .md, appPrimary fill, .pressableScale).

struct AskJuntoCardButton: View {
    let title: String
    var icon: Image? = nil
    var isLoading: Bool = false
    var action: () -> Void

    var body: some View {
        Button(action: {
            guard !isLoading else { return }
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            action()
        }) {
            HStack(spacing: Spacing.xs) {
                if isLoading {
                    ProgressView().controlSize(.small).tint(.appOnAccent)
                } else {
                    if let icon {
                        icon
                            .renderingMode(.template)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 16, height: 16)
                    }
                    Text(title).font(.system(size: 15, weight: .medium))
                }
            }
            .foregroundColor(.appOnAccent)
            .frame(maxWidth: .infinity)
            .padding(.vertical, Spacing.md)
            .background(Color.appPrimary, in: RoundedRectangle(cornerRadius: Radius.md))
        }
        .buttonStyle(.pressableScale(0.96))
        .disabled(isLoading)
    }
}

// MARK: - Confirmed pill (matches the Discover event "Going" badge — green text
// on a light-green capsule). Used for Going / Sent / Posted.

struct AskJuntoConfirmedPill: View {
    let text: String
    /// White outline used when the pill sits over a thumbnail (Discover style).
    var bordered: Bool = false

    var body: some View {
        Text(text)
            .font(.system(size: 11, weight: .semibold))
            .foregroundColor(Color(hex: 0x2B8A3E))
            .padding(.horizontal, Spacing.sm)
            .padding(.vertical, 3)
            .background(Color(hex: 0xD3F9D8), in: Capsule())
            .overlay(bordered ? Capsule().stroke(Color.appSurface, lineWidth: 2) : nil)
    }
}

// MARK: - Done button (full-width green confirmation — still reads as a button,
// in the Discover "Going" green palette). Used for Sent / Posted.

struct AskJuntoDoneButton: View {
    let title: String
    var cornerRadius: CGFloat = Radius.md

    var body: some View {
        Text(title)
            .font(.system(size: 15, weight: .semibold))
            .foregroundColor(Color(hex: 0x2B8A3E))
            .frame(maxWidth: .infinity)
            .padding(.vertical, Spacing.md)
            .background(Color(hex: 0xD3F9D8), in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
    }
}

// MARK: - Draft Ask (no Figma yet — design-system default)

struct AskJuntoDraftAskCard: View {
    let title: String
    let bodyText: String
    var onPost: (String) async -> Bool

    @State private var editedTitle: String = ""
    @State private var editedBody: String = ""
    @State private var isPosting = false
    @State private var posted = false

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Label("Draft ask", systemImage: "square.and.pencil")
                .font(.captionMedium)
                .foregroundColor(.appSecondary)

            TextField("Title", text: $editedTitle)
                .font(.bodyLargeSemibold)
                .foregroundColor(.appPrimary)
                .textFieldStyle(.plain)
                .disabled(posted)

            TextField("What do you need?", text: $editedBody, axis: .vertical)
                .font(.bodyLarge)
                .foregroundColor(.appPrimary)
                .textFieldStyle(.plain)
                .lineLimit(1...6)
                .disabled(posted)

            if posted {
                AskJuntoDoneButton(title: "Posted")
            } else {
                AskJuntoCardButton(title: "Post ask", isLoading: isPosting) {
                    isPosting = true
                    Task {
                        let ok = await onPost(editedBody)
                        isPosting = false
                        if ok { withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) { posted = true } }
                    }
                }
            }
        }
        .padding(Spacing.lg)
        .background(Color.appSurfaceSecondary, in: RoundedRectangle(cornerRadius: Radius.xxl))
        .onAppear {
            if editedTitle.isEmpty { editedTitle = title }
            if editedBody.isEmpty { editedBody = bodyText }
        }
    }
}

// MARK: - Draft Intro (no Figma yet — design-system default)

struct AskJuntoDraftIntroCard: View {
    let target: UserResponse
    let message: String
    var onSend: (String) async -> Bool
    var onViewMessage: () -> Void

    @State private var editedMessage: String = ""
    @State private var sent = false
    @State private var editing = false
    @FocusState private var messageFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            // Target's avatar + name so it's clear who the intro is to.
            HStack(spacing: Spacing.sm) {
                AvatarView(avatarUrl: target.avatarUrl, name: target.name, size: 28)
                Text(sent ? "Sent to \(target.name)" : "Intro to \(target.name)")
                    .font(.bodyLargeSemibold)
                    .foregroundColor(.appPrimary)
                    .lineLimit(1)
            }

            if editing && !sent {
                TextField("Message", text: $editedMessage, axis: .vertical)
                    .font(.bodyLarge)
                    .foregroundColor(.appPrimary)
                    .textFieldStyle(.plain)
                    .lineLimit(1...6)
                    .focused($messageFocused)
            } else {
                Text(editedMessage)
                    .font(.bodyLarge)
                    .foregroundColor(.appPrimary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .fixedSize(horizontal: false, vertical: true)
            }

            if sent {
                // Once sent: a single full-width black button to view the message.
                Button(action: onViewMessage) {
                    Text("View message")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(.appOnAccent)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, Spacing.md)
                        .background(Color.appPrimary, in: RoundedRectangle(cornerRadius: Radius.xl, style: .continuous))
                }
                .buttonStyle(.pressableScale(0.97))
            } else {
                // Send + Edit — two equal-width buttons (copies EventDetailView).
                HStack(spacing: Spacing.sm) {
                    introButton(icon: Image(.actionSend), label: "Send intro", primary: true) { send() }
                    introButton(icon: Image(.actionEdit), label: "Edit", primary: false) {
                        editing = true
                        messageFocused = true
                    }
                }
            }
        }
        .padding(Spacing.lg)
        .background(Color.appSurfaceSecondary, in: RoundedRectangle(cornerRadius: Radius.xxl))
        .onAppear { if editedMessage.isEmpty { editedMessage = message } }
    }

    private func send() {
        guard !sent else { return }
        // Optimistic: flip to "sent" immediately (no loading) — but revert if
        // the send actually fails, or the card permanently claims a delivery
        // that never happened.
        messageFocused = false
        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) { sent = true; editing = false }
        Task {
            let succeeded = await onSend(editedMessage)
            if !succeeded {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) { sent = false }
            }
        }
    }

    // Two equal-width buttons, icon stacked above a 12pt label — copies
    // EventDetailView.actionButton (Radius.xl). Secondary has no border.
    private func introButton(icon: Image, label: String, primary: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: Spacing.xxs) {
                icon
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 16, height: 16)
                Text(label).font(.captionSemibold)
            }
            .foregroundColor(primary ? .appOnAccent : .appPrimary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, Spacing.md)
            .background(
                primary ? Color.appPrimary : Color.appSurface,
                in: RoundedRectangle(cornerRadius: Radius.xl, style: .continuous)
            )
        }
        .buttonStyle(.pressableScale(0.97))
    }
}

/// Shimmer placeholder for a draft-intro while the target's profile loads.
struct AskJuntoDraftIntroSkeleton: View {
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            HStack(spacing: Spacing.sm) {
                SkeletonCircle(size: 28)
                SkeletonShape(width: 120, height: 16)
            }
            SkeletonShape(height: 14)
            SkeletonShape(width: 180, height: 14)
            HStack(spacing: Spacing.sm) {
                SkeletonShape(height: 48, cornerRadius: Radius.xl)
                SkeletonShape(height: 48, cornerRadius: Radius.xl)
            }
        }
        .padding(Spacing.lg)
        .background(Color.appSurfaceSecondary, in: RoundedRectangle(cornerRadius: Radius.xxl))
    }
}

// MARK: - One-tap action (no Figma yet — design-system default)

struct AskJuntoActionButton: View {
    let label: String
    let kind: AskJuntoActionKind
    var onTap: () -> Void

    var body: some View {
        AskJuntoCardButton(title: label, action: onTap)
    }
}
