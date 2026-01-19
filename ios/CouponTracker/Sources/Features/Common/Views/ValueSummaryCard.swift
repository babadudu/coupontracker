//
//  ValueSummaryCard.swift
//  CouponTracker
//
//  Created: January 17, 2026
//
//  Purpose: A dashboard summary card showing the total available value across
//           all cards, with breakdown by time period (this week/month) and
//           visual progress indicator.
//
//  ACCESSIBILITY:
//  - Announces total value and breakdown clearly
//  - Progress ring has accessible value description
//  - All text uses semantic colors for contrast compliance
//
//  USAGE:
//  ValueSummaryCard(
//      totalValue: 847,
//      cardCount: 4,
//      expiringThisWeek: 65,
//      expiringThisMonth: 215
//  )
//

import SwiftUI

// MARK: - Value Summary Card

/// A prominent dashboard card showing total available rewards value
struct ValueSummaryCard: View {

    // MARK: - Properties

    /// Total available value across all cards
    let totalValue: Decimal

    /// Number of cards in wallet
    let cardCount: Int

    /// Value expiring within 7 days
    var expiringThisWeek: Decimal = 0

    /// Value expiring within 30 days
    var expiringThisMonth: Decimal = 0

    /// Amount redeemed this month
    var redeemedThisMonth: Decimal = 0

    /// Callback when user taps "See breakdown"
    var onTapBreakdown: (() -> Void)? = nil

    // MARK: - Style Variants

    enum Style {
        case prominent   // Large with gradient background
        case compact     // Smaller for inline use
        case minimal     // Just the value, no extras
    }

    var style: Style = .prominent

    // MARK: - Body

