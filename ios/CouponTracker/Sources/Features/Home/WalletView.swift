//
//  WalletView.swift
//  CouponTracker
//
//  Created: January 17, 2026
//
//  Purpose: The primary wallet view displaying the user's credit cards in a
//           stacked format with an "Expiring Soon" section and total value summary.
//           This is the main view for browsing and managing cards.
//
//  ACCESSIBILITY:
//  - VoiceOver navigation through card stack
//  - Announces total value and expiring benefits count
//  - All interactive elements have minimum 44pt touch targets
//
//  DESIGN NOTES:
//  - Card stack uses 8pt vertical offset between cards
//  - Top card is fully visible, cards behind are partially hidden
//  - Tap on card navigates to CardDetailView
//  - Empty state shows "Add Card" button
//
//  COMPONENTS:
//  - CardStackView: See CardStackView.swift
//  - HorizontalCardCarousel: See CardStackView.swift
//  - WalletListView: See WalletListView.swift
//

import SwiftUI

// MARK: - Wallet View

/// The main wallet view displaying cards in a stack with value summary
struct WalletView: View {

    // MARK: - Properties

    let cards: [PreviewCard]
    var categoryRecommendations: [BenefitCategory: RecommendedCard] = [:]
    var onCardTap: ((PreviewCard) -> Void)? = nil
    var onAddCard: (() -> Void)? = nil
    var onBenefitMarkAsDone: ((PreviewBenefit) -> Void)? = nil
    var onSeeAllExpiring: (() -> Void)? = nil
    var onSearchRecommendations: (() -> Void)? = nil
    var onSelectRecommendedCard: ((UUID) -> Void)? = nil

    // MARK: - State

    @State private var selectedCardIndex: Int = 0
    @State private var refreshing = false

    // MARK: - Computed Properties

    private var totalAvailableValue: Decimal {
        cards.reduce(0) { $0 + $1.totalAvailableValue }
    }

    private var formattedTotalValue: String {
        Formatters.formatCurrencyWhole(totalAvailableValue)
    }

    private var expiringBenefits: [ExpiringBenefitItem] {
        cards.flatMap { card in
            card.availableBenefits
                .filter { $0.isExpiringSoon }
                .map { ExpiringBenefitItem(benefit: $0, card: card) }
        }
        .sorted { $0.benefit.daysRemaining < $1.benefit.daysRemaining }
    }

    private var totalCardsCount: Int {
        cards.count
    }

    // MARK: - Body

