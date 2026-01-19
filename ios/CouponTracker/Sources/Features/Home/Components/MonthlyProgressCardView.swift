// MonthlyProgressCardView.swift
// CouponTracker
//
// Created: January 17, 2026
//
// Purpose: A dashboard card that displays monthly benefit redemption progress.
//          Shows the current month name, total value redeemed, total available value,
//          a progress bar visualization, and count of benefits used vs total.
//
// ACCESSIBILITY:
// - Clear accessibility labels for VoiceOver
// - Progress information conveyed through both visual and text
// - Semantic colors for progress states
//
// DESIGN NOTES:
// - Card with rounded corners and subtle shadow
// - Month name header
// - Large currency value display for redeemed amount
// - Progress bar showing percentage used
// - Stats row showing count of used vs total benefits
// - Uses DesignSystem for consistent styling

import SwiftUI

// MARK: - Monthly Progress Card View

/// A card component displaying monthly benefit redemption progress
struct MonthlyProgressCardView: View {

    // MARK: - Properties

    let redeemedValue: Decimal
    let totalValue: Decimal
    let usedCount: Int
    let totalCount: Int
    var onTap: (() -> Void)?

    // MARK: - Computed Properties

    /// Current month name (e.g., "January 2026")
    private var currentMonthName: String {
        Formatters.monthYear.string(from: Date())
    }

    /// Progress percentage (0.0 to 1.0)
    private var progressPercentage: Double {
        guard totalValue > 0 else { return 0.0 }
        let nsRedeemed = redeemedValue as NSDecimalNumber
        let nsTotal = totalValue as NSDecimalNumber
        return min(nsRedeemed.doubleValue / nsTotal.doubleValue, 1.0)
    }

    /// Formatted redeemed value as currency
    private var formattedRedeemedValue: String {
        Formatters.formatCurrencyWhole(redeemedValue)
    }

    /// Formatted total value as currency
    private var formattedTotalValue: String {
        Formatters.formatCurrencyWhole(totalValue)
    }

    /// Progress bar color based on percentage
    private var progressColor: Color {
        if progressPercentage >= 0.8 {
            return DesignSystem.Colors.success
        } else if progressPercentage >= 0.5 {
            return DesignSystem.Colors.warning
        } else {
            return DesignSystem.Colors.primaryFallback
        }
    }

    /// Accessibility label for the entire card
    private var accessibilityLabel: String {
        let percentFormatted = String(format: "%.0f", progressPercentage * 100)
        return "\(currentMonthName). Redeemed \(formattedRedeemedValue) of \(formattedTotalValue). \(usedCount) of \(totalCount) benefits used. \(percentFormatted) percent progress."
    }

    // MARK: - Body

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
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityAddTraits(onTap != nil ? .isButton : [])
        .accessibilityHint(onTap != nil ? "Double tap to view breakdown" : "")
    }

    @ViewBuilder
    private var cardContent: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.lg) {
            // Header: Month name
            monthHeader

            // Main content: Value display
            valueSection

            // Progress bar
            progressBar

            // Stats row: Benefits used count
            statsRow
        }
        .padding(DesignSystem.Spacing.lg)
        .background(
            RoundedRectangle(cornerRadius: DesignSystem.Sizing.cardCornerRadius, style: .continuous)
                .fill(DesignSystem.Colors.backgroundSecondary)
        )
        .cardShadow()
    }

    // MARK: - Month Header

    @ViewBuilder
    private var monthHeader: some View {
        HStack {
            Text(currentMonthName)
                .font(DesignSystem.Typography.title3)
                .foregroundStyle(DesignSystem.Colors.textPrimary)

            Spacer()

            Image(systemName: "calendar")
                .font(.system(size: DesignSystem.Sizing.iconMedium, weight: .medium))
                .foregroundStyle(DesignSystem.Colors.primaryFallback)
        }
    }

    // MARK: - Value Section

    @ViewBuilder
    private var valueSection: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
            // Label
            Text("Redeemed This Month")
                .font(DesignSystem.Typography.callout)
                .foregroundStyle(DesignSystem.Colors.textSecondary)

            // Large value display
            HStack(alignment: .firstTextBaseline, spacing: DesignSystem.Spacing.xs) {
                Text(formattedRedeemedValue)
                    .font(DesignSystem.Typography.valueLarge)
                    .foregroundStyle(DesignSystem.Colors.textPrimary)

                Text("of \(formattedTotalValue)")
                    .font(DesignSystem.Typography.headline)
                    .foregroundStyle(DesignSystem.Colors.textSecondary)
            }
        }
    }

    // MARK: - Progress Bar

    @ViewBuilder
    private var progressBar: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background track
                    RoundedRectangle(cornerRadius: 4, style: .continuous)
                        .fill(DesignSystem.Colors.neutral.opacity(0.2))
                        .frame(height: 8)

                    // Progress fill
                    RoundedRectangle(cornerRadius: 4, style: .continuous)
                        .fill(progressColor)
                        .frame(width: geometry.size.width * progressPercentage, height: 8)
                        .animation(DesignSystem.Animation.spring, value: progressPercentage)
                }
            }
            .frame(height: 8)

            // Percentage label
            Text("\(Int(progressPercentage * 100))% Used")
                .font(DesignSystem.Typography.caption)
                .foregroundStyle(DesignSystem.Colors.textSecondary)
        }
    }

    // MARK: - Stats Row

    @ViewBuilder
    private var statsRow: some View {
        HStack(spacing: DesignSystem.Spacing.sm) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: DesignSystem.Sizing.iconSmall, weight: .semibold))
                .foregroundStyle(DesignSystem.Colors.success)

            Text("\(usedCount) of \(totalCount) benefits used")
                .font(DesignSystem.Typography.subhead)
                .foregroundStyle(DesignSystem.Colors.textSecondary)

            Spacer()
        }
        .padding(.top, DesignSystem.Spacing.xs)
    }
}

