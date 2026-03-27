//
//  GifPickerSheet.swift
//  mkrs-world
//
//  GIF search picker powered by Giphy REST API
//

import SwiftUI
import Combine

struct GifPickerSheet: View {
    let onSelect: (GiphyGif) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var searchText = ""
    @State private var gifs: [GiphyGif] = []
    @State private var isLoading = false
    @State private var searchTask: Task<Void, Never>?

    private let columns = [
        GridItem(.flexible(), spacing: Spacing.xs),
        GridItem(.flexible(), spacing: Spacing.xs),
    ]

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                searchBar
                    .padding(.horizontal, Spacing.md)
                    .padding(.vertical, Spacing.sm)

                if isLoading && gifs.isEmpty {
                    Spacer()
                    ProgressView()
                        .tint(.appSecondary)
                    Spacer()
                } else {
                    gifGrid
                }

                attribution
            }
            .background(Color.appBackground)
            .navigationTitle("GIFs")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(.appPrimary)
                }
            }
        }
        .task {
            await loadTrending()
        }
    }

    // MARK: - Search Bar

    private var searchBar: some View {
        HStack(spacing: Spacing.sm) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 14))
                .foregroundColor(.appSecondary)

            TextField("Search GIFs...", text: $searchText)
                .font(.body14)
                .foregroundColor(.appPrimary)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)
                .onChange(of: searchText) { _, newValue in
                    debounceSearch(query: newValue)
                }

            if !searchText.isEmpty {
                Button(action: {
                    searchText = ""
                    searchTask?.cancel()
                    Task { await loadTrending() }
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 14))
                        .foregroundColor(.appSecondary)
                }
            }
        }
        .padding(.horizontal, Spacing.md)
        .padding(.vertical, Spacing.sm)
        .background(Color.appSurfaceSecondary)
        .cornerRadius(Radius.pill)
    }

    // MARK: - GIF Grid

    private var gifGrid: some View {
        ScrollView(showsIndicators: false) {
            LazyVGrid(columns: columns, spacing: Spacing.xs) {
                ForEach(gifs) { gif in
                    Button(action: {
                        onSelect(gif)
                        dismiss()
                    }) {
                        GifPlayerView(url: gif.mp4Url)
                            .aspectRatio(gif.aspectRatio, contentMode: .fill)
                            .frame(minHeight: 100, maxHeight: 160)
                            .clipShape(RoundedRectangle(cornerRadius: Radius.md))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, Spacing.md)
            .padding(.vertical, Spacing.sm)
        }
    }

    // MARK: - Attribution

    private var attribution: some View {
        HStack {
            Spacer()
            Text("Powered by GIPHY")
                .font(.micro)
                .foregroundColor(.appSecondary)
            Spacer()
        }
        .padding(.vertical, Spacing.sm)
    }

    // MARK: - Data Loading

    private func loadTrending() async {
        isLoading = true
        do {
            gifs = try await GiphyService.shared.trending()
        } catch {
            print("GifPickerSheet: Failed to load trending - \(error)")
        }
        isLoading = false
    }

    private func debounceSearch(query: String) {
        searchTask?.cancel()
        searchTask = Task {
            try? await Task.sleep(for: .milliseconds(300))
            guard !Task.isCancelled else { return }

            isLoading = true
            do {
                gifs = try await GiphyService.shared.search(query: query)
            } catch {
                if !Task.isCancelled {
                    print("GifPickerSheet: Search failed - \(error)")
                }
            }
            isLoading = false
        }
    }
}
