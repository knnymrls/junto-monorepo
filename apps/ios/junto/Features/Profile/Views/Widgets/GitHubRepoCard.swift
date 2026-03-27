//
//  GitHubRepoCard.swift
//  mkrs-world
//
//  iOS-widget-style GitHub contribution graph — just the green squares
//

import SwiftUI

struct GitHubRepoCard: View {
    let item: PortfolioItemResponse
    @State private var dayGrid: [[Int]] = []
    @State private var isLoading = true

    private var username: String {
        (item.url ?? "")
            .replacingOccurrences(of: "https://github.com/", with: "")
            .replacingOccurrences(of: "http://github.com/", with: "")
            .replacingOccurrences(of: "github.com/", with: "")
            .trimmingCharacters(in: CharacterSet(charactersIn: "/@"))
            .components(separatedBy: "/").first ?? ""
    }

    var body: some View {
        Button(action: openProfile) {
            GeometryReader { geo in
                let side = geo.size.width
                ZStack {
                    if isLoading {
                        ProgressView()
                            .tint(.white.opacity(0.3))
                    } else {
                        contributionGrid(side: side)
                    }
                }
                .frame(width: side, height: side)
                .background(Color(red: 0.11, green: 0.12, blue: 0.14))
                .clipShape(RoundedRectangle(cornerRadius: Radius.xxl, style: .continuous))
            }
            .aspectRatio(1, contentMode: .fit)
        }
        .buttonStyle(.plain)
        .task { await fetchContributions() }
    }

    // MARK: - Grid

    private func contributionGrid(side: CGFloat) -> some View {
        let padding: CGFloat = side * 0.12
        let inner = side - padding * 2
        let rows = 7
        let gap: CGFloat = side * 0.02
        let cellFromRows = (inner - CGFloat(rows - 1) * gap) / CGFloat(rows)
        let cols = max(1, Int((inner + gap) / (cellFromRows + gap)))
        let cellSize = (inner - CGFloat(cols - 1) * gap) / CGFloat(cols)
        let grid = buildGrid(rows: rows, cols: cols)

        return VStack(spacing: gap) {
            ForEach(0..<rows, id: \.self) { row in
                HStack(spacing: gap) {
                    ForEach(0..<cols, id: \.self) { col in
                        RoundedRectangle(cornerRadius: cellSize * 0.2)
                            .fill(greenForLevel(grid[row][col]))
                            .frame(width: cellSize, height: cellSize)
                    }
                }
            }
        }
        .padding(padding)
    }

    private func buildGrid(rows: Int, cols: Int) -> [[Int]] {
        if dayGrid.isEmpty {
            return Array(repeating: Array(repeating: 0, count: cols), count: rows)
        }
        var result = Array(repeating: Array(repeating: 0, count: cols), count: rows)
        let weeks = Array(dayGrid.suffix(cols))
        for col in 0..<min(cols, weeks.count) {
            for row in 0..<min(rows, weeks[col].count) {
                result[row][col] = weeks[col][row]
            }
        }
        return result
    }

    /// Maps GitHub's 0-4 contribution level to colors matching their actual palette
    private func greenForLevel(_ level: Int) -> Color {
        switch level {
        case 0: return Color.white.opacity(0.08)
        case 1: return Color(red: 0.0, green: 0.43, blue: 0.18)
        case 2: return Color(red: 0.0, green: 0.57, blue: 0.24)
        case 3: return Color(red: 0.15, green: 0.74, blue: 0.33)
        default: return Color(red: 0.22, green: 0.9, blue: 0.42)
        }
    }

    // MARK: - Fetch

    private func fetchContributions() async {
        guard !username.isEmpty else {
            isLoading = false
            return
        }

        let endpoint = "https://github-contributions-api.jogruber.de/v4/\(username)?y=last"
        guard let url = URL(string: endpoint) else {
            isLoading = false
            return
        }

        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let response = try JSONDecoder().decode(GitHubContributionsResponse.self, from: data)

            // Group contributions by week (7 days each), level is already 0-4
            let sorted = response.contributions.sorted { $0.date < $1.date }
            var weeks: [[Int]] = []
            var currentWeek: [Int] = []

            for contrib in sorted {
                currentWeek.append(contrib.level)
                if currentWeek.count == 7 {
                    weeks.append(currentWeek)
                    currentWeek = []
                }
            }
            if !currentWeek.isEmpty {
                // Pad last partial week
                while currentWeek.count < 7 {
                    currentWeek.append(0)
                }
                weeks.append(currentWeek)
            }

            dayGrid = weeks
        } catch {
            print("GitHubRepoCard: fetch error: \(error)")
        }
        isLoading = false
    }

    private func openProfile() {
        guard !username.isEmpty,
              let url = URL(string: "https://github.com/\(username)") else { return }
        UIApplication.shared.open(url)
    }
}

// MARK: - GitHub Contributions API Models

struct GitHubContributionsResponse: Codable {
    let contributions: [GitHubContribution]
}

struct GitHubContribution: Codable {
    let date: String
    let count: Int
    let level: Int
}
