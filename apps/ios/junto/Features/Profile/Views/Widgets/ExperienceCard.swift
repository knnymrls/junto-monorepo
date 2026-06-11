//
//  ExperienceCard.swift
//  mkrs-world
//
//  Experience/internship portfolio widget
//

import SwiftUI

struct ExperienceCard: View {
    let item: PortfolioItemResponse
    @State private var resolvedUrls: [String: URL] = [:]

    private var storageIds: [String] {
        item.imageUrls ?? []
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            // Photos lead, banner-style — same fixed-box treatment as the
            // feed's event card (image fills into the box, never drives layout).
            if let bannerId = storageIds.first {
                banner(bannerId)
            }

            VStack(alignment: .leading, spacing: Spacing.xs) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: Spacing.xxs) {
                        if let title = item.title, !title.isEmpty {
                            Text(title)
                                .font(.bodyLargeSemibold)
                                .foregroundColor(.appPrimary)
                        }

                        if let org = item.organization, !org.isEmpty {
                            Text(org)
                                .font(.body14)
                                .foregroundColor(.appSecondary)
                        }
                    }

                    Spacer()

                    Image(.feedOpportunityFill)
                        .renderingMode(.template)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 14, height: 14)
                        .foregroundColor(.appSecondary)
                }

                if let dateRange = formattedDateRange {
                    Text(dateRange)
                        .font(.caption12)
                        .foregroundColor(.appSecondary)
                }

                if let description = item.description, !description.isEmpty {
                    Text(description)
                        .font(.bodySmall)
                        .foregroundColor(.appPrimary)
                        .lineSpacing(3)
                        .padding(.top, Spacing.xxs)
                }

                if storageIds.count > 1 {
                    photoStrip
                        .padding(.top, Spacing.xxs)
                }
            }
        }
        .padding(Spacing.lg)
        .cardStyle()
        .task { await resolveStorageIds() }
    }

    // MARK: - Banner (first photo, forefront)

    @ViewBuilder
    private func banner(_ storageId: String) -> some View {
        if let url = resolvedUrls[storageId] {
            ExpandableImage(url: url, cornerRadius: Radius.md) {
                Color.appSurfaceSecondary
                    .frame(maxWidth: .infinity)
                    .frame(height: 140)
                    .overlay(
                        CachedAsyncImage(url: url) { image in
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        } placeholder: {
                            Color.appSurfaceSecondary
                        }
                    )
                    .clipShape(RoundedRectangle(cornerRadius: Radius.md, style: .continuous))
            }
        } else {
            RoundedRectangle(cornerRadius: Radius.md, style: .continuous)
                .fill(Color.appSurfaceSecondary)
                .frame(maxWidth: .infinity)
                .frame(height: 140)
                .overlay(ProgressView())
        }
    }

    // Horizontal thumbnail strip for the remaining photos — same
    // resolve-then-expand flow as the gallery widget.
    private var photoStrip: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Spacing.sm) {
                ForEach(Array(storageIds.dropFirst()), id: \.self) { storageId in
                    if let url = resolvedUrls[storageId] {
                        ExpandableImage(url: url, cornerRadius: Radius.md) {
                            CachedAsyncImage(url: url) { image in
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                            } placeholder: {
                                Color.appSurfaceSecondary
                            }
                            .frame(width: 96, height: 72)
                            .clipShape(RoundedRectangle(cornerRadius: Radius.md))
                        }
                    } else {
                        RoundedRectangle(cornerRadius: Radius.md)
                            .fill(Color.appSurfaceSecondary)
                            .frame(width: 96, height: 72)
                            .overlay(ProgressView())
                    }
                }
            }
        }
    }

    private func resolveStorageIds() async {
        for storageId in storageIds {
            do {
                if let urlString = try await ConvexClientManager.shared.getFileUrl(storageId: storageId),
                   let url = URL(string: urlString) {
                    resolvedUrls[storageId] = url
                }
            } catch {
                print("ExperienceCard: resolve error for \(storageId): \(error)")
            }
        }
    }

    private var formattedDateRange: String? {
        guard let start = item.startDate, !start.isEmpty else { return nil }
        if let end = item.endDate, !end.isEmpty {
            return "\(start) - \(end)"
        }
        return "\(start) - Present"
    }
}
