//
//  MessageStatusLabel.swift
//  junto
//
//  The colored status label on a conversation row header (icon + text),
//  mirroring the Feed's type label. Request (blue) for an incoming request,
//  Requested (grey) while waiting on a sent request.
//

import SwiftUI

struct MessageStatusLabel: View {
    enum Kind {
        case request    // incoming message request
        case requested  // sent request, waiting on them
    }

    let kind: Kind

    var body: some View {
        HStack(spacing: Spacing.xxs) {
            Image(iconName)
                .renderingMode(.template)
                .resizable()
                .scaledToFit()
                .frame(width: 12, height: 12)

            Text(title)
                .font(.captionMedium)
        }
        .foregroundColor(color)
    }

    // MARK: - Per-kind config

    private var iconName: ImageResource {
        switch kind {
        case .request:   return .feedConnect
        case .requested: return .feedClock
        }
    }

    private var title: String {
        switch kind {
        case .request:   return "Request"
        case .requested: return "Requested"
        }
    }

    private var color: Color {
        switch kind {
        case .request:
            // Green — an incoming request is an opportunity to act on.
            return Color(UIColor { $0.userInterfaceStyle == .dark
                ? UIColor(red: 0.32, green: 0.82, blue: 0.55, alpha: 1.0)  // brighter green
                : UIColor(red: 0.09, green: 0.64, blue: 0.36, alpha: 1.0)  // #17A35C
            })
        case .requested:
            // Yellow/amber — sent and waiting on them.
            return Color(UIColor { $0.userInterfaceStyle == .dark
                ? UIColor(red: 0.96, green: 0.78, blue: 0.30, alpha: 1.0)  // brighter amber
                : UIColor(red: 0.72, green: 0.53, blue: 0.04, alpha: 1.0)  // #B8870A
            })
        }
    }
}

#Preview {
    VStack(alignment: .leading, spacing: Spacing.lg) {
        MessageStatusLabel(kind: .request)
        MessageStatusLabel(kind: .requested)
    }
    .padding()
    .background(Color.appBackground)
}
