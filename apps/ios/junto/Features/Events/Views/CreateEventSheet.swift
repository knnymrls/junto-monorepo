//
//  CreateEventSheet.swift
//  junto
//
//  Event creation. Mirrors the EventDetailView aesthetic — a dark, Luma-style
//  ambient backdrop that tints itself to the uploaded cover image — over a
//  poster cover + the event form fields.
//

import SwiftUI
import PhotosUI

struct CreateEventSheet: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var currentUser: CurrentUserManager

    @State private var title = ""
    @State private var description = ""
    @State private var startDate = Date()
    @State private var endDate = Date().addingTimeInterval(3600)
    @State private var location = ""
    @State private var selectedCategories: Set<SkillCategory> = []
    @State private var isLoading = false
    @State private var errorMessage: String?

    // Image + derived ambient
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var coverImage: UIImage?
    @State private var ambient: Color = Color(white: 0.13)

    var body: some View {
        NavigationStack {
            ZStack {
                ambientBackground

                ScrollView(showsIndicators: false) {
                    VStack(spacing: Spacing.xl) {
                        coverPicker
                        formFields

                        if let error = errorMessage {
                            Text(error)
                                .font(.body14)
                                .foregroundColor(.appError)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                    .padding(.horizontal, Spacing.xl)
                    .padding(.top, Spacing.lg)
                    .padding(.bottom, Spacing.huge)
                }
            }
            .navigationTitle("Create Event")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.hidden, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(.white.opacity(0.8))
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Create") {
                        Task { await createEvent() }
                    }
                    .font(.bodySemibold)
                    .foregroundColor(title.isEmpty ? .white.opacity(0.4) : .appAccent)
                    .disabled(title.isEmpty || isLoading)
                }
            }
        }
        .preferredColorScheme(.dark)
        .onChange(of: startDate) { _, newStart in
            if endDate < newStart.addingTimeInterval(3600) {
                endDate = newStart.addingTimeInterval(3600)
            }
        }
        .onChange(of: selectedPhotoItem) { _, newItem in
            Task {
                if let data = try? await newItem?.loadTransferable(type: Data.self),
                   let image = UIImage(data: data) {
                    await MainActor.run {
                        coverImage = image
                        if let c = image.ambientColor {
                            withAnimation(.easeInOut(duration: 0.6)) { ambient = Color(c) }
                        }
                    }
                }
            }
        }
    }

    // MARK: - Ambient backdrop (tints to the cover image)

    private var ambientBackground: some View {
        GeometryReader { geo in
            ZStack {
                LinearGradient(
                    colors: [ambient, .black],
                    startPoint: .top,
                    endPoint: .bottom
                )

                if let coverImage {
                    Image(uiImage: coverImage)
                        .resizable()
                        .scaledToFill()
                        .frame(width: geo.size.width, height: geo.size.height)
                        .clipped()
                        .blur(radius: 60)
                        .opacity(0.35)
                }

                Color.black.opacity(0.3)
            }
            .frame(width: geo.size.width, height: geo.size.height)
            .clipped()
        }
        .ignoresSafeArea()
    }

    // MARK: - Cover picker (poster card)

    private var coverPicker: some View {
        PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
            // A fixed-size base drives the layout; the image is a clipped overlay
            // so an aspect-fill photo can't blow out the sheet width.
            Color.white.opacity(0.08)
                .frame(maxWidth: .infinity)
                .frame(height: 208)
                .overlay {
                    if let coverImage {
                        Image(uiImage: coverImage)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } else {
                        VStack(spacing: Spacing.sm) {
                            Image(systemName: "photo.badge.plus")
                                .font(.system(size: 28))
                                .foregroundColor(.white.opacity(0.7))
                            Text("Add cover image")
                                .font(.bodySemibold)
                                .foregroundColor(.white.opacity(0.7))
                        }
                    }
                }
                .clipped()
                .clipShape(RoundedRectangle(cornerRadius: Radius.md, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: Radius.md, style: .continuous)
                        .stroke(Color.white.opacity(0.12), lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Form

    /// Surface color matching the event detail page (translucent white over the
    /// ambient, so fields pick up the image tint).
    private let fieldFill = Color.white.opacity(0.08)

    private var formFields: some View {
        VStack(spacing: Spacing.xl) {
            JuntoTextField(
                placeholder: "e.g. Coffee & pitch practice",
                text: $title,
                label: "Event name",
                fill: fieldFill
            )

            dateField("Starts", selection: $startDate, range: Date()...)
            dateField("Ends", selection: $endDate, range: startDate...)

            JuntoTextField(
                placeholder: "e.g. Union Plaza, UNL campus",
                text: $location,
                label: "Where",
                fill: fieldFill
            )

            JuntoTextArea(
                placeholder: "What's this event about?",
                text: $description,
                label: "Description (optional)",
                characterLimit: 500,
                fill: fieldFill
            )

            tagPicker
        }
    }

    // MARK: - Tags

    private var tagPicker: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("Tags")
                .font(.bodyLargeSemibold)
                .foregroundColor(.appPrimary)

            FlowLayout(spacing: Spacing.sm) {
                ForEach(SkillCategory.allCases, id: \.self) { category in
                    tagChip(category)
                }
            }
        }
    }

    private func tagChip(_ category: SkillCategory) -> some View {
        let selected = selectedCategories.contains(category)
        return Button {
            if selected { selectedCategories.remove(category) }
            else { selectedCategories.insert(category) }
        } label: {
            HStack(spacing: Spacing.xxs) {
                Image(category.icon)
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 14, height: 14)
                    .foregroundColor(selected ? category.color : .white.opacity(0.7))
                Text(category.label)
                    .font(.bodyMedium)
                    .foregroundColor(selected ? .white : .white.opacity(0.7))
            }
            .padding(.horizontal, Spacing.md)
            .padding(.vertical, Spacing.sm)
            .background(selected ? category.color.opacity(0.22) : Color.white.opacity(0.08))
            .clipShape(RoundedRectangle(cornerRadius: Radius.xxl, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: Radius.xxl, style: .continuous)
                    .stroke(selected ? category.color.opacity(0.55) : .clear, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    private func dateField(_ label: String,
                           selection: Binding<Date>,
                           range: PartialRangeFrom<Date>) -> some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text(label)
                .font(.bodyLargeSemibold)
                .foregroundColor(.appPrimary)

            // The compact picker is its own container — no extra box around it.
            HStack {
                DatePicker(
                    "",
                    selection: selection,
                    in: range,
                    displayedComponents: [.date, .hourAndMinute]
                )
                .datePickerStyle(.compact)
                .labelsHidden()
                .tint(.appAccent)

                Spacer()
            }
        }
    }

    // MARK: - Create

    private func createEvent() async {
        guard let userId = currentUser.user?._id else { return }
        isLoading = true
        errorMessage = nil

        do {
            var imageUrl: String?
            if let coverImage {
                imageUrl = try await ImageUploadService.shared.uploadForStorageId(coverImage)
            }

            try await ConvexClientManager.shared.createEvent(
                title: title,
                description: description.isEmpty ? nil : description,
                date: startDate.timeIntervalSince1970 * 1000,
                endDate: endDate.timeIntervalSince1970 * 1000,
                location: location.isEmpty ? nil : location,
                type: "in_person",
                categories: selectedCategories.isEmpty ? nil : selectedCategories.map { $0.label },
                imageUrl: imageUrl,
                createdBy: userId,
                universityId: currentUser.user?.universityId
            )
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }
}
