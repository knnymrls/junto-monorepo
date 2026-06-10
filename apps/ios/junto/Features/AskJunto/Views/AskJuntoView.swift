//
//  AskJuntoView.swift
//  junto
//
//  Ask Junto — the AI assistant on the center tab. Owns its own header (avatar +
//  title + history), the empty "Hey there" state (Figma 148-1109), the live
//  conversation (Figma 148-31), and the bottom composer (148-1218).
//
//  Send flow: the first message creates a thread, then runs the agent. The user
//  message + a pending assistant row arrive over the `getMessages` subscription
//  and render reactively; the pending row shows the "Searching..." pill until
//  the assistant message completes.
//
//  Keyboard: tapping Send drops focus (collapses the keyboard) and it stays
//  collapsed until the input is tapped again — an explicit design requirement.
//

import SwiftUI
import UIKit

struct AskJuntoView: View {
    /// Tapping the header avatar (mirrors the other tabs — toggles the side menu).
    var onProfileTap: (() -> Void)? = nil
    /// Tapping the inbox icon — opens the conversations drawer (owned by TabBarView
    /// so the whole content + tab bar slide, like the Feed).
    var onOpenConversations: () -> Void = {}

    @EnvironmentObject private var currentUser: CurrentUserManager
    @Environment(\.tabBarVisible) private var tabBarVisible
    @StateObject private var vm = AskJuntoViewModel()

    @State private var inputFocused = false
    @State private var keyboardHeight: CGFloat = 0
    @State private var selectedProfile: UserResponse?
    @State private var selectedEvent: EventWithRsvpResponse?
    @State private var selectedChatUser: UserResponse?

    @Namespace private var profileZoom
    @Namespace private var eventZoom

    private let bottomAnchorId = "askjunto-bottom"

    var body: some View {
        VStack(spacing: 0) {
                header

                ZStack(alignment: .bottom) {
                    Group {
                        if vm.displayMessages.isEmpty {
                            emptyState
                        } else {
                            messageList
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)

                    AskJuntoComposer(
                        text: $vm.draft,
                        thinkingText: vm.isThinking ? vm.thinkingStep : nil,
                        focused: $inputFocused,
                        onSend: send
                    )
                    // Idle: fills the width. Thinking: the pill hugs its content
                    // (spinner + step) and stays centered.
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.horizontal, Spacing.md)
                    .padding(.bottom, composerBottomPadding)
                }
            }
        .background(Color.appBackground)
        .fullScreenCover(item: $selectedProfile) { user in
            ProfileView(user: user)
                .zoomDestination(id: user._id, in: profileZoom)
        }
        .fullScreenCover(item: $selectedEvent) { event in
            EventDetailView(event: event)
                .zoomDestination(id: event._id, in: eventZoom)
        }
        .fullScreenCover(item: $selectedChatUser) { user in
            if let uid = currentUser.userId {
                ChatDetailView(conversationId: nil, otherParticipant: user, currentUserId: uid)
                    .environmentObject(currentUser)
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillShowNotification)) { notification in
            if let frame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect {
                withAnimation(.easeOut(duration: 0.25)) {
                    keyboardHeight = frame.height
                    tabBarVisible.wrappedValue = false
                }
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)) { _ in
            withAnimation(.easeOut(duration: 0.25)) {
                keyboardHeight = 0
                tabBarVisible.wrappedValue = true
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .askJuntoOpenThread)) { note in
            if let id = note.object as? String { vm.openThread(id) }
        }
        .onReceive(NotificationCenter.default.publisher(for: .askJuntoNewConversation)) { _ in
            vm.startNewConversation()
        }
        .onDisappear { tabBarVisible.wrappedValue = true }
        .task {
            if let uid = currentUser.userId {
                await vm.bootstrap(userId: uid)
            }
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack(spacing: Spacing.sm) {
            Button { onProfileTap?() } label: {
                AvatarView(
                    avatarUrl: currentUser.user?.avatarUrl,
                    name: currentUser.user?.name ?? "?",
                    size: 40
                )
            }
            .buttonStyle(.plain)

            // Screen title — SF Pro semibold 24 (heading1), matching BrandTopNav's
            // .title treatment (e.g. "Discover"). Wordmark Bricolage is Feed-only.
            Text("Ask Junto")
                .font(.heading1)
                .foregroundColor(.appPrimary)

            Spacer()

            // 28pt icon in a 40pt tap target — matches BrandTopNav (Figma 140:412).
            Button { onOpenConversations() } label: {
                Image("nav.inbox")
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 28, height: 28)
                    .foregroundColor(.appPrimary)
                    .frame(width: 40, height: 40)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.pressableScale(0.9))
        }
        .padding(.horizontal, Spacing.lg)
        .padding(.bottom, Spacing.sm)
        // White bar fills up through the status bar (matches BrandTopNav).
        .background(Color.appSurface.ignoresSafeArea(edges: .top))
    }

