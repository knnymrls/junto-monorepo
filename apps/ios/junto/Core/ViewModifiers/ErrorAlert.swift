//
//  ErrorAlert.swift
//  mkrs-world
//
//  System alert bound to an optional error message — the one way mutation
//  failures are surfaced. Setting the binding to a string presents the alert;
//  dismissing clears it.
//

import SwiftUI

extension View {
    /// Presents a system alert whenever `error` holds a message.
    ///
    ///     @Published var saveError: String?
    ///     ...
    ///     .errorAlert($viewModel.saveError, title: "Couldn't Save")
    func errorAlert(_ error: Binding<String?>, title: String = "Something Went Wrong") -> some View {
        alert(
            title,
            isPresented: Binding(
                get: { error.wrappedValue != nil },
                set: { if !$0 { error.wrappedValue = nil } }
            )
        ) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(error.wrappedValue ?? "")
        }
    }
}
