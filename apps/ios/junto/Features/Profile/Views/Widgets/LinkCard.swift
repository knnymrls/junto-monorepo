//
//  LinkCard.swift
//  mkrs-world
//
//  Link portfolio widget — shows URL with optional title
//

import SwiftUI

struct LinkCard: View {
    let item: PortfolioItemResponse

    var body: some View {
        if let urlString = item.url, let url = URL(string: urlString) {
            VStack(alignment: .leading, spacing: Spacing.sm) {
                if let title = item.title, !title.isEmpty {
                    Text(title)
                        .font(.bodyLargeSemibold)
                        .foregroundColor(.appPrimary)
                }

                LinkPreviewCard(url: url)
            }
            .padding(Spacing.lg)
            .cardStyle()
        }
    }
}
