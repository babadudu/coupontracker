//
//  BenefitsByUrgencySection.swift
//  CouponTracker
//
//  Created: January 2026
//
//  Purpose: Section component showing benefits grouped by urgency level.
//           Used in PeriodBenefitsView for drill-down from ValueBreakdownView.
//           Benefits show inline card info since grouping is by time, not card.
//

import SwiftUI

// MARK: - Benefits By Urgency Section

/// Displays benefits grouped by urgency level with inline card display.
/// Used for period drill-down where benefits are grouped by time.
struct BenefitsByUrgencySection: View {

    // MARK: - Properties

    let urgency: ExpirationUrgency
    let items: [ExpiringBenefitDisplayAdapter]
    var onSelectCard: ((UUID) -> Void)?
    var onMarkAsDone: ((ExpiringBenefitDisplayAdapter) -> Void)?

    // MARK: - Body

    var body: some View {
        Section {
            ForEach(items, id: \.id) { item in
                benefitRow(for: item)
            }
        } header: {
            urgencyHeader
        }
    }

    // MARK: - Urgency Header

    @ViewBuilder
    private var urgencyHeader: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(urgency.displayTitle)
                    .font(DesignSystem.Typography.headline)
                    .foregroundStyle(DesignSystem.Colors.textPrimary)

                Text(urgency.subtitle)
                    .font(DesignSystem.Typography.caption)
                    .foregroundStyle(DesignSystem.Colors.textTertiary)
            }

            Spacer()

            // Section value badge
            Text(sectionValue)
                .font(DesignSystem.Typography.subhead)
                .foregroundStyle(urgency.color)
        }
        .textCase(nil)
        .padding(.vertical, DesignSystem.Spacing.xs)
    }

    private var sectionValue: String {
        let total = items.reduce(Decimal.zero) { $0 + $1.benefit.value }
        return Formatters.formatCurrencyWhole(total)
    }

    // MARK: - Benefit Row

    @ViewBuilder
    private func benefitRow(for item: ExpiringBenefitDisplayAdapter) -> some View {
        Button(action: { onSelectCard?(item.card.id) }) {
            HStack(spacing: DesignSystem.Spacing.md) {
                // Status icon
                statusIcon(for: item.benefit)

                // Benefit info with inline card display
                VStack(alignment: .leading, spacing: 4) {
                    // Benefit name
                    Text(item.benefit.name)
                        .font(DesignSystem.Typography.subhead)
                        .foregroundStyle(DesignSystem.Colors.textPrimary)

                    // Card info (inline)
                    HStack(spacing: DesignSystem.Spacing.xs) {
                        RoundedRectangle(cornerRadius: 2)
                            .fill(item.card.gradient.gradient)
                            .frame(width: 16, height: 10)

                        Text(item.card.displayName)
                            .font(DesignSystem.Typography.caption)
                            .foregroundStyle(DesignSystem.Colors.textSecondary)
                    }
                }

                Spacer()

                // Value and urgency text
                VStack(alignment: .trailing, spacing: 2) {
                    Text(item.benefit.formattedValue)
                        .font(DesignSystem.Typography.valueSmall)
                        .foregroundStyle(DesignSystem.Colors.textPrimary)

                    Text(urgencyLabel(for: item.benefit))
                        .font(DesignSystem.Typography.caption)
                        .foregroundStyle(urgency.color)
                }

                // Chevron
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(DesignSystem.Colors.textTertiary)
            }
            .padding(.vertical, DesignSystem.Spacing.xs)
        }
        .buttonStyle(.plain)
        .background(
            DesignSystem.Colors.urgencyBackgroundColor(daysRemaining: item.benefit.daysRemaining)
        )
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            if item.benefit.status == .available {
                Button(action: { onMarkAsDone?(item) }) {
                    Label("Done", systemImage: "checkmark.circle.fill")
                }
                .tint(DesignSystem.Colors.success)
            }
        }
        .accessibilityLabel(accessibilityLabel(for: item))
        .accessibilityHint("Double tap to view card. Swipe left to mark as done.")
    }

    private func statusIcon(for benefit: BenefitDisplayAdapter) -> some View {
        let iconName: String
        let color: Color

        switch benefit.daysRemaining {
        case ..<0:
            iconName = "xmark.circle"
            color = DesignSystem.Colors.neutral
        case 0:
            iconName = "exclamationmark.circle.fill"
            color = DesignSystem.Colors.danger
        case 1:
            iconName = "exclamationmark.circle.fill"
            color = DesignSystem.Colors.danger.opacity(0.8)
        case 2...3:
            iconName = "exclamationmark.triangle.fill"
            color = DesignSystem.Colors.warning
        case 4...7:
            iconName = "clock"
            color = DesignSystem.Colors.warning.opacity(0.7)
        default:
            iconName = "circle"
            color = DesignSystem.Colors.neutral
        }

        return Image(systemName: iconName)
            .font(.system(size: 16, weight: .medium))
            .foregroundStyle(color)
            .frame(width: 20, height: 20)
    }

    private func urgencyLabel(for benefit: BenefitDisplayAdapter) -> String {
        switch benefit.daysRemaining {
        case ..<0: return "Expired"
        case 0: return "Expires at midnight"
        case 1: return "Last day tomorrow"
        default: return benefit.urgencyText
        }
    }

    private func accessibilityLabel(for item: ExpiringBenefitDisplayAdapter) -> String {
        "\(item.benefit.formattedValue) \(item.benefit.name) from \(item.card.displayName), \(item.benefit.urgencyText)"
    }
}

// MARK: - Previews

#if DEBUG
@MainActor
private struct BenefitsByUrgencySectionPreview: View {
    var body: some View {
        let viewModel = HomeViewModel.preview
        let items = viewModel.displayExpiringBenefits.filter { adapter in
            ExpirationUrgency.from(daysRemaining: adapter.benefit.daysRemaining) == .expiringToday
        }

        List {
            BenefitsByUrgencySection(
                urgency: .expiringToday,
                items: items,
                onSelectCard: { print("Selected card: \($0)") },
                onMarkAsDone: { print("Mark done: \($0.benefit.name)") }
            )
        }
        .listStyle(.insetGrouped)
    }
}

#Preview("Benefits By Urgency Section") {
    BenefitsByUrgencySectionPreview()
}
#endif
