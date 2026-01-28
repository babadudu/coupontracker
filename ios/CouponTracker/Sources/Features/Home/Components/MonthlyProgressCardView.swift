// ProgressCardView.swift
// CouponTracker
//
// Created: January 17, 2026
//
// Purpose: A swipeable dashboard card displaying benefit redemption progress across
//          multiple time periods (monthly, quarterly, semi-annual, annual).
//          Shows period label, total value redeemed, total available value,
//          a progress bar visualization, and count of benefits used vs total.
//
// ACCESSIBILITY:
// - Clear accessibility labels for VoiceOver
// - Progress information conveyed through both visual and text
// - Semantic colors for progress states
// - Swipe gesture support with page indicators
//
// DESIGN NOTES:
// - TabView with page-style navigation for period selection
// - Card with rounded corners and subtle shadow
// - Dynamic period label (e.g., "January 2026", "Q1 2026")
// - Large currency value display for redeemed amount
// - Progress bar showing percentage used
// - Stats row showing count of used vs total benefits
// - Uses DesignSystem for consistent styling

import SwiftUI

// MARK: - Progress Card View

/// A swipeable card component displaying benefit redemption progress for multiple periods
struct ProgressCardView: View {

    // MARK: - Properties

    @Binding var selectedPeriod: BenefitPeriod
    let redeemedValue: Decimal
    let totalValue: Decimal
    let usedCount: Int
    let totalCount: Int
    var onTap: (() -> Void)?

    // MARK: - Computed Properties

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

    /// Dynamic redeemed label based on selected period
    private var redeemedLabel: String {
        switch selectedPeriod {
        case .monthly:
            return "Redeemed This Month"
        case .quarterly:
            return "Redeemed This Quarter"
        case .semiAnnual:
            return "Redeemed This Half"
        case .annual:
            return "Redeemed This Year"
        }
    }

    /// Accessibility label for the entire card
    private var accessibilityLabel: String {
        let percentFormatted = String(format: "%.0f", progressPercentage * 100)
        let periodLabel = selectedPeriod.periodLabel()
        return "\(periodLabel). Redeemed \(formattedRedeemedValue) of \(formattedTotalValue). \(usedCount) of \(totalCount) benefits used. \(percentFormatted) percent progress."
    }

    // MARK: - Body

    var body: some View {
        TabView(selection: $selectedPeriod) {
            ForEach(BenefitPeriod.allCases) { period in
                cardContent(for: period)
                    .tag(period)
            }
        }
        .tabViewStyle(.page(indexDisplayMode: .always))
        .frame(height: 210)
    }

    // MARK: - Card Content

    @ViewBuilder
    private func cardContent(for period: BenefitPeriod) -> some View {
        Group {
            if let onTap = onTap {
                Button(action: onTap) {
                    cardBody
                }
                .buttonStyle(.plain)
            } else {
                cardBody
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityAddTraits(onTap != nil ? .isButton : [])
        .accessibilityHint(onTap != nil ? "Double tap to view breakdown" : "")
    }

    @ViewBuilder
    private var cardBody: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.lg) {
            // Header: Period label
            periodHeader

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

    // MARK: - Period Header

    @ViewBuilder
    private var periodHeader: some View {
        HStack {
            Text(selectedPeriod.periodLabel())
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
            Text(redeemedLabel)
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

#Preview("Progress Card - Normal") {
    @Previewable @State var selectedPeriod: BenefitPeriod = .monthly

    VStack(spacing: DesignSystem.Spacing.lg) {
        // 50% progress
        ProgressCardView(
            selectedPeriod: $selectedPeriod,
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

#Preview("Progress Card - States") {
    @Previewable @State var selectedPeriod1: BenefitPeriod = .monthly
    @Previewable @State var selectedPeriod2: BenefitPeriod = .quarterly
    @Previewable @State var selectedPeriod3: BenefitPeriod = .semiAnnual
    @Previewable @State var selectedPeriod4: BenefitPeriod = .monthly
    @Previewable @State var selectedPeriod5: BenefitPeriod = .annual

    ScrollView {
        VStack(spacing: DesignSystem.Spacing.xl) {
            // Low progress (< 50%)
            VStack(alignment: .leading) {
                Text("Low Progress (25%)")
                    .font(DesignSystem.Typography.headline)
                    .foregroundStyle(DesignSystem.Colors.textPrimary)

                ProgressCardView(
                    selectedPeriod: $selectedPeriod1,
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

                ProgressCardView(
                    selectedPeriod: $selectedPeriod2,
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

                ProgressCardView(
                    selectedPeriod: $selectedPeriod3,
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

                ProgressCardView(
                    selectedPeriod: $selectedPeriod4,
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

                ProgressCardView(
                    selectedPeriod: $selectedPeriod5,
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

#Preview("Progress Card - Dark Mode") {
    @Previewable @State var selectedPeriod: BenefitPeriod = .quarterly

    VStack(spacing: DesignSystem.Spacing.lg) {
        ProgressCardView(
            selectedPeriod: $selectedPeriod,
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

#Preview("Progress Card - Edge Cases") {
    @Previewable @State var selectedPeriod1: BenefitPeriod = .monthly
    @Previewable @State var selectedPeriod2: BenefitPeriod = .annual
    @Previewable @State var selectedPeriod3: BenefitPeriod = .semiAnnual

    ScrollView {
        VStack(spacing: DesignSystem.Spacing.xl) {
            // Zero total value (edge case handling)
            VStack(alignment: .leading) {
                Text("Zero Total Value")
                    .font(DesignSystem.Typography.headline)
                    .foregroundStyle(DesignSystem.Colors.textPrimary)

                ProgressCardView(
                    selectedPeriod: $selectedPeriod1,
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

                ProgressCardView(
                    selectedPeriod: $selectedPeriod2,
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

                ProgressCardView(
                    selectedPeriod: $selectedPeriod3,
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
