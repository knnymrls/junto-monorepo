//
//  PostDetailTopNav.swift
//  junto
//
//  Top nav for the post detail page — circular back button, centered title,
//  circular share button. Matches Figma node 56:190; mirrors FeedTopNav's
//  spacing so it reads as the same bar family.
//
//  Two styles:
//  - .standard: surface background, primary text (post detail on a light page)
//  - .overlay:  transparent background, white title, light frosted buttons —
//    for sitting on top of a dark/photo backdrop (event detail, Figma 70:1149)
//

import SwiftUI

struct PostDetailTopNav: View {
    enum Style {
        case standard
        case overlay
    }

    var title: String = "Post"
    var style: Style = .standard
    var onBack: (() -> Void)? = nil
    var onShare: (() -> Void)? = nil

    var body: some View {
        HStack(spacing: 0) {
            circleButton(icon: "nav.back", action: { onBack?() })

            Spacer(minLength: 0)

            Text(title)
                .font(.heading3)
                .foregroundColor(titleColor)

            Spacer(minLength: 0)

            circleButton(icon: "nav.share", action: { onShare?() })
        }
        .padding(.horizontal, Spacing.lg)
        .padding(.top, style == .overlay ? Spacing.xs : 0)
        .padding(.bottom, Spacing.sm)
        .background(barBackground)
    }

    private var titleColor: Color {
        style == .overlay ? .white : .appPrimary
    }

    @ViewBuilder
    private var barBackground: some View {
        switch style {
        case .standard: Color.appSurface
        case .overlay: Color.clear
        }
    }

    // Light chip buttons regardless of color scheme so they stay legible on a
    // dark photo backdrop. Figma 70:1150 — #F0F0F0 fill, #2D2D2D glyph.
    private var buttonBackground: Color {
        style == .overlay ? Color(red: 0.941, green: 0.941, blue: 0.941) : .appSurfaceSecondary
    }

    private var buttonForeground: Color {
        style == .overlay ? Color(red: 0.176, green: 0.176, blue: 0.176) : .appPrimary
    }

    private func circleButton(icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(icon)
                .renderingMode(.template)
                .resizable()
                .scaledToFit()
                .frame(width: 16, height: 16)
                .foregroundColor(buttonForeground)
                .frame(width: 40, height: 40)
                .background(buttonBackground)
                .clipShape(Circle())
        }
        .buttonStyle(.pressableScale(0.9))
    }
}

#Preview {
    ZStack {
        LinearGradient(colors: [.purple, .black], startPoint: .top, endPoint: .bottom)
            .ignoresSafeArea()
        VStack(spacing: 24) {
            PostDetailTopNav(onBack: {}, onShare: {})
            PostDetailTopNav(title: "Event", style: .overlay, onBack: {}, onShare: {})
            Spacer()
        }
    }
}
