// CouponWidgetView.swift
// CouponTracker
//
// Created: January 2026
// Purpose: Dashboard widget showing coupon summary with valid count and potential savings.
//
// ACCESSIBILITY:
// - Clear accessibility labels for VoiceOver
// - Touch target meets minimum 44pt requirement
//
// DESIGN:
// - Compact card showing key coupon metrics
// - Quick navigation to Tracker tab

import SwiftUI

// MARK: - Coupon Widget View

/// Dashboard widget showing coupon summary
struct CouponWidgetView: View {

    // MARK: - Properties

    let validCount: Int
    let expiringSoonCount: Int
    let totalSavings: Decimal
    let onTap: (() -> Void)?

    // MARK: - Computed Properties

    private var formattedSavings: String {
        Formatters.formatCurrencyWhole(totalSavings)
    }

    private var accessibilityLabel: String {
        var label = "Coupons. \(validCount) valid coupons."
        if totalSavings > 0 {
            label += " \(formattedSavings) in potential savings."
        }
        if expiringSoonCount > 0 {
            label += " \(expiringSoonCount) expiring soon."
        }
        return label
    }

    // MARK: - Body

    var body: some View {
        Button(action: { onTap?() }) {
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
                // Header
                HStack {
                    Image(systemName: "tag.fill")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(DesignSystem.Colors.success)

                    Text("Coupons")
                        .font(DesignSystem.Typography.subhead)
                        .foregroundStyle(DesignSystem.Colors.textSecondary)

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(DesignSystem.Colors.textTertiary)
                }

                // Valid Coupons + Savings
                HStack(alignment: .bottom, spacing: DesignSystem.Spacing.md) {
                    VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                        Text("\(validCount)")
                            .font(DesignSystem.Typography.title2)
                            .foregroundStyle(DesignSystem.Colors.textPrimary)

                        Text("valid")
                            .font(DesignSystem.Typography.caption)
                            .foregroundStyle(DesignSystem.Colors.textTertiary)
                    }

                    if totalSavings > 0 {
                        VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                            Text(formattedSavings)
                                .font(DesignSystem.Typography.headline)
                                .foregroundStyle(DesignSystem.Colors.success)

                            Text("savings")
                                .font(DesignSystem.Typography.caption)
                                .foregroundStyle(DesignSystem.Colors.textTertiary)
                        }
                    }

                    Spacer()
                }

                // Expiring Soon Badge (if any)
                if expiringSoonCount > 0 {
                    HStack(spacing: DesignSystem.Spacing.xs) {
                        Image(systemName: "clock.badge.exclamationmark.fill")
                            .font(.system(size: 12))
                            .foregroundStyle(DesignSystem.Colors.warning)

                        Text("\(expiringSoonCount) expiring soon")
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
        .accessibilityHint("Opens coupon list")
    }
}

// MARK: - Preview

#Preview("Coupon Widget") {
    VStack(spacing: DesignSystem.Spacing.lg) {
        // With savings and expiring
        CouponWidgetView(
            validCount: 8,
            expiringSoonCount: 3,
            totalSavings: 125,
            onTap: { print("Tapped") }
        )

        // No expiring
        CouponWidgetView(
            validCount: 5,
            expiringSoonCount: 0,
            totalSavings: 50,
            onTap: { print("Tapped") }
        )

        // Zero coupons
        CouponWidgetView(
            validCount: 0,
            expiringSoonCount: 0,
            totalSavings: 0,
            onTap: { print("Tapped") }
        )
    }
    .padding()
    .background(DesignSystem.Colors.backgroundPrimary)
}

#Preview("Coupon Widget - Dark Mode") {
    CouponWidgetView(
        validCount: 12,
        expiringSoonCount: 2,
        totalSavings: 245,
        onTap: { print("Tapped") }
    )
    .padding()
    .background(DesignSystem.Colors.backgroundPrimary)
    .preferredColorScheme(.dark)
}
