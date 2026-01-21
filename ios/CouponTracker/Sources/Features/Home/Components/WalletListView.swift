//
//  WalletListView.swift
//  CouponTracker
//
//  Created: January 20, 2026
//
//  Purpose: An alternative wallet view using a list layout instead of stack.
//           Supports swipe-to-delete actions.
//           Extracted from WalletView for reusability.
//

import SwiftUI

// MARK: - Wallet List View

/// An alternative wallet view using a list layout instead of stack
struct WalletListView: View {

    let cards: [PreviewCard]
    var onCardTap: ((PreviewCard) -> Void)? = nil
    var onDeleteCard: ((PreviewCard) -> Void)? = nil

    var body: some View {
        List {
            ForEach(cards) { card in
                CardComponent(card: card, size: .regular, showShadow: false)
                    .listRowSeparator(.hidden)
                    .listRowInsets(EdgeInsets(
                        top: DesignSystem.Spacing.sm,
                        leading: DesignSystem.Spacing.md,
                        bottom: DesignSystem.Spacing.sm,
                        trailing: DesignSystem.Spacing.md
                    ))
                    .onTapGesture {
                        onCardTap?(card)
                    }
                    .swipeActions(edge: .trailing) {
                        Button(role: .destructive) {
                            onDeleteCard?(card)
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
            }
        }
        .listStyle(.plain)
    }
}

// MARK: - Previews

#Preview("Wallet List View") {
    NavigationStack {
        WalletListView(
            cards: PreviewData.sampleCards,
            onCardTap: { card in
                print("Tapped: \(card.name)")
            },
            onDeleteCard: { card in
                print("Delete: \(card.name)")
            }
        )
        .navigationTitle("My Cards")
    }
}
