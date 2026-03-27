//
//  AboutTabView.swift
//  mkrs-world
//
//  About tab — bio, current project, looking for, can help with, skills, interests, social links
//

import SwiftUI

struct AboutTabView: View {
    let user: UserResponse

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xl) {
            if let currentProject = user.currentProject, !currentProject.isEmpty {
                infoSection(title: "Current Project", icon: "hammer.fill") {
                    Text(currentProject)
                        .font(.body14)
                        .foregroundColor(.appPrimary)
                }
            }

            if let lookingFor = user.lookingFor, !lookingFor.isEmpty {
                infoSection(title: "Looking For", icon: "magnifyingglass") {
                    Text(lookingFor)
                        .font(.body14)
                        .foregroundColor(.appPrimary)
                }
            }

            if let canHelpWith = user.canHelpWith, !canHelpWith.isEmpty {
                infoSection(title: "Can Help With", icon: "hand.raised.fill") {
                    Text(canHelpWith)
                        .font(.body14)
                        .foregroundColor(.appPrimary)
                }
            }

            if let skills = user.skills, !skills.isEmpty {
                infoSection(title: "Skills") {
                    FlowLayout(spacing: Spacing.sm) {
                        ForEach(skills, id: \.self) { skill in
                            pillView(skill)
                        }
                    }
                }
            }

            if let interests = user.interests, !interests.isEmpty {
                infoSection(title: "Interests") {
                    FlowLayout(spacing: Spacing.sm) {
                        ForEach(interests, id: \.self) { interest in
                            pillView(interest)
                        }
                    }
                }
            }

            if hasSocialLinks {
                infoSection(title: "Links") {
                    socialLinksRow
                }
            }

            if isEmpty {
                emptyState
            }
        }
        .padding(.horizontal, Spacing.lg)
        .padding(.bottom, Spacing.xxxl)
    }

    // MARK: - Section Builder

    private func infoSection<Content: View>(title: String, icon: String? = nil, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            HStack(spacing: Spacing.xs) {
                if let icon {
                    Image(systemName: icon)
                        .font(.caption12)
                        .foregroundColor(.appSecondary)
                }
                Text(title)
                    .font(.bodySmallSemibold)
                    .foregroundColor(.appSecondary)
                    .textCase(.uppercase)
            }
            content()
        }
    }

    // MARK: - Pill View

    private func pillView(_ text: String) -> some View {
        Text(text)
            .font(.bodySmall)
            .foregroundColor(.appPrimary)
            .padding(.horizontal, Spacing.md)
            .padding(.vertical, Spacing.xs)
            .background(Color.appSurfaceSecondary)
            .clipShape(Capsule())
    }

    // MARK: - Social Links

    private var hasSocialLinks: Bool {
        guard let links = user.socialLinks else { return false }
        return links.github != nil || links.linkedin != nil || links.twitter != nil || links.instagram != nil || links.website != nil
    }

    private var socialLinksRow: some View {
        HStack(spacing: Spacing.lg) {
            if let github = user.socialLinks?.github, let url = URL(string: github) {
                socialLinkButton(icon: "chevron.left.forwardslash.chevron.right", url: url, label: "GitHub")
            }
            if let linkedin = user.socialLinks?.linkedin, let url = URL(string: linkedin) {
                socialLinkButton(icon: "link", url: url, label: "LinkedIn")
            }
            if let twitter = user.socialLinks?.twitter, let url = URL(string: twitter) {
                socialLinkButton(icon: "at", url: url, label: "X")
            }
            if let instagram = user.socialLinks?.instagram, let url = URL(string: instagram) {
                socialLinkButton(icon: "camera", url: url, label: "Instagram")
            }
            if let website = user.socialLinks?.website, let url = URL(string: website) {
                socialLinkButton(icon: "globe", url: url, label: "Website")
            }
        }
    }

    private func socialLinkButton(icon: String, url: URL, label: String) -> some View {
        Link(destination: url) {
            VStack(spacing: Spacing.xxs) {
                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundColor(.appPrimary)
                    .frame(width: 40, height: 40)
                    .background(Color.appSurfaceSecondary)
                    .clipShape(Circle())
                Text(label)
                    .font(.captionSmallSemibold)
                    .foregroundColor(.appSecondary)
            }
        }
    }

    // MARK: - Empty State

    private var isEmpty: Bool {
        user.currentProject == nil &&
        user.lookingFor == nil &&
        user.canHelpWith == nil &&
        (user.skills ?? []).isEmpty &&
        (user.interests ?? []).isEmpty &&
        !hasSocialLinks
    }

    private var emptyState: some View {
        VStack(spacing: Spacing.sm) {
            Text("No info yet")
                .font(.bodyLargeMedium)
                .foregroundColor(.appSecondary)
            Text("This user hasn't added their details.")
                .font(.body14)
                .foregroundColor(.appSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Spacing.huge)
    }
}
