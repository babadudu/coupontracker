//
//  BenefitCategoryChartView.swift
//  CouponTracker
//
//  Created: January 17, 2026
//
//  Purpose: Displays a donut chart showing the distribution of available benefits by category.
//           Shows total value in the center, with a legend showing category names and values.
//           Handles empty state gracefully when no data is available.
//
//  ACCESSIBILITY:
//  - Full VoiceOver support with descriptive labels
//  - Chart data is accessible through VoiceOver gestures
//  - Color-blind friendly with both color and text labels
//
//  USAGE:
//  BenefitCategoryChartView(benefits: myBenefits)
//

import SwiftUI
import Charts

// MARK: - Category Chart Data

/// Data structure for chart display, grouping benefits by category
struct CategoryChartData: Identifiable {
    let id = UUID()
    let category: BenefitCategory
    let value: Decimal
    let percentage: Double

    /// Formatted value for display
    var formattedValue: String {
        Formatters.formatCurrencyWhole(value)
    }

    /// Formatted percentage for display
    var formattedPercentage: String {
        String(format: "%.0f%%", percentage * 100)
    }
}

// MARK: - Benefit Category Chart View

/// A donut chart component showing benefit value distribution by category.
/// Displays total value in center with legend showing categories and values.
struct BenefitCategoryChartView: View {

    // MARK: - Properties

    let benefits: [any BenefitDisplayable]
    var onMarkAsDone: ((any BenefitDisplayable) -> Void)? = nil

    // MARK: - State

    @State private var selectedCategory: BenefitCategory?

    // MARK: - Computed Properties

    /// Chart data grouped and calculated by category
    private var chartData: [CategoryChartData] {
        // Group benefits by category and sum values
        let categoryGroups = Dictionary(grouping: benefits) { $0.category }
        let totalValue = benefits.reduce(Decimal(0)) { $0 + $1.value }

        // Guard against division by zero
        guard totalValue > 0 else { return [] }

        // Map to chart data with percentages
        return categoryGroups.map { category, benefits in
            let categoryTotal = benefits.reduce(Decimal(0)) { $0 + $1.value }
            let percentage = (categoryTotal as NSDecimalNumber).doubleValue / (totalValue as NSDecimalNumber).doubleValue

            return CategoryChartData(
                category: category,
                value: categoryTotal,
                percentage: percentage
            )
        }
        .sorted { $0.value > $1.value } // Sort by value descending
    }

    /// Total value across all benefits
    private var totalValue: Decimal {
        benefits.reduce(Decimal(0)) { $0 + $1.value }
    }

    /// Formatted total value
    private var formattedTotalValue: String {
        Formatters.formatCurrencyWhole(totalValue)
    }

    /// Whether there is data to display
    private var hasData: Bool {
        !chartData.isEmpty && totalValue > 0
    }

