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

// MARK: - User Card Skeleton

struct UserCardSkeleton: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header: Avatar + Name + Location
            HStack(alignment: .center, spacing: 12) {
                SkeletonCircle(size: 44)

                VStack(alignment: .leading, spacing: 6) {
                    SkeletonShape(width: 120, height: 14)
                    SkeletonShape(width: 80, height: 10)
                }

                Spacer()
            }

            // Headline
            SkeletonShape(height: 14)
            SkeletonShape(width: 200, height: 14)

            // Looking for box
            SkeletonShape(height: 40, cornerRadius: 8)

            // Skills
            HStack(spacing: 6) {
                SkeletonShape(width: 60, height: 24, cornerRadius: 6)
                SkeletonShape(width: 80, height: 24, cornerRadius: 6)
                SkeletonShape(width: 50, height: 24, cornerRadius: 6)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.appSurface)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.appBorder, lineWidth: 1)
        )
        .shadow(color: .appShadow, radius: 6, x: 0, y: 2)
    }
}

// MARK: - Connection Row Skeleton

struct ConnectionRowSkeleton: View {
    var body: some View {
        HStack(spacing: 12) {
            SkeletonCircle(size: 48)

            VStack(alignment: .leading, spacing: 6) {
                SkeletonShape(width: 120, height: 14)
                SkeletonShape(width: 160, height: 12)
            }

            Spacer()
        }
        .padding(12)
        .background(Color.appSurface)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.appBorder, lineWidth: 1)
        )
    }
}

// MARK: - Profile Skeleton

struct ProfileSkeleton: View {
    var body: some View {
        VStack(spacing: 0) {
            // Header Section
            VStack(alignment: .leading, spacing: 16) {
                HStack(alignment: .top, spacing: 16) {
                    SkeletonCircle(size: 72)

                    VStack(alignment: .leading, spacing: 8) {
                        SkeletonShape(width: 140, height: 20)
                        SkeletonShape(width: 180, height: 14)
                        SkeletonShape(width: 100, height: 12)
                    }

                    Spacer()
                }

                // Edit Button
                SkeletonShape(width: 100, height: 36, cornerRadius: 8)

                // Looking For
                SkeletonShape(height: 44, cornerRadius: 10)

                // Interests
                HStack(spacing: 6) {
                    SkeletonShape(width: 70, height: 26, cornerRadius: 6)
                    SkeletonShape(width: 90, height: 26, cornerRadius: 6)
                    SkeletonShape(width: 60, height: 26, cornerRadius: 6)
                }
            }
            .padding(20)

            // Divider
            Rectangle()
                .fill(Color.appBorder)
                .frame(height: 1)

            // Bio Section
            VStack(alignment: .leading, spacing: 12) {
                SkeletonShape(width: 60, height: 10)
                SkeletonShape(height: 14)
                SkeletonShape(height: 14)
                SkeletonShape(width: 200, height: 14)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(20)
        }
        .background(Color.appSurface)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.appBorder, lineWidth: 1)
        )
    }
}

// MARK: - Event Card Skeleton

struct EventCardSkeleton: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Event Type Badge
            SkeletonShape(width: 80, height: 24, cornerRadius: 6)

            // Title
            SkeletonShape(width: 220, height: 18)

            // Description
            SkeletonShape(height: 14)
            SkeletonShape(width: 180, height: 14)

            // Date & Location
            HStack(spacing: 16) {
                SkeletonShape(width: 100, height: 14)
                SkeletonShape(width: 80, height: 14)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.appSurface)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.appBorder, lineWidth: 1)
        )
        .shadow(color: .appShadow, radius: 6, x: 0, y: 2)
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

// MARK: - Search Masonry Card Skeleton

struct SearchMasonryCardSkeleton: View {
    var height: CGFloat = 160

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            // Header: avatar + name
            HStack(spacing: Spacing.xs) {
                SkeletonCircle(size: 32)

                VStack(alignment: .leading, spacing: 3) {
                    SkeletonShape(width: 80, height: 12)
                    SkeletonShape(width: 60, height: 10)
                }
            }

            // Explanation lines
            SkeletonShape(height: 12)
            SkeletonShape(width: .random(in: 60...120), height: 12)

            // Skill pills
            HStack(spacing: Spacing.xxxs) {
                SkeletonShape(width: 44, height: 18, cornerRadius: 9)
                SkeletonShape(width: 56, height: 18, cornerRadius: 9)
            }

            Spacer(minLength: 0)

            // Bottom connect button
            HStack {
                Spacer()
                SkeletonShape(width: 60, height: 24, cornerRadius: 12)
            }
        }
        .padding(Spacing.sm)
        .frame(height: height)
        .background(Color.appSurface)
        .clipShape(RoundedRectangle(cornerRadius: Radius.lg))
        .overlay(
            RoundedRectangle(cornerRadius: Radius.lg)
                .stroke(Color.appDivider, lineWidth: 0.5)
        )
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

// MARK: - Skeleton List

struct SkeletonList<Skeleton: View>: View {
    let count: Int
    let skeleton: () -> Skeleton

    init(count: Int = 3, @ViewBuilder skeleton: @escaping () -> Skeleton) {
        self.count = count
        self.skeleton = skeleton
    }

    var body: some View {
        VStack(spacing: 16) {
            ForEach(0..<count, id: \.self) { _ in
                skeleton()
            }
        }
    }
}

// MARK: - Previews

#Preview("User Card Skeleton") {
    ScrollView {
        VStack(spacing: 16) {
            UserCardSkeleton()
            UserCardSkeleton()
        }
        .padding(24)
    }
    .background(Color.appBackground)
}

#Preview("Connection Row Skeleton") {
    VStack(spacing: 12) {
        ConnectionRowSkeleton()
        ConnectionRowSkeleton()
        ConnectionRowSkeleton()
    }
    .padding(24)
    .background(Color.appBackground)
}

#Preview("Profile Skeleton") {
    ScrollView {
        ProfileSkeleton()
            .padding(20)
    }
    .background(Color.appBackground)
}

#Preview("Event Skeleton") {
    VStack(spacing: 16) {
        EventCardSkeleton()
        EventCardSkeleton()
    }
    .padding(24)
    .background(Color.appBackground)
}
