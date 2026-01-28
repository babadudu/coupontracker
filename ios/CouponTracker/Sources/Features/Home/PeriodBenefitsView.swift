//
//  PeriodBenefitsView.swift
//  CouponTracker
//
//  Created: January 2026
//
//  Purpose: Drill-down view showing all benefits within a specific time period.
//           Accessed by tapping period rows in ValueBreakdownView.
//           Benefits are grouped by urgency with inline card display.
//
//  ACCESSIBILITY:
//  - VoiceOver support with descriptive labels
//  - Proper section headers with urgency announcements
//  - Swipe action descriptions
//
//  USAGE:
//  NavigationLink {
//      PeriodBenefitsView(period: .thisWeek, viewModel: viewModel, container: container)
//  }

import SwiftUI

// MARK: - Period Benefits View

/// Full-screen view showing all benefits within a specific time period, grouped by urgency.
struct PeriodBenefitsView: View {

    // MARK: - Properties

    let period: TimePeriodFilter
    let viewModel: HomeViewModel
    let container: AppContainer
    var onSelectCard: ((UUID) -> Void)?

    @Environment(\.dismiss) private var dismiss

    // MARK: - Computed Properties

    /// Benefits grouped by urgency within this period
    private var benefitsByUrgency: [(urgency: ExpirationUrgency, items: [ExpiringBenefitDisplayAdapter])] {
        viewModel.benefitsForPeriod(period)
    }

    /// Total available value in this period
    private var totalValue: Decimal {
        viewModel.totalValueForPeriod(period)
    }

    /// Count of benefits in this period
    private var benefitCount: Int {
        viewModel.benefitCountForPeriod(period)
    }

    /// Count of cards with benefits in this period
    private var cardCount: Int {
        viewModel.cardCountForPeriod(period)
    }

    /// Whether the period has no benefits
    private var isEmpty: Bool {
        benefitsByUrgency.isEmpty
    }

    // MARK: - Body

    var body: some View {
        Group {
            if isEmpty {
                emptyState
            } else {
                benefitsList
            }
        }
        .background(DesignSystem.Colors.backgroundPrimary)
        .navigationTitle(period.displayTitle)
        .navigationBarTitleDisplayMode(.large)
    }

    // MARK: - Benefits List

    @ViewBuilder
    private var benefitsList: some View {
        List {
            // Summary header
            Section {
                summaryHeader
            }
            .listRowBackground(Color.clear)
            .listRowInsets(EdgeInsets())

            // Benefits grouped by urgency
            ForEach(benefitsByUrgency, id: \.urgency) { group in
                BenefitsByUrgencySection(
                    urgency: group.urgency,
                    items: group.items,
                    onSelectCard: { cardId in
                        onSelectCard?(cardId)
                    },
                    onMarkAsDone: { item in
                        markBenefitAsDone(item.benefit)
                    }
                )
            }
        }
        .listStyle(.insetGrouped)
    }

    // MARK: - Summary Header

    @ViewBuilder
    private var summaryHeader: some View {
        VStack(spacing: DesignSystem.Spacing.sm) {
            HStack(spacing: DesignSystem.Spacing.sm) {
                // Period icon
                Circle()
                    .fill(period.color)
                    .frame(width: 40, height: 40)
                    .overlay {
                        Image(systemName: period.iconName)
                            .font(.system(size: 20, weight: .medium))
                            .foregroundStyle(DesignSystem.Colors.onColor)
                    }

                VStack(alignment: .leading, spacing: 2) {
                    Text(period.subtitle)
                        .font(DesignSystem.Typography.headline)
                        .foregroundStyle(DesignSystem.Colors.textPrimary)

                    HStack(spacing: DesignSystem.Spacing.md) {
                        Text("\(Formatters.formatCurrencyWhole(totalValue)) available")
                            .font(DesignSystem.Typography.subhead)
                            .foregroundStyle(period.color)

                        Text("• \(benefitCount) \(benefitCount == 1 ? "benefit" : "benefits")")
                            .font(DesignSystem.Typography.subhead)
                            .foregroundStyle(DesignSystem.Colors.textSecondary)
                    }
                }

                Spacer()
            }
            .padding(DesignSystem.Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: DesignSystem.Sizing.buttonCornerRadius)
                    .fill(period.color.opacity(0.1))
            )
        }
        .padding(.horizontal, DesignSystem.Spacing.lg)
        .padding(.vertical, DesignSystem.Spacing.md)
    }

    // MARK: - Empty State

    @ViewBuilder
    private var emptyState: some View {
        VStack(spacing: DesignSystem.Spacing.lg) {
            Spacer()

            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 60))
                .foregroundStyle(DesignSystem.Colors.success)

            VStack(spacing: DesignSystem.Spacing.sm) {
                Text("All Clear!")
                    .font(DesignSystem.Typography.title2)
                    .foregroundStyle(DesignSystem.Colors.textPrimary)

                Text(emptyStateMessage)
                    .font(DesignSystem.Typography.body)
                    .foregroundStyle(DesignSystem.Colors.textSecondary)
                    .multilineTextAlignment(.center)
            }

            Spacer()
        }
        .padding(DesignSystem.Spacing.xl)
    }

    private var emptyStateMessage: String {
        switch period {
        case .thisWeek:
            return "No benefits expiring this week.\nGreat job staying on top of your rewards!"
        case .thisMonth:
            return "No benefits expiring in the next 8-30 days.\nYou're all caught up!"
        case .later:
            return "No benefits expiring later.\nAll your benefits are accounted for!"
        }
    }

    // MARK: - Actions

    private func markBenefitAsDone(_ benefit: BenefitDisplayAdapter) {
        Task {
            do {
                let allBenefits = try container.benefitRepository.getAllBenefits()
                if let matchingBenefit = allBenefits.first(where: { $0.id == benefit.id }) {
                    try container.benefitRepository.markBenefitUsed(matchingBenefit)
                    container.notificationService.cancelNotifications(for: matchingBenefit)
                    await viewModel.loadData()
                }
            } catch {
                AppLogger.benefits.error("Failed to mark benefit as done: \(error.localizedDescription)")
            }
        }
    }
}

// MARK: - Previews

#Preview("Period Benefits - This Week") {
    NavigationStack {
        PeriodBenefitsView(
            period: .thisWeek,
            viewModel: HomeViewModel.preview,
            container: AppContainer.preview,
            onSelectCard: { print("Selected card: \($0)") }
        )
    }
}

#Preview("Period Benefits - This Month") {
    NavigationStack {
        PeriodBenefitsView(
            period: .thisMonth,
            viewModel: HomeViewModel.preview,
            container: AppContainer.preview,
            onSelectCard: { print("Selected card: \($0)") }
        )
    }
}

#Preview("Period Benefits - Later") {
    NavigationStack {
        PeriodBenefitsView(
            period: .later,
            viewModel: HomeViewModel.preview,
            container: AppContainer.preview,
            onSelectCard: { print("Selected card: \($0)") }
        )
    }
}
