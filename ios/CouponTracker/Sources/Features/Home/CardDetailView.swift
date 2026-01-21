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
    var onMarkAsDone: ((PreviewBenefit) -> Void)? = nil
    var onSnooze: ((PreviewBenefit, Int) -> Void)? = nil
    var onUndo: ((PreviewBenefit) -> Void)? = nil
    var onRemoveCard: (() -> Void)? = nil
    var onEditCard: (() -> Void)? = nil

    // MARK: - State

    @State private var showRemoveConfirmation = false
    @State private var expandedBenefitId: UUID? = nil
    @State private var selectedPeriod: BenefitPeriod = .monthly
    @Environment(\.dismiss) private var dismiss

    // MARK: - Body

    var body: some View {
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

                // Benefits Sections
                benefitsSections
                    .padding(.top, DesignSystem.Spacing.lg)

                // Remove Card Section
                removeCardSection
                    .padding(.top, DesignSystem.Spacing.xxl)
                    .padding(.bottom, DesignSystem.Spacing.xxxl)
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

    // MARK: - Computed Properties

    private var availableBenefitsSubtitle: String {
        let total = card.availableBenefits.reduce(Decimal.zero) { $0 + $1.value }
        return "\(Formatters.formatCurrencyWhole(total)) remaining"
    }

    private var usedBenefitsSubtitle: String {
        let total = card.usedBenefits.reduce(Decimal.zero) { $0 + $1.value }
        return "\(Formatters.formatCurrencyWhole(total)) redeemed"
    }
}

// MARK: - Previews

#Preview("Card Detail - Full") {
    NavigationStack {
        CardDetailView(
            card: PreviewData.amexPlatinum,
            onMarkAsDone: { benefit in
                print("Marked done: \(benefit.name)")
            },
            onSnooze: { benefit, days in
                print("Snoozed \(benefit.name) for \(days) days")
            },
            onRemoveCard: {
                print("Remove card")
            },
            onEditCard: {
                print("Edit card")
            }
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
