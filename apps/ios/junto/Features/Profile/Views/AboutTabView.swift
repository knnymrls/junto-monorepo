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

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xxl) {
            if hasCampusInfo {
                campusSection
            }

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

            if isEmpty {
                emptyState
            }
        }
        .padding(.horizontal, Spacing.lg)
        .padding(.bottom, Spacing.xxxl)
    }

    // MARK: - Campus

    private var hasCampusInfo: Bool {
        context?.university != nil
            || !(context?.majorNames.isEmpty ?? true)
            || !(user.graduationSemester ?? "").isEmpty
            || !(user.role ?? "").isEmpty
    }

    private var campusSection: some View {
        infoSection(title: "Campus") {
            VStack(alignment: .leading, spacing: Spacing.md) {
                if let university = context?.university {
                    campusRow(logoUrl: university.logoUrl) {
                        Text(university.name)
                            .font(.bodySemibold)
                            .foregroundColor(.appPrimary)
                    }
                }

                if let majors = context?.majorNames, !majors.isEmpty {
                    detailRow(label: roleLabel, value: majors.joined(separator: ", "))
                }

                if let grad = user.graduationSemester, !grad.isEmpty {
                    detailRow(label: "Graduates", value: grad)
                }
            }
        }
    }

    private var roleLabel: String {
        switch user.role?.lowercased() {
        case "alumni": return "Studied"
        case "faculty": return "Teaches"
        default: return "Studying"
        }
    }

    private func campusRow<Content: View>(logoUrl: String?, @ViewBuilder content: () -> Content) -> some View {
        HStack(spacing: Spacing.sm) {
            if let logoUrl, let url = URL(string: logoUrl) {
                CachedAsyncImage(url: url) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                } placeholder: {
                    Color.clear
                }
                .frame(width: 20, height: 20)
                .clipShape(RoundedRectangle(cornerRadius: Radius.xs, style: .continuous))
            }
            content()
        }
    }

    private func detailRow(label: String, value: String) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: Spacing.sm) {
            Text(label)
                .font(.body14)
                .foregroundColor(.appSecondary)

            Text(value)
                .font(.body14)
                .foregroundColor(.appPrimary)
                .fixedSize(horizontal: false, vertical: true)
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
        !hasCampusInfo &&
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
