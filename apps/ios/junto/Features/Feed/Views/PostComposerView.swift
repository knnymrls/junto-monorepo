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
    @State private var selectedCategory: PostResponse.PostCategory? = nil
    @State private var isPosting = false

    // Image state
    @State private var selectedImages: [UIImage] = []
    @State private var isUploadingImages = false
    @State private var existingImageUrls: [String] = []

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

                            HStack(spacing: Spacing.lg) {
                                Button(action: { mentionManager.togglePicker(text: &content) }) {
                                    Image("action.mention")
                                        .renderingMode(.template)
                                        .resizable()
                                        .frame(width: 20, height: 20)
                                        .foregroundColor(mentionManager.showPicker ? .appPrimary : .appSecondary)
                                }

                                MultiImagePickerWithCameraButton(
                                    selectedImages: Binding(
                                        get: { selectedImages },
                                        set: { newImages in
                                            selectedImages = newImages
                                            if !newImages.isEmpty { selectedGifUrl = nil }
                                        }
                                    ),
                                    iconColor: existingImageUrls.isEmpty && selectedImages.isEmpty ? .appSecondary : .appPrimary,
                                    maxImages: 5 - existingImageUrls.count
                                )

                                Button(action: {
                                    showGifPicker = true
                                }) {
                                    Image("action.gif")
                                        .renderingMode(.template)
                                        .resizable()
                                        .frame(width: 20, height: 20)
                                        .foregroundColor(selectedGifUrl != nil ? .appPrimary : .appSecondary)
                                }
                            }
                            .padding(.top, Spacing.md)
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
        .sheet(isPresented: $showGifPicker) {
            GifPickerSheet { gif in
                selectedGifUrl = gif.mp4Url
                selectedImages = []
                existingImageUrls = []
            }
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

    // MARK: - Bottom Bar

    private var bottomBar: some View {
        HStack {
            Menu {
                ForEach(PostResponse.PostCategory.allCases, id: \.self) { category in
                    Button(action: { selectedCategory = category }) {
                        HStack(spacing: 8) {
                            Image(category.customIconName)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 12, height: 12)
                            Text(category.displayName)
                        }
                    }
                }
            } label: {
                HStack(spacing: Spacing.xs) {
                    if let category = selectedCategory {
                        Image(category.customIconName)
                            .resizable()
                            .frame(width: 14, height: 14)
                    } else {
                        Image(systemName: "square.grid.2x2")
                            .font(.system(size: 14))
                    }

                    Text(selectedCategory?.displayName ?? "Category")
                        .font(.bodyLargeMedium)
                }
                .foregroundColor(selectedCategory == nil ? .appSecondary : .appPrimary)
                .frame(width: 140, alignment: .leading)
            }

            Spacer()

            Text("\(content.count)/\(maxPostLength)")
                .font(.caption12)
                .foregroundColor(content.count > maxPostLength ? .red : .appSecondary)

            Button(action: postContent) {
                Text(isEditing ? "Save" : "Post")
                    .font(.bodySemibold)
                    .foregroundColor(.white)
                    .padding(.horizontal, Spacing.lg)
                    .padding(.vertical, Spacing.md)
                    .background(canPost ? Color.appPrimary : Color.appSecondary)
                    .cornerRadius(Spacing.xl)
            }
            .disabled(!canPost || isPosting)
        }
        .padding(.horizontal, Spacing.md)
        .padding(.vertical, Spacing.md)
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
            print("PostComposerView: Attempting to \(isEditing ? "update" : "create") post...")
            print("PostComposerView: Content: \(content.prefix(50))...")
            print("PostComposerView: Category: \(category.rawValue)")

            let convex = ConvexClientManager.shared
            var uploadedImageUrls: [String] = existingImageUrls
            if !selectedImages.isEmpty {
                isUploadingImages = true
                for (index, image) in selectedImages.enumerated() {
                    do {
                        let storageId = try await convex.uploadImage(image)
                        if let url = try await convex.getFileUrl(storageId: storageId) {
                            uploadedImageUrls.append(url)
                            print("PostComposerView: Image \(index + 1) uploaded")
                        }
                    } catch {
                        print("PostComposerView: Failed to upload image \(index + 1) - \(error)")
                        postErrorMessage = "Failed to upload image"
                        showPostError = true
                        isPosting = false
                        isUploadingImages = false
                        return
                    }
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
                    imageUrls: uploadedImageUrls.isEmpty ? nil : uploadedImageUrls
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
                print("PostComposerView: Post \(isEditing ? "updated" : "created") successfully!")
                await viewModel.refresh()
                dismiss()
            } else {
                print("PostComposerView: Post failed - \(viewModel.error ?? "unknown error")")
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
