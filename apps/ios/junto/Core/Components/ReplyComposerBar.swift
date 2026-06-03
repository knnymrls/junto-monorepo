//
//  ReplyComposerBar.swift
//  mkrs-world
//
//  Shared pill-shaped reply input bar with avatar, @mention, image, and link buttons
//

import SwiftUI

struct ReplyComposerBar: View {
    @Binding var text: String
    @Binding var textHeight: CGFloat
    @Binding var selectedImage: UIImage?
    @Binding var selectedGifUrl: URL?
    @Binding var isFocused: Bool
    var avatarUrl: String?
    var avatarName: String = "?"
    var showMentionPicker: Bool = false
    var onMentionTap: () -> Void = {}
    var onGifTap: () -> Void = {}
    var onTextChange: ((String) -> Void)? = nil
    var onSubmit: (() -> Void)? = nil

    private var isActive: Bool {
        isFocused || !text.isEmpty
    }

    var body: some View {
        VStack(spacing: 0) {
            if selectedImage != nil || selectedGifUrl != nil {
                mediaPreview
            }

            HStack(alignment: .center, spacing: Spacing.sm) {
                if !isActive {
                    AvatarView(
                        avatarUrl: avatarUrl,
                        name: avatarName,
                        size: 32
                    )
                    .transition(
                        .asymmetric(
                            insertion: .scale(scale: 0.5).combined(with: .opacity),
                            removal: .scale(scale: 0.5).combined(with: .opacity)
                        )
                    )
                }

                ZStack(alignment: .leading) {
                    if text.isEmpty {
                        Text("Add your reply...")
                            .font(.body14)
                            .foregroundColor(.appSecondary)
                            .allowsHitTesting(false)
                            .frame(height: 28, alignment: .center)
                    }

                    MentionTextView(
                        text: $text,
                        height: $textHeight,
                        placeholder: "Add your reply...",
                        minHeight: 28,
                        returnKeyType: .send,
                        onTextChange: { newValue in
                            onTextChange?(newValue)
                        },
                        onSubmit: {
                            onSubmit?()
                        }
                    )
                    .frame(height: textHeight)
                }
                .frame(minHeight: 28)

                Button(action: onMentionTap) {
                    Image("action.mention.fill")
                        .renderingMode(.template)
                        .resizable()
                        .frame(width: 20, height: 20)
                        .foregroundColor(showMentionPicker ? .appPrimary : .appSecondary)
                        .frame(width: 28, height: 28)
                }

                CompactImagePickerButton(
                    selectedImage: Binding(
                        get: { selectedImage },
                        set: { newImage in
                            selectedImage = newImage
                            if newImage != nil { selectedGifUrl = nil }
                        }
                    ),
                    iconName: "action.camera",
                    iconColor: .appSecondary
                )
            }
            // Keep a stable height so the pill doesn't shrink when the avatar
            // hides on focus (avatar 32 = the resting content height).
            .frame(minHeight: 32)
            .padding(.horizontal, Spacing.md)
            .padding(.vertical, 10)
            .background(Color.appSurfaceSecondary)
            .cornerRadius(27)
            .animation(.spring(response: 0.5, dampingFraction: 0.8), value: isActive)
            .padding(.horizontal, 10)
            .padding(.top, Spacing.sm)
            .padding(.bottom, Spacing.md)
        }
        .background(Color.appSurface)
    }

    // MARK: - Media Preview

    private var mediaPreview: some View {
        HStack(spacing: Spacing.sm) {
            if let image = selectedImage {
                ImagePreviewView(
                    image: image,
                    isUploading: false,
                    onRemove: { selectedImage = nil },
                    size: 80,
                    cornerRadius: 8,
                    closeButtonSize: 18,
                    closeButtonPadding: 4,
                    compact: true
                )
            } else if let gifUrl = selectedGifUrl {
                ZStack(alignment: .topTrailing) {
                    GifPlayerView(url: gifUrl)
                        .frame(width: 80, height: 80)
                        .clipShape(RoundedRectangle(cornerRadius: Radius.md))

                    Button(action: { selectedGifUrl = nil }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 18))
                            .foregroundColor(.white)
                            .shadow(radius: 2)
                    }
                    .offset(x: 6, y: -6)
                }
            }

            Spacer()
        }
        .padding(.horizontal, Spacing.md)
        .padding(.top, Spacing.sm)
    }
}
