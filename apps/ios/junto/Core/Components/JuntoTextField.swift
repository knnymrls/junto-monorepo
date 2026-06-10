//
//  JuntoTextField.swift
//  junto
//
//  Reusable single-line text field — #F2F2F2 fill, 53pt tall (matches Figma)
//

import SwiftUI

struct JuntoTextField: View {
    let placeholder: String
    @Binding var text: String
    var label: String? = nil
    var icon: Image? = nil
    var keyboardType: UIKeyboardType = .default
    var textContentType: UITextContentType? = nil
    var autocapitalization: TextInputAutocapitalization = .sentences
    var fill: Color = .appInputFill

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            if let label {
                Text(label)
                    .font(.bodyLargeSemibold)
                    .foregroundColor(.appPrimary)
            }

            HStack(spacing: Spacing.sm) {
                if let icon {
                    icon
                        .resizable()
                        .scaledToFit()
                        .frame(width: 16, height: 16)
                        .foregroundColor(.appSecondary)
                }

                TextField(placeholder, text: $text)
                    .font(.bodyLarge)
                    .foregroundColor(.appPrimary)
                    .keyboardType(keyboardType)
                    .textContentType(textContentType)
                    .textInputAutocapitalization(autocapitalization)
                    .autocorrectionDisabled()
                    .submitLabel(.done)
            }
            .padding(.horizontal, Spacing.md)
            .frame(height: 53)
            .background(fill)
            .clipShape(RoundedRectangle(cornerRadius: Radius.xxl))
        }
    }
}

#Preview {
    VStack(spacing: Spacing.md) {
        JuntoTextField(
            placeholder: "knnymrls@outlook.com",
            text: .constant(""),
            keyboardType: .emailAddress,
            textContentType: .emailAddress,
            autocapitalization: .never
        )
        JuntoTextField(
            placeholder: "Enter your campus",
            text: .constant(""),
            icon: Image(systemName: "magnifyingglass")
        )
        JuntoTextField(
            placeholder: "Your name",
            text: .constant("Kenny Morales"),
            label: "Name"
        )
    }
    .padding()
}
