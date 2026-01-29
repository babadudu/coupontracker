// SubscriptionWidgetView.swift
// CouponTracker
//
// Created: January 2026
// Purpose: Dashboard widget showing subscription cost summary and renewing soon count.
//
// ACCESSIBILITY:
// - Clear accessibility labels for VoiceOver
// - Touch target meets minimum 44pt requirement
//
// DESIGN:
// - Compact card showing key subscription metrics
// - Quick navigation to Tracker tab

import SwiftUI

// MARK: - Subscription Widget View

/// Dashboard widget showing subscription summary
struct SubscriptionWidgetView: View {

    // MARK: - Properties

    let monthlyCost: Decimal
    let renewingSoonCount: Int
    let onTap: (() -> Void)?

    // MARK: - Computed Properties

    private var formattedMonthlyCost: String {
        Formatters.formatCurrencyWhole(monthlyCost)
    }

    private var accessibilityLabel: String {
        var label = "Subscriptions. Monthly cost \(formattedMonthlyCost)."
        if renewingSoonCount > 0 {
            label += " \(renewingSoonCount) renewing soon."
        }
        return label
    }

    // MARK: - Body

    var body: some View {
        Button(action: { onTap?() }) {
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
                // Header
                HStack {
                    Image(systemName: "repeat.circle.fill")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(DesignSystem.Colors.primaryFallback)

                    Text("Subscriptions")
                        .font(DesignSystem.Typography.subhead)
                        .foregroundStyle(DesignSystem.Colors.textSecondary)

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(DesignSystem.Colors.textTertiary)
                }

                // Monthly Cost
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                    Text(formattedMonthlyCost)
                        .font(DesignSystem.Typography.title2)
                        .foregroundStyle(DesignSystem.Colors.textPrimary)

                    Text("/month")
                        .font(DesignSystem.Typography.caption)
                        .foregroundStyle(DesignSystem.Colors.textTertiary)
                }

                // Renewing Soon Badge (if any)
                if renewingSoonCount > 0 {
                    HStack(spacing: DesignSystem.Spacing.xs) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 12))
                            .foregroundStyle(DesignSystem.Colors.warning)

                        Text("\(renewingSoonCount) renewing soon")
                            .font(DesignSystem.Typography.caption)
                            .foregroundStyle(DesignSystem.Colors.warning)
                    }
                    .padding(.top, DesignSystem.Spacing.xs)
                }
            }
            .padding(DesignSystem.Spacing.md)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(DesignSystem.Colors.backgroundSecondary)
            .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Sizing.cardCornerRadius))
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityAddTraits(.isButton)
        .accessibilityHint("Opens subscription list")
    }
}

// MARK: - Preview

#Preview("Subscription Widget") {
    VStack(spacing: DesignSystem.Spacing.lg) {
        // With renewals
        SubscriptionWidgetView(
            monthlyCost: 89.97,
            renewingSoonCount: 3,
            onTap: { print("Tapped") }
        )

        // No renewals
        SubscriptionWidgetView(
            monthlyCost: 45.50,
            renewingSoonCount: 0,
            onTap: { print("Tapped") }
        )

        // Zero cost
        SubscriptionWidgetView(
            monthlyCost: 0,
            renewingSoonCount: 0,
            onTap: { print("Tapped") }
        )
    }
    .padding()
    .background(DesignSystem.Colors.backgroundPrimary)
}

#Preview("Subscription Widget - Dark Mode") {
    SubscriptionWidgetView(
        monthlyCost: 125.99,
        renewingSoonCount: 2,
        onTap: { print("Tapped") }
    )
    .padding()
    .background(DesignSystem.Colors.backgroundPrimary)
    .preferredColorScheme(.dark)
}
