//
//  ValueBreakdownView.swift
//  CouponTracker
//
//  Created: January 18, 2026
//
//  Purpose: A modal sheet that provides a detailed breakdown of available benefit
//           values organized by card, category, and time period.
//
//  ACCESSIBILITY:
//  - VoiceOver support with descriptive labels
//  - Proper section headers
//
//  USAGE:
//  .sheet(isPresented: $showBreakdown) {
//      ValueBreakdownView(viewModel: viewModel, onSelectCard: { cardId in ... })
//  }

import SwiftUI

// MARK: - Value Breakdown View

/// Modal view showing detailed breakdown of benefit values
struct ValueBreakdownView: View {

    // MARK: - Properties

    let viewModel: HomeViewModel
    var onSelectCard: ((UUID) -> Void)?

    @Environment(\.dismiss) private var dismiss

    // MARK: - Computed Properties

    /// Cards sorted by available value (descending)
    private var cardsByValue: [CardDisplayAdapter] {
        viewModel.displayCards.sorted { $0.totalAvailableValue > $1.totalAvailableValue }
    }

    /// Categories sorted by value (descending)
    private var categoriesByValue: [(category: BenefitCategory, value: Decimal)] {
        viewModel.benefitsByCategory
            .map { (category: $0.key, value: $0.value) }
            .sorted { $0.value > $1.value }
    }

    /// Value expiring this week
    private var thisWeekValue: Decimal {
        viewModel.benefitsExpiringThisWeek.reduce(Decimal.zero) { $0 + $1.value }
    }

    /// Value expiring this month (8-30 days)
    private var thisMonthValue: Decimal {
        viewModel.benefitsExpiringThisMonth.reduce(Decimal.zero) { $0 + $1.value }
    }