    // MARK: - Empty state (Figma 148-1109)

    private var emptyState: some View {
        VStack(spacing: Spacing.lg) {
            Spacer()
            Image("tab.junto")
                .renderingMode(.template)
                .resizable()
                .scaledToFit()
                .frame(width: 48, height: 48)
                .foregroundColor(.appPrimary)
            Text("Hey there, \(currentUser.user?.name ?? "there")")
                .font(.system(size: 24, weight: .medium))
                .foregroundColor(.appPrimary)
                .multilineTextAlignment(.center)
            Spacer()
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.horizontal, Spacing.lg)
    }

    // MARK: - Conversation (Figma 148-31)

    private var messageList: some View {
        ScrollViewReader { proxy in
            ScrollView(showsIndicators: false) {
                LazyVStack(alignment: .leading, spacing: Spacing.lg) {
                    Color.clear.frame(height: Spacing.sm)

                    ForEach(vm.displayMessages) { message in
                        AskJuntoMessageRow(
                            message: message,
                            isLive: message.id == vm.liveAssistantId,
                            pendingBlockHint: (message.id == vm.liveAssistantId && message.messageStatus == .pending) ? vm.pendingBlockHint : nil,
                            vm: vm,
                            onOpenProfile: { selectedProfile = $0 },
                            onOpenEvent: { selectedEvent = $0 },
                            onOpenChat: { selectedChatUser = $0 },
                            onFollowUp: handleFollowUp,
                            onAction: handleAction,
                            profileZoomNamespace: profileZoom
                        )
                        .id(message.id)
                    }

                    // Bottom spacer keeps the last message clear of the composer —
                    // grows with the keyboard so you can scroll to the very bottom.
                    Color.clear
                        .frame(height: bottomSpacerHeight)
                        .id(bottomAnchorId)
                }
            }
            // Soft fade at the top + bottom edges (matches Home/Discover).
            .scrollEdgeFade(top: true, bottom: true)
            .onChange(of: vm.displayMessages) { _, _ in scrollToBottom(proxy) }
            .onChange(of: vm.liveAssistantId) { _, _ in scrollToBottom(proxy) }
            .onChange(of: keyboardHeight) { _, _ in
                // Scroll now and again after the keyboard + spacer settle.
                scrollToBottom(proxy)
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { scrollToBottom(proxy) }
            }
            .onChange(of: inputFocused) { _, focused in
                if focused {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { scrollToBottom(proxy) }
                }
            }
        }
    }

    private func scrollToBottom(_ proxy: ScrollViewProxy) {
        withAnimation(.easeOut(duration: 0.25)) {
            proxy.scrollTo(bottomAnchorId, anchor: .bottom)
        }
    }

    // MARK: - Actions

    private func send() {
        let text = vm.draft
        vm.send(text)
        inputFocused = false
    }

    /// Tapping a follow-up chip pre-fills the composer (user can edit or send).
    private func handleFollowUp(_ text: String) {
        vm.draft = text
        inputFocused = true
    }

    /// `action` blocks aren't in Figma yet — pre-fill the composer with the
    /// label so the user can act through the agent until they're designed.
    private func handleAction(_ kind: AskJuntoActionKind, _ label: String) {
        vm.draft = label
        inputFocused = true
    }

    // MARK: - Layout helpers

    private var composerBottomPadding: CGFloat {
        keyboardHeight > 0
            ? keyboardHeight - bottomSafeArea + Spacing.sm
            : 72
    }

    /// Trailing scroll space — clears the composer in both states, and grows with
    /// the keyboard so the last message can be scrolled above it.
    private var bottomSpacerHeight: CGFloat {
        keyboardHeight > 0 ? composerBottomPadding + 64 : 180
    }

    private var bottomSafeArea: CGFloat {
        let scenes = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
        return scenes.first?.windows.first?.safeAreaInsets.bottom ?? 34
    }
}
