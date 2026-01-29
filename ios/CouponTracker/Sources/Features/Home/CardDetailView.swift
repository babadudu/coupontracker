//
//  CardDetailView.swift
//  CouponTracker
//
//  Created: January 17, 2026
//
//  Purpose: Full-screen detail view for a single credit card showing all benefits.
//           Displays card artwork at top, followed by benefits grouped by status.
//           Supports mark as done and snooze actions on benefits.
//
//  ACCESSIBILITY:
//  - Full VoiceOver navigation through all elements
//  - Grouped sections announced properly
//  - All actions accessible via VoiceOver
//
//  NAVIGATION:
//  - Push navigation from WalletView
//  - Edit button in navigation bar for card settings
//  - Remove card action at bottom (with confirmation)
//
//  COMPONENTS:
//  - SummaryPill: See BenefitSummaryPill.swift
//  - BenefitSection: See BenefitSection.swift
//  - ExpandedBenefitDetail: See ExpandedBenefitDetail.swift
//

import SwiftUI

// MARK: - Card Detail View

/// Detailed view of a single card showing all its benefits
struct CardDetailView: View {

    // MARK: - Properties

    let card: PreviewCard
    var highlightBenefitId: UUID? = nil
    var onMarkAsDone: ((PreviewBenefit) -> Void)? = nil
    var onSnooze: ((PreviewBenefit, Int) -> Void)? = nil
    var onUndo: ((PreviewBenefit) -> Void)? = nil
    var onRemoveCard: (() -> Void)? = nil
    var onEditCard: (() -> Void)? = nil

    // MARK: - State

    @State private var showRemoveConfirmation = false
    @State private var expandedBenefitId: UUID? = nil
    @State private var selectedPeriod: BenefitPeriod = .monthly
    @State private var highlightedId: UUID? = nil
    @Environment(\.dismiss) private var dismiss

    // MARK: - Body

