//
//  ExpandedBenefitDetail.swift
//  CouponTracker
//
//  Created: January 20, 2026
//
//  Purpose: An expanded view showing additional benefit details and action buttons.
//           Displays description, metadata (frequency, merchant, category), and
//           contextual actions (mark as done, snooze, undo).
//           Extracted from CardDetailView for reusability.
//

import SwiftUI

// MARK: - Expanded Benefit Detail

/// An expanded view showing additional benefit details and actions
struct ExpandedBenefitDetail: View {

    let benefit: PreviewBenefit
    var onMarkAsDone: (() -> Void)? = nil
    var onSnooze: ((Int) -> Void)? = nil
    var onUndo: (() -> Void)? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
            // Description
            if !benefit.description.isEmpty {
                Text(benefit.description)
                    .font(DesignSystem.Typography.body)
                    .foregroundStyle(DesignSystem.Colors.textSecondary)
            }

            // Metadata
            HStack(spacing: DesignSystem.Spacing.lg) {
                MetadataItem(icon: "repeat", label: benefit.frequency.rawValue)

                if let merchant = benefit.merchant {
                    MetadataItem(icon: "storefront", label: merchant)
                }

                MetadataItem(icon: benefit.category.iconName, label: benefit.category.rawValue)
            }

            // Actions (for available benefits)
            if benefit.status == .available {
                Divider()

                HStack(spacing: DesignSystem.Spacing.md) {
                    // Mark as Done button
                    if onMarkAsDone != nil {
                        Button(action: { onMarkAsDone?() }) {
                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                Text("Mark as Done")
                            }
                            .font(DesignSystem.Typography.subhead)
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, DesignSystem.Spacing.sm)
                            .background(
                                RoundedRectangle(cornerRadius: DesignSystem.Sizing.buttonCornerRadius)
                                    .fill(DesignSystem.Colors.success)
                            )
                        }
                    }

                    // Snooze button
                    if onSnooze != nil {
                        Menu {
                            Button("1 Day") { onSnooze?(1) }
                            Button("3 Days") { onSnooze?(3) }
                            Button("1 Week") { onSnooze?(7) }
                        } label: {
                            HStack {
                                Image(systemName: "clock.arrow.circlepath")
                                Text("Snooze")
                            }
                            .font(DesignSystem.Typography.subhead)
                            .foregroundStyle(DesignSystem.Colors.primaryFallback)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, DesignSystem.Spacing.sm)
                            .background(
                                RoundedRectangle(cornerRadius: DesignSystem.Sizing.buttonCornerRadius)
                                    .strokeBorder(DesignSystem.Colors.primaryFallback, lineWidth: 1)
                            )
                        }
                    }
                }
            }

            // Actions (for used benefits)
            if benefit.status == .used, onUndo != nil {
                Divider()

                Button(action: { onUndo?() }) {
                    HStack {
                        Image(systemName: "arrow.uturn.backward.circle.fill")
                        Text("Undo Mark as Used")
                    }
                    .font(DesignSystem.Typography.subhead)
                    .foregroundStyle(DesignSystem.Colors.primaryFallback)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, DesignSystem.Spacing.sm)
                    .background(
                        RoundedRectangle(cornerRadius: DesignSystem.Sizing.buttonCornerRadius)
                            .strokeBorder(DesignSystem.Colors.primaryFallback, lineWidth: 1)
                    )
                }
            }
        }
        .padding(DesignSystem.Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: DesignSystem.Sizing.buttonCornerRadius)
                .fill(DesignSystem.Colors.backgroundTertiary)
        )
    }
}

// MARK: - Metadata Item

/// A small metadata label with icon
struct MetadataItem: View {
    let icon: String
    let label: String

    var body: some View {
        HStack(spacing: DesignSystem.Spacing.xs) {
            Image(systemName: icon)
                .font(.system(size: 12))
                .foregroundStyle(DesignSystem.Colors.textTertiary)

            Text(label)
                .font(DesignSystem.Typography.caption)
                .foregroundStyle(DesignSystem.Colors.textSecondary)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(label)
    }
}

// MARK: - Previews

#Preview("Expanded Benefit Detail - Available") {
    VStack(spacing: DesignSystem.Spacing.lg) {
        ExpandedBenefitDetail(
            benefit: PreviewData.amexPlatinum.availableBenefits.first!,
            onMarkAsDone: { },
            onSnooze: { _ in }
        )
    }
    .padding()
    .background(DesignSystem.Colors.backgroundPrimary)
}

#Preview("Expanded Benefit Detail - Used") {
    VStack(spacing: DesignSystem.Spacing.lg) {
        ExpandedBenefitDetail(
            benefit: PreviewData.amexPlatinum.usedBenefits.first ?? PreviewBenefit.used(value: 20, name: "Test Credit"),
            onUndo: { }
        )
    }
    .padding()
    .background(DesignSystem.Colors.backgroundPrimary)
}
