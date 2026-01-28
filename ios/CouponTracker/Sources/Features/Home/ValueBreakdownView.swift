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
    var onSelectCategory: ((BenefitCategory) -> Void)?
    var onSelectPeriod: ((TimePeriodFilter) -> Void)?

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
                    ForEach(TimePeriodFilter.allCases) { period in
                        timePeriodRow(period: period)
                    }
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
        Button(action: {
            dismiss()
            onSelectCategory?(category)
        }) {
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

                    Text("\(viewModel.benefitCountForCategory(category)) benefits")
                        .font(DesignSystem.Typography.caption)
                        .foregroundStyle(DesignSystem.Colors.textSecondary)
                }

                Spacer()

                Text(Formatters.formatCurrencyWhole(value))
                    .font(DesignSystem.Typography.valueSmall)
                    .foregroundStyle(DesignSystem.Colors.textPrimary)

                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(DesignSystem.Colors.textTertiary)
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(category.displayName), \(Formatters.formatCurrencyWhole(value))")
        .accessibilityHint("Double tap to view \(category.displayName.lowercased()) benefits")
    }

    // MARK: - Time Period Row

    @ViewBuilder
    private func timePeriodRow(period: TimePeriodFilter) -> some View {
        let value = viewModel.totalValueForPeriod(period)
        let count = viewModel.benefitCountForPeriod(period)

        Button(action: {
            dismiss()
            onSelectPeriod?(period)
        }) {
            HStack(spacing: DesignSystem.Spacing.md) {
                // Time indicator
                Circle()
                    .fill(period.color)
                    .frame(width: 12, height: 12)

                // Period info
                VStack(alignment: .leading, spacing: 2) {
                    Text(period.displayTitle)
                        .font(DesignSystem.Typography.subhead)
                        .foregroundStyle(DesignSystem.Colors.textPrimary)

                    Text("\(count) \(count == 1 ? "benefit" : "benefits")")
                        .font(DesignSystem.Typography.caption)
                        .foregroundStyle(DesignSystem.Colors.textSecondary)
                }

                Spacer()

                Text(Formatters.formatCurrencyWhole(value))
                    .font(DesignSystem.Typography.valueSmall)
                    .foregroundStyle(DesignSystem.Colors.textPrimary)

                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(DesignSystem.Colors.textTertiary)
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(period.displayTitle), \(Formatters.formatCurrencyWhole(value))")
        .accessibilityHint("Double tap to view \(period.displayTitle.lowercased()) benefits")
    }
}

// MARK: - Previews

#Preview("Value Breakdown") {
    ValueBreakdownView(
        viewModel: HomeViewModel.preview,
        onSelectCard: { cardId in
            print("Selected card: \(cardId)")
        },
        onSelectCategory: { category in
            print("Selected category: \(category)")
        },
        onSelectPeriod: { period in
            print("Selected period: \(period)")
        }
    )
}

#Preview("Value Breakdown - Dark Mode") {
    ValueBreakdownView(
        viewModel: HomeViewModel.preview,
        onSelectCard: { cardId in
            print("Selected card: \(cardId)")
        },
        onSelectCategory: { category in
            print("Selected category: \(category)")
        },
        onSelectPeriod: { period in
            print("Selected period: \(period)")
        }
    )
    .preferredColorScheme(.dark)
}
