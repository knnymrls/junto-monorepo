//
//  ProfileHeaderView.swift
//  mkrs-world
//
//  Profile header — avatar, name, headline, major/program, skills, stats, action buttons
//

import SwiftUI

struct ProfileHeaderView: View {
    let user: UserResponse
    let connectionStatus: ConnectionStatus
    let connectionCount: Int
    let vouchCount: Int
    let hasVouched: Bool
    let isSelf: Bool
    let isLoadingStatus: Bool
    @Binding var isActioning: Bool
    @Binding var showVouchSheet: Bool
    var onConnect: () -> Void
    var onAccept: () -> Void
    @State private var showEditSheet = false

    var body: some View {
        VStack(spacing: Spacing.md) {
            AvatarView(
                avatarUrl: user.avatarUrl,
                name: user.name,
                size: 80
            )
            .padding(.top, Spacing.lg)

            Text(user.name)
                .font(.heading2)
                .foregroundColor(.appPrimary)

            if let headline = user.headline, !headline.isEmpty {
                Text(headline)
                    .font(.body14)
                    .foregroundColor(.appSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, Spacing.xxxl)
            }

            // Major / Program / Grad semester
            if let detailLine = userDetailLine, !detailLine.isEmpty {
                Text(detailLine)
                    .font(.bodySmall)
                    .foregroundColor(.appSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, Spacing.xxl)
            }

            // Skill chips
            if let skills = user.skills, !skills.isEmpty {
                FlowLayout(spacing: Spacing.sm) {
                    ForEach(Array(skills.prefix(5)), id: \.self) { skill in
                        Text(skill)
                            .font(.bodySmall)
                            .foregroundColor(.appPrimary)
                            .padding(.horizontal, Spacing.md)
                            .padding(.vertical, Spacing.xs)
                            .background(Color.appSurfaceSecondary)
                            .clipShape(Capsule())
                    }
                }
                .padding(.horizontal, Spacing.xxl)
            }

            // Stats row
            if connectionCount > 0 || vouchCount > 0 {
                HStack(spacing: Spacing.xs) {
                    if connectionCount > 0 {
                        Text("\(connectionCount) connection\(connectionCount == 1 ? "" : "s")")
                    }
                    if connectionCount > 0 && vouchCount > 0 {
                        Text("\u{00B7}")
                    }
                    if vouchCount > 0 {
                        Text("\(vouchCount) vouch\(vouchCount == 1 ? "" : "es")")
                    }
                }
                .font(.bodySmall)
                .foregroundColor(.appSecondary)
            }

            if !isLoadingStatus {
                actionButtons
                    .padding(.horizontal, Spacing.xxl)
                    .padding(.top, Spacing.xxs)
            }
        }
    }

    // MARK: - User Detail Line

    private var userDetailLine: String? {
        var parts: [String] = []

        if let majors = user.majors, !majors.isEmpty {
            let majorNames = majors.map { $0.majorId }
            parts.append(contentsOf: majorNames)
        }

        if let programs = user.programs, !programs.isEmpty {
            parts.append(contentsOf: programs)
        }

        if let grad = user.graduationSemester, !grad.isEmpty {
            parts.append(grad)
        }

        return parts.isEmpty ? nil : parts.joined(separator: " · ")
    }

    // MARK: - Action Buttons

    @ViewBuilder
    private var actionButtons: some View {
        if isSelf {
            HStack(spacing: Spacing.md) {
                Button(action: { showEditSheet = true }) {
                    Text("Edit Profile")
                        .font(.bodyMedium)
                        .foregroundColor(.appPrimary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, Spacing.xs + Spacing.xxs)
                        .overlay(
                            RoundedRectangle(cornerRadius: Radius.md)
                                .stroke(Color.appDivider, lineWidth: 1)
                        )
                }
                .buttonStyle(.plain)
                .sheet(isPresented: $showEditSheet) {
                    EditProfileSheet(user: user)
                }

                ShareLink(item: "Check out my profile on Junto! https://onjunto.com") {
                    Text("Share Profile")
                        .font(.bodyMedium)
                        .foregroundColor(.appPrimary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, Spacing.xs + Spacing.xxs)
                        .overlay(
                            RoundedRectangle(cornerRadius: Radius.md)
                                .stroke(Color.appDivider, lineWidth: 1)
                        )
                }
            }
        } else {
            connectionButton
        }
    }

    @ViewBuilder
    private var connectionButton: some View {
        switch connectionStatus {
        case .connected:
            HStack(spacing: Spacing.md) {
                Label("Connected", systemImage: "checkmark")
                    .font(.bodyLargeMedium)
                    .foregroundColor(.appSecondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, Spacing.xs + Spacing.xxs)
                    .overlay(
                        RoundedRectangle(cornerRadius: Radius.md)
                            .stroke(Color.appDivider, lineWidth: 1)
                    )

                if hasVouched {
                    Label("Vouched", systemImage: "checkmark.seal.fill")
                        .font(.bodyLargeMedium)
                        .foregroundColor(.appSecondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, Spacing.xs + Spacing.xxs)
                        .overlay(
                            RoundedRectangle(cornerRadius: Radius.md)
                                .stroke(Color.appDivider, lineWidth: 1)
                        )
                } else {
                    Button(action: { showVouchSheet = true }) {
                        Text("Vouch")
                            .font(.bodyLargeMedium)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, Spacing.xs + Spacing.xxs)
                            .background(Color.appPrimary)
                            .clipShape(RoundedRectangle(cornerRadius: Radius.md))
                    }
                    .buttonStyle(.plain)
                }
            }

        case .pendingSent:
            Text("Request Sent")
                .font(.bodyLargeMedium)
                .foregroundColor(.appSecondary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, Spacing.xs + Spacing.xxs)
                .overlay(
                    RoundedRectangle(cornerRadius: Radius.md)
                        .stroke(Color.appDivider, lineWidth: 1)
                )

        case .pendingReceived:
            Button(action: onAccept) {
                Text("Accept Request")
                    .font(.bodyLargeMedium)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, Spacing.xs + Spacing.xxs)
                    .background(Color.appPrimary)
                    .clipShape(RoundedRectangle(cornerRadius: Radius.md))
            }
            .buttonStyle(.plain)
            .disabled(isActioning)

        case .none:
            Button(action: onConnect) {
                Text("Connect")
                    .font(.bodyLargeMedium)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, Spacing.xs + Spacing.xxs)
                    .background(Color.appPrimary)
                    .clipShape(RoundedRectangle(cornerRadius: Radius.md))
            }
            .buttonStyle(.plain)
            .disabled(isActioning)
        }
    }
}
