//
//  ExpiringBenefitsListView.swift
//  CouponTracker
//
//  Created: January 18, 2026
//
//  Purpose: Full-screen list view showing all expiring benefits grouped by time period.
//           Provides swipe-to-mark-done functionality and navigation to card detail.
//
//  ACCESSIBILITY:
//  - VoiceOver section announcements
//  - Swipe action descriptions
//  - All interactive elements have 44pt touch targets
//
//  USAGE:
//  ExpiringBenefitsListView(
//      viewModel: homeViewModel,
//      container: appContainer,
//      onSelectCard: { cardId in ... }
//  )

import SwiftUI
import os

// MARK: - Expiring Benefits List View

/// Full-screen view showing all expiring benefits grouped by time period
struct ExpiringBenefitsListView: View {

    // MARK: - Properties

    let viewModel: HomeViewModel
    let container: AppContainer
    var onSelectCard: ((UUID) -> Void)?

    @Environment(\.dismiss) private var dismiss

    // MARK: - Computed Properties

    /// Benefits grouped by urgency level (uses ViewModel's grouping)
    private var benefitsByUrgency: [ExpirationUrgency: [ExpiringBenefitDisplayAdapter]] {
        viewModel.displayBenefitsByUrgency
    }

    /// Get benefits for a specific urgency level
    private func benefits(for urgency: ExpirationUrgency) -> [ExpiringBenefitDisplayAdapter] {
        benefitsByUrgency[urgency] ?? []
    }

    /// Total value of all expiring benefits
    private var totalExpiringValue: Decimal {
        viewModel.displayExpiringBenefits.reduce(Decimal.zero) { $0 + $1.benefit.value }
    }

