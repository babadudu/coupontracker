// CardROICard.swift
// CouponTracker
//
// Created: January 2026
// Purpose: ROI visualization card showing annual fee analysis and retention recommendation.
//
// ACCESSIBILITY:
// - Clear accessibility labels for VoiceOver
// - Status colors have text alternatives
//
// DESIGN:
// - Shows annual fee, benefits redeemed, ROI percentage
// - Retention recommendation with color-coded status
// - Optional subscription costs section

import SwiftUI

// MARK: - Card ROI Card View

/// ROI visualization card for CardDetailView
struct CardROICard: View {

    // MARK: - Properties

    let annualFee: Decimal
    let annualFeeDate: Date?
    let benefitsRedeemed: Decimal
    let subscriptionCosts: Decimal
    let recommendation: CardRetentionRecommendation

    // MARK: - Computed Properties

    private var netValue: Decimal {
        benefitsRedeemed - annualFee
    }

    private var roiPercentage: Decimal {
        guard annualFee > 0 else {
            return benefitsRedeemed > 0 ? 100 : 0
        }
        return (netValue / annualFee) * 100
    }

    private var formattedFee: String {
        Formatters.formatCurrency(annualFee)
    }

    private var formattedBenefits: String {
        Formatters.formatCurrency(benefitsRedeemed)
    }

    private var formattedNetValue: String {
        let prefix = netValue >= 0 ? "+" : ""
        return prefix + Formatters.formatCurrency(netValue)
    }

    private var formattedROI: String {
        let roiInt = NSDecimalNumber(decimal: roiPercentage).intValue
        return "\(roiInt)%"
    }

    private var formattedSubscriptionCosts: String {
        Formatters.formatCurrency(subscriptionCosts)
    }

    private var feeDateText: String? {
        guard let date = annualFeeDate else { return nil }
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }

    private var daysUntilFee: Int? {
        guard let date = annualFeeDate else { return nil }
        let calendar = Calendar.current
        let components = calendar.dateComponents(
            [.day],
            from: calendar.startOfDay(for: Date()),
            to: calendar.startOfDay(for: date)
        )
        return components.day
    }

    private var recommendationColor: Color {
        switch recommendation {
        case .strongKeep:
            return DesignSystem.Colors.success
        case .marginalKeep:
            return DesignSystem.Colors.success.opacity(0.7)
        case .evaluate:
            return DesignSystem.Colors.warning
        case .considerCancelling:
            return DesignSystem.Colors.danger
        }
    }

    private var netValueColor: Color {
        netValue >= 0 ? DesignSystem.Colors.success : DesignSystem.Colors.danger
    }

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
            // Header
            HStack {
                Label("Annual Fee ROI", systemImage: "chart.pie.fill")
                    .font(DesignSystem.Typography.headline)
                    .foregroundStyle(DesignSystem.Colors.textPrimary)

                Spacer()

                // ROI Badge
                Text(formattedROI)
                    .font(DesignSystem.Typography.headline)
                    .foregroundStyle(netValue >= 0 ? DesignSystem.Colors.success : DesignSystem.Colors.danger)
                    .padding(.horizontal, DesignSystem.Spacing.sm)
                    .padding(.vertical, DesignSystem.Spacing.xs)
                    .background(
                        Capsule()
                            .fill(netValueColor.opacity(0.15))
                    )
            }

            Divider()

            // Fee Details
            VStack(spacing: DesignSystem.Spacing.sm) {
                // Annual Fee Row
                HStack {
                    Text("Annual Fee")
                        .font(DesignSystem.Typography.subhead)
                        .foregroundStyle(DesignSystem.Colors.textSecondary)

                    Spacer()

                    VStack(alignment: .trailing, spacing: 2) {
                        Text(formattedFee)
                            .font(DesignSystem.Typography.headline)
                            .foregroundStyle(DesignSystem.Colors.textPrimary)

                        if let dateText = feeDateText {
                            Text("Due \(dateText)")
                                .font(DesignSystem.Typography.caption)
                                .foregroundStyle(DesignSystem.Colors.textTertiary)
                        }
                    }
                }

                // Benefits Redeemed Row
                HStack {
                    Text("Benefits Redeemed")
                        .font(DesignSystem.Typography.subhead)
                        .foregroundStyle(DesignSystem.Colors.textSecondary)

                    Spacer()

                    Text(formattedBenefits)
                        .font(DesignSystem.Typography.headline)
                        .foregroundStyle(DesignSystem.Colors.success)
                }

                // Net Value Row
                HStack {
                    Text("Net Value")
                        .font(DesignSystem.Typography.subhead)
                        .foregroundStyle(DesignSystem.Colors.textSecondary)

                    Spacer()

                    Text(formattedNetValue)
                        .font(DesignSystem.Typography.headline)
                        .foregroundStyle(netValueColor)
                }

                // Subscription Costs Row (if any)
                if subscriptionCosts > 0 {
                    HStack {
                        Text("Linked Subscriptions")
                            .font(DesignSystem.Typography.subhead)
                            .foregroundStyle(DesignSystem.Colors.textSecondary)

                        Spacer()

                        Text("\(formattedSubscriptionCosts)/yr")
                            .font(DesignSystem.Typography.subhead)
                            .foregroundStyle(DesignSystem.Colors.textTertiary)
                    }
                }
            }

