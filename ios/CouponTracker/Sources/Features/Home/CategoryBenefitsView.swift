//
//  CategoryBenefitsView.swift
//  CouponTracker
//
//  Created: January 2026
//
//  Purpose: Drill-down view showing all benefits in a specific category.
//           Accessed by tapping category rows in ValueBreakdownView.
//           Benefits are grouped by card with swipe-to-mark-done support.
//
//  ACCESSIBILITY:
//  - VoiceOver support with descriptive labels
//  - Proper section headers
//  - Swipe action descriptions
//
//  USAGE:
//  NavigationLink {
//      CategoryBenefitsView(category: .travel, viewModel: viewModel, container: container)
//  }

import SwiftUI

// MARK: - Category Benefits View

/// Full-screen view showing all benefits in a specific category, grouped by card.
struct CategoryBenefitsView: View {

    // MARK: - Properties

    let category: BenefitCategory
    let viewModel: HomeViewModel
    let container: AppContainer
    var onSelectCard: ((UUID) -> Void)?

    @Environment(\.dismiss) private var dismiss

    // MARK: - State

    @State private var showUsedSection = false

    // MARK: - Computed Properties

    /// Benefits grouped by card (available only)
    private var benefitsByCard: [(card: CardDisplayAdapter, benefits: [BenefitDisplayAdapter])] {
        viewModel.benefitsForCategory(category)
    }

    /// Used benefits grouped by card
    private var usedBenefitsByCard: [(card: CardDisplayAdapter, benefits: [BenefitDisplayAdapter])] {
        viewModel.usedBenefitsForCategory(category)
    }

    /// Total available value in this category
    private var totalAvailableValue: Decimal {
        viewModel.totalValueForCategory(category)
    }

    /// Total used value in this category
    private var totalUsedValue: Decimal {
        usedBenefitsByCard.flatMap { $0.benefits }.reduce(Decimal.zero) { $0 + $1.value }
    }

    /// Count of available benefits
    private var availableCount: Int {
        viewModel.benefitCountForCategory(category)
    }

    /// Count of cards with benefits in this category
    private var cardCount: Int {
        benefitsByCard.count
    }

    /// Count of used benefits
    private var usedCount: Int {
        usedBenefitsByCard.flatMap { $0.benefits }.count
    }

    /// Whether the category is empty (no available benefits)
    private var isEmpty: Bool {
        benefitsByCard.isEmpty
    }

    // MARK: - Body

