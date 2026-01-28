//
//  StatCard.swift
//  CouponTracker
//
//  Created: January 2026
//  Purpose: A small stat card for dashboard displays.
//

import SwiftUI

// MARK: - Stat Card

/// A small stat card for the dashboard
struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    var onTap: (() -> Void)? = nil

    var body: some View {
        Group {
            if let onTap = onTap {
                Button(action: onTap) {
                    cardContent
                }
                .buttonStyle(.plain)
            } else {
                cardContent
            }
        }
    }

    private var cardContent: some View {
        VStack(spacing: DesignSystem.Spacing.sm) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundStyle(color)

            Text(value)
                .font(DesignSystem.Typography.title2)
                .foregroundStyle(DesignSystem.Colors.textPrimary)

            HStack(spacing: DesignSystem.Spacing.xs) {
                Text(title)
                    .font(DesignSystem.Typography.caption)
                    .foregroundStyle(DesignSystem.Colors.textSecondary)

                if onTap != nil {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(DesignSystem.Colors.textTertiary)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, DesignSystem.Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: DesignSystem.Sizing.buttonCornerRadius)
                .fill(DesignSystem.Colors.backgroundSecondary)
        )
    }
}

// MARK: - Preview

#Preview("Stat Cards") {
    HStack(spacing: DesignSystem.Spacing.md) {
        StatCard(
            title: "Cards",
            value: "5",
            icon: "creditcard.fill",
            color: DesignSystem.Colors.primaryFallback
        )

        StatCard(
            title: "Expiring Soon",
            value: "3",
            icon: "clock.badge.exclamationmark.fill",
            color: DesignSystem.Colors.warning,
            onTap: { print("Tapped") }
        )
    }
    .padding()
}