    var body: some View {
        ScrollViewReader { scrollProxy in
            ScrollView {
                VStack(spacing: 0) {
                    // Card Header
                    cardHeader

                    // Accomplishment Rings
                    if !card.benefits.isEmpty {
                        PreviewCardPeriodSection(
                            benefits: card.benefits,
                            selectedPeriod: $selectedPeriod
                        )
                        .padding(.horizontal, DesignSystem.Spacing.lg)
                        .padding(.top, DesignSystem.Spacing.lg)
                    }

                    // ROI Section (if annual fee > 0)
                    if card.annualFee > 0 {
                        roiSection
                            .padding(.top, DesignSystem.Spacing.lg)
                            .padding(.horizontal, DesignSystem.Spacing.lg)
                    }

                    // Benefits Sections
                    benefitsSections
                        .padding(.top, DesignSystem.Spacing.lg)

                    // Remove Card Section
                    removeCardSection
                        .padding(.top, DesignSystem.Spacing.xxl)
                        .padding(.bottom, DesignSystem.Spacing.xxxl)
                }
            }
            .onAppear {
                scrollToBenefitIfNeeded(proxy: scrollProxy)
            }
        }
        .background(DesignSystem.Colors.backgroundPrimary)
        .navigationTitle(card.displayName)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { onEditCard?() }) {
                    Text("Edit")
                }
            }
        }
        .confirmationDialog(
            "Remove Card",
            isPresented: $showRemoveConfirmation,
            titleVisibility: .visible
        ) {
            Button("Remove Card", role: .destructive) {
                // Call the handler - parent view handles navigation
                onRemoveCard?()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Are you sure you want to remove \(card.name)? This will delete all tracked benefits for this card.")
        }
    }

    // MARK: - Card Header

    @ViewBuilder
    private var cardHeader: some View {
        VStack(spacing: DesignSystem.Spacing.lg) {
            // Large card artwork
            CardComponent(card: card, size: .regular, showShadow: true)
                .padding(.horizontal, DesignSystem.Spacing.lg)
                .padding(.top, DesignSystem.Spacing.md)

            // Card info
            VStack(spacing: DesignSystem.Spacing.xs) {
                Text(card.issuer)
                    .font(DesignSystem.Typography.subhead)
                    .foregroundStyle(DesignSystem.Colors.textSecondary)

                if let nickname = card.nickname {
                    Text(nickname)
                        .font(DesignSystem.Typography.caption)
                        .foregroundStyle(DesignSystem.Colors.textTertiary)
                }
            }

            // Value summary pills
            HStack(spacing: DesignSystem.Spacing.md) {
                SummaryPill(
                    title: "Available",
                    value: card.formattedTotalValue,
                    color: DesignSystem.Colors.success
                )

                if card.usedBenefits.count > 0 {
                    SummaryPill(
                        title: "Used",
                        value: "\(card.usedBenefits.count)",
                        color: DesignSystem.Colors.textSecondary
                    )
                }

                if card.expiringBenefitsCount > 0 {
                    SummaryPill(
                        title: "Expiring",
                        value: "\(card.expiringBenefitsCount)",
                        color: DesignSystem.Colors.warning
                    )
                }
            }
            .padding(.horizontal, DesignSystem.Spacing.lg)
        }
        .padding(.bottom, DesignSystem.Spacing.lg)
        .background(DesignSystem.Colors.backgroundSecondary)
    }

    // MARK: - Benefits Sections

    @ViewBuilder
    private var benefitsSections: some View {
        VStack(spacing: DesignSystem.Spacing.xl) {
            // Available Benefits
            if !card.availableBenefits.isEmpty {
                BenefitSection(
                    title: "Available Benefits",
                    subtitle: availableBenefitsSubtitle,
                    benefits: card.availableBenefits.sorted { $0.daysRemaining < $1.daysRemaining },
                    cardGradient: card.gradient,
                    onMarkAsDone: onMarkAsDone,
                    onSnooze: onSnooze,
                    highlightedBenefitId: highlightedId,
                    expandedBenefitId: $expandedBenefitId
                )
            }

            // Used Benefits
            if !card.usedBenefits.isEmpty {
                BenefitSection(
                    title: "Used This Period",
                    subtitle: usedBenefitsSubtitle,
                    benefits: card.usedBenefits,
                    cardGradient: card.gradient,
                    onUndo: onUndo,
                    highlightedBenefitId: highlightedId,
                    expandedBenefitId: $expandedBenefitId
                )
            }

            // Expired Benefits
            if !card.expiredBenefits.isEmpty {
                BenefitSection(
                    title: "Expired",
                    subtitle: nil,
                    benefits: card.expiredBenefits,
                    cardGradient: card.gradient,
                    isCollapsible: true,
                    highlightedBenefitId: highlightedId,
                    expandedBenefitId: $expandedBenefitId
                )
            }
        }
        .padding(.horizontal, DesignSystem.Spacing.lg)
    }

    // MARK: - Remove Card Section

    @ViewBuilder
    private var removeCardSection: some View {
        VStack(spacing: DesignSystem.Spacing.md) {
            Divider()
                .padding(.horizontal, DesignSystem.Spacing.lg)

            Button(role: .destructive, action: { showRemoveConfirmation = true }) {
                HStack {
                    Image(systemName: "trash")
                    Text("Remove Card")
                }
                .font(DesignSystem.Typography.body)
                .foregroundStyle(DesignSystem.Colors.danger)
                .frame(maxWidth: .infinity)
                .padding(.vertical, DesignSystem.Spacing.md)
            }
            .accessibilityLabel("Remove \(card.name) from wallet")
            .accessibilityHint("This will delete all tracked benefits for this card")
        }
    }

    // MARK: - ROI Section

    @ViewBuilder
    private var roiSection: some View {
        let benefitsRedeemed = card.usedBenefits.reduce(Decimal.zero) { $0 + $1.value }
        let recommendation = generateRetentionRecommendation(
            annualFee: card.annualFee,
            redeemedValue: benefitsRedeemed
        )

        CardROICard(
            annualFee: card.annualFee,
            annualFeeDate: card.annualFeeDate,
            benefitsRedeemed: benefitsRedeemed,
            subscriptionCosts: card.totalSubscriptionCost,
            recommendation: recommendation
        )
    }

    /// Generates a retention recommendation based on redeemed benefits vs annual fee.
    private func generateRetentionRecommendation(
        annualFee: Decimal,
        redeemedValue: Decimal
    ) -> CardRetentionRecommendation {
        guard annualFee > 0 else {
            return .strongKeep(reason: "No annual fee - keep for available benefits")
        }

        let netValue = redeemedValue - annualFee
        let roiPercentage = (netValue / annualFee) * 100

        if roiPercentage >= 50 {
            return .strongKeep(
                reason: "Getting \(Formatters.formatCurrency(redeemedValue)) in value vs \(Formatters.formatCurrency(annualFee)) fee"
            )
        } else if roiPercentage >= 0 {
            return .marginalKeep(
                reason: "Earning \(Formatters.formatCurrency(netValue)) above the annual fee"
            )
        } else if roiPercentage >= -20 {
            return .evaluate(
                reason: "Currently \(Formatters.formatCurrency(abs(netValue))) short of breaking even on the fee"
            )
        } else {
            return .considerCancelling(
                reason: "Losing \(Formatters.formatCurrency(abs(netValue))) after accounting for the annual fee"
            )
        }
    }

    // MARK: - Computed Properties

    private var availableBenefitsSubtitle: String {
        let total = card.availableBenefits.reduce(Decimal.zero) { $0 + $1.value }
        return "\(Formatters.formatCurrencyWhole(total)) remaining"
    }

    private var usedBenefitsSubtitle: String {
        let total = card.usedBenefits.reduce(Decimal.zero) { $0 + $1.value }
        return "\(Formatters.formatCurrencyWhole(total)) redeemed"
    }

    // MARK: - Deep Link Handling

    /// Scrolls to and highlights the specified benefit if needed
    private func scrollToBenefitIfNeeded(proxy: ScrollViewProxy) {
        guard let benefitId = highlightBenefitId else { return }

        // Small delay to ensure layout is complete
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            withAnimation(DesignSystem.Animation.spring) {
                proxy.scrollTo(benefitId, anchor: .center)
                expandedBenefitId = benefitId
                highlightedId = benefitId
            }

            // Clear highlight after animation
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                withAnimation(DesignSystem.Animation.spring) {
                    highlightedId = nil
                }
            }
        }
    }
}

