//
//  StreamingText.swift
//  junto
//
//  Smoothly reveals streamed text at a steady cadence, decoupled from the bursty
//  network updates that drive `text`. The server pushes the accumulated `say`
//  in irregular chunks; this types it out at a constant chars/sec so it reads
//  naturally instead of jumping in clumps. (Standard streaming-LLM UI pattern —
//  separate "tokens received" from "characters shown".)
//
//  `animated` is true only for the message currently streaming; settled/history
//  messages render their full text instantly (no replay on appear or scroll).
//

import SwiftUI

struct StreamingText: View {
    let text: String
    var animated: Bool
    var charsPerSecond: Double = 240
    var font: Font = .bodyLarge
    var color: Color = .appPrimary

    @State private var shown: Double = 0
    private let tick = Timer.publish(every: 1.0 / 60.0, on: .main, in: .common).autoconnect()

    var body: some View {
        Text(String(text.prefix(Int(shown))))
            .font(font)
            .foregroundColor(color)
            .frame(maxWidth: .infinity, alignment: .leading)
            .onAppear {
                // History / settled messages: show the whole thing immediately.
                if !animated { shown = Double(text.count) }
            }
            .onReceive(tick) { _ in
                guard animated else { return }
                let target = Double(text.count)
                if shown < target {
                    shown = min(target, shown + charsPerSecond / 60.0)
                }
            }
            .onChange(of: animated) { _, isAnimated in
                // Turn ended → make sure the full text is shown.
                if !isAnimated { shown = Double(text.count) }
            }
            .onChange(of: text) { _, newText in
                if !animated {
                    shown = Double(newText.count)
                } else if shown > Double(newText.count) {
                    shown = Double(newText.count)
                }
            }
    }
}
