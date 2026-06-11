//
//  ConvexClient+Storage.swift
//  mkrs-world
//
//  File storage: upload URLs, raw uploads, URL resolution.
//

import Foundation
import ConvexMobile
import Combine
import UIKit

extension ConvexClientManager {

    /// Generate an upload URL for file storage
    func generateUploadUrl() async throws -> String {
        return try await client.mutation("storage:generateUploadUrl", with: [:] as [String: String])
    }

    /// Upload raw data without compression (for pre-compressed or non-image data).
    /// Image uploads go through ImageUploadService, which compresses off-main.
    func uploadRawData(_ data: Data, contentType: String = "application/octet-stream") async throws -> String {
        // Get upload URL from Convex
        let uploadUrl = try await generateUploadUrl()

        guard let url = URL(string: uploadUrl) else {
            throw ConvexUploadError.invalidUrl
        }

        // Upload the data
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue(contentType, forHTTPHeaderField: "Content-Type")
        request.httpBody = data

        let (responseData, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw ConvexUploadError.uploadFailed
        }

        // Parse the storage ID from response
        let json = try JSONDecoder().decode(UploadResponse.self, from: responseData)
        return json.storageId
    }

    /// Get a URL for a stored file
    func getFileUrl(storageId: String) async throws -> String? {
        return try await queryOnce("storage:getUrl", with: ["storageId": storageId], yielding: String?.self)
    }
}

enum ConvexUploadError: Error, LocalizedError {
    case invalidUrl
    case uploadFailed
    case noStorageId
    case compressionFailed
    case urlResolutionFailed

    var errorDescription: String? {
        switch self {
        case .invalidUrl: return "Invalid upload URL"
        case .uploadFailed: return "Failed to upload image"
        case .noStorageId: return "No storage ID returned"
        case .compressionFailed: return "Failed to compress image"
        case .urlResolutionFailed: return "Image uploaded but its URL couldn't be resolved"
        }
    }
}

struct UploadResponse: Codable {
    let storageId: String
}
