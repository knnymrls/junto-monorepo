//
//  ImageGalleryCard.swift
//  mkrs-world
//
//  Image gallery portfolio widget — 2-column grid of images
//

import SwiftUI

struct ImageGalleryCard: View {
    let item: PortfolioItemResponse
    @State private var resolvedUrls: [String: URL] = [:]

    private var storageIds: [String] {
        item.imageUrls ?? []
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            if let title = item.title, !title.isEmpty {
                Text(title)
                    .font(.bodyLargeSemibold)
                    .foregroundColor(.appPrimary)
            }

            let columns = [
                GridItem(.flexible(), spacing: Spacing.sm),
                GridItem(.flexible(), spacing: Spacing.sm)
            ]

            LazyVGrid(columns: columns, spacing: Spacing.sm) {
                ForEach(storageIds, id: \.self) { storageId in
                    if let url = resolvedUrls[storageId] {
                        ExpandableImage(url: url, cornerRadius: Radius.md) {
                            CachedAsyncImage(url: url) { image in
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                            } placeholder: {
                                Color.appSurfaceSecondary
                            }
                            .frame(height: 120)
                            .clipShape(RoundedRectangle(cornerRadius: Radius.md))
                        }
                    } else {
                        RoundedRectangle(cornerRadius: Radius.md)
                            .fill(Color.appSurfaceSecondary)
                            .frame(height: 120)
                            .overlay(ProgressView())
                    }
                }
            }
        }
        .padding(Spacing.lg)
        .cardStyle()
        .task { await resolveStorageIds() }
    }

    private func resolveStorageIds() async {
        for storageId in storageIds {
            do {
                if let urlString = try await ConvexClientManager.shared.getFileUrl(storageId: storageId),
                   let url = URL(string: urlString) {
                    resolvedUrls[storageId] = url
                }
            } catch {
                print("ImageGalleryCard: resolve error for \(storageId): \(error)")
            }
        }
    }
}
