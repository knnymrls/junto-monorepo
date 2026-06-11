//
//  AddPortfolioItemSheet.swift
//  mkrs-world
//
//  Sheet for adding new portfolio items — type picker then type-specific form
//

import SwiftUI
import PhotosUI

struct AddPortfolioItemSheet: View {
    let userId: String
    /// When set, the sheet opens straight on that type's form (vocation
    /// suggestions on the Work tab deep-link here).
    private let initialType: PortfolioItemResponse.PortfolioType?
    @Environment(\.dismiss) private var dismiss
    @State private var selectedType: PortfolioItemResponse.PortfolioType?
    @State private var isSaving = false
    @State private var saveError: String?

    init(userId: String, initialType: PortfolioItemResponse.PortfolioType? = nil, suggestedTitle: String? = nil) {
        self.userId = userId
        self.initialType = initialType
        _selectedType = State(initialValue: initialType)
        if let suggestedTitle {
            switch initialType {
            case .gallery: _galleryTitle = State(initialValue: suggestedTitle)
            case .link: _linkTitle = State(initialValue: suggestedTitle)
            case .experience: _expTitle = State(initialValue: suggestedTitle)
            default: break
            }
        }
    }

    // GitHub fields
    @State private var githubUrl = ""

    // Gallery fields
    @State private var galleryTitle = ""
    @State private var galleryImages: [UIImage] = []

    // Link fields
    @State private var linkUrl = ""
    @State private var linkTitle = ""

    // Experience fields
    @State private var expTitle = ""
    @State private var expOrganization = ""
    @State private var expDescription = ""
    @State private var expStartDate = Date()
    @State private var expEndDate = Date()
    @State private var expIsOngoing = true
    @State private var expImages: [UIImage] = []

