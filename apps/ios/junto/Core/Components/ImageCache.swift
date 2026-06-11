//
//  ImageCache.swift
//  mkrs-world
//
//  Image caching with memory + disk persistence. Disk I/O and JPEG encoding
//  run off the main thread; concurrent requests for the same URL share one
//  network fetch.
//

import SwiftUI
import UIKit

/// Shared image cache with memory and disk storage.
final class ImageCache: @unchecked Sendable {
    static let shared = ImageCache()

    private let memoryCache = NSCache<NSString, UIImage>()
    private let fileManager = FileManager.default
    private let cacheDirectory: URL
    private let diskQueue = DispatchQueue(label: "ImageCache.disk", qos: .utility)

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

    /// Synchronous memory-only lookup — safe to call from view bodies.
    func memoryImage(for url: URL) -> UIImage? {
        memoryCache.object(forKey: cacheKey(for: url) as NSString)
    }

    /// Memory, then disk (off-main) lookup.
    func image(for url: URL) async -> UIImage? {
        if let cached = memoryImage(for: url) { return cached }

        let key = cacheKey(for: url)
        let filePath = cacheDirectory.appendingPathComponent(key)
        let loaded: UIImage? = await withCheckedContinuation { continuation in
            diskQueue.async {
                guard let data = try? Data(contentsOf: filePath),
                      let image = UIImage(data: data) else {
                    continuation.resume(returning: nil)
                    return
                }
                continuation.resume(returning: image)
            }
        }
        if let loaded {
            memoryCache.setObject(loaded, forKey: key as NSString)
        }
        return loaded
    }

    /// Store image in memory now, on disk asynchronously (encode included —
    /// jpegData on the caller's thread was a main-thread stall).
    func store(_ image: UIImage, for url: URL) {
        let key = cacheKey(for: url)
        memoryCache.setObject(image, forKey: key as NSString)

        let filePath = cacheDirectory.appendingPathComponent(key)
        diskQueue.async {
            guard let data = image.jpegData(compressionQuality: 0.8) else { return }
            try? data.write(to: filePath)
        }
    }

    /// Generate cache key from URL (djb2 hash of the absolute string).
    private func cacheKey(for url: URL) -> String {
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
        diskQueue.async { [cacheDirectory, fileManager] in
            try? fileManager.removeItem(at: cacheDirectory)
            try? fileManager.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
        }
    }

    /// Clear old cache entries (older than 7 days)
    func clearOldEntries() {
        diskQueue.async { [cacheDirectory, fileManager] in
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
}

/// Deduplicates concurrent fetches: N views asking for the same URL share one
/// network request.
@MainActor
private final class ImageFetchCoordinator {
    static let shared = ImageFetchCoordinator()
    private var inFlight: [URL: Task<UIImage?, Never>] = [:]

    func fetch(_ url: URL) async -> UIImage? {
        if let existing = inFlight[url] {
            return await existing.value
        }
        let task = Task<UIImage?, Never> {
            if let cached = await ImageCache.shared.image(for: url) {
                return cached
            }
            do {
                let (data, _) = try await URLSession.shared.data(from: url)
                guard let image = UIImage(data: data) else { return nil }
                ImageCache.shared.store(image, for: url)
                return image
            } catch {
                return nil
            }
        }
        inFlight[url] = task
        let image = await task.value
        inFlight[url] = nil
        return image
    }
}

/// SwiftUI view that loads images with caching. Reloads when `url` changes —
/// the old version kept showing the previous image after e.g. an avatar
/// upload produced a new URL.
struct CachedAsyncImage<Content: View, Placeholder: View>: View {
    let url: URL?
    let content: (Image) -> Content
    let placeholder: () -> Placeholder

    @State private var loadedImage: UIImage?

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
            }
        }
        .task(id: url) {
            await load()
        }
    }

    private func load() async {
        guard let url else {
            loadedImage = nil
            return
        }
        // Memory hit renders without a placeholder frame.
        if let cached = ImageCache.shared.memoryImage(for: url) {
            loadedImage = cached
            return
        }
        loadedImage = nil
        let image = await ImageFetchCoordinator.shared.fetch(url)
        // task(id:) cancelled us if the URL changed mid-flight — don't apply
        // a stale result over the newer load.
        if !Task.isCancelled {
            loadedImage = image
        }
    }
}

// Convenience initializer for simple cases
extension CachedAsyncImage where Placeholder == ProgressView<EmptyView, EmptyView> {
    init(url: URL?, @ViewBuilder content: @escaping (Image) -> Content) {
        self.init(url: url, content: content, placeholder: { ProgressView() })
    }
}
