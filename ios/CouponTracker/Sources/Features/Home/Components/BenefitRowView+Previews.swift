//
//  BenefitRowView+Previews.swift
//  CouponTracker
//
//  Created: January 2026
//  Purpose: Preview providers for BenefitRowView components
//

import SwiftUI

// MARK: - Previews

#Preview("Unified - All 3 Styles") {
    let sampleBenefit = PreviewBenefit.expiring(in: 5, value: 50, name: "Travel Credit")

    ScrollView {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.lg) {
            // Standard Style
            Text("Standard Style")
                .font(DesignSystem.Typography.headline)
                .padding(.horizontal)

            BenefitRowView(
                benefit: sampleBenefit,
                configuration: BenefitRowConfiguration(
                    style: .standard,
                    showCard: true,
                    cardGradient: .platinum,
                    cardName: "Amex Platinum",
                    onMarkAsDone: { print("Done") },
                    onSnooze: nil,
                    onUndo: nil,
                    onTap: { print("Tap") }
                )
            )
            .padding(.horizontal)

            Divider()
                .padding(.vertical)

            // Compact Style (using configuration)
            Text("Compact Style (via configuration)")
                .font(DesignSystem.Typography.headline)
                .padding(.horizontal)

            BenefitRowView(
                benefit: sampleBenefit,
                configuration: .compact(
                    cardName: "Amex Platinum",
                    cardGradient: .platinum,
                    onMarkAsDone: { print("Done") },
                    onTap: { print("Tap") }
                )
            )
            .padding(.horizontal)

            Divider()
                .padding(.vertical)

            // Compact Style (using wrapper)
            Text("Compact Style (via wrapper)")
                .font(DesignSystem.Typography.headline)
                .padding(.horizontal)

            CompactBenefitRowView(
                benefit: sampleBenefit,
                cardName: "Sapphire Reserve",
                cardGradient: .sapphire,
                onMarkAsDone: { print("Done") }
            )
            .padding(.horizontal)

            Divider()
                .padding(.vertical)

            // Swipeable (shown in List)
            Text("Swipeable Style (swipe to see actions)")
                .font(DesignSystem.Typography.headline)
                .padding(.horizontal)

            List {
                SwipeableBenefitRowView(
                    benefit: sampleBenefit,
                    cardGradient: .gold,
                    showCard: true,
                    cardName: "Amex Gold",
                    onMarkAsDone: { print("Done") },
                    onSnooze: { days in print("Snooze \(days)") }
                )
            }
            .listStyle(.plain)
            .frame(height: 100)
        }
        .padding(.vertical)
    }
}

#Preview("Benefit Row - All States") {
    List {
        Section("Available - Safe (8+ days)") {
            BenefitRowView(
                benefit: PreviewBenefit.expiring(in: 15, value: 100, name: "Travel Credit"),
                onMarkAsDone: { print("Done tapped") },
                onSnooze: { days in print("Snooze \(days) days") }
            )
        }

        Section("Available - Warning (4-7 days)") {
            BenefitRowView(
                benefit: PreviewBenefit.expiring(in: 5, value: 50, name: "Saks Credit"),
                onMarkAsDone: { print("Done tapped") }
            )
        }

        Section("Available - Urgent (1-3 days)") {
            BenefitRowView(
                benefit: PreviewBenefit.expiring(in: 2, value: 15, name: "Uber Credit"),
                onMarkAsDone: { print("Done tapped") }
            )
        }

        Section("Available - Expires Today") {
            BenefitRowView(
                benefit: PreviewBenefit.expiring(in: 0, value: 20, name: "Entertainment Credit"),
                onMarkAsDone: { print("Done tapped") }
            )
        }

        Section("Used") {
            BenefitRowView(
                benefit: PreviewBenefit.used(value: 10, name: "Dining Credit")
            )
        }

        Section("Expired") {
            BenefitRowView(
                benefit: PreviewBenefit.expired(value: 100, name: "Hotel Credit")
            )
        }
    }
    .listStyle(.insetGrouped)
}

#Preview("Benefit Row - With Card Info") {
    List {
        BenefitRowView(
            benefit: PreviewData.uberCredit,
            cardGradient: .platinum,
            showCard: true,
            cardName: "Amex Platinum",
            onMarkAsDone: { }
        )

        BenefitRowView(
            benefit: PreviewData.travelCredit,
            cardGradient: .sapphire,
            showCard: true,
            cardName: "Sapphire Reserve",
            onMarkAsDone: { }
        )
    }
    .listStyle(.insetGrouped)
}

#Preview("Swipeable Benefit Rows") {
    List {
        ForEach(PreviewData.amexPlatinum.benefits) { benefit in
            SwipeableBenefitRowView(
                benefit: benefit,
                cardGradient: .platinum,
                showCard: true,
                cardName: "Amex Platinum",
                onMarkAsDone: { print("Marked done: \(benefit.name)") },
                onSnooze: { days in print("Snoozed \(days) days: \(benefit.name)") }
            )
        }
    }
    .listStyle(.plain)
}

#Preview("Compact Benefit Rows") {
    VStack(spacing: DesignSystem.Spacing.md) {
        CompactBenefitRowView(
            benefit: PreviewData.uberCredit,
            cardName: "Amex Platinum",
            cardGradient: .platinum,
            onMarkAsDone: { }
        )

        CompactBenefitRowView(
            benefit: PreviewData.saksCredit,
            cardName: "Amex Platinum",
            cardGradient: .platinum,
            onMarkAsDone: { }
        )

        CompactBenefitRowView(
            benefit: PreviewData.travelCredit,
            cardName: "Sapphire Reserve",
            cardGradient: .sapphire,
            onMarkAsDone: { }
        )
    }
    .padding()
    .background(DesignSystem.Colors.backgroundSecondary)
}

#Preview("Benefit Row - Dark Mode") {
    List {
        BenefitRowView(
            benefit: PreviewBenefit.expiring(in: 2, value: 15, name: "Uber Credit"),
            onMarkAsDone: { }
        )

        BenefitRowView(
            benefit: PreviewBenefit.used(value: 10, name: "Dining Credit")
        )

        BenefitRowView(
            benefit: PreviewBenefit.expired(value: 100, name: "Hotel Credit")
        )
    }
    .listStyle(.insetGrouped)
    .preferredColorScheme(.dark)
}