    /// Whether there are any expiring benefits
    private var isEmpty: Bool {
        viewModel.displayExpiringBenefits.isEmpty
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            Group {
                if isEmpty {
                    emptyState
                } else {
                    benefitsList
                }
            }
            .background(DesignSystem.Colors.backgroundPrimary)
            .navigationTitle("Expiring Benefits")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
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

            // Dynamic sections based on ExpirationUrgency enum
            ForEach(ExpirationUrgency.expiringLevels, id: \.self) { urgency in
                let sectionBenefits = benefits(for: urgency)
                if !sectionBenefits.isEmpty {
                    benefitSection(
                        title: urgency.displayTitle,
                        subtitle: urgency.subtitle,
                        benefits: sectionBenefits,
                        urgencyColor: urgency.color
                    )
                }
            }
        }
        .listStyle(.insetGrouped)
    }

    // MARK: - Summary Header

    @ViewBuilder
    private var summaryHeader: some View {
        VStack(spacing: DesignSystem.Spacing.sm) {
            HStack(spacing: DesignSystem.Spacing.sm) {
                Image(systemName: "clock.badge.exclamationmark.fill")
                    .font(.system(size: 24))
                    .foregroundStyle(DesignSystem.Colors.warning)

                VStack(alignment: .leading, spacing: 2) {
                    Text("\(viewModel.displayExpiringBenefits.count) Benefits Expiring")
                        .font(DesignSystem.Typography.headline)
                        .foregroundStyle(DesignSystem.Colors.textPrimary)

                    Text("Total value: \(Formatters.formatCurrencyWhole(totalExpiringValue))")
                        .font(DesignSystem.Typography.subhead)
                        .foregroundStyle(DesignSystem.Colors.textSecondary)
                }

                Spacer()
            }
            .padding(DesignSystem.Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: DesignSystem.Sizing.buttonCornerRadius)
                    .fill(DesignSystem.Colors.warning.opacity(0.1))
            )
        }
        .padding(.horizontal, DesignSystem.Spacing.lg)
        .padding(.vertical, DesignSystem.Spacing.md)
    }

    // MARK: - Benefit Section

    @ViewBuilder
    private func benefitSection(title: String, subtitle: String, benefits: [ExpiringBenefitDisplayAdapter], urgencyColor: Color) -> some View {
        Section {
            ForEach(benefits, id: \.id) { item in
                benefitRow(for: item, urgencyColor: urgencyColor)
            }
        } header: {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(DesignSystem.Typography.headline)
                        .foregroundStyle(DesignSystem.Colors.textPrimary)

                    Text(subtitle)
                        .font(DesignSystem.Typography.caption)
                        .foregroundStyle(DesignSystem.Colors.textTertiary)
                }

                Spacer()

                // Section value badge
                Text(Formatters.formatCurrencyWhole(benefits.reduce(Decimal.zero) { $0 + $1.benefit.value }))
                    .font(DesignSystem.Typography.subhead)
                    .foregroundStyle(urgencyColor)
            }
            .textCase(nil)
            .padding(.vertical, DesignSystem.Spacing.xs)
        }
    }

    // MARK: - Benefit Row

    @ViewBuilder
    private func benefitRow(for item: ExpiringBenefitDisplayAdapter, urgencyColor: Color) -> some View {
        Button(action: {
            onSelectCard?(item.card.id)
        }) {
            HStack(spacing: DesignSystem.Spacing.md) {
                // Category indicator
                Circle()
                    .fill(DesignSystem.Colors.categoryColor(for: item.benefit.category))
                    .frame(width: 10, height: 10)

                // Benefit info
                VStack(alignment: .leading, spacing: 2) {
                    Text(item.benefit.name)
                        .font(DesignSystem.Typography.subhead)
                        .foregroundStyle(DesignSystem.Colors.textPrimary)

                    Text(item.card.displayName)
                        .font(DesignSystem.Typography.caption)
                        .foregroundStyle(DesignSystem.Colors.textSecondary)
                }

                Spacer()

                // Value and urgency
                VStack(alignment: .trailing, spacing: 2) {
                    Text(item.benefit.formattedValue)
                        .font(DesignSystem.Typography.valueSmall)
                        .foregroundStyle(DesignSystem.Colors.textPrimary)

                    Text(item.benefit.urgencyText)
                        .font(DesignSystem.Typography.caption)
                        .foregroundStyle(urgencyColor)
                }

                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(DesignSystem.Colors.textTertiary)
            }
            .padding(.vertical, DesignSystem.Spacing.xs)
        }
        .buttonStyle(.plain)
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            Button(action: {
                markBenefitAsDone(item.benefit)
            }) {
                Label("Done", systemImage: "checkmark.circle.fill")
            }
            .tint(DesignSystem.Colors.success)
        }
        .accessibilityLabel("\(item.benefit.formattedValue) \(item.benefit.name) from \(item.card.displayName), \(item.benefit.urgencyText)")
        .accessibilityHint("Double tap to view card. Swipe left to mark as done.")
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

                Text("No benefits are expiring soon.\nGreat job staying on top of your rewards!")
                    .font(DesignSystem.Typography.body)
                    .foregroundStyle(DesignSystem.Colors.textSecondary)
                    .multilineTextAlignment(.center)
            }

            Spacer()
        }
        .padding(DesignSystem.Spacing.xl)
    }

    // MARK: - Actions

    private func markBenefitAsDone(_ benefit: any BenefitDisplayable) {
        Task {
            do {
                let allBenefits = try container.benefitRepository.getAllBenefits()
                if let matchingBenefit = allBenefits.first(where: { $0.id == benefit.id }) {
                    try container.benefitRepository.markBenefitUsed(matchingBenefit)
                    await viewModel.loadData()
                }
            } catch {
                AppLogger.benefits.error("Failed to mark benefit as done: \(error.localizedDescription)")
            }
        }
    }
}

// MARK: - Previews

#Preview("Expiring Benefits List - Full") {
    ExpiringBenefitsListView(
        viewModel: HomeViewModel.preview,
        container: AppContainer.preview,
        onSelectCard: { cardId in
            print("Selected card: \(cardId)")
        }
    )
}

#Preview("Expiring Benefits List - Dark Mode") {
    ExpiringBenefitsListView(
        viewModel: HomeViewModel.preview,
        container: AppContainer.preview,
        onSelectCard: { cardId in
            print("Selected card: \(cardId)")
        }
    )
    .preferredColorScheme(.dark)
}
