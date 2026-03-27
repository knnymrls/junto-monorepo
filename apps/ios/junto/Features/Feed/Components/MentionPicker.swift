//
//  MentionPicker.swift
//  mkrs-world
//
//  Floating list of mention suggestions
//

import SwiftUI

struct MentionPicker: View {
    let suggestions: [MentionSuggestion]
    let isLoading: Bool
    var onSelect: ((MentionSuggestion) -> Void)?
    var onClose: (() -> Void)?

    private var hairline: CGFloat {
        1 / UIScreen.main.scale
    }

    var body: some View {
        ZStack(alignment: .topTrailing) {
            VStack(spacing: 0) {
                if isLoading {
                    HStack {
                        Spacer()
                        ProgressView()
                            .tint(.appSecondary)
                        Spacer()
                    }
                    .padding(.vertical, Spacing.xl)
                } else if suggestions.isEmpty {
                    Text("No suggestions")
                        .font(.body14)
                        .foregroundColor(.appSecondary)
                        .padding(.vertical, Spacing.xl)
                } else {
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 0) {
                            ForEach(suggestions) { suggestion in
                                Button(action: { onSelect?(suggestion) }) {
                                    MentionRow(suggestion: suggestion)
                                }
                                .buttonStyle(.plain)

                                if suggestion.id != suggestions.last?.id {
                                    Rectangle()
                                        .fill(Color.appDivider)
                                        .frame(height: hairline)
                                }
                            }
                        }
                    }
                    .frame(maxHeight: 250)
                }
            }
            .padding(Spacing.sm)

            // Close button overlay
            Button(action: { onClose?() }) {
                Image(systemName: "xmark")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(.appSecondary)
                    .padding(Spacing.xs)
            }
            .padding(Spacing.xxs)
        }
        .background(Color.white)
        .cornerRadius(Radius.xxl)
        .shadow(color: .black.opacity(0.1), radius: Spacing.sm, y: Spacing.xxs)
        .padding(.horizontal, 10)
        .padding(.bottom, 80)
    }
}