    var body: some View {
        Group {
            switch style {
            case .prominent:
                prominentCard
            case .compact:
                compactCard
            case .minimal:
                minimalCard
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityLabel)
    }

    // MARK: - Prominent Card

    @ViewBuilder
    private var prominentCard: some View {
        VStack(spacing: DesignSystem.Spacing.lg) {
            // Main value section
            VStack(spacing: DesignSystem.Spacing.xs) {
                Text("Total Available")
                    .font(DesignSystem.Typography.subhead)
                    .foregroundStyle(.white.opacity(0.8))

                Text(formattedTotalValue)
                    .font(DesignSystem.Typography.valueLarge)
                    .foregroundStyle(.white)
                    .contentTransition(.numericText())

                Text("Across \(cardCount) card\(cardCount == 1 ? "" : "s")")
                    .font(DesignSystem.Typography.footnote)
                    .foregroundStyle(.white.opacity(0.6))
            }

            // Breakdown section
            if expiringThisWeek > 0 || expiringThisMonth > 0 {
                Divider()
                    .background(.white.opacity(0.2))

                HStack(spacing: DesignSystem.Spacing.xl) {
                    // Expiring this week
                    if expiringThisWeek > 0 {
                        ValueBreakdownItem(
                            label: "This Week",
                            value: formatCurrency(expiringThisWeek),
                            icon: "exclamationmark.circle",
                            isUrgent: true
                        )
                    }

                    // Expiring this month
                    if expiringThisMonth > 0 {
                        ValueBreakdownItem(
                            label: "This Month",
                            value: formatCurrency(expiringThisMonth),
                            icon: "calendar",
                            isUrgent: false
                        )
                    }
                }
            }

            // See breakdown button
            if onTapBreakdown != nil {
                Button(action: { onTapBreakdown?() }) {
                    HStack {
                        Text("See breakdown")
                        Image(systemName: "chevron.right")
                            .font(.system(size: 12, weight: .semibold))
                    }
                    .font(DesignSystem.Typography.subhead)
                    .foregroundStyle(.white.opacity(0.8))
                }
            }
        }
        .padding(DesignSystem.Spacing.xl)
        .frame(maxWidth: .infinity)
        .background(prominentGradient)
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Sizing.sheetCornerRadius))
        .shadow(DesignSystem.Shadow.level2)
    }

    // MARK: - Compact Card

    @ViewBuilder
    private var compactCard: some View {
        HStack(spacing: DesignSystem.Spacing.lg) {
            // Progress ring
            ZStack {
                Circle()
                    .stroke(DesignSystem.Colors.primaryFallback.opacity(0.2), lineWidth: 4)

                Circle()
                    .trim(from: 0, to: progressValue)
                    .stroke(DesignSystem.Colors.primaryFallback, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                    .rotationEffect(.degrees(-90))

                Text("\(cardCount)")
                    .font(DesignSystem.Typography.headline)
                    .foregroundStyle(DesignSystem.Colors.primaryFallback)
            }
            .frame(width: 48, height: 48)

            // Value info
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs - 2) {
                Text("Total Available")
                    .font(DesignSystem.Typography.caption)
                    .foregroundStyle(DesignSystem.Colors.textSecondary)

                Text(formattedTotalValue)
                    .font(DesignSystem.Typography.valueMedium)
                    .foregroundStyle(DesignSystem.Colors.textPrimary)

                if expiringThisWeek > 0 {
                    HStack(spacing: DesignSystem.Spacing.xs) {
                        Image(systemName: "exclamationmark.circle.fill")
                            .font(.system(size: 10))
                            .foregroundStyle(DesignSystem.Colors.warning)

                        Text("\(formatCurrency(expiringThisWeek)) expiring soon")
                            .font(DesignSystem.Typography.caption)
                            .foregroundStyle(DesignSystem.Colors.warning)
                    }
                }
            }

            Spacer()

            // Chevron
            if onTapBreakdown != nil {
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(DesignSystem.Colors.textTertiary)
            }
        }
        .padding(DesignSystem.Spacing.lg)
        .background(
            RoundedRectangle(cornerRadius: DesignSystem.Sizing.cardCornerRadius)
                .fill(DesignSystem.Colors.backgroundSecondary)
        )
        .onTapGesture {
            onTapBreakdown?()
        }
    }

    // MARK: - Minimal Card

    @ViewBuilder
    private var minimalCard: some View {
        VStack(spacing: DesignSystem.Spacing.xs) {
            Text("Available")
                .font(DesignSystem.Typography.caption)
                .foregroundStyle(DesignSystem.Colors.textSecondary)

            Text(formattedTotalValue)
                .font(DesignSystem.Typography.valueMedium)
                .foregroundStyle(DesignSystem.Colors.textPrimary)
        }
    }

    // MARK: - Helper Views

    private var prominentGradient: LinearGradient {
        LinearGradient(
            colors: [
                DesignSystem.Colors.primaryFallback,
                DesignSystem.Colors.primaryDark
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    // MARK: - Computed Properties

    private var formattedTotalValue: String {
        formatCurrency(totalValue)
    }

    private var progressValue: CGFloat {
        // Visual representation - could be based on used vs available
        min(CGFloat(cardCount) / 5.0, 1.0)
    }

    private var accessibilityLabel: String {
        var label = "Total available value: \(formattedTotalValue) across \(cardCount) cards"
        if expiringThisWeek > 0 {
            label += ". \(formatCurrency(expiringThisWeek)) expiring this week"
        }
        if expiringThisMonth > 0 {
            label += ". \(formatCurrency(expiringThisMonth)) expiring this month"
        }
        return label
    }

    // MARK: - Helper Methods

    private func formatCurrency(_ value: Decimal) -> String {
        Formatters.formatCurrencyWhole(value)
    }
}

// MARK: - Value Breakdown Item

/// A single item in the value breakdown section
struct ValueBreakdownItem: View {
    let label: String
    let value: String
    let icon: String
    var isUrgent: Bool = false

    var body: some View {
        VStack(spacing: DesignSystem.Spacing.xs) {
            HStack(spacing: DesignSystem.Spacing.xs) {
                Image(systemName: icon)
                    .font(.system(size: 12))
                Text(label)
                    .font(DesignSystem.Typography.caption)
            }
            .foregroundStyle(.white.opacity(0.7))

            Text(value)
                .font(DesignSystem.Typography.headline)
                .foregroundStyle(isUrgent ? DesignSystem.Colors.warning : .white)
        }
    }
}

// MARK: - Progress Ring View

/// A circular progress indicator for value tracking
struct ValueProgressRing: View {
    let usedValue: Decimal
    let totalValue: Decimal
    var size: CGFloat = 120
    var lineWidth: CGFloat = 12

    private var progress: CGFloat {
        guard totalValue > 0 else { return 0 }
        return CGFloat(truncating: (usedValue / totalValue) as NSDecimalNumber)
    }

    private var remainingValue: Decimal {
        totalValue - usedValue
    }

    var body: some View {
        ZStack {
            // Background ring
            Circle()
                .stroke(DesignSystem.Colors.success.opacity(0.2), lineWidth: lineWidth)

            // Progress ring
            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    DesignSystem.Colors.success,
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(DesignSystem.Animation.spring, value: progress)

            // Center content
            VStack(spacing: 2) {
                Text(formatCurrency(remainingValue))
                    .font(DesignSystem.Typography.valueMedium)
                    .foregroundStyle(DesignSystem.Colors.textPrimary)

                Text("remaining")
                    .font(DesignSystem.Typography.caption)
                    .foregroundStyle(DesignSystem.Colors.textSecondary)
            }
        }
        .frame(width: size, height: size)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(formatCurrency(remainingValue)) remaining out of \(formatCurrency(totalValue))")
        .accessibilityValue("\(Int(progress * 100))% used")
    }

    private func formatCurrency(_ value: Decimal) -> String {
        Formatters.formatCurrencyWhole(value)
    }
}

// MARK: - Monthly Summary Card

/// An alternative summary showing monthly tracking
struct MonthlySummaryCard: View {
    let monthName: String
    let availableValue: Decimal
    let usedValue: Decimal
    let expiredValue: Decimal

    private var totalValue: Decimal {
        availableValue + usedValue + expiredValue
    }

    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
            // Header
            Text(monthName)
                .font(DesignSystem.Typography.headline)
                .foregroundStyle(DesignSystem.Colors.textPrimary)

            // Progress bar
            GeometryReader { geometry in
                HStack(spacing: 2) {
                    // Used section (green)
                    if usedValue > 0 {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(DesignSystem.Colors.success)
                            .frame(width: sectionWidth(for: usedValue, in: geometry.size.width))
                    }

                    // Available section (blue)
                    if availableValue > 0 {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(DesignSystem.Colors.primaryFallback)
                            .frame(width: sectionWidth(for: availableValue, in: geometry.size.width))
                    }

                    // Expired section (gray)
                    if expiredValue > 0 {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(DesignSystem.Colors.neutral)
                            .frame(width: sectionWidth(for: expiredValue, in: geometry.size.width))
                    }
                }
            }
            .frame(height: 8)

            // Legend
            HStack(spacing: DesignSystem.Spacing.lg) {
                LegendItem(color: DesignSystem.Colors.success, label: "Used", value: usedValue)
                LegendItem(color: DesignSystem.Colors.primaryFallback, label: "Available", value: availableValue)
                if expiredValue > 0 {
                    LegendItem(color: DesignSystem.Colors.neutral, label: "Expired", value: expiredValue)
                }
            }
        }
        .padding(DesignSystem.Spacing.lg)
        .background(
            RoundedRectangle(cornerRadius: DesignSystem.Sizing.cardCornerRadius)
                .fill(DesignSystem.Colors.backgroundSecondary)
        )
    }

    private func sectionWidth(for value: Decimal, in totalWidth: CGFloat) -> CGFloat {
        guard totalValue > 0 else { return 0 }
        let ratio = CGFloat(truncating: (value / totalValue) as NSDecimalNumber)
        return max(totalWidth * ratio - 2, 0) // Subtract spacing
    }
}

