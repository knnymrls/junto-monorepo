//
//  AvatarView.swift
//  mkrs-world
//
//  Reusable avatar component with cached image loading
//

import SwiftUI

struct AvatarView: View {
    let avatarUrl: String?
    let name: String
    let size: CGFloat
    var onLoad: (() -> Void)? = nil

    var body: some View {
        Group {
            if let avatarUrl = avatarUrl, let url = URL(string: avatarUrl) {
                CachedAsyncImage(url: url) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: size, height: size)
                        .clipShape(Circle())
                        .onAppear {
                            onLoad?()
                        }
                } placeholder: {
                    fallbackInitial
                }
                .frame(width: size, height: size)
            } else {
                fallbackInitial
                    .onAppear {
                        onLoad?()
                    }
            }
        }
    }

    private var fallbackInitial: some View {
        Circle()
            .fill(Color.appSurfaceSecondary)
            .frame(width: size, height: size)
            .overlay(
                Text(name.prefix(1).uppercased())
                    .font(.system(size: size * 0.4, weight: .medium))
                    .foregroundColor(.appSecondary)
            )
    }
}

#Preview {
    VStack(spacing: 20) {
        AvatarView(avatarUrl: nil, name: "John Doe", size: 80)
        AvatarView(avatarUrl: "https://example.com/avatar.jpg", name: "Jane Smith", size: 80)
    }
}
