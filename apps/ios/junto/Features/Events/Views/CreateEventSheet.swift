//
//  CreateEventSheet.swift
//  junto
//
//  Simple event creation for students
//

import SwiftUI

struct CreateEventSheet: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var currentUser: CurrentUserManager

    @State private var title = ""
    @State private var description = ""
    @State private var date = Date()
    @State private var location = ""
    @State private var isLoading = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            ZStack {
                Color.appBackground.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: Spacing.xl) {
                        // Title
                        VStack(alignment: .leading, spacing: Spacing.xs) {
                            Text("Event name")
                                .font(.body14Semibold)
                                .foregroundColor(.appPrimary)
                            TextField("e.g. Coffee & pitch practice", text: $title)
                                .font(.bodyLarge)
                                .foregroundColor(.appPrimary)
                                .padding(Spacing.md)
                                .background(Color.appSurface)
                                .cornerRadius(Radius.md)
                        }

                        // Date & Time
                        VStack(alignment: .leading, spacing: Spacing.xs) {
                            Text("When")
                                .font(.body14Semibold)
                                .foregroundColor(.appPrimary)
                            DatePicker("", selection: $date, in: Date()..., displayedComponents: [.date, .hourAndMinute])
                                .datePickerStyle(.compact)
                                .labelsHidden()
                                .tint(.appAccent)
                        }

                        // Location
                        VStack(alignment: .leading, spacing: Spacing.xs) {
                            Text("Where")
                                .font(.body14Semibold)
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
                                .font(.body14Semibold)
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
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(.appSecondary)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Create") {
                        Task { await createEvent() }
                    }
                    .font(.body14Semibold)
                    .foregroundColor(title.isEmpty ? .appSecondary : .appAccent)
                    .disabled(title.isEmpty || isLoading)
                }
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
                date: date.timeIntervalSince1970 * 1000,
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
