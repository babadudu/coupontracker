//
//  BenefitSection.swift
//  CouponTracker
//
//  Created: January 20, 2026
//
//  Purpose: A section component containing a list of benefits with a collapsible header.
//           Used in CardDetailView to group benefits by status (available, used, expired).
//           Extracted from CardDetailView for reusability.
//

import SwiftUI

// MARK: - Benefit Section

/// A section containing a list of benefits with a header
struct BenefitSection: View {

    let title: String
    let subtitle: String?
    let benefits: [PreviewBenefit]
    var cardGradient: DesignSystem.CardGradient = .obsidian
    var onMarkAsDone: ((PreviewBenefit) -> Void)? = nil
    var onSnooze: ((PreviewBenefit, Int) -> Void)? = nil
    var onUndo: ((PreviewBenefit) -> Void)? = nil
    var isCollapsible: Bool = false

    @Binding var expandedBenefitId: UUID?
    @State private var isExpanded: Bool = true

    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
            // Section header
            sectionHeader

            // Benefits list
            if isExpanded || !isCollapsible {
                VStack(spacing: DesignSystem.Spacing.sm) {
                    ForEach(benefits) { benefit in
                        BenefitRowView(
                            benefit: benefit,
                            cardGradient: cardGradient,
                            showCard: false,
                            onMarkAsDone: onMarkAsDone != nil ? { onMarkAsDone?(benefit) } : nil,
                            onSnooze: onSnooze != nil ? { days in onSnooze?(benefit, days) } : nil,
                            onUndo: onUndo != nil ? { onUndo?(benefit) } : nil,
                            onTap: {
                                withAnimation(DesignSystem.Animation.quickSpring) {
                                    if expandedBenefitId == benefit.id {
                                        expandedBenefitId = nil
                                    } else {
                                        expandedBenefitId = benefit.id
                                    }
                                }
                            }
                        )
                        .background(
                            RoundedRectangle(cornerRadius: DesignSystem.Sizing.buttonCornerRadius)
                                .fill(DesignSystem.Colors.backgroundSecondary)
                        )

                        // Expanded detail (if this benefit is expanded)
                        if expandedBenefitId == benefit.id {
                            ExpandedBenefitDetail(
                                benefit: benefit,
                                onMarkAsDone: onMarkAsDone != nil ? { onMarkAsDone?(benefit) } : nil,
                                onSnooze: onSnooze != nil ? { days in onSnooze?(benefit, days) } : nil,
                                onUndo: onUndo != nil ? { onUndo?(benefit) } : nil
                            )
                            .transition(.asymmetric(
                                insertion: .move(edge: .top).combined(with: .opacity),
                                removal: .opacity
                            ))
                        }
                    }
                }
            }
        }
        .accessibilityElement(children: .contain)
    }

    @ViewBuilder
    private var sectionHeader: some View {
        Button(action: {
            if isCollapsible {
                withAnimation(DesignSystem.Animation.spring) {
                    isExpanded.toggle()
                }
            }
        }) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(DesignSystem.Typography.title3)
                        .foregroundStyle(DesignSystem.Colors.textPrimary)

                    if let subtitle {
                        Text(subtitle)
                            .font(DesignSystem.Typography.caption)
                            .foregroundStyle(DesignSystem.Colors.textSecondary)
                    }
                }

                Spacer()

                if isCollapsible {
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(DesignSystem.Colors.textSecondary)
                }
            }
        }
        .buttonStyle(.plain)
        .disabled(!isCollapsible)
    }
}

// MARK: - Previews

#Preview("Benefit Section") {
    struct PreviewWrapper: View {
        @State private var expandedId: UUID? = nil

        var body: some View {
            ScrollView {
                VStack(spacing: DesignSystem.Spacing.xl) {
                    BenefitSection(
                        title: "Available Benefits",
                        subtitle: "$454 remaining",
                        benefits: PreviewData.amexPlatinum.availableBenefits,
                        cardGradient: .platinum,
                        onMarkAsDone: { _ in },
                        onSnooze: { _, _ in },
                        expandedBenefitId: $expandedId
                    )

                    BenefitSection(
                        title: "Used This Period",
                        subtitle: "$20 redeemed",
                        benefits: PreviewData.amexPlatinum.usedBenefits,
                        cardGradient: .platinum,
                        expandedBenefitId: $expandedId
                    )
                }
                .padding()
            }
        }
    }

    return PreviewWrapper()
}