    var body: some View {
        ScrollView {
            VStack(spacing: DesignSystem.Spacing.xl) {
                // Value Summary Header
                valueSummaryHeader
                    .padding(.top, DesignSystem.Spacing.md)

                // Expiring Soon Section
                if !expiringBenefits.isEmpty {
                    expiringSoonSection
                }

                // Card Stack Section
                if !cards.isEmpty {
                    cardStackSection
                } else {
                    emptyStateView
                }
            }
            .padding(.horizontal, DesignSystem.Spacing.lg)
            .padding(.bottom, DesignSystem.Spacing.lg)
        }
        .refreshable {
            await performRefresh()
        }
        .background(DesignSystem.Colors.backgroundPrimary)
        .navigationTitle("My Wallet")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { onAddCard?() }) {
                    Image(systemName: "plus")
                        .font(.system(size: 17, weight: .semibold))
                }
                .accessibilityLabel("Add new card")
            }
        }
    }

    // MARK: - Value Summary Header

    @ViewBuilder
    private var valueSummaryHeader: some View {
        VStack(spacing: DesignSystem.Spacing.xs) {
            Text("Total Available")
                .font(DesignSystem.Typography.subhead)
                .foregroundStyle(DesignSystem.Colors.textSecondary)

            Text(formattedTotalValue)
                .font(DesignSystem.Typography.valueLarge)
                .foregroundStyle(DesignSystem.Colors.textPrimary)
                .contentTransition(.numericText())

            Text("Across \(totalCardsCount) card\(totalCardsCount == 1 ? "" : "s")")
                .font(DesignSystem.Typography.footnote)
                .foregroundStyle(DesignSystem.Colors.textTertiary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, DesignSystem.Spacing.xl)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Total available value: \(formattedTotalValue) across \(totalCardsCount) cards")
    }

    // MARK: - Expiring Soon Section

    @ViewBuilder
    private var expiringSoonSection: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
            // Section header
            HStack {
                Text("Expiring Soon")
                    .font(DesignSystem.Typography.title3)
                    .foregroundStyle(DesignSystem.Colors.textPrimary)

                Spacer()

                if expiringBenefits.count > 3 {
                    Button("See All") {
                        onSeeAllExpiring?()
                    }
                    .font(DesignSystem.Typography.subhead)
                    .foregroundStyle(DesignSystem.Colors.primaryFallback)
                }
            }

            // Expiring benefits list (max 3)
            VStack(spacing: DesignSystem.Spacing.sm) {
                ForEach(Array(expiringBenefits.prefix(3))) { item in
                    CompactBenefitRowView(
                        benefit: item.benefit,
                        cardName: item.card.name,
                        cardGradient: item.card.gradient,
                        onMarkAsDone: {
                            onBenefitMarkAsDone?(item.benefit)
                        },
                        onTap: {
                            onCardTap?(item.card)
                        }
                    )
                }
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Expiring soon, \(expiringBenefits.count) benefits")
    }

    // MARK: - Card Stack Section

    @ViewBuilder
    private var cardStackSection: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
            // Section header
            HStack {
                Text("Your Cards")
                    .font(DesignSystem.Typography.title3)
                    .foregroundStyle(DesignSystem.Colors.textPrimary)

                Spacer()

                Text("\(cards.count) card\(cards.count == 1 ? "" : "s")")
                    .font(DesignSystem.Typography.caption)
                    .foregroundStyle(DesignSystem.Colors.textSecondary)
            }

            // Horizontal card carousel (swipeable)
            HorizontalCardCarousel(
                cards: cards,
                onCardTap: { card in
                    onCardTap?(card)
                }
            )
        }
    }

    // MARK: - Empty State

    @ViewBuilder
    private var emptyStateView: some View {
        VStack(spacing: DesignSystem.Spacing.lg) {
            Spacer()
                .frame(height: DesignSystem.Spacing.xxl)

            Image(systemName: "creditcard.and.123")
                .font(.system(size: 60))
                .foregroundStyle(DesignSystem.Colors.textTertiary)

            VStack(spacing: DesignSystem.Spacing.sm) {
                Text("Your wallet is empty")
                    .font(DesignSystem.Typography.title2)
                    .foregroundStyle(DesignSystem.Colors.textPrimary)

                Text("Add your first card to start tracking rewards")
                    .font(DesignSystem.Typography.body)
                    .foregroundStyle(DesignSystem.Colors.textSecondary)
                    .multilineTextAlignment(.center)
            }

            Button(action: { onAddCard?() }) {
                HStack {
                    Image(systemName: "plus")
                    Text("Add Card")
                }
                .font(DesignSystem.Typography.headline)
                .foregroundStyle(.white)
                .padding(.horizontal, DesignSystem.Spacing.xl)
                .padding(.vertical, DesignSystem.Spacing.md)
                .background(
                    Capsule()
                        .fill(DesignSystem.Colors.primaryFallback)
                )
            }
            .padding(.top, DesignSystem.Spacing.md)

            Spacer()
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Your wallet is empty. Add your first card to start tracking rewards.")
    }

    // MARK: - Helper Methods

    private func performRefresh() async {
        refreshing = true
        // Simulate network delay
        try? await Task.sleep(nanoseconds: 1_000_000_000)
        refreshing = false
    }
}

// MARK: - Expiring Benefit Item

/// Helper struct to pair a benefit with its parent card
struct ExpiringBenefitItem: Identifiable {
    let benefit: PreviewBenefit
    let card: PreviewCard

    var id: UUID { benefit.id }
}

// MARK: - Previews

#Preview("Wallet View - With Cards") {
    NavigationStack {
        WalletView(
            cards: PreviewData.sampleCards,
            onCardTap: { card in
                print("Tapped: \(card.name)")
            },
            onAddCard: {
                print("Add card tapped")
            },
            onBenefitMarkAsDone: { benefit in
                print("Marked done: \(benefit.name)")
            }
        )
    }
}

#Preview("Wallet View - Empty State") {
    NavigationStack {
        WalletView(
            cards: [],
            onAddCard: {
                print("Add card tapped")
            }
        )
    }
}

#Preview("Wallet View - Single Card") {
    NavigationStack {
        WalletView(
            cards: [PreviewData.amexPlatinum],
            onCardTap: { _ in }
        )
    }
}

#Preview("Wallet View - Dark Mode") {
    NavigationStack {
        WalletView(
            cards: PreviewData.sampleCards,
            onCardTap: { _ in },
            onAddCard: { }
        )
    }
    .preferredColorScheme(.dark)
}