    var body: some View {
        Group {
            if isEmpty && usedBenefitsByCard.isEmpty {
                emptyState
            } else {
                benefitsList
            }
        }
        .background(DesignSystem.Colors.backgroundPrimary)
        .navigationTitle(category.displayName)
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

            // Available benefits grouped by card
            if isEmpty {
                // All done state
                Section {
                    allDoneState
                }
                .listRowBackground(Color.clear)
            } else {
                ForEach(benefitsByCard, id: \.card.id) { item in
                    BenefitsByCardSection(
                        card: item.card,
                        benefits: item.benefits,
                        onSelectCard: {
                            onSelectCard?(item.card.id)
                        },
                        onMarkAsDone: { benefit in
                            markBenefitAsDone(benefit)
                        },
                        onTapBenefit: { _ in
                            onSelectCard?(item.card.id)
                        }
                    )
                }
            }

            // Used benefits section (collapsed by default)
            if !usedBenefitsByCard.isEmpty {
                usedBenefitsSection
            }
        }
        .listStyle(.insetGrouped)
    }

    // MARK: - Summary Header

    @ViewBuilder
    private var summaryHeader: some View {
        VStack(spacing: DesignSystem.Spacing.sm) {
            HStack(spacing: DesignSystem.Spacing.sm) {
                // Category icon
                Circle()
                    .fill(DesignSystem.Colors.categoryColor(for: category))
                    .frame(width: 40, height: 40)
                    .overlay {
                        Image(systemName: category.iconName)
                            .font(.system(size: 20, weight: .medium))
                            .foregroundStyle(DesignSystem.Colors.onColor)
                    }

                VStack(alignment: .leading, spacing: 2) {
                    Text("\(availableCount) \(availableCount == 1 ? "Benefit" : "Benefits") across \(cardCount) \(cardCount == 1 ? "Card" : "Cards")")
                        .font(DesignSystem.Typography.headline)
                        .foregroundStyle(DesignSystem.Colors.textPrimary)

                    HStack(spacing: DesignSystem.Spacing.md) {
                        Text("\(Formatters.formatCurrencyWhole(totalAvailableValue)) available")
                            .font(DesignSystem.Typography.subhead)
                            .foregroundStyle(DesignSystem.Colors.primaryFallback)

                        if totalUsedValue > 0 {
                            Text("• \(Formatters.formatCurrencyWhole(totalUsedValue)) used")
                                .font(DesignSystem.Typography.subhead)
                                .foregroundStyle(DesignSystem.Colors.success)
                        }
                    }
                }

                Spacer()
            }
            .padding(DesignSystem.Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: DesignSystem.Sizing.buttonCornerRadius)
                    .fill(DesignSystem.Colors.categoryColor(for: category).opacity(0.1))
            )
        }
        .padding(.horizontal, DesignSystem.Spacing.lg)
        .padding(.vertical, DesignSystem.Spacing.md)
    }

    // MARK: - All Done State

    @ViewBuilder
    private var allDoneState: some View {
        VStack(spacing: DesignSystem.Spacing.md) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 48))
                .foregroundStyle(DesignSystem.Colors.success)

            Text("All \(category.displayName) benefits used!")
                .font(DesignSystem.Typography.headline)
                .foregroundStyle(DesignSystem.Colors.textPrimary)
                .multilineTextAlignment(.center)

            Text("Great job maximizing your rewards in this category.")
                .font(DesignSystem.Typography.subhead)
                .foregroundStyle(DesignSystem.Colors.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, DesignSystem.Spacing.xl)
    }

    // MARK: - Used Benefits Section

    @ViewBuilder
    private var usedBenefitsSection: some View {
        Section {
            if showUsedSection {
                ForEach(usedBenefitsByCard, id: \.card.id) { item in
                    usedCardSection(card: item.card, benefits: item.benefits)
                }
            }
        } header: {
            Button(action: { withAnimation { showUsedSection.toggle() } }) {
                HStack {
                    Text("Used This Period (\(usedCount))")
                        .font(DesignSystem.Typography.headline)
                        .foregroundStyle(DesignSystem.Colors.textSecondary)

                    Spacer()

                    Image(systemName: showUsedSection ? "chevron.up" : "chevron.down")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(DesignSystem.Colors.textTertiary)
                }
                .textCase(nil)
                .padding(.vertical, DesignSystem.Spacing.xs)
            }
            .buttonStyle(.plain)
        }
    }

    @ViewBuilder
    private func usedCardSection(card: CardDisplayAdapter, benefits: [BenefitDisplayAdapter]) -> some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
            // Card header
            HStack(spacing: DesignSystem.Spacing.sm) {
                RoundedRectangle(cornerRadius: 3)
                    .fill(card.gradient.gradient)
                    .frame(width: 24, height: 16)

                Text(card.displayName)
                    .font(DesignSystem.Typography.subhead)
                    .foregroundStyle(DesignSystem.Colors.textSecondary)
            }

            // Benefits
            ForEach(benefits, id: \.id) { benefit in
                HStack {
                    Image(systemName: "checkmark.seal.fill")
                        .font(.system(size: 14))
                        .foregroundStyle(DesignSystem.Colors.success)

                    Text(benefit.name)
                        .font(DesignSystem.Typography.subhead)
                        .foregroundStyle(DesignSystem.Colors.textSecondary)
                        .strikethrough()

                    Spacer()

                    Text(benefit.formattedValue)
                        .font(DesignSystem.Typography.caption)
                        .foregroundStyle(DesignSystem.Colors.success)
                }
            }
        }
        .padding(.vertical, DesignSystem.Spacing.xs)
    }

    // MARK: - Empty State

    @ViewBuilder
    private var emptyState: some View {
        VStack(spacing: DesignSystem.Spacing.lg) {
            Spacer()

            Circle()
                .fill(DesignSystem.Colors.categoryColor(for: category).opacity(0.2))
                .frame(width: 100, height: 100)
                .overlay {
                    Image(systemName: category.iconName)
                        .font(.system(size: 40))
                        .foregroundStyle(DesignSystem.Colors.categoryColor(for: category))
                }

            VStack(spacing: DesignSystem.Spacing.sm) {
                Text("No \(category.displayName) Benefits")
                    .font(DesignSystem.Typography.title2)
                    .foregroundStyle(DesignSystem.Colors.textPrimary)

                Text("Add a card with \(category.displayName.lowercased()) benefits to see them here.")
                    .font(DesignSystem.Typography.body)
                    .foregroundStyle(DesignSystem.Colors.textSecondary)
                    .multilineTextAlignment(.center)
            }

            Spacer()
        }
        .padding(DesignSystem.Spacing.xl)
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

#Preview("Category Benefits - Travel") {
    NavigationStack {
        CategoryBenefitsView(
            category: .travel,
            viewModel: HomeViewModel.preview,
            container: AppContainer.preview,
            onSelectCard: { print("Selected card: \($0)") }
        )
    }
}

#Preview("Category Benefits - Empty") {
    NavigationStack {
        CategoryBenefitsView(
            category: .business,
            viewModel: HomeViewModel.preview,
            container: AppContainer.preview,
            onSelectCard: { print("Selected card: \($0)") }
        )
    }
}
