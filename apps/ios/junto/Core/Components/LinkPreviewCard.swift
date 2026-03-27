//
//  LinkPreviewCard.swift
//  mkrs-world
//
//  Link preview card using LinkPresentation framework for OpenGraph data
//

import SwiftUI
import LinkPresentation
import UIKit

// MARK: - Link Metadata Model

struct LinkMetadata: Equatable {
    let url: URL
    var title: String?
    var siteName: String?
    var image: UIImage?

    static func == (lhs: LinkMetadata, rhs: LinkMetadata) -> Bool {
        lhs.url == rhs.url
    }
}

// MARK: - Link Preview Card

struct LinkPreviewCard: View {
    let url: URL
    var isRemovable: Bool = false
    var onRemove: (() -> Void)?

    @State private var metadata: LinkMetadata?
    @State private var isLoading = true
    @State private var loadError = false

    var body: some View {
        Group {
            if isLoading {
                loadingView
            } else if let metadata = metadata {
                previewCard(metadata)
            } else if loadError {
                errorView
            }
        }
        .layoutPriority(-1)
        .task {
            await loadMetadata()
        }
    }

    // MARK: - Loading View

    private var loadingView: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Image placeholder
            Rectangle()
                .fill(Color.appSurfaceSecondary)
                .frame(height: 140)
                .overlay(
                    ProgressView()
                        .tint(.appSecondary)
                )

