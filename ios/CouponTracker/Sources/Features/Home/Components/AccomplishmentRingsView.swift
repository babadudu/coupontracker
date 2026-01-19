//
//  AccomplishmentRingsView.swift
//  CouponTracker
//
//  Created: January 2026
//  Purpose: Apple Fitness-inspired accomplishment ring display.
//           Shows overall progress for a selected period.

import SwiftUI

/// Data model for ring progress calculation
struct RingProgress {
    let redeemedValue: Decimal
    let totalValue: Decimal
    let usedCount: Int
    let totalCount: Int

    var progress: Double {
        guard totalValue > 0 else { return 0 }
        return NSDecimalNumber(decimal: redeemedValue / totalValue).doubleValue
    }

    var percentageText: String {
        let percentage = Int(progress * 100)
        return "\(percentage)%"
    }

    var isEmpty: Bool {
        totalCount == 0
    }
}

/// Main accomplishment ring view for the dashboard.
///
/// Displays a large progress ring with:
/// - Redeemed value in center
/// - Total value below
/// - Percentage indicator
struct AccomplishmentRingsView: View {

    // MARK: - Properties

    let progress: RingProgress
    let period: BenefitPeriod
    var size: CGFloat = 200

    // MARK: - State

    @State private var showCelebration = false
    @State private var hasShownCelebration = false

    // MARK: - Body

    var body: some View {
        VStack(spacing: DesignSystem.Spacing.md) {
            if progress.isEmpty {
                emptyStateView
            } else {
                ringView
            }
        }
        .onChange(of: progress.progress) { oldValue, newValue in
            checkForCelebration(oldValue: oldValue, newValue: newValue)
        }
        .sensoryFeedback(.impact(weight: .light), trigger: progressMilestone)
    }

    // MARK: - Ring View

    private var ringView: some View {
        ZStack {
            // Main ring
            AchievementRing(
                progress: progress.progress,
                gradientColors: ringColors,
                lineWidth: size * 0.1,
                size: size,
                showCompletionMark: false
            )

            // Center content
            VStack(spacing: 2) {
                // Redeemed value
                Text(formattedRedeemed)
                    .font(DesignSystem.Typography.valueMedium)
                    .fontWeight(.bold)
                    .foregroundStyle(DesignSystem.Colors.textPrimary)

                // Divider line
                Rectangle()
                    .fill(DesignSystem.Colors.textTertiary)
                    .frame(width: size * 0.35, height: 1)

                // Total value
                Text(formattedTotal)
                    .font(DesignSystem.Typography.body)
                    .foregroundStyle(DesignSystem.Colors.textSecondary)
            }

            // Celebration overlay
            if showCelebration {
                celebrationOverlay
            }
        }
        .frame(width: size, height: size)
    }

    // MARK: - Empty State

    private var emptyStateView: some View {
        ZStack {
            Circle()
                .stroke(
                    DesignSystem.Colors.neutral.opacity(0.2),
                    style: StrokeStyle(lineWidth: size * 0.1, lineCap: .round)
                )
                .frame(width: size, height: size)

            VStack(spacing: DesignSystem.Spacing.xs) {
                Image(systemName: "circle.dashed")
                    .font(.system(size: size * 0.2))
                    .foregroundStyle(DesignSystem.Colors.textTertiary)

                Text("No \(period.displayName.lowercased()) benefits")
                    .font(DesignSystem.Typography.footnote)
                    .foregroundStyle(DesignSystem.Colors.textSecondary)
                    .multilineTextAlignment(.center)
            }
            .frame(width: size * 0.6)
        }
    }

    // MARK: - Celebration

    private var celebrationOverlay: some View {
        ZStack {
            Circle()
                .fill(DesignSystem.Colors.success.opacity(0.1))
                .frame(width: size, height: size)

            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: size * 0.35))
                .foregroundStyle(DesignSystem.Colors.success)
                .transition(.scale.combined(with: .opacity))
        }
        .onAppear {
            // Trigger success haptic
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.success)

            // Auto-dismiss after delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                withAnimation {
                    showCelebration = false
                }
            }
        }
    }

    // MARK: - Helpers

    private var ringColors: [Color] {
        if progress.progress >= 1.0 {
            return [DesignSystem.Colors.success, DesignSystem.Colors.success.opacity(0.8)]
        } else if progress.progress >= 0.75 {
            return [DesignSystem.Colors.success, DesignSystem.Colors.success.opacity(0.7)]
        } else if progress.progress >= 0.5 {
            return [DesignSystem.Colors.warning, DesignSystem.Colors.success]
        } else {
            return [DesignSystem.Colors.primaryFallback, DesignSystem.Colors.primaryFallback.opacity(0.7)]
        }
    }

    private var formattedRedeemed: String {
        CurrencyFormatter.shared.format(progress.redeemedValue)
    }

    private var formattedTotal: String {
        CurrencyFormatter.shared.format(progress.totalValue)
    }

    /// Returns milestone value for haptic feedback (0.25, 0.5, 0.75, 1.0)
    private var progressMilestone: Int {
        let p = progress.progress
        if p >= 1.0 { return 4 }
        if p >= 0.75 { return 3 }
        if p >= 0.5 { return 2 }
        if p >= 0.25 { return 1 }
        return 0
    }

    private func checkForCelebration(oldValue: Double, newValue: Double) {
        // Trigger celebration when hitting 100% for the first time
        if newValue >= 1.0 && oldValue < 1.0 && !hasShownCelebration {
            hasShownCelebration = true
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                showCelebration = true
            }
        }
    }
}

// MARK: - Compact Ring View

/// Compact version of accomplishment ring for card detail views
struct CompactAccomplishmentRing: View {

    let progress: RingProgress
    var size: CGFloat = 100

    var body: some View {
        ZStack {
            AchievementRing(
                progress: progress.progress,
                gradientColors: [
                    DesignSystem.Colors.success,
                    DesignSystem.Colors.success.opacity(0.7)
                ],
                lineWidth: size * 0.08,
                size: size,
                showCompletionMark: false
            )

            VStack(spacing: 0) {
                Text("\(progress.usedCount)/\(progress.totalCount)")
                    .font(DesignSystem.Typography.headline)
                    .fontWeight(.bold)

                Text(progress.percentageText)
                    .font(DesignSystem.Typography.caption)
                    .foregroundStyle(DesignSystem.Colors.textSecondary)
            }
        }
    }
}

// MARK: - Preview

#Preview("Accomplishment Rings") {
    VStack(spacing: 32) {
        AccomplishmentRingsView(
            progress: RingProgress(
                redeemedValue: 240,
                totalValue: 300,
                usedCount: 4,
                totalCount: 5
            ),
            period: .monthly
        )

        AccomplishmentRingsView(
            progress: RingProgress(
                redeemedValue: 300,
                totalValue: 300,
                usedCount: 5,
                totalCount: 5
            ),
            period: .monthly,
            size: 150
        )

        AccomplishmentRingsView(
            progress: RingProgress(
                redeemedValue: 0,
                totalValue: 0,
                usedCount: 0,
                totalCount: 0
            ),
            period: .quarterly,
            size: 150
        )
    }
    .padding()
}

#Preview("Compact Ring") {
    CompactAccomplishmentRing(
        progress: RingProgress(
            redeemedValue: 150,
            totalValue: 200,
            usedCount: 3,
            totalCount: 4
        )
    )
    .padding()
}