// MARK: - Legend Item

struct LegendItem: View {
    let color: Color
    let label: String
    let value: Decimal

    var body: some View {
        HStack(spacing: DesignSystem.Spacing.xs) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)

            VStack(alignment: .leading, spacing: 0) {
                Text(label)
                    .font(DesignSystem.Typography.caption)
                    .foregroundStyle(DesignSystem.Colors.textSecondary)

                Text(formatCurrency(value))
                    .font(DesignSystem.Typography.subhead)
                    .foregroundStyle(DesignSystem.Colors.textPrimary)
            }
        }
    }

    private func formatCurrency(_ value: Decimal) -> String {
        Formatters.formatCurrencyWhole(value)
    }
}

// MARK: - Previews

#Preview("Value Summary - Prominent") {
    VStack {
        ValueSummaryCard(
            totalValue: 847,
            cardCount: 4,
            expiringThisWeek: 65,
            expiringThisMonth: 215,
            onTapBreakdown: { print("Breakdown tapped") },
            style: .prominent
        )
    }
    .padding()
    .background(DesignSystem.Colors.backgroundPrimary)
}

#Preview("Value Summary - Compact") {
    VStack(spacing: DesignSystem.Spacing.md) {
        ValueSummaryCard(
            totalValue: 847,
            cardCount: 4,
            expiringThisWeek: 65,
            onTapBreakdown: { print("Breakdown tapped") },
            style: .compact
        )

        ValueSummaryCard(
            totalValue: 250,
            cardCount: 2,
            style: .compact
        )
    }
    .padding()
    .background(DesignSystem.Colors.backgroundPrimary)
}

