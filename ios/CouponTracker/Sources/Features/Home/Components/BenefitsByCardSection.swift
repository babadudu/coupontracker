//
//  BenefitsByCardSection.swift
//  CouponTracker
//
//  Created: January 2026
//
//  Purpose: Section component showing benefits grouped under a card header.
//           Used in CategoryBenefitsView for drill-down from ValueBreakdownView.
//

import SwiftUI

// MARK: - Benefits By Card Section

/// Displays a card header with its benefits list.
/// Used for category drill-down where benefits are grouped by card.
struct BenefitsByCardSection: View {

    // MARK: - Properties

    let card: CardDisplayAdapter
    let benefits: [BenefitDisplayAdapter]
    var onSelectCard: (() -> Void)?
    var onMarkAsDone: ((BenefitDisplayAdapter) -> Void)?
    var onTapBenefit: ((BenefitDisplayAdapter) -> Void)?

    // MARK: - Body

    var body: some View {
        Section {
            ForEach(benefits, id: \.id) { benefit in
                benefitRow(for: benefit)
            }
        } header: {
            cardHeader
        }
    }

    // MARK: - Card Header

    @ViewBuilder
    private var cardHeader: some View {
        Button(action: { onSelectCard?() }) {
            HStack(spacing: DesignSystem.Spacing.md) {
                // Mini gradient
                RoundedRectangle(cornerRadius: 4)
                    .fill(card.gradient.gradient)
                    .frame(width: 32, height: 20)

                // Card name
                Text(card.displayName)
                    .font(DesignSystem.Typography.headline)
                    .foregroundStyle(DesignSystem.Colors.textPrimary)

                Spacer()

                // Value badge
                Text(sectionValue)
                    .font(DesignSystem.Typography.subhead)
                    .foregroundStyle(DesignSystem.Colors.primaryFallback)

                // Chevron
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(DesignSystem.Colors.textTertiary)
            }
            .textCase(nil)
            .padding(.vertical, DesignSystem.Spacing.xs)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(card.displayName), \(sectionValue)")
        .accessibilityHint("Double tap to view card details")
    }

    private var sectionValue: String {
        let total = benefits.reduce(Decimal.zero) { $0 + $1.value }
        return Formatters.formatCurrencyWhole(total)
    }

    // MARK: - Benefit Row

    @ViewBuilder
    private func benefitRow(for benefit: BenefitDisplayAdapter) -> some View {
        HStack(spacing: DesignSystem.Spacing.md) {
            // Status icon
            statusIcon(for: benefit)

            // Benefit info
            VStack(alignment: .leading, spacing: 2) {
                Text(benefit.name)
                    .font(DesignSystem.Typography.subhead)
                    .foregroundStyle(DesignSystem.Colors.textPrimary)

                Text(benefit.urgencyText)
                    .font(DesignSystem.Typography.caption)
                    .foregroundStyle(
                        DesignSystem.Colors.urgencyColor(daysRemaining: benefit.daysRemaining)
                    )
            }

            Spacer()

            // Value
            Text(benefit.formattedValue)
                .font(DesignSystem.Typography.valueSmall)
                .foregroundStyle(DesignSystem.Colors.textPrimary)
        }
        .padding(.vertical, DesignSystem.Spacing.xs)
        .background(
            DesignSystem.Colors.urgencyBackgroundColor(daysRemaining: benefit.daysRemaining)
        )
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            if benefit.status == .available {
                Button(action: { onMarkAsDone?(benefit) }) {
                    Label("Done", systemImage: "checkmark.circle.fill")
                }
                .tint(DesignSystem.Colors.success)
            }
        }
        .onTapGesture {
            onTapBenefit?(benefit)
        }
        .accessibilityLabel("\(benefit.formattedValue) \(benefit.name), \(benefit.urgencyText)")
        .accessibilityHint("Swipe left to mark as done")
    }

    private func statusIcon(for benefit: BenefitDisplayAdapter) -> some View {
        let iconName: String
        let color: Color

        switch benefit.daysRemaining {
        case ..<0:
            iconName = "xmark.circle"
            color = DesignSystem.Colors.neutral
        case 0...3:
            iconName = "exclamationmark.circle.fill"
            color = DesignSystem.Colors.danger
        case 4...7:
            iconName = "clock"
            color = DesignSystem.Colors.warning
        default:
            iconName = "circle"
            color = DesignSystem.Colors.success
        }

        return Image(systemName: iconName)
            .font(.system(size: 16, weight: .medium))
            .foregroundStyle(color)
            .frame(width: 20, height: 20)
    }
}

// MARK: - Previews

#if DEBUG
@MainActor
private struct BenefitsByCardSectionPreview: View {
    var body: some View {
        let viewModel = HomeViewModel.preview
        let card = viewModel.displayCards.first!
        let benefits = card.benefits.filter { $0.status == .available }

        List {
            BenefitsByCardSection(
                card: card,
                benefits: benefits,
                onSelectCard: { print("Card tapped") },
                onMarkAsDone: { print("Mark done: \($0.name)") }
            )
        }
        .listStyle(.insetGrouped)
    }
}

#Preview("Benefits By Card Section") {
    BenefitsByCardSectionPreview()
}
#endif
