//
//  AboutTabView.swift
//  junto
//
//  About tab — campus details (resolved names, never raw IDs), skills,
//  programs, social links, and member-since. The story fields (building /
//  can help with / looking for) live in the profile hero's maker card.
//

import SwiftUI

struct AboutTabView: View {
    let user: UserResponse
    var context: ProfileContextResponse? = nil
    var isSelf: Bool = false
    var onEdit: (() -> Void)? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xxl) {
            storySections

            if let skills = context?.skillNames, !skills.isEmpty {
                infoSection(title: "Skills") {
                    FlowLayout(spacing: Spacing.sm) {
                        ForEach(skills, id: \.self) { skill in
                            pillView(skill)
                        }
                    }
                }
            }

            if let programs = user.programs, !programs.isEmpty {
                infoSection(title: "Programs") {
                    FlowLayout(spacing: Spacing.sm) {
                        ForEach(programs, id: \.self) { program in
                            pillView(program)
                        }
                    }
                }
            }

            if hasSocialLinks {
                infoSection(title: "Links") {
                    socialLinksRow
                }
            }

            memberSince

            if isEmpty && !isSelf {
                emptyState
            }
        }
        .padding(.horizontal, Spacing.lg)
        .padding(.bottom, Spacing.xxxl)
    }

    // MARK: - Story (Building / Can help with / Looking for)

    private var hasStory: Bool {
        !(user.currentProject ?? "").isEmpty
            || !(user.canHelpWith ?? "").isEmpty
            || !(user.lookingFor ?? "").isEmpty
    }

    @ViewBuilder
    private var storySections: some View {
        if hasStory {
            if let building = user.currentProject, !building.isEmpty {
                storySection(icon: "content.update", title: "Building", text: building)
            }
            if let help = user.canHelpWith, !help.isEmpty {
                storySection(icon: "content.sharing", title: "Can help with", text: help)
            }
            if let looking = user.lookingFor, !looking.isEmpty {
                storySection(icon: "content.looking", title: "Looking for", text: looking)
            }
        } else if isSelf, let onEdit {
            Button(action: onEdit) {
                HStack(spacing: Spacing.md) {
                    Image("content.sharing")
                        .renderingMode(.template)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 16, height: 16)
                        .foregroundColor(.appSecondary)
                        .frame(width: 32, height: 32)
                        .background(Color.appSurfaceSecondary)
                        .clipShape(Circle())

                    VStack(alignment: .leading, spacing: Spacing.xxxs) {
                        Text("Add your story")
                            .font(.bodySemibold)
                            .foregroundColor(.appPrimary)
                        Text("What you're building and what you can help with")
                            .font(.bodySmall)
                            .foregroundColor(.appSecondary)
                    }

                    Spacer(minLength: 0)

                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.appSecondary)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.pressableScale(0.98))
        }
    }

    private func storySection(icon: String, title: String, text: String) -> some View {
        HStack(alignment: .top, spacing: Spacing.md) {
            Image(icon)
                .renderingMode(.template)
                .resizable()
                .scaledToFit()
                .frame(width: 16, height: 16)
                .foregroundColor(.appPrimary)
                .frame(width: 32, height: 32)
                .background(Color.appSurfaceSecondary)
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: Spacing.xxxs) {
                Text(title)
                    .font(.bodySemibold)
                    .foregroundColor(.appPrimary)

                Text(text)
                    .font(.body14)
                    .foregroundColor(.appSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    // MARK: - Section Builder

    private func infoSection<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text(title.uppercased())
                .font(.captionSmallSemibold)
                .foregroundColor(.appSecondary)
            content()
        }
    }

    // Tag treatment matches the event detail page's tag pills — Radius.md
    // continuous corners, md/sm padding.
    private func pillView(_ text: String) -> some View {
        Text(text)
            .font(.bodyMedium)
            .foregroundColor(.appPrimary)
            .padding(.horizontal, Spacing.md)
            .padding(.vertical, Spacing.sm)
            .background(Color.appSurfaceSecondary)
            .clipShape(RoundedRectangle(cornerRadius: Radius.md, style: .continuous))
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

    // MARK: - Member Since

    private var memberSince: some View {
        Text("On Junto since \(joinedText)")
            .font(.bodySmall)
            .foregroundColor(.appSecondary)
    }

    private var joinedText: String {
        let date = Date(timeIntervalSince1970: user.createdAt / 1000)
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: date)
    }

    // MARK: - Empty State

    private var isEmpty: Bool {
        !hasStory &&
        (context?.skillNames ?? []).isEmpty &&
        (user.programs ?? []).isEmpty &&
        !hasSocialLinks
    }

    private var emptyState: some View {
        VStack(spacing: Spacing.sm) {
            Text("No info yet")
                .font(.bodyLargeMedium)
                .foregroundColor(.appSecondary)
            Text("This maker hasn't added their details.")
                .font(.body14)
                .foregroundColor(.appSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Spacing.huge)
    }
}
