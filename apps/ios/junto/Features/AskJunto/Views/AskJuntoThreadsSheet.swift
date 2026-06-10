//
//  AskJuntoThreadsSheet.swift
//  junto
//
//  Past Ask Junto conversations (askJuntoData:listThreads) shown as a right
//  side drawer behind the main view. Tapping a row reopens that thread; a
//  floating button at the bottom starts a fresh conversation.
//

import SwiftUI
import Combine

struct AskJuntoThreadsDrawer: View {
    let userId: String
    var onSelect: (String) -> Void
    var onNew: () -> Void

    @State private var threads: [AskJuntoThreadResponse] = []
    @State private var cancellable: AnyCancellable?

    private let convex = ConvexClientManager.shared

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            VStack(alignment: .leading, spacing: 0) {
                Text("Recent")
                    .font(.heading2)
                    .foregroundColor(.appPrimary)
                    .padding(.bottom, Spacing.xl)

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 0) {
                        if threads.isEmpty {
                            Text("No conversations yet")
                                .font(.body14)
                                .foregroundColor(.appSecondary)
                                .padding(.vertical, Spacing.md)
                        } else {
                            ForEach(threads) { thread in
                                Button { onSelect(thread.id) } label: {
                                    Text(thread.title)
                                        .font(.bodyLargeMedium)
                                        .foregroundColor(.appPrimary)
                                        .lineLimit(1)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .padding(.vertical, Spacing.sm)
                                        .contentShape(Rectangle())
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        // Leaves room so the last row clears the floating button.
                        Color.clear.frame(height: 80)
                    }
                }
            }
            .padding(.horizontal, Spacing.xl)
            .padding(.top, 60)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)

            // Floating "New conversation" button, on top of the list.
            Button(action: onNew) {
                HStack(spacing: Spacing.sm) {
                    Image("action.add")
                        .renderingMode(.template)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 16, height: 16)
                    Text("New")
                        .font(.bodyLargeSemibold)
                }
                .foregroundColor(.appOnAccent)
                .padding(.horizontal, Spacing.lg)
                .padding(.vertical, Spacing.md)
                .background(Color.appPrimary, in: Capsule())
                .shadow(color: .black.opacity(0.18), radius: 10, x: 0, y: 3)
            }
            .buttonStyle(.pressableScale(0.96))
            .padding(.leading, Spacing.xl)
            .padding(.bottom, 44)
        }
        .background(Color.appDrawerBackground)
        .ignoresSafeArea()
        .onAppear {
            cancellable = convex.subscribeAskJuntoThreads(userId: userId, limit: 50)
                .receive(on: DispatchQueue.main)
                .sink(
                    receiveCompletion: { _ in },
                    receiveValue: { threads = $0 }
                )
        }
        .onDisappear { cancellable?.cancel() }
    }
}
