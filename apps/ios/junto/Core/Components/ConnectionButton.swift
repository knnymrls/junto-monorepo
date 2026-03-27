//
//  ConnectionButton.swift
//  mkrs-world
//
//  Shared connection state button in two styles: full-width and compact capsule
//

import SwiftUI

struct ConnectionButton: View {
    let status: ConnectionStatus
    var isLoading: Bool = false
    var style: Style = .fullWidth
    var onConnect: () -> Void = {}
    var onAccept: () -> Void = {}

    enum Style {
        case fullWidth
        case compact
    }

    var body: some View {
        switch style {
        case .fullWidth:
            fullWidthButton
        case .compact:
            compactButton
        }
    }

    // MARK: - Full Width (Profile, PostDetail)

    @ViewBuilder
    private var fullWidthButton: some View {
        switch status {
        case .connected:
            Label("Connected", systemImage: "checkmark")
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(.appSecondary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, Spacing.lg)
                .overlay(
                    RoundedRectangle(cornerRadius: Radius.md)
                        .stroke(Color.appDivider, lineWidth: 1)
                )

        case .pendingSent:
            Text("Request Sent")
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(.appSecondary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, Spacing.lg)
                .overlay(
                    RoundedRectangle(cornerRadius: Radius.md)
                        .stroke(Color.appDivider, lineWidth: 1)
                )

        case .pendingReceived:
            Button(action: onAccept) {
                Text("Accept Request")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, Spacing.lg)
                    .background(Color.appPrimary)
                    .clipShape(RoundedRectangle(cornerRadius: Radius.md))
            }
            .buttonStyle(.plain)
            .disabled(isLoading)

        case .none:
            Button(action: onConnect) {
                Text("Connect")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, Spacing.lg)
                    .background(Color.appPrimary)
                    .clipShape(RoundedRectangle(cornerRadius: Radius.md))
            }
            .buttonStyle(.plain)
            .disabled(isLoading)
        }
    }

    // MARK: - Compact Capsule (Attendees, EventDetail)

    @ViewBuilder
    private var compactButton: some View {
        switch status {
        case .connected:
            Text("Connected")
                .font(.bodySmallSemibold)
                .foregroundColor(.appSecondary)
                .padding(.horizontal, Spacing.md)
                .padding(.vertical, Spacing.xs)
                .background(Color.appSurfaceSecondary)
                .clipShape(Capsule())

        case .pendingSent, .pendingReceived:
            Text("Pending")
                .font(.bodySmallSemibold)
                .foregroundColor(.appSecondary)
                .padding(.horizontal, Spacing.md)
                .padding(.vertical, Spacing.xs)
                .background(Color.appSurfaceSecondary)
                .clipShape(Capsule())

        case .none:
            Button(action: onConnect) {
                Text("Connect")
                    .font(.bodySmallSemibold)
                    .foregroundColor(.white)
                    .padding(.horizontal, Spacing.md)
                    .padding(.vertical, Spacing.xs)
                    .background(Color.appPrimary)
                    .clipShape(Capsule())
            }
            .disabled(isLoading)
        }
    }
}
