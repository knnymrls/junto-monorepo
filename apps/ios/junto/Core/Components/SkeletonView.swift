//
//  SkeletonView.swift
//  mkrs-world
//
//  Shimmer loading placeholder components
//

import SwiftUI

// MARK: - Skeleton Shape

struct SkeletonShape: View {
    var width: CGFloat? = nil
    var height: CGFloat = 16
    var cornerRadius: CGFloat = 6

    @State private var isAnimating = false

    var body: some View {
        RoundedRectangle(cornerRadius: cornerRadius)
            .fill(Color.appPrimary.opacity(0.06))
            .frame(width: width, height: height)
            .overlay(
                GeometryReader { geo in
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.clear,
                                    Color.appPrimary.opacity(0.08),
                                    Color.clear
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geo.size.width)
                        .offset(x: isAnimating ? geo.size.width : -geo.size.width)
                }
                .clipped()
            )
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
            .onAppear {
                withAnimation(
                    .linear(duration: 1.2)
                    .repeatForever(autoreverses: false)
                ) {
                    isAnimating = true
                }
            }
    }
}

// MARK: - Skeleton Circle

struct SkeletonCircle: View {
    var size: CGFloat = 44

    @State private var isAnimating = false

    var body: some View {
        Circle()
            .fill(Color.appPrimary.opacity(0.06))
            .frame(width: size, height: size)
            .overlay(
                GeometryReader { geo in
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.clear,
                                    Color.appPrimary.opacity(0.08),
                                    Color.clear
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geo.size.width)
                        .offset(x: isAnimating ? geo.size.width : -geo.size.width)
                }
                .clipped()
            )
            .clipShape(Circle())
            .onAppear {
                withAnimation(
                    .linear(duration: 1.2)
                    .repeatForever(autoreverses: false)
                ) {
                    isAnimating = true
                }
            }
    }
}









// MARK: - Post Card Skeleton

struct PostCardSkeleton: View {
    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            // Left column
            VStack(spacing: 4) {
                SkeletonCircle(size: 36)

                Capsule()
                    .fill(Color.appPrimary.opacity(0.06))
                    .frame(width: 2)
                    .frame(height: 40)

                SkeletonCircle(size: 16)
            }
            .frame(width: 40)

            // Right column
            VStack(alignment: .leading, spacing: 16) {
                // Header
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        SkeletonShape(width: 100, height: 14)
                        SkeletonShape(width: 30, height: 12)
                        Spacer()
                    }

                    // Content lines
                    SkeletonShape(height: 14)
                    SkeletonShape(width: 200, height: 14)
                }

                // Footer
                HStack {
                    SkeletonShape(width: 60, height: 14)
                    Spacer()
                    SkeletonShape(width: 70, height: 14)
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 16)
        .background(Color.appSurface)
    }
}

// MARK: - Feed Skeleton

struct FeedSkeleton: View {
    var body: some View {
        VStack(spacing: 0) {
            ForEach(0..<5, id: \.self) { _ in
                PostCardSkeleton()

                Rectangle()
                    .fill(Color.appDivider)
                    .frame(height: 0.5)
            }
        }
    }
}



// MARK: - Discover Event Row Skeleton (matches DiscoverEventCard)

struct DiscoverEventCardSkeleton: View {
    var body: some View {
        HStack(alignment: .top, spacing: Spacing.md) {
            SkeletonShape(width: 80, height: 80, cornerRadius: Radius.xl)

            VStack(alignment: .leading, spacing: Spacing.sm) {
                SkeletonShape(width: 90, height: 12)
                SkeletonShape(width: 210, height: 16)
                SkeletonShape(width: 150, height: 14)
                HStack(spacing: Spacing.xs) {
                    SkeletonShape(width: 56, height: 18, cornerRadius: 9)
                    SkeletonShape(width: 44, height: 18, cornerRadius: 9)
                }
            }

            Spacer(minLength: 0)
        }
        .padding(.horizontal, Spacing.lg)
        .padding(.vertical, Spacing.md)
        .background(Color.appSurface)
    }
}

// MARK: - Discover Person Row Skeleton (matches DiscoverPersonCard)

struct DiscoverPersonCardSkeleton: View {
    var body: some View {
        HStack(alignment: .top, spacing: Spacing.md) {
            SkeletonCircle(size: 44)

            VStack(alignment: .leading, spacing: Spacing.sm) {
                VStack(alignment: .leading, spacing: Spacing.xxs) {
                    SkeletonShape(width: 100, height: 12)
                    SkeletonShape(width: 220, height: 16)
                }
                HStack(spacing: Spacing.xs) {
                    SkeletonShape(width: 56, height: 18, cornerRadius: 9)
                    SkeletonShape(width: 72, height: 18, cornerRadius: 9)
                    SkeletonShape(width: 44, height: 18, cornerRadius: 9)
                }
            }

            Spacer(minLength: 0)
        }
        .padding(.horizontal, Spacing.md)
        .padding(.vertical, Spacing.lg)
        .background(Color.appSurface)
    }
}



// MARK: - Previews








