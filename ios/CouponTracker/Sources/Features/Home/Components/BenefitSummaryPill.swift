//
//  BenefitSummaryPill.swift
//  CouponTracker
//
//  Created: January 20, 2026
//
//  Purpose: A small pill component showing a summary statistic (e.g., available value, used count).
//           Extracted from CardDetailView for reusability.
//

import SwiftUI

// MARK: - Summary Pill

/// A small pill showing a summary statistic
struct SummaryPill: View {
    let title: String
    let value: String
    let color: Color

    var body: some View {
        VStack(spacing: DesignSystem.Spacing.xs - 2) {
            Text(title)
                .font(DesignSystem.Typography.caption)
                .foregroundStyle(DesignSystem.Colors.textSecondary)

            Text(value)
                .font(DesignSystem.Typography.headline)
                .foregroundStyle(color)
        }
        .padding(.horizontal, DesignSystem.Spacing.md)
        .padding(.vertical, DesignSystem.Spacing.sm)
        .background(
            RoundedRectangle(cornerRadius: DesignSystem.Sizing.buttonCornerRadius)
                .fill(DesignSystem.Colors.backgroundTertiary)
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title): \(value)")
    }
}

// MARK: - Previews

#Preview("Summary Pills") {
    HStack(spacing: DesignSystem.Spacing.md) {
        SummaryPill(
            title: "Available",
            value: "$454",
            color: DesignSystem.Colors.success
        )

        SummaryPill(
            title: "Used",
            value: "3",
            color: DesignSystem.Colors.textSecondary
        )

        SummaryPill(
            title: "Expiring",
            value: "2",
            color: DesignSystem.Colors.warning
        )
    }
    .padding()
}
