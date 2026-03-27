//
//  EditProfileSheet.swift
//  mkrs-world
//
//  Sheet for reordering portfolio widgets via drag-and-drop.
//  Local-first editing — only syncs on Save.
//

import SwiftUI

struct EditProfileSheet: View {
    let user: UserResponse
    @Environment(\.dismiss) private var dismiss
    @State private var items: [PortfolioItemResponse] = []
    @State private var isLoading = true
    @State private var isSaving = false
    @State private var showAddSheet = false

    var body: some View {
        NavigationStack {
            Group {
                if isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if items.isEmpty {
                    EmptyStateView(
                        icon: "square.grid.2x2",
                        title: "No widgets yet",
                        subtitle: "Add GitHub repos, images, links, or experiences"
                    )
                } else {
                    WidgetGridEditor(items: $items)
                }
            }
            .navigationTitle("Edit Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .disabled(isSaving)
                        .fontWeight(.semibold)
                }
                ToolbarItem(placement: .bottomBar) {
                    Button(action: { showAddSheet = true }) {
                        HStack(spacing: Spacing.xs) {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 16))
                            Text("Add Widget")
                                .font(.bodyMedium)
                        }
                        .foregroundColor(.appPrimary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, Spacing.xs + Spacing.xxs)
                        .overlay(
                            RoundedRectangle(cornerRadius: Radius.md)
                                .stroke(Color.appDivider, lineWidth: 1)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
            .sheet(isPresented: $showAddSheet) {
                AddPortfolioItemSheet(userId: user._id)
            }
        }
        .task { await loadItems() }
    }

    // MARK: - Data

    private func loadItems() async {
        do {
            items = try await ConvexClientManager.shared.fetchPortfolioItems(userId: user._id)
            isLoading = false
        } catch {
            print("EditProfileSheet: load error: \(error)")
            isLoading = false
        }
    }

    private func save() {
        isSaving = true
        Task {
            do {
                let reorderItems = items.enumerated().map { (index, item) in
                    (id: item._id, order: index, size: item.size)
                }
                try await ConvexClientManager.shared.reorderPortfolioItems(items: reorderItems)
                await MainActor.run { dismiss() }
            } catch {
                print("EditProfileSheet: save error: \(error)")
                isSaving = false
            }
        }
    }
}
