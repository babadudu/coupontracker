//
//  PeriodCarouselView.swift
//  CouponTracker
//
//  Created: January 2026
//  Purpose: Horizontal swipeable carousel for period selection.
//           Displays accomplishment rings for each time period.

import SwiftUI

/// Horizontal carousel for navigating between benefit periods.
///
/// Shows:
/// - Period label (e.g., "January 2026")
/// - Page indicator dots
/// - Swipeable content for each period
struct PeriodCarouselView<Content: View>: View {

    // MARK: - Properties

    @Binding var selectedPeriod: BenefitPeriod
    let content: (BenefitPeriod) -> Content

    // MARK: - State

    @State private var dragOffset: CGFloat = 0

    // MARK: - Body

    var body: some View {
        VStack(spacing: DesignSystem.Spacing.sm) {
            headerView

            TabView(selection: $selectedPeriod) {
                ForEach(BenefitPeriod.allCases) { period in
                    content(period)
                        .tag(period)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .animation(.easeInOut, value: selectedPeriod)
        }
    }

    // MARK: - Header

    private var headerView: some View {
        HStack {
            Text(selectedPeriod.periodLabel())
                .font(DesignSystem.Typography.headline)
                .foregroundStyle(DesignSystem.Colors.textPrimary)
                .animation(.none, value: selectedPeriod)

            Spacer()

            pageIndicator
        }
        .padding(.horizontal, DesignSystem.Spacing.lg)
    }

    // MARK: - Page Indicator

    private var pageIndicator: some View {
        HStack(spacing: 6) {
            ForEach(BenefitPeriod.allCases) { period in
                Circle()
                    .fill(period == selectedPeriod
                          ? DesignSystem.Colors.primaryFallback
                          : DesignSystem.Colors.neutral.opacity(0.3))
                    .frame(width: 8, height: 8)
                    .animation(.easeInOut(duration: 0.2), value: selectedPeriod)
            }
        }
    }
}

// MARK: - Dashboard Period Section

/// Complete period section for the dashboard with rings.
///
/// Combines the carousel header with the accomplishment ring display.
struct DashboardPeriodSection: View {

    // MARK: - Properties

    let benefits: [Benefit]
    @Binding var selectedPeriod: BenefitPeriod
    /// Optional closure to fetch historical redeemed value for a period.
    /// If provided, uses actual BenefitUsage records instead of current status.
    var historicalRedeemedValue: ((BenefitPeriod) -> Decimal)?

    // MARK: - Body

    var body: some View {
        VStack(spacing: 0) {
            PeriodCarouselView(selectedPeriod: $selectedPeriod) { period in
                periodContent(for: period)
                    .padding(.horizontal, DesignSystem.Spacing.lg)
            }
            .frame(height: 280)
        }
        .background(
            RoundedRectangle(cornerRadius: DesignSystem.Sizing.cardCornerRadius)
                .fill(DesignSystem.Colors.backgroundSecondary)
        )
        .padding(.horizontal, DesignSystem.Spacing.lg)
    }

    // MARK: - Period Content

    @ViewBuilder
    private func periodContent(for period: BenefitPeriod) -> some View {
        let progress = calculateProgress(for: period)

        VStack(spacing: DesignSystem.Spacing.md) {
            AccomplishmentRingsView(
                progress: progress,
                period: period,
                size: 180
            )

            if !progress.isEmpty {
                Text("\(progress.percentageText) redeemed")
                    .font(DesignSystem.Typography.footnote)
                    .foregroundStyle(DesignSystem.Colors.textSecondary)
            }
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Progress Calculation

    private func calculateProgress(for period: BenefitPeriod) -> RingProgress {
        let metrics: PeriodMetrics
        if let historicalRedeemed = historicalRedeemedValue?(period) {
            metrics = PeriodMetrics.calculateWithHistory(
                for: benefits,
                historicalRedeemed: historicalRedeemed,
                period: period
            )
        } else {
            metrics = PeriodMetrics.calculate(for: benefits, period: period)
        }

        return RingProgress(
            redeemedValue: metrics.redeemedValue,
            totalValue: metrics.totalValue,
            usedCount: metrics.usedCount,
            totalCount: metrics.totalCount
        )
    }
}

// MARK: - Card Period Section

/// Period section for individual card detail views.
///
/// Shows category-based rings for a single card.
struct CardPeriodSection: View {

    // MARK: - Properties

    let card: UserCard
    let benefits: [Benefit]
    @Binding var selectedPeriod: BenefitPeriod

    // MARK: - Body

    var body: some View {
        VStack(spacing: 0) {
            PeriodCarouselView(selectedPeriod: $selectedPeriod) { period in
                cardPeriodContent(for: period)
            }
            .frame(height: 200)
        }
        .background(
            RoundedRectangle(cornerRadius: DesignSystem.Sizing.cardCornerRadius)
                .fill(DesignSystem.Colors.backgroundSecondary)
        )
    }

    // MARK: - Content

    @ViewBuilder
    private func cardPeriodContent(for period: BenefitPeriod) -> some View {
        let (viewStart, viewEnd) = period.periodDates()
        let periodBenefits = benefits.filter { benefit in
            benefit.currentPeriodStart <= viewEnd &&
            benefit.currentPeriodEnd >= viewStart
        }

        if periodBenefits.isEmpty {
            emptyState(for: period)
        } else {
            categoryRingsView(benefits: periodBenefits)
        }
    }

    private func categoryRingsView(benefits: [Benefit]) -> some View {
        let categoryProgress = calculateCategoryProgress(benefits: benefits)

        return VStack(spacing: DesignSystem.Spacing.md) {
            HStack(spacing: DesignSystem.Spacing.xl) {
                ForEach(categoryProgress.prefix(3), id: \.category) { item in
                    CategoryRing(
                        category: item.category,
                        usedCount: item.usedCount,
                        totalCount: item.totalCount
                    )
                }
            }

            progressSummary(benefits: benefits)
        }
        .padding(.horizontal, DesignSystem.Spacing.lg)
    }

    private func emptyState(for period: BenefitPeriod) -> some View {
        VStack(spacing: DesignSystem.Spacing.sm) {
            Image(systemName: "circle.dashed")
                .font(.system(size: 40))
                .foregroundStyle(DesignSystem.Colors.textTertiary)

            Text("No \(period.displayName.lowercased()) benefits")
                .font(DesignSystem.Typography.footnote)
                .foregroundStyle(DesignSystem.Colors.textSecondary)

            Text("This card doesn't have benefits that reset \(period.displayName.lowercased()).")
                .font(DesignSystem.Typography.caption)
                .foregroundStyle(DesignSystem.Colors.textTertiary)
                .multilineTextAlignment(.center)
        }
        .padding()
    }

    private func progressSummary(benefits: [Benefit]) -> some View {
        let used = benefits.filter { $0.status == .used }
        let usedValue = used.reduce(Decimal.zero) { $0 + $1.effectiveValue }
        let totalValue = benefits.reduce(Decimal.zero) { $0 + $1.effectiveValue }
        let percentage: Int
        if totalValue > 0 {
            percentage = NSDecimalNumber(decimal: usedValue / totalValue * 100).intValue
        } else {
            percentage = 0
        }

        return Text("\(percentage)% complete · \(CurrencyFormatter.shared.format(usedValue)) of \(CurrencyFormatter.shared.format(totalValue))")
            .font(DesignSystem.Typography.caption)
            .foregroundStyle(DesignSystem.Colors.textSecondary)
    }

    // MARK: - Helpers

    private struct CategoryProgress {
        let category: BenefitCategory
        let usedCount: Int
        let totalCount: Int
    }

    private func calculateCategoryProgress(benefits: [Benefit]) -> [CategoryProgress] {
        let grouped = Dictionary(grouping: benefits) { $0.category }

        return grouped.map { category, categoryBenefits in
            let used = categoryBenefits.filter { $0.status == .used }.count
            return CategoryProgress(
                category: category,
                usedCount: used,
                totalCount: categoryBenefits.count
            )
        }.sorted { $0.totalCount > $1.totalCount }
    }
}

// MARK: - Preview Card Period Section

/// Period section for CardDetailView using PreviewBenefit.
struct PreviewCardPeriodSection: View {

    // MARK: - Properties

    let benefits: [PreviewBenefit]
    @Binding var selectedPeriod: BenefitPeriod

    // MARK: - Body

    var body: some View {
        VStack(spacing: 0) {
            PeriodCarouselView(selectedPeriod: $selectedPeriod) { period in
                cardPeriodContent(for: period)
            }
            .frame(height: 200)
        }
        .background(
            RoundedRectangle(cornerRadius: DesignSystem.Sizing.cardCornerRadius)
                .fill(DesignSystem.Colors.backgroundSecondary)
        )
    }

    // MARK: - Content

    @ViewBuilder
    private func cardPeriodContent(for period: BenefitPeriod) -> some View {
        let periodBenefits = benefits.filter {
            $0.frequency == period.correspondingFrequency
        }

        if periodBenefits.isEmpty {
            emptyState(for: period)
        } else {
            categoryRingsView(benefits: periodBenefits)
        }
    }

    private func categoryRingsView(benefits: [PreviewBenefit]) -> some View {
        let categoryProgress = calculateCategoryProgress(benefits: benefits)

        return VStack(spacing: DesignSystem.Spacing.md) {
            HStack(spacing: DesignSystem.Spacing.xl) {
                ForEach(categoryProgress.prefix(3), id: \.category) { item in
                    CategoryRing(
                        category: item.category,
                        usedCount: item.usedCount,
                        totalCount: item.totalCount
                    )
                }
            }

            progressSummary(benefits: benefits)
        }
        .padding(.horizontal, DesignSystem.Spacing.lg)
    }

    private func emptyState(for period: BenefitPeriod) -> some View {
        VStack(spacing: DesignSystem.Spacing.sm) {
            Image(systemName: "circle.dashed")
                .font(.system(size: 40))
                .foregroundStyle(DesignSystem.Colors.textTertiary)

            Text("No \(period.displayName.lowercased()) benefits")
                .font(DesignSystem.Typography.footnote)
                .foregroundStyle(DesignSystem.Colors.textSecondary)

            Text("This card doesn't have benefits that reset \(period.displayName.lowercased()).")
                .font(DesignSystem.Typography.caption)
                .foregroundStyle(DesignSystem.Colors.textTertiary)
                .multilineTextAlignment(.center)
        }
        .padding()
    }

    private func progressSummary(benefits: [PreviewBenefit]) -> some View {
        let used = benefits.filter { $0.status == .used }
        let usedValue = used.reduce(Decimal.zero) { $0 + $1.value }
        let totalValue = benefits.reduce(Decimal.zero) { $0 + $1.value }
        let percentage: Int
        if totalValue > 0 {
            percentage = NSDecimalNumber(decimal: usedValue / totalValue * 100).intValue
        } else {
            percentage = 0
        }

        return Text("\(percentage)% complete · \(CurrencyFormatter.shared.format(usedValue)) of \(CurrencyFormatter.shared.format(totalValue))")
            .font(DesignSystem.Typography.caption)
            .foregroundStyle(DesignSystem.Colors.textSecondary)
    }

    // MARK: - Helpers

    private struct CategoryProgress {
        let category: BenefitCategory
        let usedCount: Int
        let totalCount: Int
    }

    private func calculateCategoryProgress(benefits: [PreviewBenefit]) -> [CategoryProgress] {
        let grouped = Dictionary(grouping: benefits) { $0.category }

        return grouped.map { category, categoryBenefits in
            let used = categoryBenefits.filter { $0.status == .used }.count
            return CategoryProgress(
                category: category,
                usedCount: used,
                totalCount: categoryBenefits.count
            )
        }.sorted { $0.totalCount > $1.totalCount }
    }
}

// MARK: - Preview

#Preview("Period Carousel") {
    struct PreviewWrapper: View {
        @State private var period: BenefitPeriod = .monthly

        var body: some View {
            PeriodCarouselView(selectedPeriod: $period) { p in
                VStack {
                    Text(p.periodLabel())
                        .font(.title)
                    Text("Content for \(p.displayName)")
                }
                .frame(maxWidth: .infinity)
                .frame(height: 200)
                .background(Color.gray.opacity(0.1))
            }
            .frame(height: 280)
        }
    }

    return PreviewWrapper()
}

#Preview("Dashboard Period Section") {
    struct PreviewWrapper: View {
        @State private var period: BenefitPeriod = .monthly

        var body: some View {
            DashboardPeriodSection(
                benefits: [],
                selectedPeriod: $period
            )
        }
    }

    return PreviewWrapper()
        .padding()
}
