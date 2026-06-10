//
//  DiscoverListTopBar.swift
//  junto
//
//  Shared top bar for Discover's drill-in lists (events, people): a circular
//  back button, a center slot (segmented control or search pill), and a
//  circular filter button. Matches the Discover list artboards' Top Nav
//  (Paper 7YI-0 / 861-0).
//

import SwiftUI

struct DiscoverListTopBar<Center: View>: View {
    var onBack: () -> Void
    var onFilter: (() -> Void)? = nil
    @ViewBuilder var center: () -> Center

    var body: some View {
        HStack(spacing: Spacing.sm) {
            DiscoverCircleButton(icon: "nav.back", action: onBack)

            Spacer(minLength: Spacing.sm)
            center()
            Spacer(minLength: Spacing.sm)

            DiscoverCircleButton(icon: "action.filter", action: { onFilter?() })
                .opacity(onFilter == nil ? 0 : 1)
                .disabled(onFilter == nil)
        }
        .padding(.horizontal, Spacing.lg)
        .padding(.bottom, Spacing.sm)
        // White bar fills up through the status bar so it reads as one solid
        // surface from the screen's top edge (Figma bg-white spans pt-56).
        .background(Color.appSurface.ignoresSafeArea(edges: .top))
    }
}

/// 40pt circular icon button on a subtle fill — the back / filter affordance.
struct DiscoverCircleButton: View {
    let icon: String
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(icon)
                .renderingMode(.template)
                .resizable()
                .scaledToFit()
                .frame(width: 16, height: 16)
                .foregroundColor(.appPrimary)
                .frame(width: 40, height: 40)
                .background(Color.appSurfaceSecondary, in: Circle())
                .contentShape(Circle())
        }
        .buttonStyle(.pressableScale(0.9))
    }
}

/// Pill segmented control (Upcoming / Past style). Matches Paper 7YN-0.
struct DiscoverSegmentedControl<T: Hashable>: View {
    let options: [T]
    let title: (T) -> String
    @Binding var selection: T

    var body: some View {
        HStack(spacing: 0) {
            ForEach(options, id: \.self) { option in
                let isSelected = option == selection
                Text(title(option))
                    .font(.bodySemibold)
                    .foregroundColor(.appPrimary)
                    // Pill 86×32, outer padding 4 → 40pt tall control (Figma 140:384).
                    .frame(width: 86, height: 32)
                    .background(
                        isSelected
                            ? AnyView(Color.appSurface.clipShape(RoundedRectangle(cornerRadius: Radius.pill)))
                            : AnyView(Color.clear)
                    )
                    .contentShape(Rectangle())
                    .onTapGesture {
                        withAnimation(.easeInOut(duration: 0.2)) { selection = option }
                    }
            }
        }
        .padding(4)
        .background(Color.appSurfaceSecondary, in: RoundedRectangle(cornerRadius: Radius.pill))
    }
}

/// Tappable "Search" pill for the people list. Matches Paper 866-0.
struct DiscoverSearchPill: View {
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: Spacing.sm) {
                Image("tab.search")
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 16, height: 16)
                Text("Search")
                    .font(.bodyLargeSemibold)
            }
            .foregroundColor(.appPrimary)
            .padding(.vertical, 9)
            // Fixed-width pill matching the People list Top Nav (Figma 140:398, w-153).
            .frame(width: 153)
            .background(Color.appSurfaceSecondary, in: RoundedRectangle(cornerRadius: Radius.pill))
            .contentShape(RoundedRectangle(cornerRadius: Radius.pill))
        }
        .buttonStyle(.pressableScale(0.97))
    }
}
