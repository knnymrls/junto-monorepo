//
//  ImageCarousel.swift
//  mkrs-world
//
//  Horizontal swipeable image carousel for posts
//

import SwiftUI
import UIKit

struct ImageCarousel: View {
    let imageUrls: [String]

    var body: some View {
        if imageUrls.isEmpty {
            EmptyView()
        } else if imageUrls.count == 1 {
            singleImage
        } else {
            multipleImages
        }
    }

    // MARK: - Single Image

    private var singleImage: some View {
        Group {
            if let urlString = imageUrls.first, let url = URL(string: urlString) {
                CachedAsyncImage(url: url) { image in
                    ExpandableImage(url: url, cornerRadius: Radius.xxxl) {
                        image.resizable().aspectRatio(contentMode: .fit)
                    }
                    .frame(maxHeight: 220)
                } placeholder: {
                    RoundedRectangle(cornerRadius: Radius.xxxl)
                        .fill(Color.appSurfaceSecondary)
                        .frame(width: 150, height: 220)
                        .overlay(
                            ProgressView()
                                .tint(.appSecondary)
                        )
                }
            }
        }
    }

    // MARK: - Multiple Images

    private var multipleImages: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(alignment: .bottom, spacing: 4) {
                ForEach(Array(imageUrls.enumerated()), id: \.offset) { _, urlString in
                    if let url = URL(string: urlString) {
                        CachedAsyncImage(url: url) { image in
                            ExpandableImage(url: url, cornerRadius: Radius.xxxl) {
                                image.resizable().aspectRatio(contentMode: .fit)
                            }
                            .frame(maxHeight: 220)
                        } placeholder: {
                            RoundedRectangle(cornerRadius: Radius.xxxl)
                                .fill(Color.appSurfaceSecondary)
                                .frame(width: 150, height: 220)
                                .overlay(
                                    ProgressView()
                                        .tint(.appSecondary)
                                )
                        }
                    }
                }
            }
        }
        .frame(height: 220)
    }
}

// MARK: - Preview Carousel (for composer)

struct ImagePreviewCarousel: View {
    @Binding var images: [UIImage]
    var isUploading: Bool = false
    var onRemove: ((Int) -> Void)?

    var body: some View {
        if images.isEmpty {
            EmptyView()
        } else if images.count == 1 {
            // Single image preview
            singlePreview
        } else {
            // Multiple images - horizontal scroll
            multiplePreview
        }
    }

    private var singlePreview: some View {
        ZStack(alignment: .topTrailing) {
            if let image = images.first {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxHeight: 220)
                    .cornerRadius(11)
                    .overlay(
                        Group {
                            if isUploading {
                                RoundedRectangle(cornerRadius: Radius.xxxl)
                                    .fill(Color.black.opacity(0.5))
                                    .overlay(
                                        ProgressView()
                                            .tint(.white)
                                    )
                            }
                        }
                    )
            }

            if !isUploading {
                Button(action: { onRemove?(0) }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.white)
                        .shadow(color: .black.opacity(0.3), radius: 2)
                }
                .padding(8)
            }
        }
    }

    private var multiplePreview: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(alignment: .bottom, spacing: 8) {
                ForEach(Array(images.enumerated()), id: \.offset) { index, image in
                    ZStack(alignment: .topTrailing) {
                        Image(uiImage: image)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(maxHeight: 220)
                            .cornerRadius(11)
                            .overlay(
                                Group {
                                    if isUploading {
                                        RoundedRectangle(cornerRadius: Radius.xxxl)
                                            .fill(Color.black.opacity(0.5))
                                            .overlay(
                                                ProgressView()
                                                    .tint(.white)
                                            )
                                    }
                                }
                            )

                        if !isUploading {
                            Button(action: { onRemove?(index) }) {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.system(size: 24))
                                    .foregroundColor(.white)
                                    .shadow(color: .black.opacity(0.3), radius: 2)
                            }
                            .padding(8)
                        }
                    }
                }

                // Add more button
                if !isUploading {
                    AddMoreImagesButton()
                }
            }
        }
    }
}

// MARK: - Add More Images Button (placeholder, will be wired up in composer)

struct AddMoreImagesButton: View {
    var body: some View {
        RoundedRectangle(cornerRadius: Radius.xxxl)
            .strokeBorder(Color.appSecondary.opacity(0.3), style: StrokeStyle(lineWidth: 1, dash: [5]))
            .frame(width: 60, height: 80)
            .overlay(
                VStack(spacing: 4) {
                    Image(systemName: "plus")
                        .font(.system(size: 18))
                        .foregroundColor(.appSecondary)
                    Text("Add")
                        .font(.system(size: 11))
                        .foregroundColor(.appSecondary)
                }
            )
    }
}

#Preview {
    VStack(spacing: 20) {
        ImageCarousel(
            imageUrls: ["https://picsum.photos/400/600", "https://picsum.photos/600/400"]
        )

        ImagePreviewCarousel(
            images: .constant([UIImage(systemName: "photo")!, UIImage(systemName: "photo.fill")!])
        )
    }
    .padding()
}
