//
//  ExperienceCard.swift
//  mkrs-world
//
//  Experience/internship portfolio widget
//

import SwiftUI

struct ExperienceCard: View {
    let item: PortfolioItemResponse

    var body: some View {
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

                Image(systemName: "briefcase.fill")
                    .font(.body14)
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
        }
        .padding(Spacing.lg)
        .cardStyle()
    }

    private var formattedDateRange: String? {
        guard let start = item.startDate, !start.isEmpty else { return nil }
        if let end = item.endDate, !end.isEmpty {
            return "\(start) - \(end)"
        }
        return "\(start) - Present"
    }
}
