//
//  WidgetDropDelegate.swift
//  mkrs-world
//
//  Handles drag-and-drop reordering of portfolio widgets in the editor.
//

import SwiftUI

struct WidgetDropDelegate: DropDelegate {
    let item: PortfolioItemResponse
    @Binding var items: [PortfolioItemResponse]
    @Binding var draggingItem: PortfolioItemResponse?

    func dropEntered(info: DropInfo) {
        guard let dragging = draggingItem,
              dragging.id != item.id,
              let fromIndex = items.firstIndex(where: { $0.id == dragging.id }),
              let toIndex = items.firstIndex(where: { $0.id == item.id })
        else { return }

        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            items.move(fromOffsets: IndexSet(integer: fromIndex), toOffset: toIndex > fromIndex ? toIndex + 1 : toIndex)
        }
    }

    func dropUpdated(info: DropInfo) -> DropProposal? {
        DropProposal(operation: .move)
    }

    func performDrop(info: DropInfo) -> Bool {
        draggingItem = nil
        return true
    }
}
