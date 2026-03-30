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
    @State private var coverImageUrl: String?

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
                                .background(Color.appSurface)
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
                        VStack(alignment: .leading, spacing: Spacing.xs) {
                            Text("Event name")
                                .font(.bodySemibold)
                                .foregroundColor(.appPrimary)
                            TextField("e.g. Coffee & pitch practice", text: $title)
                                .font(.bodyLarge)
                                .foregroundColor(.appPrimary)
                                .padding(Spacing.md)
                                .background(Color.appSurface)
                                .cornerRadius(Radius.md)
                        }

                        // Start date & time
                        VStack(alignment: .leading, spacing: Spacing.xs) {
                            Text("Starts")
                                .font(.bodySemibold)
                                .foregroundColor(.appPrimary)
                            DatePicker("", selection: $startDate, in: Date()..., displayedComponents: [.date, .hourAndMinute])
                                .datePickerStyle(.compact)
                                .labelsHidden()
                                .tint(.appAccent)
                                .colorScheme(.dark)
                        }

                        // End date & time
                        VStack(alignment: .leading, spacing: Spacing.xs) {
                            Text("Ends")
                                .font(.bodySemibold)
                                .foregroundColor(.appPrimary)
                            DatePicker("", selection: $endDate, in: startDate..., displayedComponents: [.date, .hourAndMinute])
                                .datePickerStyle(.compact)
                                .labelsHidden()
                                .tint(.appAccent)
                                .colorScheme(.dark)
                        }

                        // Location
                        VStack(alignment: .leading, spacing: Spacing.xs) {
                            Text("Where")
                                .font(.bodySemibold)
                                .foregroundColor(.appPrimary)
                            TextField("e.g. Union Plaza, UNL campus", text: $location)
                                .font(.bodyLarge)
                                .foregroundColor(.appPrimary)
                                .padding(Spacing.md)
                                .background(Color.appSurface)
                                .cornerRadius(Radius.md)
                        }

                        // Description (optional)
                        VStack(alignment: .leading, spacing: Spacing.xs) {
                            Text("Description (optional)")
                                .font(.bodySemibold)
                                .foregroundColor(.appPrimary)
                            TextEditor(text: $description)
                                .font(.bodyLarge)
                                .foregroundColor(.appPrimary)
                                .frame(minHeight: 80)
                                .padding(Spacing.sm)
                                .background(Color.appSurface)
                                .cornerRadius(Radius.md)
                                .scrollContentBackground(.hidden)
                        }

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
            .toolbarColorScheme(.dark, for: .navigationBar)
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
        .preferredColorScheme(.dark)
        .onChange(of: startDate) { _, newStart in
            // Keep end date at least 1 hour after start
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
            // TODO: Upload cover image to Convex storage if selected
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