    /// Benefits filtered by selected category
    private var filteredBenefits: [any BenefitDisplayable] {
        guard let category = selectedCategory else { return [] }
        return benefits.filter { $0.category == category }
    }

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.lg) {
            // Header
            Text("Benefits by Category")
                .font(DesignSystem.Typography.title3)
                .foregroundStyle(DesignSystem.Colors.textPrimary)

            if hasData {
                // Chart and legend
                VStack(spacing: DesignSystem.Spacing.xl) {
                    // Donut chart
                    donutChart
                        .frame(height: 240)

                    // Legend
                    categoryLegend

                    // Benefits list for selected category
                    if selectedCategory != nil {
                        benefitsList
                            .transition(.opacity.combined(with: .move(edge: .top)))
                    }
                }
            } else {
                // Empty state
                emptyState
            }
        }
        .padding(DesignSystem.Spacing.lg)
        .background(DesignSystem.Colors.backgroundSecondary)
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Sizing.cardCornerRadius))
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Benefits by Category Chart")
    }

    // MARK: - Donut Chart

    @ViewBuilder
    private var donutChart: some View {
        ZStack {
            // Chart
            Chart(chartData) { data in
                SectorMark(
                    angle: .value("Value", (data.value as NSDecimalNumber).doubleValue),
                    innerRadius: .ratio(0.6),
                    angularInset: 2
                )
                .foregroundStyle(DesignSystem.Colors.categoryColor(for: data.category))
                .opacity(selectedCategory == nil || selectedCategory == data.category ? 1.0 : 0.3)
                .accessibilityLabel("\(data.category.displayName): \(data.formattedValue)")
                .accessibilityValue("\(data.formattedPercentage) of total")
            }

            // Center content - total value
            VStack(spacing: DesignSystem.Spacing.xs) {
                Text(formattedTotalValue)
                    .font(DesignSystem.Typography.valueMedium)
                    .foregroundStyle(DesignSystem.Colors.textPrimary)

                Text("Total Available")
                    .font(DesignSystem.Typography.caption)
                    .foregroundStyle(DesignSystem.Colors.textSecondary)
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Total available value: \(formattedTotalValue)")
        }
        .chartLegend(.hidden) // We'll use custom legend
    }

    // MARK: - Category Legend

    @ViewBuilder
    private var categoryLegend: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
            ForEach(chartData) { data in
                categoryLegendRow(data)
            }
        }
    }

    @ViewBuilder
    private func categoryLegendRow(_ data: CategoryChartData) -> some View {
        Button(action: {
            // Toggle selection
            withAnimation(.easeInOut(duration: 0.2)) {
                if selectedCategory == data.category {
                    selectedCategory = nil
                } else {
                    selectedCategory = data.category
                }
            }
        }) {
            HStack(spacing: DesignSystem.Spacing.md) {
                // Color indicator with category icon
                ZStack {
                    Circle()
                        .fill(DesignSystem.Colors.categoryColor(for: data.category))
                        .frame(width: 32, height: 32)

                    Image(systemName: data.category.iconName)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(DesignSystem.Colors.onColor)
                }

                // Category name
                VStack(alignment: .leading, spacing: 2) {
                    Text(data.category.displayName)
                        .font(DesignSystem.Typography.subhead)
                        .foregroundStyle(DesignSystem.Colors.textPrimary)

                    Text(data.formattedPercentage)
                        .font(DesignSystem.Typography.caption)
                        .foregroundStyle(DesignSystem.Colors.textSecondary)
                }

                Spacer()

                // Value
                Text(data.formattedValue)
                    .font(DesignSystem.Typography.valueSmall)
                    .foregroundStyle(DesignSystem.Colors.textPrimary)
            }
            .padding(.vertical, DesignSystem.Spacing.xs)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(data.category.displayName): \(data.formattedValue), \(data.formattedPercentage) of total")
        .accessibilityHint("Double tap to highlight this category in the chart")
    }

    // MARK: - Empty State

    @ViewBuilder
    private var emptyState: some View {
        VStack(spacing: DesignSystem.Spacing.md) {
            Image(systemName: "chart.pie")
                .font(.system(size: 48))
                .foregroundStyle(DesignSystem.Colors.textTertiary)

            Text("No Available Benefits")
                .font(DesignSystem.Typography.headline)
                .foregroundStyle(DesignSystem.Colors.textSecondary)

            Text("Add benefits to your cards to see the category breakdown")
                .font(DesignSystem.Typography.subhead)
                .foregroundStyle(DesignSystem.Colors.textTertiary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, DesignSystem.Spacing.xl)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("No available benefits to display")
    }

    // MARK: - Benefits List

    @ViewBuilder
    private var benefitsList: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
            // Section header
            if let category = selectedCategory {
                HStack {
                    Text("\(category.displayName) Benefits")
                        .font(DesignSystem.Typography.headline)
                        .foregroundStyle(DesignSystem.Colors.textPrimary)

                    Spacer()

                    Text("\(filteredBenefits.count)")
                        .font(DesignSystem.Typography.subhead)
                        .foregroundStyle(DesignSystem.Colors.textSecondary)
                }
            }

            // Benefits rows
            ForEach(filteredBenefits, id: \.id) { benefit in
                benefitRow(benefit)
            }
        }
        .padding(.top, DesignSystem.Spacing.md)
    }

    @ViewBuilder
    private func benefitRow(_ benefit: any BenefitDisplayable) -> some View {
        HStack(spacing: DesignSystem.Spacing.md) {
            // Benefit info
            VStack(alignment: .leading, spacing: 2) {
                Text(benefit.name)
                    .font(DesignSystem.Typography.subhead)
                    .foregroundStyle(DesignSystem.Colors.textPrimary)

                HStack(spacing: DesignSystem.Spacing.sm) {
                    Text(benefit.formattedValue)
                        .font(DesignSystem.Typography.caption)
                        .foregroundStyle(DesignSystem.Colors.textSecondary)

                    Text("•")
                        .foregroundStyle(DesignSystem.Colors.textTertiary)

                    Text(benefit.urgencyText)
                        .font(DesignSystem.Typography.caption)
                        .foregroundStyle(DesignSystem.Colors.urgencyColor(daysRemaining: benefit.daysRemaining))
                }
            }

            Spacer()

            // Mark as Done button
            if onMarkAsDone != nil {
                Button(action: {
                    onMarkAsDone?(benefit)
                }) {
                    Text("Mark Done")
                        .font(DesignSystem.Typography.caption)
                        .foregroundStyle(DesignSystem.Colors.onColor)
                        .padding(.horizontal, DesignSystem.Spacing.sm)
                        .padding(.vertical, DesignSystem.Spacing.xs)
                        .background(
                            RoundedRectangle(cornerRadius: DesignSystem.Sizing.buttonCornerRadius)
                                .fill(DesignSystem.Colors.success)
                        )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(DesignSystem.Spacing.sm)
        .background(
            RoundedRectangle(cornerRadius: DesignSystem.Sizing.buttonCornerRadius)
                .fill(DesignSystem.Colors.backgroundPrimary)
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(benefit.name), \(benefit.formattedValue), \(benefit.urgencyText)")
    }

}

// MARK: - Previews

#Preview("Category Chart - Full Data") {
    ScrollView {
        VStack(spacing: DesignSystem.Spacing.lg) {
            BenefitCategoryChartView(
                benefits: PreviewData.sampleCards.flatMap { $0.availableBenefits }
            )
            .padding()
        }
    }
    .background(DesignSystem.Colors.backgroundPrimary)
}

#Preview("Category Chart - Single Category") {
    ScrollView {
        VStack(spacing: DesignSystem.Spacing.lg) {
            BenefitCategoryChartView(
                benefits: [
                    PreviewData.uberCredit,
                    PreviewData.saksCredit,
                    PreviewData.airlineCredit
                ]
            )
            .padding()
        }
    }
    .background(DesignSystem.Colors.backgroundPrimary)
}

#Preview("Category Chart - Empty State") {
    ScrollView {
        VStack(spacing: DesignSystem.Spacing.lg) {
            BenefitCategoryChartView(benefits: [])
                .padding()
        }
    }
    .background(DesignSystem.Colors.backgroundPrimary)
}

