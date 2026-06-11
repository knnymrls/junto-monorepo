//
//  EditProfileSheet.swift
//  junto
//
//  Edit Profile — photo, identity (name + headline), the maker story
//  (building / can help with / looking for), social links, and an entry into
//  the portfolio layout editor. Local-first; everything syncs on Save.
//

import SwiftUI

struct EditProfileSheet: View {
    let user: UserResponse
    var onSaved: ((UserResponse) -> Void)? = nil

    @Environment(\.dismiss) private var dismiss

    // Photo
    @State private var newAvatar: UIImage?

    // Identity
    @State private var name: String
    @State private var headline: String

    // Maker story
    @State private var lookingFor: String

    // Links
    @State private var linkedin: String
    @State private var instagram: String
    @State private var twitter: String
    @State private var github: String
    @State private var website: String

    @State private var isSaving = false
    @State private var errorMessage: String?

    init(user: UserResponse, onSaved: ((UserResponse) -> Void)? = nil) {
        self.user = user
        self.onSaved = onSaved
        _name = State(initialValue: user.name)
        _headline = State(initialValue: user.headline ?? "")
        _lookingFor = State(initialValue: user.lookingFor ?? "")
        _linkedin = State(initialValue: user.socialLinks?.linkedin ?? "")
        _instagram = State(initialValue: user.socialLinks?.instagram ?? "")
        _twitter = State(initialValue: user.socialLinks?.twitter ?? "")
        _github = State(initialValue: user.socialLinks?.github ?? "")
        _website = State(initialValue: user.socialLinks?.website ?? "")
    }

