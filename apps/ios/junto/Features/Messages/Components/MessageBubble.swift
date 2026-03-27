//
//  MessageBubble.swift
//  mkrs-world
//
//  Sent/received message bubble with read receipts
//

import SwiftUI

struct MessageBubble: View {
    let message: MessageResponse
    let isSent: Bool

    var body: some View {
        HStack {
            if isSent { Spacer(minLength: 60) }

            VStack(alignment: isSent ? .trailing : .leading, spacing: Spacing.xxxs) {
                if let gifUrlString = message.gifUrl, let gifUrl = URL(string: gifUrlString) {
                    GifPlayerView(url: gifUrl)
                        .frame(maxWidth: 240, maxHeight: 200)
                        .clipShape(RoundedRectangle(cornerRadius: Radius.xxl))
                } else {
                    Text(message.content)
                        .font(.bodyLarge)
                        .foregroundColor(isSent ? .white : .appPrimary)
                        .padding(.horizontal, Spacing.md)
                        .padding(.vertical, Spacing.sm)
                        .background(isSent ? Color.appPrimary : Color.appSurfaceSecondary)
                        .clipShape(RoundedRectangle(cornerRadius: Radius.xxl))
                }

                HStack(spacing: Spacing.xxxs) {
                    Text(timeString(from: message.createdDate))
                        .font(.micro)
                        .foregroundColor(.appSecondary)

                    if isSent {
                        readReceipt
                    }
                }
            }

            if !isSent { Spacer(minLength: 60) }
        }
        .padding(.vertical, 1)
    }

    @ViewBuilder
    private var readReceipt: some View {
        if message.isRead {
            HStack(spacing: -4) {
                Image(systemName: "checkmark")
                    .font(.microBold)
                Image(systemName: "checkmark")
                    .font(.microBold)
            }
            .foregroundColor(.appSecondary)
        } else {
            Image(systemName: "checkmark")
                .font(.microBold)
                .foregroundColor(.appSecondary)
        }
    }

    private func timeString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: date)
    }
}