// MARK: - Previews

#Preview("Monthly Progress Card - Normal") {
    VStack(spacing: DesignSystem.Spacing.lg) {
        // 50% progress
        MonthlyProgressCardView(
            redeemedValue: 500,
            totalValue: 1000,
            usedCount: 3,
            totalCount: 6
        )

        Spacer()
    }
    .padding()
    .background(DesignSystem.Colors.backgroundPrimary)
}

#Preview("Monthly Progress Card - States") {
    ScrollView {
        VStack(spacing: DesignSystem.Spacing.xl) {
            // Low progress (< 50%)
            VStack(alignment: .leading) {
                Text("Low Progress (25%)")
                    .font(DesignSystem.Typography.headline)
                    .foregroundStyle(DesignSystem.Colors.textPrimary)

                MonthlyProgressCardView(
                    redeemedValue: 250,
                    totalValue: 1000,
                    usedCount: 2,
                    totalCount: 8
                )
            }

            // Medium progress (50-80%)
            VStack(alignment: .leading) {
                Text("Medium Progress (65%)")
                    .font(DesignSystem.Typography.headline)
                    .foregroundStyle(DesignSystem.Colors.textPrimary)

                MonthlyProgressCardView(
                    redeemedValue: 650,
                    totalValue: 1000,
                    usedCount: 5,
                    totalCount: 8
                )
            }

            // High progress (80%+)
            VStack(alignment: .leading) {
                Text("High Progress (90%)")
                    .font(DesignSystem.Typography.headline)
                    .foregroundStyle(DesignSystem.Colors.textPrimary)

                MonthlyProgressCardView(
                    redeemedValue: 900,
                    totalValue: 1000,
                    usedCount: 7,
                    totalCount: 8
                )
            }

            // No progress
            VStack(alignment: .leading) {
                Text("No Progress (0%)")
                    .font(DesignSystem.Typography.headline)
                    .foregroundStyle(DesignSystem.Colors.textPrimary)

                MonthlyProgressCardView(
                    redeemedValue: 0,
                    totalValue: 1000,
                    usedCount: 0,
                    totalCount: 8
                )
            }

            // Complete progress
            VStack(alignment: .leading) {
                Text("Complete Progress (100%)")
                    .font(DesignSystem.Typography.headline)
                    .foregroundStyle(DesignSystem.Colors.textPrimary)

                MonthlyProgressCardView(
                    redeemedValue: 1000,
                    totalValue: 1000,
                    usedCount: 8,
                    totalCount: 8
                )
            }
        }
        .padding()
    }
    .background(DesignSystem.Colors.backgroundPrimary)
}

#Preview("Monthly Progress Card - Dark Mode") {
    VStack(spacing: DesignSystem.Spacing.lg) {
        MonthlyProgressCardView(
            redeemedValue: 750,
            totalValue: 1200,
            usedCount: 5,
            totalCount: 7
        )

        Spacer()
    }
    .padding()
    .background(DesignSystem.Colors.backgroundPrimary)
    .preferredColorScheme(.dark)
}

#Preview("Monthly Progress Card - Edge Cases") {
    ScrollView {
        VStack(spacing: DesignSystem.Spacing.xl) {
            // Zero total value (edge case handling)
            VStack(alignment: .leading) {
                Text("Zero Total Value")
                    .font(DesignSystem.Typography.headline)
                    .foregroundStyle(DesignSystem.Colors.textPrimary)

                MonthlyProgressCardView(
                    redeemedValue: 0,
                    totalValue: 0,
                    usedCount: 0,
                    totalCount: 0
                )
            }

            // Very large values
            VStack(alignment: .leading) {
                Text("Large Values")
                    .font(DesignSystem.Typography.headline)
                    .foregroundStyle(DesignSystem.Colors.textPrimary)

                MonthlyProgressCardView(
                    redeemedValue: 15000,
                    totalValue: 20000,
                    usedCount: 15,
                    totalCount: 20
                )
            }

            // Single benefit
            VStack(alignment: .leading) {
                Text("Single Benefit")
                    .font(DesignSystem.Typography.headline)
                    .foregroundStyle(DesignSystem.Colors.textPrimary)

                MonthlyProgressCardView(
                    redeemedValue: 100,
                    totalValue: 100,
                    usedCount: 1,
                    totalCount: 1
                )
            }
        }
        .padding()
    }
    .background(DesignSystem.Colors.backgroundPrimary)
}