            Divider()

            // Retention Recommendation
            HStack(spacing: DesignSystem.Spacing.sm) {
                Image(systemName: recommendation.iconName)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(recommendationColor)

                VStack(alignment: .leading, spacing: 2) {
                    Text(recommendation.displayTitle)
                        .font(DesignSystem.Typography.headline)
                        .foregroundStyle(DesignSystem.Colors.textPrimary)

                    Text(recommendation.reason)
                        .font(DesignSystem.Typography.caption)
                        .foregroundStyle(DesignSystem.Colors.textSecondary)
                        .lineLimit(2)
                }

                Spacer()
            }
            .padding(.vertical, DesignSystem.Spacing.xs)
        }
        .padding(DesignSystem.Spacing.lg)
        .background(DesignSystem.Colors.backgroundSecondary)
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Sizing.cardCornerRadius))
    }
}

// MARK: - CardRetentionRecommendation Extension

extension CardRetentionRecommendation {
    var reason: String {
        switch self {
        case .strongKeep(let reason):
            return reason
        case .marginalKeep(let reason):
            return reason
        case .evaluate(let reason):
            return reason
        case .considerCancelling(let reason):
            return reason
        }
    }
}

// MARK: - Preview

#Preview("ROI Card - Strong Keep") {
    ScrollView {
        VStack(spacing: DesignSystem.Spacing.lg) {
            CardROICard(
                annualFee: 695,
                annualFeeDate: Calendar.current.date(byAdding: .month, value: 3, to: Date()),
                benefitsRedeemed: 1250,
                subscriptionCosts: 240,
                recommendation: .strongKeep(reason: "Getting $1,250 in value vs $695 fee")
            )

            CardROICard(
                annualFee: 550,
                annualFeeDate: Calendar.current.date(byAdding: .month, value: 6, to: Date()),
                benefitsRedeemed: 600,
                subscriptionCosts: 0,
                recommendation: .marginalKeep(reason: "Earning $50 above the annual fee")
            )
        }
        .padding()
    }
    .background(DesignSystem.Colors.backgroundPrimary)
}

#Preview("ROI Card - Evaluate") {
    ScrollView {
        VStack(spacing: DesignSystem.Spacing.lg) {
            CardROICard(
                annualFee: 450,
                annualFeeDate: Calendar.current.date(byAdding: .month, value: 2, to: Date()),
                benefitsRedeemed: 400,
                subscriptionCosts: 120,
                recommendation: .evaluate(reason: "Currently $50 short of breaking even on the fee")
            )

            CardROICard(
                annualFee: 250,
                annualFeeDate: nil,
                benefitsRedeemed: 100,
                subscriptionCosts: 0,
                recommendation: .considerCancelling(reason: "Losing $150 after accounting for the annual fee")
            )
        }
        .padding()
    }
    .background(DesignSystem.Colors.backgroundPrimary)
}

#Preview("ROI Card - No Fee") {
    CardROICard(
        annualFee: 0,
        annualFeeDate: nil,
        benefitsRedeemed: 250,
        subscriptionCosts: 60,
        recommendation: .strongKeep(reason: "No annual fee - keep for available benefits")
    )
    .padding()
    .background(DesignSystem.Colors.backgroundPrimary)
}

#Preview("ROI Card - Dark Mode") {
    CardROICard(
        annualFee: 695,
        annualFeeDate: Calendar.current.date(byAdding: .month, value: 3, to: Date()),
        benefitsRedeemed: 1250,
        subscriptionCosts: 240,
        recommendation: .strongKeep(reason: "Getting $1,250 in value vs $695 fee")
    )
    .padding()
    .background(DesignSystem.Colors.backgroundPrimary)
    .preferredColorScheme(.dark)
}
