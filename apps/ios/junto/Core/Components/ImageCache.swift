//
//  ImageCache.swift
//  mkrs-world
//
//  Image caching with memory + disk persistence
//

import SwiftUI
import UIKit

/// Shared image cache with memory and disk storage
final class ImageCache {
    static let shared = ImageCache()

    private let memoryCache = NSCache<NSString, UIImage>()
    private let fileManager = FileManager.default
    private let cacheDirectory: URL

    private init() {
        // Set up disk cache directory
        let cachesDir = fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first!
        cacheDirectory = cachesDir.appendingPathComponent("ImageCache", isDirectory: true)

        // Create directory if needed
        try? fileManager.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)

        // Configure memory cache limits
        memoryCache.countLimit = 100
        memoryCache.totalCostLimit = 50 * 1024 * 1024 // 50MB
    }

    /// Get cached image for URL
    func image(for url: URL) -> UIImage? {
        let key = cacheKey(for: url)

        // Check memory cache first
        if let cached = memoryCache.object(forKey: key as NSString) {
            return cached
        }

        // Check disk cache
        let filePath = cacheDirectory.appendingPathComponent(key)
        if let data = try? Data(contentsOf: filePath),
           let image = UIImage(data: data) {
            // Store in memory for faster subsequent access
            memoryCache.setObject(image, forKey: key as NSString, cost: data.count)
            return image
        }

        return nil
    }

    /// Store image in cache
    func store(_ image: UIImage, for url: URL) {
        let key = cacheKey(for: url)

        // Store in memory
        if let data = image.jpegData(compressionQuality: 0.8) {
            memoryCache.setObject(image, forKey: key as NSString, cost: data.count)

            // Store on disk asynchronously
            let filePath = cacheDirectory.appendingPathComponent(key)
            DispatchQueue.global(qos: .utility).async {
                try? data.write(to: filePath)
            }
        }
    }

    /// Generate cache key from URL
    private func cacheKey(for url: URL) -> String {
        // Use SHA256-like hash of URL string for filename
        let urlString = url.absoluteString
        var hash: UInt64 = 5381
        for char in urlString.utf8 {
            hash = ((hash << 5) &+ hash) &+ UInt64(char)
        }
        return String(hash, radix: 16)
    }

    /// Clear all cached images
    func clearCache() {
        memoryCache.removeAllObjects()
        try? fileManager.removeItem(at: cacheDirectory)
        try? fileManager.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
    }

    /// Clear old cache entries (older than 7 days)
    func clearOldEntries() {
        let sevenDaysAgo = Date().addingTimeInterval(-7 * 24 * 60 * 60)

        guard let files = try? fileManager.contentsOfDirectory(
            at: cacheDirectory,
            includingPropertiesForKeys: [.contentModificationDateKey]
        ) else { return }

        for file in files {
            if let attributes = try? fileManager.attributesOfItem(atPath: file.path),
               let modDate = attributes[.modificationDate] as? Date,
               modDate < sevenDaysAgo {
                try? fileManager.removeItem(at: file)
            }
        }
    }
}

/// SwiftUI view that loads images with caching
struct CachedAsyncImage<Content: View, Placeholder: View>: View {
    let url: URL?
    let content: (Image) -> Content
    let placeholder: () -> Placeholder

    @State private var loadedImage: UIImage?
    @State private var isLoading = false

    init(
        url: URL?,
        @ViewBuilder content: @escaping (Image) -> Content,
        @ViewBuilder placeholder: @escaping () -> Placeholder
    ) {
        self.url = url
        self.content = content
        self.placeholder = placeholder
    }

    var body: some View {
        Group {
            if let image = loadedImage {
                content(Image(uiImage: image))
            } else {
                placeholder()
                    .onAppear {
                        loadImage()
                    }
            }
        }
    }

    private func loadImage() {
        guard let url = url, !isLoading else { return }

        // Check cache first
        if let cached = ImageCache.shared.image(for: url) {
            loadedImage = cached
            return
        }

        // Fetch from network
        isLoading = true
        Task {
            do {
                let (data, _) = try await URLSession.shared.data(from: url)
                if let image = UIImage(data: data) {
                    ImageCache.shared.store(image, for: url)
                    await MainActor.run {
                        loadedImage = image
                    }
                }
            } catch {
                print("ImageCache: Failed to load image: \(error)")
            }
            await MainActor.run {
                isLoading = false
            }
        }
    }
}

// Convenience initializer for simple cases
extension CachedAsyncImage where Placeholder == ProgressView<EmptyView, EmptyView> {
    init(url: URL?, @ViewBuilder content: @escaping (Image) -> Content) {
        self.init(url: url, content: content, placeholder: { ProgressView() })
    }
}
