//
//  SearchInputBar.swift
//  mkrs-world
//
//  Top search bar with loading indicator, auto-focus, and submit action
//

import SwiftUI

struct SearchInputBar: View {
    @Binding var text: String
    let isLoading: Bool
    var isFocused: FocusState<Bool>.Binding
    var placeholder: String = "What kind of user are you looking for?"
    var onSubmit: (() -> Void)? = nil
    var onClear: (() -> Void)? = nil

    var body: some View {
        HStack(spacing: Spacing.sm) {
            // Left icon: loading spinner or magnifying glass
            if isLoading {
                ProgressView()
                    .scaleEffect(0.7)
                    .frame(width: 16, height: 16)
            } else {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.appSecondary)
            }

            TextField(placeholder, text: $text)
                .font(.body14)
                .foregroundColor(.appPrimary)
                .focused(isFocused)
                .submitLabel(.search)
                .onSubmit {
                    onSubmit?()
                }

            if !text.isEmpty {
                Button(action: {
                    text = ""
                    onClear?()
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 16))
                        .foregroundColor(.appSecondary)
                }
            }
        }
        .padding(.horizontal, Spacing.md)
        .padding(.vertical, Spacing.sm)
        .background(Color.appSurfaceSecondary)
        .clipShape(RoundedRectangle(cornerRadius: Radius.xl))
        .padding(.horizontal, Spacing.md)
    }
}
