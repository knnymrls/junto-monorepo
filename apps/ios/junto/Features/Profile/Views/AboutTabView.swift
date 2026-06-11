//
//  AboutTabView.swift
//  junto
//
//  About tab — minimal: what they're looking for, skills, programs, social
//  links, member-since. "Can help with" is implied by skills; work lives in
//  the Work tab.
//

import SwiftUI

struct AboutTabView: View {
    let user: UserResponse
    var context: ProfileContextResponse? = nil
    var isSelf: Bool = false
    var onEdit: (() -> Void)? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xxl) {
            lookingForSection

            if let skills = context?.skillNames, !skills.isEmpty {
                infoSection(title: "Skills") {
                    FlowLayout(spacing: Spacing.sm) {
                        ForEach(skills, id: \.self) { skill in
                            skillPill(skill)
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

    // MARK: - Looking For

    @ViewBuilder
    private var lookingForSection: some View {
        let looking = (user.lookingFor ?? "").trimmingCharacters(in: .whitespacesAndNewlines)

        if !looking.isEmpty {
            HStack(alignment: .top, spacing: Spacing.md) {
                Image(.contentLookingFill)
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 16, height: 16)
                    .foregroundColor(.appPrimary)
                    .frame(width: 32, height: 32)
                    .background(Color.appSurfaceSecondary)
                    .clipShape(Circle())

                VStack(alignment: .leading, spacing: Spacing.xxxs) {
                    Text("Looking for")
                        .font(.bodySemibold)
                        .foregroundColor(.appPrimary)

                    Text(looking)
                        .font(.body14)
                        .foregroundColor(.appSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        } else if isSelf, let onEdit {
            Button(action: onEdit) {
                HStack(spacing: Spacing.md) {
                    Image(.contentLookingFill)
                        .renderingMode(.template)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 16, height: 16)
                        .foregroundColor(.appSecondary)
                        .frame(width: 32, height: 32)
                        .background(Color.appSurfaceSecondary)
                        .clipShape(Circle())

                    VStack(alignment: .leading, spacing: Spacing.xxxs) {
                        Text("What are you looking for?")
                            .font(.bodySemibold)
                            .foregroundColor(.appPrimary)
                        Text("Junto matches you with people who can help")
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

    /// Skill pill — the skill's maker category drives the icon and its brand
    /// color, same vocabulary as Discover's category chips.
    private func skillPill(_ skill: String) -> some View {
        let category = SkillCategory.match(skill)
        return HStack(spacing: Spacing.xxs) {
            if let category {
                Image(category.icon)
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 14, height: 14)
                    .foregroundColor(category.color)
            }

            Text(skill)
                .font(.bodyMedium)
                .foregroundColor(.appPrimary)
        }
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
                socialLinkButton(icon: .linkGithub, url: url, label: "GitHub")
            }
            if let linkedin = user.socialLinks?.linkedin, let url = URL(string: linkedin) {
                socialLinkButton(icon: .linkLinkedin, url: url, label: "LinkedIn")
            }
            if let twitter = user.socialLinks?.twitter, let url = URL(string: twitter) {
                socialLinkButton(icon: .linkX, url: url, label: "X")
            }
            if let instagram = user.socialLinks?.instagram, let url = URL(string: instagram) {
                socialLinkButton(icon: .linkInstagram, url: url, label: "Instagram")
            }
            if let website = user.socialLinks?.website, let url = URL(string: website) {
                socialLinkButton(icon: .linkWebsite, url: url, label: "Website")
            }
        }
    }

    // Solid Streamline Flex brand glyphs — icons on a background container
    // are always the solid set.
    private func socialLinkButton(icon: ImageResource, url: URL, label: String) -> some View {
        Link(destination: url) {
            VStack(spacing: Spacing.xxs) {
                Image(icon)
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 18, height: 18)
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
        (user.lookingFor ?? "").isEmpty &&
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
