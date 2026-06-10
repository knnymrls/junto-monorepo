//
//  AskJuntoMessageRow.swift
//  junto
//
//  One row in the Ask Junto conversation. User messages render as a right-
//  aligned grey bubble; assistant messages render the lead `say` line (typed out
//  smoothly while streaming via StreamingText), then the single `show` block,
//  then a tappable `followUp` line. While the assistant row is `.pending` with no
//  text yet, the loader lives on the input field (not here).
//

import SwiftUI

struct AskJuntoMessageRow: View {
    let message: AskJuntoMessageResponse
    /// True only for the message currently streaming — it types its text out.
    var isLive: Bool
    /// Non-nil only for the live pending message — shows card skeletons early.
    var pendingBlockHint: AskJuntoBlockHint?
    @ObservedObject var vm: AskJuntoViewModel
    var onOpenProfile: (UserResponse) -> Void
    var onOpenEvent: (EventWithRsvpResponse) -> Void
    var onOpenChat: (UserResponse) -> Void
    var onFollowUp: (String) -> Void
    var onAction: (AskJuntoActionKind, String) -> Void
    var profileZoomNamespace: Namespace.ID

    var body: some View {
        if message.isUser {
            userBubble
        } else {
            assistant
        }
    }

    // MARK: - User

    private var userBubble: some View {
        HStack {
            Spacer(minLength: 40)
            Text(message.text ?? "")
                .font(.bodyLarge)
                .foregroundColor(.appPrimary)
                .multilineTextAlignment(.leading)
                .padding(.horizontal, Spacing.lg)
                .padding(.vertical, Spacing.md)
                .background(Color.appSurfaceSecondary, in: RoundedRectangle(cornerRadius: 18))
        }
        .padding(.horizontal, Spacing.lg)
    }

    // MARK: - Assistant

    @ViewBuilder
    private var assistant: some View {
        if message.messageStatus == .error {
            HStack {
                Text(message.text ?? "Something went wrong. Try again.")
                    .font(.bodyLarge)
                    .foregroundColor(.appSecondary)
                Spacer(minLength: 40)
            }
            .padding(.horizontal, Spacing.lg)
        } else {
            assistantContent
        }
    }

    @ViewBuilder
    private var assistantContent: some View {
        let isComplete = message.messageStatus == .complete
        let blocks = message.parsedBlocks
        // While streaming we show the partial `text`; on completion the canonical
        // `say` from the parsed blocks (same string) — one stable view either way.
        let say = (isComplete ? blocks?.say : message.text) ?? message.text

        VStack(alignment: .leading, spacing: Spacing.md) {
            if let say, !say.isEmpty {
                StreamingText(text: say, animated: isLive)
                    .padding(.horizontal, Spacing.lg)
            }

            if isComplete, let show = blocks?.show {
                AskJuntoShowBlockView(
                    block: show,
                    vm: vm,
                    onOpenProfile: onOpenProfile,
                    onOpenEvent: onOpenEvent,
                    onOpenChat: onOpenChat,
                    onAction: onAction,
                    profileZoomNamespace: profileZoomNamespace
                )
            } else if let hint = pendingBlockHint {
                // Still fetching — show card skeletons early.
                skeletonStrip(for: hint)
            }

            if isComplete, let followUp = blocks?.followUp, !followUp.isEmpty {
                followUpLine(followUp)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    @ViewBuilder
    private func skeletonStrip(for hint: AskJuntoBlockHint) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Spacing.md) {
                ForEach(0..<3, id: \.self) { _ in
                    switch hint {
                    case .people: AskJuntoPersonCardSkeleton()
                    case .events: AskJuntoEventCardSkeleton()
                    }
                }
            }
            .padding(.horizontal, Spacing.lg)
        }
    }

    /// The follow-up renders as a normal assistant text line (not a bubble);
    /// tapping it pre-fills the composer.
    private func followUpLine(_ text: String) -> some View {
        // Just a suggestion — muted, taps to pre-fill the composer (doesn't send).
        Button { onFollowUp(text) } label: {
            HStack(alignment: .center, spacing: Spacing.xs) {
                Text(text)
                    .font(.bodyLargeMedium)
                    .foregroundColor(.appSecondary)
                    .multilineTextAlignment(.leading)
                Image("action.arrow")
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 14, height: 14)
                    .foregroundColor(.appSecondary)
                Spacer(minLength: 0)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, Spacing.lg)
        }
        .buttonStyle(.plain)
    }
}
