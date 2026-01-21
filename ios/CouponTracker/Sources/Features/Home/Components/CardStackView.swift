//
//  CardStackView.swift
//  CouponTracker
//
//  Created: January 20, 2026
//
//  Purpose: A stacked display of credit cards with offset positioning.
//           Shows cards in a visually layered stack with decreasing opacity and scale.
//           Also includes HorizontalCardCarousel for swipeable card browsing.
//           Extracted from WalletView for reusability.
//

import SwiftUI

// MARK: - Card Stack View

/// A stacked display of credit cards with offset positioning
struct CardStackView: View {

    let cards: [PreviewCard]
    var maxVisibleCards: Int = 4
    var onCardTap: ((PreviewCard) -> Void)? = nil

    var body: some View {
        ZStack(alignment: .top) {
            ForEach(Array(cards.prefix(maxVisibleCards).enumerated().reversed()), id: \.element.id) { index, card in
                CardComponent(card: card, showShadow: true)
                    .offset(y: CGFloat(index) * DesignSystem.Spacing.cardStackOffset)
                    .zIndex(Double(maxVisibleCards - index))
                    .onTapGesture {
                        onCardTap?(card)
                    }
                    .opacity(opacityForIndex(index))
                    .scaleEffect(scaleForIndex(index), anchor: .top)
            }
        }
        .padding(.bottom, CGFloat(min(cards.count, maxVisibleCards) - 1) * DesignSystem.Spacing.cardStackOffset)
    }

    private func opacityForIndex(_ index: Int) -> Double {
        switch index {
        case 0: return 1.0
        case 1: return 0.95
        case 2: return 0.9
        default: return 0.85
        }
    }

    private func scaleForIndex(_ index: Int) -> CGFloat {
        // Slight scale reduction for cards behind
        let reduction = CGFloat(index) * 0.02
        return 1.0 - reduction
    }
}

// MARK: - Horizontal Card Carousel

/// An alternative layout using horizontal scroll for card browsing
struct HorizontalCardCarousel: View {

    let cards: [PreviewCard]
    var onCardTap: ((PreviewCard) -> Void)? = nil

    @State private var currentIndex: Int = 0

    var body: some View {
        TabView(selection: $currentIndex) {
            ForEach(Array(cards.enumerated()), id: \.element.id) { index, card in
                CardComponent(card: card, showShadow: true)
                    .padding(.horizontal, DesignSystem.Spacing.lg)
                    .tag(index)
                    .onTapGesture {
                        onCardTap?(card)
                    }
            }
        }
        .tabViewStyle(.page(indexDisplayMode: .automatic))
        .frame(height: 240)
    }
}

// MARK: - Previews

#Preview("Card Stack") {
    VStack {
        CardStackView(
            cards: PreviewData.sampleCards,
            onCardTap: { card in
                print("Tapped: \(card.name)")
            }
        )
    }
    .padding()
    .background(DesignSystem.Colors.backgroundSecondary)
}

#Preview("Horizontal Card Carousel") {
    VStack {
        HorizontalCardCarousel(
            cards: PreviewData.sampleCards,
            onCardTap: { card in
                print("Tapped: \(card.name)")
            }
        )
    }
    .background(DesignSystem.Colors.backgroundSecondary)
}