    /// Value expiring later (30+ days)
    private var laterValue: Decimal {
        viewModel.allDisplayBenefits
            .filter { $0.daysRemaining > 30 }
            .reduce(Decimal.zero) { $0 + $1.value }
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            List {
                // Summary header
                Section {
                    summaryHeader
                }
                .listRowBackground(Color.clear)
                .listRowInsets(EdgeInsets())

                // By Card section
                Section("By Card") {
                    ForEach(cardsByValue, id: \.id) { card in
                        cardRow(for: card)
                    }
                }

                // By Category section
                Section("By Category") {
                    ForEach(categoriesByValue, id: \.category) { item in
                        categoryRow(for: item.category, value: item.value)
                    }
                }

                // By Time Period section
                Section("By Time Period") {
                    timePeriodRow(title: "This Week", subtitle: "0-7 days", value: thisWeekValue, color: DesignSystem.Colors.danger)
                    timePeriodRow(title: "This Month", subtitle: "8-30 days", value: thisMonthValue, color: DesignSystem.Colors.warning)
                    timePeriodRow(title: "Later", subtitle: "30+ days", value: laterValue, color: DesignSystem.Colors.success)
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Value Breakdown")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }

    // MARK: - Summary Header

    @ViewBuilder
    private var summaryHeader: some View {
        VStack(spacing: DesignSystem.Spacing.sm) {
            Text("Total Available")
                .font(DesignSystem.Typography.subhead)
                .foregroundStyle(DesignSystem.Colors.textSecondary)

            Text(Formatters.formatCurrencyWhole(viewModel.totalAvailableValue))
                .font(DesignSystem.Typography.valueLarge)
                .foregroundStyle(DesignSystem.Colors.textPrimary)

            HStack(spacing: DesignSystem.Spacing.lg) {
                VStack(spacing: 2) {
                    Text(Formatters.formatCurrencyWhole(viewModel.redeemedThisMonth))
                        .font(DesignSystem.Typography.headline)
                        .foregroundStyle(DesignSystem.Colors.success)
                    Text("Redeemed")
                        .font(DesignSystem.Typography.caption)
                        .foregroundStyle(DesignSystem.Colors.textSecondary)
                }

                VStack(spacing: 2) {
                    Text(Formatters.formatCurrencyWhole(viewModel.expiredValueThisMonth))
                        .font(DesignSystem.Typography.headline)
                        .foregroundStyle(DesignSystem.Colors.danger)
                    Text("Expired")
                        .font(DesignSystem.Typography.caption)
                        .foregroundStyle(DesignSystem.Colors.textSecondary)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, DesignSystem.Spacing.lg)
    }

    // MARK: - Card Row

    @ViewBuilder
    private func cardRow(for card: CardDisplayAdapter) -> some View {
        Button(action: {
            dismiss()
            onSelectCard?(card.id)
        }) {
            HStack(spacing: DesignSystem.Spacing.md) {
                // Mini gradient icon
                RoundedRectangle(cornerRadius: 4)
                    .fill(card.gradient.gradient)
                    .frame(width: 32, height: 20)

                // Card info
                VStack(alignment: .leading, spacing: 2) {
                    Text(card.displayName)
                        .font(DesignSystem.Typography.subhead)
                        .foregroundStyle(DesignSystem.Colors.textPrimary)

                    Text("\(card.availableBenefits.count) benefits available")
                        .font(DesignSystem.Typography.caption)
                        .foregroundStyle(DesignSystem.Colors.textSecondary)
                }

                Spacer()

                Text(card.formattedTotalValue)
                    .font(DesignSystem.Typography.valueSmall)
                    .foregroundStyle(DesignSystem.Colors.textPrimary)

                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(DesignSystem.Colors.textTertiary)
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(card.displayName), \(card.formattedTotalValue) available")
        .accessibilityHint("Double tap to view card details")
    }

    // MARK: - Category Row

    @ViewBuilder
    private func categoryRow(for category: BenefitCategory, value: Decimal) -> some View {
        HStack(spacing: DesignSystem.Spacing.md) {
            // Category color dot
            Circle()
                .fill(DesignSystem.Colors.categoryColor(for: category))
                .frame(width: 12, height: 12)

            // Category info
            VStack(alignment: .leading, spacing: 2) {
                Text(category.displayName)
                    .font(DesignSystem.Typography.subhead)
                    .foregroundStyle(DesignSystem.Colors.textPrimary)
            }

            Spacer()

            Text(Formatters.formatCurrencyWhole(value))
                .font(DesignSystem.Typography.valueSmall)
                .foregroundStyle(DesignSystem.Colors.textPrimary)
        }
        .accessibilityLabel("\(category.displayName), \(Formatters.formatCurrencyWhole(value))")
    }

    // MARK: - Time Period Row

    @ViewBuilder
    private func timePeriodRow(title: String, subtitle: String, value: Decimal, color: Color) -> some View {
        HStack(spacing: DesignSystem.Spacing.md) {
            // Time indicator
            Circle()
                .fill(color)
                .frame(width: 12, height: 12)

            // Period info
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(DesignSystem.Typography.subhead)
                    .foregroundStyle(DesignSystem.Colors.textPrimary)

                Text(subtitle)
                    .font(DesignSystem.Typography.caption)
                    .foregroundStyle(DesignSystem.Colors.textSecondary)
            }

            Spacer()

            Text(Formatters.formatCurrencyWhole(value))
                .font(DesignSystem.Typography.valueSmall)
                .foregroundStyle(DesignSystem.Colors.textPrimary)
        }
        .accessibilityLabel("\(title), \(Formatters.formatCurrencyWhole(value))")
    }
}

// MARK: - Previews

#Preview("Value Breakdown") {
    ValueBreakdownView(
        viewModel: HomeViewModel.preview,
        onSelectCard: { cardId in
            print("Selected card: \(cardId)")
        }
    )
}

#Preview("Value Breakdown - Dark Mode") {
    ValueBreakdownView(
        viewModel: HomeViewModel.preview,
        onSelectCard: { cardId in
            print("Selected card: \(cardId)")
        }
    )
    .preferredColorScheme(.dark)
}