    private var trimmedName: String {
        name.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var canSave: Bool {
        !trimmedName.isEmpty && !isSaving
    }

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: Spacing.xxl) {
                    photoSection

                    identitySection

                    storySection

                    linksSection

                    portfolioSection

                    if let errorMessage {
                        Text(errorMessage)
                            .font(.bodySmall)
                            .foregroundColor(.appError)
                            .frame(maxWidth: .infinity, alignment: .center)
                    }

                    Color.clear.frame(height: Spacing.huge)
                }
                .padding(.horizontal, Spacing.lg)
                .padding(.top, Spacing.lg)
            }
            .scrollDismissesKeyboard(.interactively)
            .background(Color.appBackground)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .font(.body14)
                        .foregroundColor(.appSecondary)
                }

                ToolbarItem(placement: .principal) {
                    Text("Edit Profile")
                        .font(.bodyLargeSemibold)
                        .foregroundColor(.appPrimary)
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button(action: save) {
                        if isSaving {
                            ProgressView()
                                .tint(.appOnAccent)
                                .padding(.horizontal, Spacing.lg)
                                .padding(.vertical, Spacing.xs)
                                .background(Capsule().fill(Color.appAccent))
                        } else {
                            Text("Save")
                                .font(.bodySemibold)
                                .foregroundColor(.appOnAccent)
                                .padding(.horizontal, Spacing.lg)
                                .padding(.vertical, Spacing.xs)
                                .background(Capsule().fill(Color.appAccent))
                        }
                    }
                    .buttonStyle(.pressableScale(0.95))
                    .disabled(!canSave)
                    .opacity(canSave ? 1 : 0.4)
                }
            }
        }
        .presentationDragIndicator(.visible)
        .interactiveDismissDisabled(isSaving)
    }

    // MARK: - Photo

    private var photoSection: some View {
        VStack(spacing: Spacing.sm) {
            ProfilePhotoPicker(
                image: $newAvatar,
                existingAvatarUrl: user.avatarUrl,
                existingName: user.name,
                size: 96
            )

            Text("Change photo")
                .font(.bodySmallMedium)
                .foregroundColor(.appSecondary)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Identity

    private var identitySection: some View {
        VStack(alignment: .leading, spacing: Spacing.lg) {
            JuntoTextField(
                placeholder: "Your name",
                text: $name,
                label: "Name",
                autocapitalization: .words
            )

            JuntoTextArea(
                placeholder: "Introduce yourself as you would at a party, keep it short",
                text: $headline,
                label: "Headline",
                characterLimit: 50
            )
        }
    }

    // MARK: - Maker Story

    private var storySection: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            JuntoTextArea(
                placeholder: "e.g. a technical co-founder, beta testers, an intro to UNL faculty",
                text: $lookingFor,
                label: "What you're looking for",
                characterLimit: 200
            )

            Text("Junto matches you with people who can help.")
                .font(.caption12)
                .foregroundColor(.appSecondary)
        }
    }

    // MARK: - Links

    private var linksSection: some View {
        VStack(alignment: .leading, spacing: Spacing.lg) {
            sectionHeader("Links")

            linkField("LinkedIn", icon: "link", text: $linkedin)
            linkField("Instagram", icon: "camera", text: $instagram)
            linkField("X", icon: "at", text: $twitter)
            linkField("GitHub", icon: "chevron.left.forwardslash.chevron.right", text: $github)
            linkField("Website", icon: "globe", text: $website)
        }
    }

    private func linkField(_ label: String, icon: String, text: Binding<String>) -> some View {
        JuntoTextField(
            placeholder: label,
            text: text,
            icon: Image(systemName: icon),
            keyboardType: .URL,
            autocapitalization: .never
        )
    }

    // MARK: - Portfolio

    private var portfolioSection: some View {
        VStack(alignment: .leading, spacing: Spacing.lg) {
            sectionHeader("Portfolio")

            NavigationLink {
                WidgetLayoutEditor(userId: user._id)
            } label: {
                HStack(spacing: Spacing.md) {
                    Image(systemName: "square.grid.2x2")
                        .font(.system(size: 16))
                        .foregroundColor(.appPrimary)
                        .frame(width: 32, height: 32)
                        .background(Color.appSurfaceSecondary)
                        .clipShape(Circle())

                    VStack(alignment: .leading, spacing: Spacing.xxxs) {
                        Text("Edit widgets")
                            .font(.bodySemibold)
                            .foregroundColor(.appPrimary)
                        Text("Add, remove, and rearrange your work")
                            .font(.bodySmall)
                            .foregroundColor(.appSecondary)
                    }

                    Spacer(minLength: 0)

                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.appSecondary)
                }
                .padding(Spacing.md)
                .background(Color.appSurface)
                .clipShape(RoundedRectangle(cornerRadius: Radius.xxl, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: Radius.xxl, style: .continuous)
                        .strokeBorder(Color.appBorder, lineWidth: 1)
                )
                .contentShape(RoundedRectangle(cornerRadius: Radius.xxl, style: .continuous))
            }
            .buttonStyle(.pressableScale(0.98))
        }
    }

    private func sectionHeader(_ title: String) -> some View {
        Text(title.uppercased())
            .font(.captionSmallSemibold)
            .foregroundColor(.appSecondary)
    }

    // MARK: - Save

    /// Empty link fields become nil (dropped from the saved object); bare
    /// domains get an https:// prefix so they open as real links.
    private func normalizedLink(_ raw: String) -> String? {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        if trimmed.lowercased().hasPrefix("http://") || trimmed.lowercased().hasPrefix("https://") {
            return trimmed
        }
        return "https://" + trimmed
    }

    private func save() {
        guard canSave else { return }
        isSaving = true
        errorMessage = nil
        UIImpactFeedbackGenerator(style: .light).impactOccurred()

        Task {
            do {
                // Upload the new photo first (if picked) and resolve a real URL.
                var avatarUrl: String?
                if let newAvatar {
                    let storageId = try await ConvexClientManager.shared.uploadImage(newAvatar)
                    avatarUrl = try await ConvexClientManager.shared.getFileUrl(storageId: storageId) ?? storageId
                }

                // users:upsert patches only the keys we send — academic fields,
                // skills, and interests stay untouched. Free-text fields send ""
                // (not nil) so clearing them actually persists.
                let input = UserInput(
                    clerkId: user.clerkId,
                    email: user.email,
                    phone: user.phone,
                    name: trimmedName,
                    headline: headline.trimmingCharacters(in: .whitespacesAndNewlines),
                    avatarUrl: avatarUrl,
                    lookingFor: lookingFor.trimmingCharacters(in: .whitespacesAndNewlines),
                    socialLinks: UserInput.SocialLinksInput(
                        linkedin: normalizedLink(linkedin),
                        instagram: normalizedLink(instagram),
                        twitter: normalizedLink(twitter),
                        github: normalizedLink(github),
                        website: normalizedLink(website)
                    )
                )

                _ = try await ConvexClientManager.shared.upsertUser(input)

                let fresh = try await ConvexClientManager.shared.fetchUser(id: user._id)

                await MainActor.run {
                    if let fresh {
                        if CurrentUserManager.shared.userId == fresh._id {
                            CurrentUserManager.shared.user = fresh
                        }
                        onSaved?(fresh)
                    }
                    UINotificationFeedbackGenerator().notificationOccurred(.success)
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    errorMessage = "Couldn't save your profile. Try again."
                    isSaving = false
                }
                print("EditProfileSheet: save error: \(error)")
            }
        }
    }
}