    var body: some View {
        NavigationStack {
            Group {
                if let type = selectedType {
                    formForType(type)
                } else {
                    typePicker
                }
            }
            .background(Color.appBackground)
            .navigationTitle(selectedType == nil ? "Add to Portfolio" : typeTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(action: {
                        // Deep-linked sheets have no picker to go back to.
                        if selectedType != nil && initialType == nil {
                            selectedType = nil
                        } else {
                            dismiss()
                        }
                    }) {
                        if selectedType != nil && initialType == nil {
                            Image(systemName: "chevron.left")
                                .font(.bodyMedium)
                        } else {
                            Text("Cancel")
                                .font(.bodyLarge)
                        }
                    }
                    .foregroundColor(.appPrimary)
                }

                if selectedType != nil {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Save") { save() }
                            .font(.bodyLargeSemibold)
                            .foregroundColor(canSave ? .appPrimary : .appSecondary)
                            .disabled(!canSave || isSaving)
                    }
                }
            }
        }
        .presentationDragIndicator(.visible)
        .errorAlert($saveError, title: "Couldn't Save")
    }

    // MARK: - Type Picker

    private var typePicker: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: Spacing.md) {
            typeButton(type: .github, icon: "chevron.left.forwardslash.chevron.right", label: "GitHub")
            typeButton(type: .gallery, icon: "photo.on.rectangle.angled", label: "Image Gallery")
            typeButton(type: .link, icon: "link", label: "Link")
            typeButton(type: .experience, icon: "briefcase.fill", label: "Experience")
        }
        .padding(Spacing.lg)
    }

    private func typeButton(type: PortfolioItemResponse.PortfolioType, icon: String, label: String) -> some View {
        Button(action: { selectedType = type }) {
            VStack(spacing: Spacing.xs + Spacing.xxs) {
                Image(systemName: icon)
                    .font(.system(size: 24))
                    .foregroundColor(.appPrimary)
                Text(label)
                    .font(.bodyMedium)
                    .foregroundColor(.appPrimary)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 100)
            .cardStyle()
        }
        .buttonStyle(.plain)
    }

    // MARK: - Type-Specific Forms

    private var typeTitle: String {
        switch selectedType {
        case .github: return "GitHub"
        case .gallery: return "Image Gallery"
        case .link: return "Link"
        case .experience: return "Experience"
        case nil: return "Add to Portfolio"
        }
    }

    @ViewBuilder
    private func formForType(_ type: PortfolioItemResponse.PortfolioType) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.lg) {
                switch type {
                case .github:
                    githubForm
                case .gallery:
                    galleryForm
                case .link:
                    linkForm
                case .experience:
                    experienceForm
                }
            }
            .padding(Spacing.lg)
        }
    }

    // MARK: GitHub Form

    private var githubForm: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("GitHub Username")
                .font(.bodySmallMedium)
                .foregroundColor(.appSecondary)

            TextField("e.g. knnymrls", text: $githubUrl)
                .font(.bodyLarge)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .padding(Spacing.md)
                .background(Color.appSurfaceSecondary)
                .clipShape(RoundedRectangle(cornerRadius: Radius.md))
        }
    }

    // MARK: Gallery Form

    private var galleryForm: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            VStack(alignment: .leading, spacing: Spacing.sm) {
                Text("Title (optional)")
                    .font(.bodySmallMedium)
                    .foregroundColor(.appSecondary)

                TextField("e.g. Design Portfolio", text: $galleryTitle)
                    .font(.bodyLarge)
                    .padding(Spacing.md)
                    .background(Color.appSurfaceSecondary)
                    .clipShape(RoundedRectangle(cornerRadius: Radius.md))
            }

            VStack(alignment: .leading, spacing: Spacing.sm) {
                Text("Images (max 6)")
                    .font(.bodySmallMedium)
                    .foregroundColor(.appSecondary)

                MultiImagePickerButton(selectedImages: $galleryImages, maxImages: 6)
            }

            if !galleryImages.isEmpty {
                let columns = [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())]
                LazyVGrid(columns: columns, spacing: Spacing.sm) {
                    ForEach(galleryImages.indices, id: \.self) { index in
                        ZStack(alignment: .topTrailing) {
                            Image(uiImage: galleryImages[index])
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(height: 80)
                                .clipShape(RoundedRectangle(cornerRadius: Radius.md))

                            Button(action: { galleryImages.remove(at: index) }) {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.system(size: 18))
                                    .foregroundColor(.white)
                                    .shadow(radius: 2)
                            }
                            .offset(x: -Spacing.xxs, y: Spacing.xxs)
                        }
                    }
                }
            }
        }
    }

    // MARK: Link Form

    private var linkForm: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            VStack(alignment: .leading, spacing: Spacing.sm) {
                Text("URL")
                    .font(.bodySmallMedium)
                    .foregroundColor(.appSecondary)

                HStack {
                    TextField("https://...", text: $linkUrl)
                        .font(.bodyLarge)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .keyboardType(.URL)

                    Button(action: pasteFromClipboard) {
                        Image(systemName: "doc.on.clipboard")
                            .font(.system(size: 16))
                            .foregroundColor(.appSecondary)
                    }
                }
                .padding(Spacing.md)
                .background(Color.appSurfaceSecondary)
                .clipShape(RoundedRectangle(cornerRadius: Radius.md))
            }

            VStack(alignment: .leading, spacing: Spacing.sm) {
                Text("Title (optional)")
                    .font(.bodySmallMedium)
                    .foregroundColor(.appSecondary)

                TextField("e.g. My Portfolio Website", text: $linkTitle)
                    .font(.bodyLarge)
                    .padding(Spacing.md)
                    .background(Color.appSurfaceSecondary)
                    .clipShape(RoundedRectangle(cornerRadius: Radius.md))
            }
        }
    }

    // MARK: Experience Form

    private var experienceForm: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            formField("Title", text: $expTitle, placeholder: "e.g. Software Engineering Intern")
            formField("Organization", text: $expOrganization, placeholder: "e.g. Google")

            // Same compact date components as Create Event (month/year matters here).
            dateField("Starts", selection: $expStartDate, range: nil)

            Toggle(isOn: $expIsOngoing) {
                Text("I'm still doing this")
                    .font(.body14)
                    .foregroundColor(.appPrimary)
            }
            .tint(.appAccent)

            if !expIsOngoing {
                dateField("Ends", selection: $expEndDate, range: expStartDate...)
            }

            VStack(alignment: .leading, spacing: Spacing.sm) {
                Text("Description (optional)")
                    .font(.bodySmallMedium)
                    .foregroundColor(.appSecondary)

                TextEditor(text: $expDescription)
                    .font(.bodyLarge)
                    .foregroundColor(.appPrimary)
                    .scrollContentBackground(.hidden)
                    .frame(minHeight: 80)
                    .padding(Spacing.sm)
                    .background(Color.appSurfaceSecondary)
                    .clipShape(RoundedRectangle(cornerRadius: Radius.md))
            }

            VStack(alignment: .leading, spacing: Spacing.sm) {
                Text("Photos (optional, max 4)")
                    .font(.bodySmallMedium)
                    .foregroundColor(.appSecondary)

                MultiImagePickerButton(selectedImages: $expImages, maxImages: 4)
            }

            if !expImages.isEmpty {
                imagePreviewGrid($expImages)
            }
        }
        .onChange(of: expStartDate) { _, newStart in
            if expEndDate < newStart {
                expEndDate = newStart
            }
        }
    }

    /// Compact date picker field — mirrors CreateEventSheet's dateField, minus
    /// the time-of-day components (experiences live at month/year granularity).
    private func dateField(_ label: String, selection: Binding<Date>, range: PartialRangeFrom<Date>?) -> some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text(label)
                .font(.bodyLargeSemibold)
                .foregroundColor(.appPrimary)

            HStack {
                if let range {
                    DatePicker("", selection: selection, in: range, displayedComponents: [.date])
                        .datePickerStyle(.compact)
                        .labelsHidden()
                        .tint(.appAccent)
                } else {
                    DatePicker("", selection: selection, displayedComponents: [.date])
                        .datePickerStyle(.compact)
                        .labelsHidden()
                        .tint(.appAccent)
                }

                Spacer()
            }
        }
    }

    private func imagePreviewGrid(_ images: Binding<[UIImage]>) -> some View {
        let columns = [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())]
        return LazyVGrid(columns: columns, spacing: Spacing.sm) {
            ForEach(images.wrappedValue.indices, id: \.self) { index in
                ZStack(alignment: .topTrailing) {
                    Image(uiImage: images.wrappedValue[index])
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(height: 80)
                        .clipShape(RoundedRectangle(cornerRadius: Radius.md))

                    Button(action: { images.wrappedValue.remove(at: index) }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 18))
                            .foregroundColor(.white)
                            .shadow(radius: 2)
                    }
                    .offset(x: -Spacing.xxs, y: Spacing.xxs)
                }
            }
        }
    }

    private func formField(_ label: String, text: Binding<String>, placeholder: String) -> some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text(label)
                .font(.bodySmallMedium)
                .foregroundColor(.appSecondary)

            TextField(placeholder, text: text)
                .font(.bodyLarge)
                .padding(Spacing.md)
                .background(Color.appSurfaceSecondary)
                .clipShape(RoundedRectangle(cornerRadius: Radius.md))
        }
    }

    // MARK: - Validation

    private var canSave: Bool {
        switch selectedType {
        case .github:
            return !githubUrl.trimmingCharacters(in: .whitespaces).isEmpty
        case .gallery:
            return !galleryImages.isEmpty
        case .link:
            return !linkUrl.trimmingCharacters(in: .whitespaces).isEmpty
        case .experience:
            return !expTitle.trimmingCharacters(in: .whitespaces).isEmpty
        case nil:
            return false
        }
    }

    // MARK: - Save

    private func save() {
        guard let type = selectedType else { return }
        isSaving = true

        Task {
            do {
                switch type {
                case .github:
                    let username = githubUrl
                        .trimmingCharacters(in: .whitespaces)
                        .replacingOccurrences(of: "https://github.com/", with: "")
                        .replacingOccurrences(of: "http://github.com/", with: "")
                        .replacingOccurrences(of: "github.com/", with: "")
                        .replacingOccurrences(of: "@", with: "")
                        .trimmingCharacters(in: CharacterSet(charactersIn: "/"))
                    _ = try await ConvexClientManager.shared.createPortfolioItem(
                        userId: userId,
                        type: "github",
                        url: username
                    )

                case .gallery:
                    var storageIds: [String] = []
                    for image in galleryImages {
                        let storageId = try await ImageUploadService.shared.uploadForStorageId(image)
                        storageIds.append(storageId)
                    }
                    _ = try await ConvexClientManager.shared.createPortfolioItem(
                        userId: userId,
                        type: "gallery",
                        title: galleryTitle.isEmpty ? nil : galleryTitle,
                        imageUrls: storageIds
                    )

                case .link:
                    _ = try await ConvexClientManager.shared.createPortfolioItem(
                        userId: userId,
                        type: "link",
                        title: linkTitle.isEmpty ? nil : linkTitle,
                        url: linkUrl.trimmingCharacters(in: .whitespaces)
                    )

                case .experience:
                    var storageIds: [String] = []
                    for image in expImages {
                        let storageId = try await ImageUploadService.shared.uploadForStorageId(image)
                        storageIds.append(storageId)
                    }
                    _ = try await ConvexClientManager.shared.createPortfolioItem(
                        userId: userId,
                        type: "experience",
                        title: expTitle.trimmingCharacters(in: .whitespaces),
                        description: expDescription.isEmpty ? nil : expDescription,
                        imageUrls: storageIds.isEmpty ? nil : storageIds,
                        organization: expOrganization.isEmpty ? nil : expOrganization,
                        startDate: monthYearText(expStartDate),
                        endDate: expIsOngoing ? nil : monthYearText(expEndDate)
                    )
                }

                dismiss()
            } catch {
                print("AddPortfolioItemSheet: save error: \(error)")
                saveError = "Couldn't save your widget. Check your connection and try again."
                isSaving = false
            }
        }
    }

    // MARK: - Helpers

    /// Experiences live at month/year granularity — "Jan 2025".
    private func monthYearText(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM yyyy"
        return formatter.string(from: date)
    }

    private func pasteFromClipboard() {
        if let string = UIPasteboard.general.string {
            linkUrl = string
        }
    }
}
