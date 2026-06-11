//
//  ImageUploadService.swift
//  mkrs-world
//
//  Single upload pipeline for images: compress off the main actor, upload to
//  Convex storage, and resolve the serving URL. Callers either get a usable
//  HTTP URL or a thrown error — never a raw storage ID masquerading as a URL.
//

import UIKit

/// Result of a successful image upload.
struct UploadedImage {
    let storageId: String
    /// Resolved HTTP serving URL (never a bare storage ID).
    let url: String
}

final class ImageUploadService {
    static let shared = ImageUploadService()

    private init() {}

    /// Compress and upload one image, resolving its serving URL.
    /// Runs compression off the main actor (this type is not actor-isolated).
    func upload(_ image: UIImage, maxSizeKB: Int = 1024) async throws -> UploadedImage {
        let storageId = try await uploadForStorageId(image, maxSizeKB: maxSizeKB)
        guard let url = try await ConvexClientManager.shared.getFileUrl(storageId: storageId),
              url.hasPrefix("http") else {
            throw ConvexUploadError.urlResolutionFailed
        }
        return UploadedImage(storageId: storageId, url: url)
    }

    /// Upload several images sequentially. Throws on the first failure so the
    /// caller can surface one clear error instead of silently dropping images.
    func upload(_ images: [UIImage], maxSizeKB: Int = 1024) async throws -> [UploadedImage] {
        var uploaded: [UploadedImage] = []
        for image in images {
            uploaded.append(try await upload(image, maxSizeKB: maxSizeKB))
        }
        return uploaded
    }

    /// Compress and upload one image, returning only the storage ID.
    /// For flows that persist storage IDs and resolve URLs server-side
    /// (portfolio widgets, event covers).
    func uploadForStorageId(_ image: UIImage, maxSizeKB: Int = 1024) async throws -> String {
        guard let data = Self.compress(image, maxSizeKB: maxSizeKB) else {
            throw ConvexUploadError.compressionFailed
        }
        return try await ConvexClientManager.shared.uploadRawData(data, contentType: "image/jpeg")
    }

    // MARK: - Compression (moved out of @MainActor ConvexClientManager so it
    // no longer freezes the UI during multi-image posts)

    static func compress(_ image: UIImage, maxSizeKB: Int = 1024) -> Data? {
        let maxBytes = maxSizeKB * 1024

        // First, resize if image is very large (> 3000px on longest side)
        var processedImage = image
        let maxDimension: CGFloat = 3000
        if image.size.width > maxDimension || image.size.height > maxDimension {
            let scale = maxDimension / max(image.size.width, image.size.height)
            let newSize = CGSize(width: image.size.width * scale, height: image.size.height * scale)
            let format = UIGraphicsImageRendererFormat()
            format.scale = image.scale
            processedImage = UIGraphicsImageRenderer(size: newSize, format: format).image { _ in
                image.draw(in: CGRect(origin: .zero, size: newSize))
            }
        }

        // Start with high quality and reduce gradually if needed
        var compression: CGFloat = 0.9
        var imageData = processedImage.jpegData(compressionQuality: compression)

        while let data = imageData, data.count > maxBytes, compression > 0.5 {
            compression -= 0.05
            imageData = processedImage.jpegData(compressionQuality: compression)
        }

        // If still too large after quality reduction, resize proportionally
        if let data = imageData, data.count > maxBytes {
            let scale: CGFloat = 0.8
            let newSize = CGSize(
                width: processedImage.size.width * scale,
                height: processedImage.size.height * scale
            )
            let format = UIGraphicsImageRendererFormat()
            format.scale = 1.0
            let smaller = UIGraphicsImageRenderer(size: newSize, format: format).image { _ in
                processedImage.draw(in: CGRect(origin: .zero, size: newSize))
            }
            imageData = smaller.jpegData(compressionQuality: 0.85)
        }

        return imageData
    }
}