// MARK: - Widget Layout Editor

/// Pushed page hosting the drag-and-drop portfolio grid editor.
/// Local-first — only syncs the new order on Save.
struct WidgetLayoutEditor: View {
    let userId: String
    @Environment(\.dismiss) private var dismiss
    @State private var items: [PortfolioItemResponse] = []
    @State private var isLoading = true
    @State private var isSaving = false
    @State private var showAddSheet = false

    var body: some View {
        Group {
            if isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if items.isEmpty {
                EmptyStateView(
                    icon: "square.grid.2x2",
                    title: "No widgets yet",
                    subtitle: "Add GitHub repos, images, links, or experiences"
                )
            } else {
                WidgetGridEditor(items: $items)
            }
        }
        .background(Color.appBackground)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("Edit Widgets")
                    .font(.bodyLargeSemibold)
                    .foregroundColor(.appPrimary)
            }

            ToolbarItem(placement: .confirmationAction) {
                Button("Save") { save() }
                    .font(.bodySemibold)
                    .foregroundColor(.appPrimary)
                    .disabled(isSaving)
            }

            ToolbarItem(placement: .bottomBar) {
                Button(action: { showAddSheet = true }) {
                    HStack(spacing: Spacing.xs) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 16))
                        Text("Add Widget")
                            .font(.bodySemibold)
                    }
                    .foregroundColor(.appOnAccent)
                    .frame(maxWidth: .infinity)
                    .frame(height: 42)
                    .background(Color.appAccent)
                    .clipShape(RoundedRectangle(cornerRadius: Radius.xl, style: .continuous))
                }
                .buttonStyle(.pressableScale(0.97))
            }
        }
        .sheet(isPresented: $showAddSheet) {
            AddPortfolioItemSheet(userId: userId)
        }
        .task { await loadItems() }
    }

    private func loadItems() async {
        do {
            items = try await ConvexClientManager.shared.fetchPortfolioItems(userId: userId)
            isLoading = false
        } catch {
            print("WidgetLayoutEditor: load error: \(error)")
            isLoading = false
        }
    }

    private func save() {
        isSaving = true
        Task {
            do {
                let reorderItems = items.enumerated().map { (index, item) in
                    (id: item._id, order: index, size: item.size)
                }
                try await ConvexClientManager.shared.reorderPortfolioItems(items: reorderItems)
                await MainActor.run { dismiss() }
            } catch {
                print("WidgetLayoutEditor: save error: \(error)")
                isSaving = false
            }
        }
    }
}
