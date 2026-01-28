//
//  InsightBannerView.swift
//  CouponTracker
//
//  Created: January 18, 2026
//
//  Purpose: A contextual banner that displays smart insights about the user's
//           benefits, such as urgent expirations, monthly success, or available value.
//
//  ACCESSIBILITY:
//  - Full VoiceOver support with descriptive labels
//  - Minimum 44pt touch target for dismiss button
//
//  USAGE:
//  InsightBannerView(insight: .urgentExpiring(value: 50, count: 2))
//  InsightBannerView(insight: viewModel.currentInsight, onDismiss: { ... })

import SwiftUI

// MARK: - Insight Banner View

/// A contextual banner displaying dashboard insights
struct InsightBannerView: View {

    // MARK: - Properties

    let insight: DashboardInsight
    var onDismiss: (() -> Void)?
    var onTap: (() -> Void)?

    // MARK: - Body

    var body: some View {
        Button(action: {
            onTap?()
        }) {
            HStack(spacing: DesignSystem.Spacing.md) {
                // Icon
                Image(systemName: insight.icon)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(DesignSystem.Colors.onColor)
                    .frame(width: 32, height: 32)
                    .background(
                        Circle()
                            .fill(.white.opacity(0.2))
                    )

                // Message
                Text(insight.message)
                    .font(DesignSystem.Typography.subhead)
                    .foregroundStyle(DesignSystem.Colors.onColor)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)

                Spacer(minLength: 0)

                // Dismiss button (if callback provided)
                if onDismiss != nil {
                    Button(action: {
                        withAnimation(DesignSystem.Animation.quickSpring) {
                            onDismiss?()
                        }
                    }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(DesignSystem.Colors.onColor.opacity(0.7))
                            .frame(width: DesignSystem.Sizing.minTouchTarget, height: DesignSystem.Sizing.minTouchTarget)
                    }
                    .accessibilityLabel("Dismiss banner")
                } else {
                    // Chevron for tap action
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(DesignSystem.Colors.onColor.opacity(0.7))
                }
            }
            .padding(.horizontal, DesignSystem.Spacing.lg)
            .padding(.vertical, DesignSystem.Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: DesignSystem.Sizing.cardCornerRadius)
                    .fill(insight.backgroundColor)
            )
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(insight.message)
        .accessibilityHint(onTap != nil ? "Double tap to view details" : "")
    }
}

// MARK: - Previews

#Preview("Insight Banner - Urgent Expiring") {
    VStack(spacing: DesignSystem.Spacing.lg) {
        InsightBannerView(
            insight: .urgentExpiring(value: 50, count: 2),
            onDismiss: { print("Dismissed") },
            onTap: { print("Tapped") }
        )

        InsightBannerView(
            insight: .urgentExpiring(value: 15, count: 1),
            onTap: { print("Tapped") }
        )
    }
    .padding()
    .background(DesignSystem.Colors.backgroundPrimary)
}

#Preview("Insight Banner - Monthly Success") {
    VStack(spacing: DesignSystem.Spacing.lg) {
        InsightBannerView(
            insight: .monthlySuccess(value: 250),
            onDismiss: { print("Dismissed") }
        )
    }
    .padding()
    .background(DesignSystem.Colors.backgroundPrimary)
}

#Preview("Insight Banner - Available Value") {
    VStack(spacing: DesignSystem.Spacing.lg) {
        InsightBannerView(
            insight: .availableValue(value: 847),
            onTap: { print("Tapped") }
        )
    }
    .padding()
    .background(DesignSystem.Colors.backgroundPrimary)
}

#Preview("Insight Banner - Onboarding") {
    VStack(spacing: DesignSystem.Spacing.lg) {
        InsightBannerView(
            insight: .onboarding,
            onTap: { print("Tapped") }
        )
    }
    .padding()
    .background(DesignSystem.Colors.backgroundPrimary)
}

#Preview("Insight Banner - All Types") {
    ScrollView {
        VStack(spacing: DesignSystem.Spacing.lg) {
            InsightBannerView(insight: .urgentExpiring(value: 50, count: 2))
            InsightBannerView(insight: .monthlySuccess(value: 250))
            InsightBannerView(insight: .availableValue(value: 847))
            InsightBannerView(insight: .onboarding)
        }
        .padding()
    }
    .background(DesignSystem.Colors.backgroundPrimary)
}

#Preview("Insight Banner - Dark Mode") {
    VStack(spacing: DesignSystem.Spacing.lg) {
        InsightBannerView(insight: .urgentExpiring(value: 50, count: 2))
        InsightBannerView(insight: .monthlySuccess(value: 250))
        InsightBannerView(insight: .availableValue(value: 847))
    }
    .padding()
    .background(DesignSystem.Colors.backgroundPrimary)
    .preferredColorScheme(.dark)
}
