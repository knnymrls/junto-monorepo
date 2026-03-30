//
//  CreateEventSheet.swift
//  junto
//
//  Event creation for students
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
    @State private var isLoading = false
    @State private var errorMessage: String?

    // Image
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var coverImage: UIImage?

    var body: some View {
        NavigationStack {
            ZStack {
                Color.appBackground.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: Spacing.xl) {
                        // Cover image
                        PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                            if let coverImage {
                                Image(uiImage: coverImage)
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(height: 160)
                                    .frame(maxWidth: .infinity)
                                    .clipped()
                                    .cornerRadius(Radius.lg)
                            } else {
                                VStack(spacing: Spacing.sm) {
                                    Image(systemName: "photo")
                                        .font(.system(size: 28))
                                        .foregroundColor(.appSecondary)
                                    Text("Add cover image")
                                        .font(.bodySemibold)
                                        .foregroundColor(.appSecondary)
                                }
                                .frame(height: 160)
                                .frame(maxWidth: .infinity)
                                .background(Color.appInputFill)
                                .cornerRadius(Radius.lg)
                            }
                        }
                        .onChange(of: selectedPhotoItem) { _, newItem in
                            Task {
                                if let data = try? await newItem?.loadTransferable(type: Data.self),
                                   let image = UIImage(data: data) {
                                    coverImage = image
                                }
                            }
                        }

                        // Title
                        JuntoTextField(
                            placeholder: "e.g. Coffee & pitch practice",
                            text: $title,
                            label: "Event name"
                        )

                        // Start
                        VStack(alignment: .leading, spacing: Spacing.sm) {
                            Text("Starts")
                                .font(.bodyLargeSemibold)
                                .foregroundColor(.appPrimary)
                            DatePicker("", selection: $startDate, in: Date()..., displayedComponents: [.date, .hourAndMinute])
                                .datePickerStyle(.compact)
                                .labelsHidden()
                                .tint(.appAccent)
                        }

                        // End
                        VStack(alignment: .leading, spacing: Spacing.sm) {
                            Text("Ends")
                                .font(.bodyLargeSemibold)
                                .foregroundColor(.appPrimary)
                            DatePicker("", selection: $endDate, in: startDate..., displayedComponents: [.date, .hourAndMinute])
                                .datePickerStyle(.compact)
                                .labelsHidden()
                                .tint(.appAccent)
                        }

                        // Location
                        JuntoTextField(
                            placeholder: "e.g. Union Plaza, UNL campus",
                            text: $location,
                            label: "Where"
                        )

                        // Description
                        JuntoTextArea(
                            text: $description,
                            label: "Description (optional)",
                            placeholder: "What's this event about?",
                            maxLength: 500
                        )

                        if let error = errorMessage {
                            Text(error)
                                .font(.body14)
                                .foregroundColor(.appError)
                        }

                        Spacer()
                    }
                    .padding(.horizontal, Spacing.xxl)
                    .padding(.top, Spacing.xl)
                }
            }
            .navigationTitle("Create Event")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(.appSecondary)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Create") {
                        Task { await createEvent() }
                    }
                    .font(.bodySemibold)
                    .foregroundColor(title.isEmpty ? .appSecondary : .appAccent)
                    .disabled(title.isEmpty || isLoading)
                }
            }
        }
        .onChange(of: startDate) { _, newStart in
            if endDate < newStart.addingTimeInterval(3600) {
                endDate = newStart.addingTimeInterval(3600)
            }
        }
    }

    private func createEvent() async {
        guard let userId = currentUser.user?._id else { return }
        isLoading = true
        errorMessage = nil

        do {
            try await ConvexClientManager.shared.createEvent(
                title: title,
                description: description.isEmpty ? nil : description,
                date: startDate.timeIntervalSince1970 * 1000,
                endDate: endDate.timeIntervalSince1970 * 1000,
                location: location.isEmpty ? nil : location,
                type: "in_person",
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
