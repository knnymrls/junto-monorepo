//
//  MentionText.swift
//  mkrs-world
//
//  Attributed text view with tappable @mentions rendered in blue
//

import SwiftUI

struct MentionText: View {
    let content: String
    var onMentionTap: ((String) -> Void)?
    /// Base font for body text. Mentions match this size at medium weight.
    var font: Font = .body14
    /// Font for @mention runs. Defaults to medium weight at the body size.
    var mentionFont: Font = .bodyMedium

    var body: some View {
        Text(attributedContent)
            .font(font)
            .lineSpacing(Spacing.xxxs)
            .fixedSize(horizontal: false, vertical: true)
            .environment(\.openURL, OpenURLAction { url in
                if url.scheme == "mention", let name = url.host {
                    let decodedName = name.removingPercentEncoding ?? name
                    onMentionTap?(decodedName)
                    return .handled
                }
                return .systemAction
            })
    }

    private var attributedContent: AttributedString {
        var result = AttributedString()
        let pattern = "@([A-Za-z]+(\\s[A-Za-z]+)?)"
        let regex = try? NSRegularExpression(pattern: pattern)
        let nsString = content as NSString
        let range = NSRange(location: 0, length: nsString.length)
        let matches = regex?.matches(in: content, range: range) ?? []

        var lastEnd = 0
        for match in matches {
            // Add text before mention
            if match.range.location > lastEnd {
                let beforeRange = NSRange(location: lastEnd, length: match.range.location - lastEnd)
                let beforeText = nsString.substring(with: beforeRange)
                var beforeAttr = AttributedString(beforeText)
                beforeAttr.foregroundColor = .appPrimary
                result += beforeAttr
            }

            // Add mention as link
            let mentionText = nsString.substring(with: match.range)
            let nameRange = match.range(at: 1)
            let name = nsString.substring(with: nameRange)

            var mentionAttr = AttributedString(mentionText)
            mentionAttr.foregroundColor = .blue
            mentionAttr.font = mentionFont
            if let encodedName = name.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed),
               let url = URL(string: "mention://\(encodedName)") {
                mentionAttr.link = url
            }
            result += mentionAttr

            lastEnd = match.range.location + match.range.length
        }

        // Add remaining text
        if lastEnd < nsString.length {
            let remainingRange = NSRange(location: lastEnd, length: nsString.length - lastEnd)
            let remainingText = nsString.substring(with: remainingRange)
            var remainingAttr = AttributedString(remainingText)
            remainingAttr.foregroundColor = .appPrimary
            result += remainingAttr
        }

        return result
    }
}
