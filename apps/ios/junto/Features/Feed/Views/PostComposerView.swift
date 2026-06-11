//
//  PostComposerView.swift
//  mkrs-world
//
//  Sheet for creating a new post
//

import SwiftUI
import UIKit

struct PostComposerView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: FeedViewModel
    var editingPost: PostResponse? = nil

    @State private var content = ""
    @State private var selectedCategory: PostResponse.PostCategory? = .asking
    @State private var isPosting = false
    // Slides the white "thumb" between category segments.
    @Namespace private var categoryThumb

    // Image state
    @State private var selectedImages: [UIImage] = []
    @State private var isUploadingImages = false
    @State private var existingImageUrls: [String] = []
    @State private var showImagePicker = false

    // GIF state
    @State private var showGifPicker = false
    @State private var selectedGifUrl: URL?

    // Mention manager
    @StateObject private var mentionManager = MentionManager()
    @State private var textViewHeight: CGFloat = 36
    @State private var showCategoryRequired = false
    @State private var showPostError = false
    @State private var postErrorMessage = ""

    private let maxPostLength = 200

    private var isEditing: Bool { editingPost != nil }

    var body: some View {
        ZStack(alignment: .bottom) {
            VStack(spacing: 0) {
                VStack(alignment: .leading, spacing: 0) {
                    HStack(alignment: .top, spacing: Spacing.sm) {
                        AvatarView(
                            avatarUrl: viewModel.currentUser?.avatarUrl,
                            name: viewModel.currentUser?.name ?? "?",
                            size: 36
                        )

                        VStack(alignment: .leading, spacing: Spacing.xxs) {
                            Text(viewModel.currentUser?.name ?? "")
                                .font(.bodyMedium)
                                .foregroundColor(.appPrimary)

                            ZStack(alignment: .topLeading) {
                                if content.isEmpty {
                                    Text(placeholderText)
                                        .font(.body14)
                                        .foregroundColor(.appSecondary)
                                }

                                MentionTextView(
                                    text: $content,
                                    height: $textViewHeight,
                                    placeholder: placeholderText,
                                    autoFocus: true,
                                    onTextChange: { newValue in
                                        mentionManager.handleTextChange(newValue)
                                    }
                                )
                                .frame(height: textViewHeight)
                            }

                            // Existing images preview (when editing)
                            if !existingImageUrls.isEmpty {
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: Spacing.sm) {
                                        ForEach(Array(existingImageUrls.enumerated()), id: \.offset) { index, urlString in
                                            if let url = URL(string: urlString) {
                                                ZStack(alignment: .topTrailing) {
                                                    CachedAsyncImage(url: url) { image in
                                                        image
                                                            .resizable()
                                                            .aspectRatio(contentMode: .fill)
                                                            .frame(width: 120, height: 120)
                                                            .clipShape(RoundedRectangle(cornerRadius: Radius.md))
                                                    } placeholder: {
                                                        RoundedRectangle(cornerRadius: Radius.md)
                                                            .fill(Color.appSurfaceSecondary)
                                                            .frame(width: 120, height: 120)
                                                            .overlay(ProgressView().tint(.appSecondary))
                                                    }

                                                    Button(action: {
                                                        existingImageUrls.remove(at: index)
                                                    }) {
                                                        Image(systemName: "xmark.circle.fill")
                                                            .font(.system(size: 20))
                                                            .foregroundColor(.white)
                                                            .shadow(radius: Spacing.xxxs)
                                                    }
                                                    .offset(x: Spacing.xxs, y: -Spacing.xxs)
                                                }
                                            }
                                        }
                                    }
                                }
                                .padding(.top, Spacing.md)
                            }

                            if !selectedImages.isEmpty {
                                ImagePreviewCarousel(
                                    images: $selectedImages,
                                    isUploading: isUploadingImages,
                                    onRemove: { index in
                                        selectedImages.remove(at: index)
                                    }
                                )
                                .padding(.top, Spacing.md)
                            }

                            if let gifUrl = selectedGifUrl {
                                ZStack(alignment: .topTrailing) {
                                    GifPlayerView(url: gifUrl)
                                        .frame(maxHeight: 200)
                                        .clipShape(RoundedRectangle(cornerRadius: Radius.md))

                                    Button(action: { selectedGifUrl = nil }) {
                                        Image(systemName: "xmark.circle.fill")
                                            .font(.system(size: 22))
                                            .foregroundColor(.white)
                                            .shadow(radius: 2)
                                    }
                                    .offset(x: -Spacing.xs, y: Spacing.xs)
                                }
                                .padding(.top, Spacing.md)
                            }

                            HStack(spacing: Spacing.sm) {
                                composerChip(icon: "action.camera", label: "Add Image") {
                                    showImagePicker = true
                                }
                                composerChip(icon: "action.mention.fill", label: "Mention") {
                                    mentionManager.togglePicker(text: &content)
                                }
                            }
                            .padding(.top, Spacing.lg)
                        }
                    }
                    .padding(.horizontal, Spacing.md)
                    .padding(.top, Spacing.xxl)

                    Spacer()
                }

                bottomBar
            }

            if mentionManager.showPicker {
                MentionPicker(
                    suggestions: mentionManager.suggestions,
                    isLoading: mentionManager.isLoading,
                    onSelect: { mentionManager.selectMention($0, text: &content) },
                    onClose: { mentionManager.showPicker = false }
                )
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.easeInOut(duration: 0.2), value: mentionManager.showPicker)
        .background(Color.appSurface)
        .presentationDragIndicator(.visible)
        .alert("Category Required", isPresented: $showCategoryRequired) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("Please select a category for your post.")
        }
        .alert(isEditing ? "Couldn't Save Post" : "Couldn't Post", isPresented: $showPostError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(postErrorMessage)
        }
        .sheet(isPresented: $showGifPicker) {
            GifPickerSheet { gif in
                selectedGifUrl = gif.mp4Url
                selectedImages = []
                existingImageUrls = []
            }
            .presentationDetents([.large])
        }
        .sheet(isPresented: $showImagePicker) {
            // Same unified picker as the reply composer — photo grid + camera.
            // Single-select per open; tap "Add Image" again to add more (up to 5).
            MediaPickerSheet(selectedImage: Binding(
                get: { nil },
                set: { newImage in
                    guard let newImage else { return }
                    if selectedImages.count + existingImageUrls.count < 5 {
                        selectedImages.append(newImage)
                        selectedGifUrl = nil
                    }
                }
            ))
            .presentationDetents([.large])
        }
        .onAppear {
            if let post = editingPost {
                content = post.content
                selectedCategory = post.categoryType
                existingImageUrls = post.allImageUrls
            }
        }
    }

    // MARK: - Chips

    private func composerChip(icon: String, label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: Spacing.xxs) {
                Image(icon)
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 12, height: 12)
                Text(label)
                    .font(.captionSemibold)
            }
            .foregroundColor(.appSecondary)
            .padding(Spacing.sm)
            .background(Color.appSurfaceSecondary)
            .clipShape(RoundedRectangle(cornerRadius: Radius.xl))
        }
        .buttonStyle(.pressableScale(0.95))
    }

    // MARK: - Bottom Bar

    /// Categories offered in the composer.
    private let composerCategories: [PostResponse.PostCategory] = [.asking, .sharing]

    private func categoryIcon(_ category: PostResponse.PostCategory) -> String {
        switch category {
        case .asking:     return "feed.ask"        // open-hand
        case .sharing:    return "content.update"  // peace-hand — "Update"
        case .lookingFor: return "content.looking"
        }
    }

    private func categoryLabel(_ category: PostResponse.PostCategory) -> String {
        switch category {
        case .asking:     return "Ask"
        case .sharing:    return "Update"
        case .lookingFor: return "Looking For"
        }
    }

    // Compact iOS-style segmented toggle: a white "thumb" slides under the
    // selected segment via matchedGeometryEffect.
    private var categoryToggle: some View {
        HStack(spacing: 0) {
            ForEach(composerCategories, id: \.self) { category in
                let isSelected = selectedCategory == category
                Button {
                    withAnimation(.snappy(duration: 0.28)) { selectedCategory = category }
                } label: {
                    HStack(spacing: Spacing.xxs) {
                        Image(categoryIcon(category))
                            .renderingMode(.template)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 14, height: 14)
                        Text(categoryLabel(category))
                            .font(.bodyMedium)
                    }
                    .foregroundColor(isSelected ? .appPrimary : .appSecondary)
                    .padding(.horizontal, Spacing.sm)
                    .padding(.vertical, Spacing.xs)
                    .background {
                        if isSelected {
                            Capsule()
                                .fill(Color.appSurface)
                                .shadow(color: Color.black.opacity(0.06), radius: 2, y: 1)
                                .matchedGeometryEffect(id: "categoryThumb", in: categoryThumb)
                        }
                    }
                }
                .buttonStyle(.plain)
            }
        }
        .padding(4)
        .background(Capsule().fill(Color.appSurfaceSecondary))
    }

    private var bottomBar: some View {
        HStack(spacing: Spacing.sm) {
            categoryToggle

            Spacer()

            Text("\(content.count)/\(maxPostLength)")
                .font(.caption12)
                .foregroundColor(content.count > maxPostLength ? .appError : .appSecondary)

            Button(action: postContent) {
                Text(isEditing ? "Save" : "Post")
                    .font(.bodySemibold)
                    .foregroundColor(.appOnAccent)
                    .padding(.horizontal, Spacing.lg)
                    .padding(.vertical, 10)
                    .background(canPost ? Color.appPrimary : Color.appSecondary)
                    .clipShape(RoundedRectangle(cornerRadius: Radius.xl))
            }
            .buttonStyle(.pressableScale(0.95))
            .disabled(!canPost || isPosting)
        }
        .padding(.horizontal, Spacing.md)
        .padding(.top, Spacing.sm)
        .padding(.bottom, Spacing.sm)
    }

    // MARK: - Computed

    private var hasContent: Bool {
        !content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private var canPost: Bool {
        hasContent && content.count <= maxPostLength
    }

    private var placeholderText: String {
        guard let category = selectedCategory else {
            return "What's new?"
        }
        switch category {
        case .asking:
            return "What do you need help with?"
        case .sharing:
            return "What's new?"
        case .lookingFor:
            return "Who or what are you looking for?"
        }
    }

    // MARK: - Actions

    private func postContent() {
        guard canPost else { return }

        guard let category = selectedCategory else {
            showCategoryRequired = true
            return
        }

        isPosting = true

        Task {
            var uploadedImageUrls: [String] = existingImageUrls
            if !selectedImages.isEmpty {
                isUploadingImages = true
                do {
                    let uploaded = try await ImageUploadService.shared.upload(selectedImages)
                    uploadedImageUrls.append(contentsOf: uploaded.map(\.url))
                } catch {
                    postErrorMessage = "Couldn't upload your image. Check your connection and try again."
                    showPostError = true
                    isPosting = false
                    isUploadingImages = false
                    return
                }
                isUploadingImages = false
            }

            let gifUrlString = selectedGifUrl?.absoluteString

            let success: Bool
            if isEditing, let postId = editingPost?._id {
                success = await viewModel.updatePost(
                    postId: postId,
                    content: content.trimmingCharacters(in: .whitespacesAndNewlines),
                    category: category,
                    // Full set, [] included, so removing every image persists.
                    imageUrls: uploadedImageUrls
                )
            } else {
                success = await viewModel.createPost(
                    content: content.trimmingCharacters(in: .whitespacesAndNewlines),
                    category: category,
                    imageUrls: uploadedImageUrls.isEmpty ? nil : uploadedImageUrls,
                    gifUrl: gifUrlString,
                    mentions: mentionManager.selectedMentionIds.isEmpty ? nil : mentionManager.selectedMentionIds
                )
            }

            if success {
                await viewModel.refresh()
                dismiss()
            } else {
                postErrorMessage = viewModel.error ?? "Failed to \(isEditing ? "update" : "create") post"
                showPostError = true
            }

            isPosting = false
        }
    }
}

#Preview {
    PostComposerView(viewModel: FeedViewModel())
}
