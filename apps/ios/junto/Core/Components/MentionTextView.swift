//
//  MentionTextView.swift
//  mkrs-world
//
//  Shared UIKit UITextView wrapper with @mention highlighting
//

import SwiftUI
import UIKit

struct MentionTextView: UIViewRepresentable {
    @Binding var text: String
    @Binding var height: CGFloat
    var placeholder: String = ""
    var minHeight: CGFloat = 36
    var fontSize: CGFloat = 14
    var autoFocus: Bool = false
    var returnKeyType: UIReturnKeyType = .default
    var onTextChange: ((String) -> Void)?
    var onSubmit: (() -> Void)?

    func makeUIView(context: Context) -> UITextView {
        let textView = UITextView()
        textView.delegate = context.coordinator
        textView.font = .systemFont(ofSize: fontSize)
        textView.backgroundColor = .clear
        textView.textContainerInset = returnKeyType == .send
            ? UIEdgeInsets(top: 5, left: 0, bottom: 5, right: 0)
            : .zero
        textView.textContainer.lineFragmentPadding = 0
        textView.isScrollEnabled = false
        textView.tintColor = UIColor.secondaryLabel
        textView.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        textView.returnKeyType = returnKeyType

        if autoFocus {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                textView.becomeFirstResponder()
            }
        }

        return textView
    }

    func updateUIView(_ textView: UITextView, context: Context) {
        let currentPlainText = textView.text ?? ""
        if currentPlainText != text {
            let attributed = Self.attributedString(from: text, fontSize: fontSize)
            textView.attributedText = attributed
            textView.selectedRange = NSRange(location: textView.text.count, length: 0)
        }

        DispatchQueue.main.async {
            guard textView.frame.width > 0 else { return }
            let size = textView.sizeThatFits(CGSize(width: textView.frame.width, height: .greatestFiniteMagnitude))
            let newHeight = max(minHeight, size.height)
            if self.height != newHeight {
                self.height = newHeight
            }
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    static func attributedString(from text: String, fontSize: CGFloat = 14) -> NSAttributedString {
        let attributed = NSMutableAttributedString(
            string: text,
            attributes: [
                .font: UIFont.systemFont(ofSize: fontSize),
                .foregroundColor: UIColor.label
            ]
        )

        let pattern = "@[A-Za-z]+(\\s[A-Za-z]+)?"
        if let regex = try? NSRegularExpression(pattern: pattern) {
            let range = NSRange(location: 0, length: text.utf16.count)
            let matches = regex.matches(in: text, range: range)
            for match in matches {
                attributed.addAttributes([
                    .foregroundColor: UIColor.systemBlue
                ], range: match.range)
            }
        }

        return attributed
    }

    class Coordinator: NSObject, UITextViewDelegate {
        var parent: MentionTextView

        init(_ parent: MentionTextView) {
            self.parent = parent
        }

        func textViewDidChange(_ textView: UITextView) {
            let newText = textView.text ?? ""
            parent.text = newText
            parent.onTextChange?(newText)

            let cursorPosition = textView.selectedRange
            let attributed = MentionTextView.attributedString(from: newText, fontSize: parent.fontSize)
            textView.attributedText = attributed
            textView.selectedRange = cursorPosition

            let size = textView.sizeThatFits(CGSize(width: textView.frame.width, height: .greatestFiniteMagnitude))
            let newHeight = max(parent.minHeight, size.height)
            DispatchQueue.main.async {
                self.parent.height = newHeight
            }
        }

        func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
            if text == "\n", let onSubmit = parent.onSubmit {
                onSubmit()
                return false
            }
            return true
        }
    }
}
