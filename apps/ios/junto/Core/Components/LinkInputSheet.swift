//
//  LinkInputSheet.swift
//  mkrs-world
//
//  Sheet for inputting and previewing a URL before adding to post/comment
//

import SwiftUI

struct LinkInputSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var linkUrl: String?

    @State private var urlText = ""
    @State private var showPreview = false
    @State private var isValidUrl = false
    @FocusState private var isTextFieldFocused: Bool

    var body: some View {
        NavigationStack {
            VStack(spacing: Spacing.xl) {
                // URL Input
                VStack(alignment: .leading, spacing: Spacing.sm) {
                    Text("Link URL")
                        .font(.bodyMedium)
                        .foregroundColor(.appPrimary)

                    HStack {
                        TextField("https://", text: $urlText)
                            .font(.body14)
                            .textContentType(.URL)
                            .keyboardType(.URL)
                            .autocapitalization(.none)
                            .autocorrectionDisabled()
                            .focused($isTextFieldFocused)
                            .onChange(of: urlText) { _, newValue in
                                validateUrl(newValue)
                            }

                        if !urlText.isEmpty {
                            Button(action: { urlText = "" }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.appSecondary)
                            }
                        }
                    }
                    .padding(Spacing.md)
                    .background(Color.appSurfaceSecondary)
                    .cornerRadius(Radius.md)

                    if !urlText.isEmpty && !isValidUrl {
                        Text("Please enter a valid URL")
                            .font(.caption12)
                            .foregroundColor(.red)
                    }
                }

                // Preview section
                if showPreview, let url = URL(string: normalizedUrl) {
                    VStack(alignment: .leading, spacing: Spacing.sm) {
                        Text("Preview")
                            .font(.bodyMedium)
                            .foregroundColor(.appPrimary)

                        LinkPreviewCard(url: url)
                    }
                }

                Spacer()

                // Preview button
                if isValidUrl && !showPreview {
                    Button(action: { showPreview = true }) {
                        HStack {
                            Image(systemName: "eye")
                            Text("Preview Link")
                        }
                        .font(.bodyMedium)
                        .foregroundColor(.appPrimary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, Spacing.md)
                        .background(Color.appSurfaceSecondary)
                        .cornerRadius(Radius.md)
                    }
                }

                // Add button
                Button(action: addLink) {
                    Text("Add Link")
                        .font(.bodySemibold)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(isValidUrl ? Color.appPrimary : Color.appSecondary)
                        .cornerRadius(Radius.md)
                }
                .disabled(!isValidUrl)
            }
            .padding(Spacing.lg)
            .background(Color.appSurface)
            .navigationTitle("Add Link")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.appPrimary)
                }
            }
        }
        .presentationDetents([.medium])
        .onAppear {
            isTextFieldFocused = true
        }
    }

    // MARK: - Helpers

    private var normalizedUrl: String {
        var url = urlText.trimmingCharacters(in: .whitespacesAndNewlines)
        if !url.isEmpty && !url.hasPrefix("http://") && !url.hasPrefix("https://") {
            url = "https://" + url
        }
        return url
    }

    private func validateUrl(_ text: String) {
        showPreview = false

        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            isValidUrl = false
            return
        }

        let urlString = normalizedUrl
        if let url = URL(string: urlString),
           let host = url.host,
           !host.isEmpty,
           host.contains(".") {
            isValidUrl = true
        } else {
            isValidUrl = false
        }
    }

    private func addLink() {
        guard isValidUrl else { return }
        linkUrl = normalizedUrl
        dismiss()
    }
}

#Preview {
    LinkInputSheet(linkUrl: .constant(nil))
}