#Preview("Value Summary - Minimal") {
    HStack(spacing: DesignSystem.Spacing.xl) {
        ValueSummaryCard(
            totalValue: 847,
            cardCount: 4,
            style: .minimal
        )

        ValueSummaryCard(
            totalValue: 125,
            cardCount: 2,
            style: .minimal
        )
    }
    .padding()
}

#Preview("Progress Ring") {
    VStack(spacing: DesignSystem.Spacing.xl) {
        ValueProgressRing(
            usedValue: 320,
            totalValue: 847
        )

        ValueProgressRing(
            usedValue: 100,
            totalValue: 500,
            size: 80,
            lineWidth: 8
        )
    }
    .padding()
}

#Preview("Monthly Summary") {
    VStack(spacing: DesignSystem.Spacing.md) {
        MonthlySummaryCard(
            monthName: "January 2026",
            availableValue: 320,
            usedValue: 427,
            expiredValue: 100
        )

        MonthlySummaryCard(
            monthName: "December 2025",
            availableValue: 0,
            usedValue: 785,
            expiredValue: 62
        )
    }
    .padding()
    .background(DesignSystem.Colors.backgroundPrimary)
}

#Preview("Value Summary - Dark Mode") {
    VStack(spacing: DesignSystem.Spacing.lg) {
        ValueSummaryCard(
            totalValue: 847,
            cardCount: 4,
            expiringThisWeek: 65,
            expiringThisMonth: 215,
            style: .prominent
        )

        ValueSummaryCard(
            totalValue: 250,
            cardCount: 2,
            expiringThisWeek: 15,
            style: .compact
        )
    }
    .padding()
    .background(DesignSystem.Colors.backgroundPrimary)
    .preferredColorScheme(.dark)
}

#Preview("All Summary Styles") {
    ScrollView {
        VStack(spacing: DesignSystem.Spacing.xl) {
            Text("Prominent Style")
                .font(DesignSystem.Typography.headline)
            ValueSummaryCard(
                totalValue: 847,
                cardCount: 4,
                expiringThisWeek: 65,
                expiringThisMonth: 215,
                style: .prominent
            )

            Text("Compact Style")
                .font(DesignSystem.Typography.headline)
            ValueSummaryCard(
                totalValue: 847,
                cardCount: 4,
                expiringThisWeek: 65,
                style: .compact
            )

            Text("Minimal Style")
                .font(DesignSystem.Typography.headline)
            ValueSummaryCard(
                totalValue: 847,
                cardCount: 4,
                style: .minimal
            )

            Text("Monthly Summary")
                .font(DesignSystem.Typography.headline)
            MonthlySummaryCard(
                monthName: "January 2026",
                availableValue: 320,
                usedValue: 427,
                expiredValue: 100
            )
        }
        .padding()
    }
    .background(DesignSystem.Colors.backgroundPrimary)
}