// MARK: - Previews

#Preview("Card Detail - Full") {
    NavigationStack {
        CardDetailView(
            card: PreviewData.amexPlatinum,
            onMarkAsDone: { _ in },
            onSnooze: { _, _ in },
            onRemoveCard: { },
            onEditCard: { }
        )
    }
}

#Preview("Card Detail - All Used") {
    let allUsedCard = PreviewCard(
        name: "Test Card",
        issuer: "Test Bank",
        nickname: "Daily Card",
        gradient: .emerald,
        benefits: [
            .used(value: 50, name: "Monthly Credit"),
            .used(value: 25, name: "Dining Credit")
        ]
    )

    return NavigationStack {
        CardDetailView(
            card: allUsedCard,
            onRemoveCard: { }
        )
    }
}

#Preview("Card Detail - Mixed States") {
    NavigationStack {
        CardDetailView(
            card: PreviewData.chaseSapphireReserve,
            onMarkAsDone: { _ in },
            onSnooze: { _, _ in },
            onRemoveCard: { }
        )
    }
}

#Preview("Card Detail - Dark Mode") {
    NavigationStack {
        CardDetailView(
            card: PreviewData.amexGold,
            onMarkAsDone: { _ in },
            onRemoveCard: { }
        )
    }
    .preferredColorScheme(.dark)
}
