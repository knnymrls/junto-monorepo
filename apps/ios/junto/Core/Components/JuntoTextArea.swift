//
//  JuntoTextArea.swift
//  junto
//
//  Multi-line text area with label, character counter, and wrapping placeholder
//

import SwiftUI

struct JuntoTextArea: View {
    let placeholder: String
    @Binding var text: String
    var label: String? = nil
    var characterLimit: Int? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            if let label {
                Text(label)
                    .font(.bodyLargeSemibold)
                    .foregroundColor(.appPrimary)
            }

            ZStack(alignment: .topLeading) {
                VStack(spacing: 0) {
                    TextEditor(text: $text)
                        .font(.bodyLarge)
                        .lineSpacing(3)
                        .foregroundColor(.appPrimary)
                        .scrollContentBackground(.hidden)
                        .scrollDisabled(true)
                        .autocorrectionDisabled()
                        .frame(minHeight: 60)
                        .fixedSize(horizontal: false, vertical: true)
                        .onChange(of: text) { _, newValue in
                            if let limit = characterLimit, newValue.count > limit {
                                text = String(newValue.prefix(limit))
                            }
                        }

                    if let characterLimit {
                        HStack {
                            Spacer()
                            Text("\(text.count)/\(characterLimit)")
                                .font(.captionSmall)
                                .foregroundColor(.appSecondary)
                        }
                        .padding(.trailing, Spacing.xs)
                        .padding(.bottom, Spacing.xs)
                    }
                }

                if text.isEmpty {
                    Text(placeholder)
                        .font(.bodyLarge)
                        .lineSpacing(3)
                        .foregroundColor(.appSecondary)
                        .padding(.top, 8)
                        .padding(.leading, 5)
                        .allowsHitTesting(false)
                }
            }
            .padding(.horizontal, Spacing.sm)
            .padding(.vertical, Spacing.xs)
            .background(Color.appInputFill)
            .clipShape(RoundedRectangle(cornerRadius: Radius.xxl))
        }
    }
}

#Preview {
    JuntoTextArea(
        placeholder: "Introduce yourself as you would at a party, keep it short",
        text: .constant(""),
        label: "Headline",
        characterLimit: 50
    )
    .padding()
}