            // Text placeholder
            HStack {
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    RoundedRectangle(cornerRadius: Radius.xs)
                        .fill(Color.appSurfaceSecondary.opacity(0.8))
                        .frame(width: 200, height: 14)

                    RoundedRectangle(cornerRadius: Radius.xs)
                        .fill(Color.appSurfaceSecondary.opacity(0.8))
                        .frame(width: 100, height: 10)
                }
                Spacer(minLength: 0)
            }
            .padding(Spacing.md)
            .background(Color.appSurfaceSecondary.opacity(0.5))
        }
        .clipShape(RoundedRectangle(cornerRadius: 11))
        .overlay(
            RoundedRectangle(cornerRadius: 11)
                .stroke(Color.appDivider, lineWidth: 0.5)
        )
    }

    // MARK: - Preview Card

    private func previewCard(_ metadata: LinkMetadata) -> some View {
        ZStack(alignment: .topTrailing) {
            Button(action: openLink) {
                VStack(alignment: .leading, spacing: 0) {
                    // Large image at top (X/Twitter style)
                    if let image = metadata.image {
                        Color.clear
                            .aspectRatio(16/9, contentMode: .fit)
                            .frame(maxHeight: 200)
                            .overlay(
                                Image(uiImage: image)
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                            )
                            .clipped()
                    } else {
                        // Fallback when no image
                        Rectangle()
                            .fill(Color.appSurfaceSecondary)
                            .frame(height: 80)
                            .overlay(
                                Image(systemName: "link")
                                    .font(.system(size: 28))
                                    .foregroundColor(.appSecondary)
                            )
                    }

                    // Text content below image
                    HStack {
                        VStack(alignment: .leading, spacing: Spacing.xxs) {
                            if let title = metadata.title, !title.isEmpty {
                                Text(title)
                                    .font(.bodyMedium)
                                    .foregroundColor(.appPrimary)
                                    .lineLimit(2)
                                    .multilineTextAlignment(.leading)
                            }

                            HStack(spacing: Spacing.xxs) {
                                Image(systemName: "link")
                                    .font(.micro)
                                Text(metadata.siteName ?? metadata.url.host ?? "")
                                    .font(.caption12)
                            }
                            .foregroundColor(.appSecondary)
                        }
                        Spacer(minLength: 0)
                    }
                    .padding(Spacing.md)
                    .background(Color.appSurfaceSecondary.opacity(0.5))
                }
                .clipShape(RoundedRectangle(cornerRadius: 11))
                .overlay(
                    RoundedRectangle(cornerRadius: 11)
                        .stroke(Color.appDivider, lineWidth: 0.5)
                )
            }
            .buttonStyle(.plain)

            // Remove button
            if isRemovable, let onRemove = onRemove {
                Button(action: onRemove) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.heading2)
                        .foregroundColor(.white)
                        .shadow(color: .black.opacity(0.3), radius: 2)
                }
                .padding(Spacing.sm)
            }
        }
    }

    // MARK: - Error View

    private var errorView: some View {
        ZStack(alignment: .topTrailing) {
            Button(action: openLink) {
                VStack(alignment: .leading, spacing: 0) {
                    // Fallback image area
                    Rectangle()
                        .fill(Color.appSurfaceSecondary)
                        .frame(height: 80)
                        .overlay(
                            Image(systemName: "globe")
                                .font(.system(size: 28))
                                .foregroundColor(.appSecondary)
                        )

                    // Text content
                    HStack {
                        VStack(alignment: .leading, spacing: Spacing.xxs) {
                            Text(url.host ?? "Link")
                                .font(.bodyMedium)
                                .foregroundColor(.appPrimary)
                                .lineLimit(1)

                            HStack(spacing: Spacing.xxs) {
                                Image(systemName: "link")
                                    .font(.micro)
                                Text(url.absoluteString)
                                    .font(.caption12)
                                    .lineLimit(1)
                            }
                            .foregroundColor(.appSecondary)
                        }
                        Spacer(minLength: 0)
                    }
                    .padding(Spacing.md)
                    .background(Color.appSurfaceSecondary.opacity(0.5))
                }
                .clipShape(RoundedRectangle(cornerRadius: 11))
                .overlay(
                    RoundedRectangle(cornerRadius: 11)
                        .stroke(Color.appDivider, lineWidth: 0.5)
                )
            }
            .buttonStyle(.plain)

            // Remove button
            if isRemovable, let onRemove = onRemove {
                Button(action: onRemove) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.heading2)
                        .foregroundColor(.white)
                        .shadow(color: .black.opacity(0.3), radius: 2)
                }
                .padding(Spacing.sm)
            }
        }
    }

    // MARK: - Actions

    private func openLink() {
        UIApplication.shared.open(url)
    }

    private func loadMetadata() async {
        let provider = LPMetadataProvider()

        do {
            let lpMetadata = try await provider.startFetchingMetadata(for: url)

            var linkMetadata = LinkMetadata(url: url)
            linkMetadata.title = lpMetadata.title
            linkMetadata.siteName = lpMetadata.url?.host

            // Extract image from imageProvider
            if let imageProvider = lpMetadata.imageProvider {
                linkMetadata.image = await loadImage(from: imageProvider)
            }

            await MainActor.run {
                self.metadata = linkMetadata
                self.isLoading = false
            }
        } catch {
            print("LinkPreviewCard: Failed to load metadata - \(error)")
            await MainActor.run {
                self.loadError = true
                self.isLoading = false
            }
        }
    }

    private func loadImage(from provider: NSItemProvider) async -> UIImage? {
        await withCheckedContinuation { continuation in
            provider.loadObject(ofClass: UIImage.self) { image, error in
                continuation.resume(returning: image as? UIImage)
            }
        }
    }
}

// MARK: - Compact variant for display in feed

struct CompactLinkPreviewCard: View {
    let url: URL
    var onTap: (() -> Void)?

    var body: some View {
        Button(action: { onTap?() ?? openLink() }) {
            HStack(spacing: Spacing.sm) {
                Image(systemName: "link")
                    .font(.body14)
                    .foregroundColor(.blue)

                Text(url.host ?? url.absoluteString)
                    .font(.bodySmall)
                    .foregroundColor(.blue)
                    .lineLimit(1)

                Image(systemName: "arrow.up.right")
                    .font(.micro)
                    .foregroundColor(.blue.opacity(0.7))
            }
            .padding(.horizontal, Spacing.md)
            .padding(.vertical, Spacing.sm)
            .background(Color.blue.opacity(0.1))
            .cornerRadius(Radius.md)
        }
        .buttonStyle(.plain)
    }

    private func openLink() {
        UIApplication.shared.open(url)
    }
}

#Preview {
    VStack(spacing: 20) {
        LinkPreviewCard(
            url: URL(string: "https://apple.com")!,
            isRemovable: true,
            onRemove: {}
        )

        CompactLinkPreviewCard(
            url: URL(string: "https://github.com/knnymrls")!
        )
    }
    .padding()
}
