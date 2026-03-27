//
//  GiphyService.swift
//  mkrs-world
//
//  Giphy REST API client for GIF search and trending
//

import Foundation

struct GiphyGif: Identifiable, Hashable {
    let id: String
    let mp4Url: URL
    let previewUrl: URL
    let stillUrl: URL?
    let aspectRatio: CGFloat
    let title: String
}

@MainActor
class GiphyService {
    static let shared = GiphyService()

    // Beta key — 100 req/hr. Replace with production key after applying.
    private let apiKey = "GlVGYHkr3WSBnllca54iNt0yFbjz7L65"
    private let baseUrl = "https://api.giphy.com/v1/gifs"

    private init() {}

    func trending(limit: Int = 25, offset: Int = 0) async throws -> [GiphyGif] {
        var components = URLComponents(string: "\(baseUrl)/trending")!
        components.queryItems = [
            URLQueryItem(name: "api_key", value: apiKey),
            URLQueryItem(name: "limit", value: String(limit)),
            URLQueryItem(name: "offset", value: String(offset)),
            URLQueryItem(name: "rating", value: "pg-13"),
        ]

        return try await fetch(url: components.url!)
    }

    func search(query: String, limit: Int = 25, offset: Int = 0) async throws -> [GiphyGif] {
        guard !query.trimmingCharacters(in: .whitespaces).isEmpty else {
            return try await trending(limit: limit, offset: offset)
        }

        var components = URLComponents(string: "\(baseUrl)/search")!
        components.queryItems = [
            URLQueryItem(name: "api_key", value: apiKey),
            URLQueryItem(name: "q", value: query),
            URLQueryItem(name: "limit", value: String(limit)),
            URLQueryItem(name: "offset", value: String(offset)),
            URLQueryItem(name: "rating", value: "pg-13"),
        ]

        return try await fetch(url: components.url!)
    }

    private func fetch(url: URL) async throws -> [GiphyGif] {
        let (data, _) = try await URLSession.shared.data(from: url)
        let response = try JSONDecoder().decode(GiphyResponse.self, from: data)
        return response.data.compactMap { item in
            guard let mp4String = item.images.fixedWidth.mp4,
                  let mp4Url = URL(string: mp4String),
                  let previewMp4 = item.images.previewGif?.url ?? item.images.fixedWidthSmall?.url,
                  let previewUrl = URL(string: previewMp4) else {
                // Fallback: use fixed_width mp4 for both
                guard let mp4String = item.images.fixedWidth.mp4,
                      let mp4Url = URL(string: mp4String) else { return nil }
                let width = CGFloat(Int(item.images.fixedWidth.width) ?? 200)
                let height = CGFloat(Int(item.images.fixedWidth.height) ?? 200)
                return GiphyGif(
                    id: item.id,
                    mp4Url: mp4Url,
                    previewUrl: mp4Url,
                    stillUrl: item.images.fixedWidthStill.flatMap { URL(string: $0.url) },
                    aspectRatio: width / max(height, 1),
                    title: item.title
                )
            }

            let width = CGFloat(Int(item.images.fixedWidth.width) ?? 200)
            let height = CGFloat(Int(item.images.fixedWidth.height) ?? 200)

            return GiphyGif(
                id: item.id,
                mp4Url: mp4Url,
                previewUrl: previewUrl,
                stillUrl: item.images.fixedWidthStill.flatMap { URL(string: $0.url) },
                aspectRatio: width / max(height, 1),
                title: item.title
            )
        }
    }
}

// MARK: - Giphy API Response Models

private struct GiphyResponse: Codable {
    let data: [GiphyItem]
}

private struct GiphyItem: Codable {
    let id: String
    let title: String
    let images: GiphyImages
}

private struct GiphyImages: Codable {
    let fixedWidth: GiphyImageVariant
    let fixedWidthSmall: GiphyImageVariant?
    let fixedWidthStill: GiphyStillVariant?
    let previewGif: GiphyStillVariant?

    enum CodingKeys: String, CodingKey {
        case fixedWidth = "fixed_width"
        case fixedWidthSmall = "fixed_width_small"
        case fixedWidthStill = "fixed_width_still"
        case previewGif = "preview_gif"
    }
}

private struct GiphyImageVariant: Codable {
    let url: String?
    let mp4: String?
    let width: String
    let height: String
}

private struct GiphyStillVariant: Codable {
    let url: String
}