#Preview("Category Chart - Mixed Categories") {
    ScrollView {
        VStack(spacing: DesignSystem.Spacing.lg) {
            let mixedBenefits: [PreviewBenefit] = [
                PreviewBenefit(
                    name: "Travel Credit",
                    value: 300,
                    frequency: .annual,
                    category: .travel,
                    expirationDate: PreviewData.endOfYear
                ),
                PreviewBenefit(
                    name: "Dining Credit",
                    value: 120,
                    frequency: .monthly,
                    category: .dining,
                    expirationDate: PreviewData.endOfMonth
                ),
                PreviewBenefit(
                    name: "Entertainment Credit",
                    value: 240,
                    frequency: .annual,
                    category: .entertainment,
                    expirationDate: PreviewData.endOfYear
                ),
                PreviewBenefit(
                    name: "Shopping Credit",
                    value: 100,
                    frequency: .semiAnnual,
                    category: .shopping,
                    expirationDate: PreviewData.endOfQuarter
                ),
                PreviewBenefit(
                    name: "Transportation Credit",
                    value: 180,
                    frequency: .monthly,
                    category: .transportation,
                    expirationDate: PreviewData.endOfMonth
                ),
                PreviewBenefit(
                    name: "Business Credit",
                    value: 200,
                    frequency: .annual,
                    category: .business,
                    expirationDate: PreviewData.endOfYear
                )
            ]

            BenefitCategoryChartView(benefits: mixedBenefits)
                .padding()
        }
    }
    .background(DesignSystem.Colors.backgroundPrimary)
}

#Preview("Category Chart - Dark Mode") {
    ScrollView {
        VStack(spacing: DesignSystem.Spacing.lg) {
            BenefitCategoryChartView(
                benefits: PreviewData.sampleCards.flatMap { $0.availableBenefits }
            )
            .padding()
        }
    }
    .background(DesignSystem.Colors.backgroundPrimary)
    .preferredColorScheme(.dark)
}
