//
//  AskJuntoComposer.swift
//  junto
//
//  Bottom input pill for Ask Junto — leading Junto mark + a text field that
//  grows vertically as you type (UITextView under the hood, so Return = Send via
//  returnKeyType, like the post-detail reply composer). Matches Figma 148-1218.
//
//  While the agent is working, the pill becomes the loader (Figma 148-1093):
//  the Junto mark spins and the live step ("Searching campus...") replaces the
//  field. No separate spinner in the chat.
//

import SwiftUI
import UIKit

struct AskJuntoComposer: View {
    @Binding var text: String
    var placeholder: String = "Ask any question..."
    /// Live agent step while thinking; nil when idle (normal input).
    var thinkingText: String? = nil
    /// Two-way focus so the parent can collapse the keyboard on send / focus on
    /// a follow-up tap.
    @Binding var focused: Bool
    var onSend: () -> Void

    @State private var spinAngle: Double = 0
    @State private var isEditing = false
    @State private var textHeight: CGFloat = 28

    /// Pill fill — #E5E5E5 light / #262626 dark (Figma 155-148).
    private let pillFill = Color(UIColor { tc in
        tc.userInterfaceStyle == .dark
            ? UIColor(red: 0.149, green: 0.149, blue: 0.149, alpha: 1.0)  // #262626
            : UIColor(red: 0.898, green: 0.898, blue: 0.898, alpha: 1.0)  // #E5E5E5
    })

    /// The Junto mark sits in a circular frame — white on the light pill.
    private let markFrameFill = Color(UIColor { tc in
        tc.userInterfaceStyle == .dark
            ? UIColor(red: 0.227, green: 0.227, blue: 0.227, alpha: 1.0)  // #3A3A3A
            : .white
    })

    private var isThinking: Bool { thinkingText != nil }

    var body: some View {
        HStack(alignment: .center, spacing: Spacing.sm) {
            if isThinking || !isEditing {
                mark
                    .transition(.scale(scale: 0.5).combined(with: .opacity))
            }

            if let thinkingText {
                Text(thinkingText)
                    .font(.bodyMedium)
                    .foregroundColor(.appPrimary)
                    .id(thinkingText)
                    .transition(.opacity)
                    .frame(minHeight: 28, alignment: .center)
            } else {
                ZStack(alignment: .leading) {
                    if text.isEmpty {
                        Text(placeholder)
                            .font(.bodyLarge)
                            .foregroundStyle(Color.appSecondary)
                            .allowsHitTesting(false)
                            .frame(height: 28, alignment: .leading)
                    }
                    AskJuntoGrowingTextView(
                        text: $text,
                        height: $textHeight,
                        isFocused: $focused,
                        onSubmit: onSend
                    )
                    .frame(height: textHeight)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        // Hold the mark's height so the pill doesn't shrink when it hides on focus.
        .frame(minHeight: 32)
        // More leading room once the mark is gone; base padding while it's there.
        .padding(.leading, isEditing ? Spacing.lg : Spacing.sm)
        .padding(.trailing, Spacing.sm)
        .padding(.vertical, Spacing.sm)
        .background(pillFill, in: Capsule())
        .contentShape(Capsule())
        .onTapGesture { if !isThinking { focused = true } }
        .animation(.easeInOut(duration: 0.3), value: thinkingText)
        .animation(.spring(response: 0.5, dampingFraction: 0.8), value: isEditing)
        // Hide the mark only once there's text — not just on focus/open.
        .onChange(of: text) { _, _ in isEditing = !text.isEmpty }
    }

    // Junto mark framed in a circle (Figma node 155-149 "Avatar Like"). Spins
    // while thinking, and shrinks (24pt) so the bar grows back to 32pt when done.
    private var markFrameSize: CGFloat { isThinking ? 24 : 32 }
    private var markGlyphSize: CGFloat { isThinking ? 14 : 20 }

    private var mark: some View {
        ZStack {
            Circle().fill(markFrameFill)
            Image("tab.junto")
                .renderingMode(.template)
                .resizable()
                .scaledToFit()
                .frame(width: markGlyphSize, height: markGlyphSize)
                .foregroundColor(.appPrimary)
                .rotationEffect(.degrees(spinAngle))
        }
        .frame(width: markFrameSize, height: markFrameSize)
        .onChange(of: isThinking) { _, thinking in
            if thinking {
                spinAngle = 0
                withAnimation(.linear(duration: 0.9).repeatForever(autoreverses: false)) {
                    spinAngle = 360
                }
            } else {
                withAnimation(.easeOut(duration: 0.2)) { spinAngle = 0 }
            }
        }
    }
}

// MARK: - Growing text view (UITextView so Return submits and it grows vertically)

struct AskJuntoGrowingTextView: UIViewRepresentable {
    @Binding var text: String
    @Binding var height: CGFloat
    @Binding var isFocused: Bool
    var minHeight: CGFloat = 28
    var maxHeight: CGFloat = 120
    var fontSize: CGFloat = 16
    var onSubmit: () -> Void

    func makeUIView(context: Context) -> UITextView {
        let tv = UITextView()
        tv.delegate = context.coordinator
        tv.font = .systemFont(ofSize: fontSize)
        tv.backgroundColor = .clear
        // Vertical inset so a single line sits centered in the resting pill.
        tv.textContainerInset = UIEdgeInsets(top: 4, left: 0, bottom: 4, right: 0)
        tv.textContainer.lineFragmentPadding = 0
        tv.isScrollEnabled = false
        tv.returnKeyType = .send
        tv.tintColor = UIColor(Color.appPrimary)
        tv.textColor = UIColor(Color.appPrimary)
        tv.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        return tv
    }

    func updateUIView(_ tv: UITextView, context: Context) {
        if tv.text != text {
            tv.text = text
            recalc(tv)
        }
        DispatchQueue.main.async {
            if isFocused, !tv.isFirstResponder {
                tv.becomeFirstResponder()
            } else if !isFocused, tv.isFirstResponder {
                tv.resignFirstResponder()
            }
        }
    }

    private func recalc(_ tv: UITextView) {
        guard tv.frame.width > 0 else { return }
        let size = tv.sizeThatFits(CGSize(width: tv.frame.width, height: .greatestFiniteMagnitude))
        let h = min(maxHeight, max(minHeight, size.height))
        tv.isScrollEnabled = size.height > maxHeight
        if abs(height - h) > 0.5 {
            DispatchQueue.main.async { height = h }
        }
    }

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    final class Coordinator: NSObject, UITextViewDelegate {
        let parent: AskJuntoGrowingTextView
        init(_ parent: AskJuntoGrowingTextView) { self.parent = parent }

        func textViewDidChange(_ tv: UITextView) {
            parent.text = tv.text
            parent.recalc(tv)
        }

        func textViewDidBeginEditing(_ tv: UITextView) {
            if !parent.isFocused { DispatchQueue.main.async { self.parent.isFocused = true } }
        }

        func textViewDidEndEditing(_ tv: UITextView) {
            if parent.isFocused { DispatchQueue.main.async { self.parent.isFocused = false } }
        }

        func textView(_ tv: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
            if text == "\n" {
                parent.onSubmit()
                return false
            }
            return true
        }
    }
}
