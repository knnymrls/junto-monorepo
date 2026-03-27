//
//  CodeInputView.swift
//  mkrs-world
//
//  Six-digit OTP code input with individual boxes
//

import SwiftUI

struct CodeInputView: View {
    @Binding var code: String
    let length: Int = 6
    @FocusState private var isFocused: Bool

    var body: some View {
        ZStack {
            // Hidden text field for keyboard input
            TextField("", text: $code)
                .keyboardType(.numberPad)
                .textContentType(.oneTimeCode)
                .focused($isFocused)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .opacity(0)
                .allowsHitTesting(false)

            // Visual code boxes
            HStack(spacing: Spacing.sm) {
                ForEach(0..<length, id: \.self) { index in
                    codeBox(at: index)
                }
            }
        }
        .fixedSize(horizontal: true, vertical: true)
        .contentShape(Rectangle())
        .onTapGesture {
            isFocused = true
        }
        .onAppear {
            isFocused = true
        }
        .onChange(of: code) { _, newValue in
            let filtered = String(newValue.filter { $0.isNumber }.prefix(length))
            if filtered != newValue {
                code = filtered
            }
        }
    }

    private func codeBox(at index: Int) -> some View {
        let character: String = {
            guard index < code.count else { return "" }
            return String(code[code.index(code.startIndex, offsetBy: index)])
        }()

        return Text(character)
            .font(.system(size: 28, weight: .semibold))
            .foregroundColor(.appPrimary)
            .frame(width: 50, height: 62)
            .background(
                RoundedRectangle(cornerRadius: Radius.xl)
                    .fill(Color.appSurfaceSecondary)
            )
    }
}

#Preview {
    CodeInputView(code: .constant("345"))
}
