//
//  ExpiringBenefitsSectionView.swift
//  CouponTracker
//
//  Created: January 17, 2026
//
//  Purpose: Enhanced expiring benefits section for the dashboard that groups
//           benefits by time period (Today, This Week, This Month) and provides
//           navigation to see all expiring benefits.
//
//  ACCESSIBILITY:
//  - VoiceOver support with section announcements
//  - Period headers announced as section headers
//  - All interactive elements have minimum 44pt touch targets
//
//  USAGE:
//  ExpiringBenefitsSectionView(
//      benefits: expiringBenefits,
//      onBenefitTap: { benefit in ... },
//      onSeeAll: { ... }
//  )
//

import SwiftUI

// MARK: - Expiring Benefits Section View

/// Dashboard section showing benefits grouped by expiration timeframe
struct ExpiringBenefitsSectionView: View {

    // MARK: - Properties

    let benefits: [any BenefitDisplayable]
    var onBenefitTap: ((any BenefitDisplayable) -> Void)?
    var onSeeAll: (() -> Void)?
    var onMarkDone: ((any BenefitDisplayable) -> Void)?

    // MARK: - State

    @State private var expandedToday = true
    @State private var expandedThisWeek = true
    @State private var expandedThisMonth = false

    // MARK: - Constants

    private let maxDisplayedBenefits = 5

    // MARK: - Computed Properties

    /// Benefits expiring today (0 days remaining)
    private var todayBenefits: [any BenefitDisplayable] {
        benefits.filter { $0.daysRemaining == 0 }
    }

    /// Benefits expiring this week (1-7 days remaining)
    private var thisWeekBenefits: [any BenefitDisplayable] {
        benefits.filter { $0.daysRemaining > 0 && $0.daysRemaining <= 7 }
    }

    /// Benefits expiring this month (8-30 days remaining)
    private var thisMonthBenefits: [any BenefitDisplayable] {
        benefits.filter { $0.daysRemaining > 7 && $0.daysRemaining <= 30 }
    }

    /// Total count of all expiring benefits
    private var totalCount: Int {
        benefits.count
    }

    /// Whether to show the "See All" button (always show if benefits exist and callback provided)
    private var shouldShowSeeAll: Bool {
        totalCount > 0 && onSeeAll != nil
    }

    /// Benefits to display (limited to maxDisplayedBenefits)
    private var displayedBenefits: [any BenefitDisplayable] {
        Array(benefits.prefix(maxDisplayedBenefits))
    }

    // MARK: - Body

    var body: some View {
        if benefits.isEmpty {
            emptyStateView
        } else {
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
                // Section header with count badge
                sectionHeader

                // Grouped benefits
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
                    // Today section
                    if !todayBenefits.isEmpty {
                        collapsibleSection(
                            title: "Today",
                            benefits: todayBenefits,
                            isExpanded: $expandedToday
                        )
                    }

                    // This Week section
                    if !thisWeekBenefits.isEmpty {
                        collapsibleSection(
                            title: "This Week",
                            benefits: thisWeekBenefits,
                            isExpanded: $expandedThisWeek
                        )
                    }

                    // This Month section
                    if !thisMonthBenefits.isEmpty {
                        collapsibleSection(
                            title: "This Month",
                            benefits: thisMonthBenefits,
                            isExpanded: $expandedThisMonth
                        )
                    }
                }

                // See All button
                if shouldShowSeeAll {
                    seeAllButton
                }
            }
            .accessibilityElement(children: .contain)
            .accessibilityLabel("Expiring soon, \(totalCount) benefits")
        }
    }

    // MARK: - Section Header

    @ViewBuilder
    private var sectionHeader: some View {
        HStack(alignment: .center, spacing: DesignSystem.Spacing.sm) {
            Text("Expiring Soon")
                .font(DesignSystem.Typography.title3)
                .foregroundStyle(DesignSystem.Colors.textPrimary)

            // Count badge
            Text("\(totalCount)")
                .font(DesignSystem.Typography.badge)
                .foregroundStyle(DesignSystem.Colors.onColor)
                .padding(.horizontal, DesignSystem.Spacing.sm)
                .padding(.vertical, DesignSystem.Spacing.xs - 2)
                .background(
                    Capsule()
                        .fill(DesignSystem.Colors.danger)
                )

            Spacer()
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Expiring soon section, \(totalCount) benefits")
    }

    // MARK: - Collapsible Section

    @ViewBuilder
    private func collapsibleSection(title: String, benefits: [any BenefitDisplayable], isExpanded: Binding<Bool>) -> some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
            // Collapsible header
            Button(action: {
                withAnimation(DesignSystem.Animation.quickSpring) {
                    isExpanded.wrappedValue.toggle()
                }
            }) {
                HStack {
                    Text(title)
                        .font(DesignSystem.Typography.subhead)
                        .foregroundStyle(DesignSystem.Colors.textSecondary)

                    Text("(\(benefits.count))")
                        .font(DesignSystem.Typography.caption)
                        .foregroundStyle(DesignSystem.Colors.textTertiary)

                    Spacer()

                    Image(systemName: isExpanded.wrappedValue ? "chevron.up" : "chevron.down")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(DesignSystem.Colors.textTertiary)
                }
                .padding(.horizontal, DesignSystem.Spacing.sm)
                .padding(.vertical, DesignSystem.Spacing.xs)
            }
            .buttonStyle(.plain)
            .accessibilityAddTraits(.isHeader)
            .accessibilityLabel("\(title), \(benefits.count) benefits, \(isExpanded.wrappedValue ? "expanded" : "collapsed")")
            .accessibilityHint("Double tap to \(isExpanded.wrappedValue ? "collapse" : "expand")")

            // Benefits in this period (animated)
            if isExpanded.wrappedValue {
                ForEach(Array(benefits.prefix(maxDisplayedBenefits)), id: \.id) { benefit in
                    benefitRow(for: benefit)
                        .transition(.opacity.combined(with: .move(edge: .top)))
                }
            }
        }
    }

    // MARK: - Benefit Row

    @ViewBuilder
    private func benefitRow(for benefit: any BenefitDisplayable) -> some View {
        Button(action: {
            onBenefitTap?(benefit)
        }) {
            HStack(spacing: DesignSystem.Spacing.md) {
                // Urgency icon
                Image(systemName: urgencyIcon(for: benefit))
                    .font(.system(size: DesignSystem.Sizing.iconMedium, weight: .medium))
                    .foregroundStyle(urgencyColor(for: benefit))
                    .frame(width: DesignSystem.Sizing.iconMedium, height: DesignSystem.Sizing.iconMedium)

                // Benefit info
                VStack(alignment: .leading, spacing: 2) {
                    // Name and value
                    HStack {
                        Text(benefit.name)
                            .font(DesignSystem.Typography.subhead)
                            .foregroundStyle(DesignSystem.Colors.textPrimary)
                            .lineLimit(1)

                        Spacer()

                        Text(benefit.formattedValue)
                            .font(DesignSystem.Typography.valueSmall)
                            .foregroundStyle(DesignSystem.Colors.textPrimary)
                    }

                    // Days remaining
                    Text(benefit.urgencyText)
                        .font(DesignSystem.Typography.caption)
                        .foregroundStyle(urgencyColor(for: benefit))
                }

                // Chevron
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(DesignSystem.Colors.textTertiary)
            }
            .padding(.horizontal, DesignSystem.Spacing.lg)
            .padding(.vertical, DesignSystem.Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: DesignSystem.Sizing.buttonCornerRadius)
                    .fill(DesignSystem.Colors.backgroundTertiary)
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(benefit.formattedValue) \(benefit.name), \(benefit.urgencyText)")
        .accessibilityHint("Double tap to view details")
    }

    // MARK: - See All Button

    @ViewBuilder
    private var seeAllButton: some View {
        Button(action: {
            onSeeAll?()
        }) {
            HStack {
                Spacer()

                Text(totalCount > maxDisplayedBenefits ? "See All \(totalCount) Benefits" : "View All Expiring")
                    .font(DesignSystem.Typography.subhead)
                    .foregroundStyle(DesignSystem.Colors.primaryFallback)

                Image(systemName: "arrow.right")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(DesignSystem.Colors.primaryFallback)

                Spacer()
            }
            .padding(.vertical, DesignSystem.Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: DesignSystem.Sizing.buttonCornerRadius)
                    .stroke(DesignSystem.Colors.primaryFallback, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("View all \(totalCount) expiring benefits")
        .accessibilityHint("Double tap to view complete list")
    }

    // MARK: - Empty State

    @ViewBuilder
    private var emptyStateView: some View {
        Button(action: {
            onSeeAll?()
        }) {
            VStack(spacing: DesignSystem.Spacing.md) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 40))
                    .foregroundStyle(DesignSystem.Colors.success)

                VStack(spacing: DesignSystem.Spacing.xs) {
                    Text("All Clear!")
                        .font(DesignSystem.Typography.headline)
                        .foregroundStyle(DesignSystem.Colors.textPrimary)

                    Text("No benefits expiring soon")
                        .font(DesignSystem.Typography.subhead)
                        .foregroundStyle(DesignSystem.Colors.textSecondary)

                    if onSeeAll != nil {
                        Text("Tap to view all benefits")
                            .font(DesignSystem.Typography.caption)
                            .foregroundStyle(DesignSystem.Colors.primaryFallback)
                            .padding(.top, DesignSystem.Spacing.xs)
                    }
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, DesignSystem.Spacing.xl)
            .background(
                RoundedRectangle(cornerRadius: DesignSystem.Sizing.buttonCornerRadius)
                    .fill(DesignSystem.Colors.backgroundSecondary)
            )
        }
        .buttonStyle(.plain)
        .disabled(onSeeAll == nil)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("All clear. No benefits expiring soon.")
        .accessibilityHint(onSeeAll != nil ? "Double tap to view all benefits" : "")
    }

    // MARK: - Helper Methods

    /// Returns the appropriate icon for the benefit's urgency level
    private func urgencyIcon(for benefit: any BenefitDisplayable) -> String {
        switch benefit.daysRemaining {
        case 0:
            return "exclamationmark.circle.fill"
        case 1...3:
            return "exclamationmark.circle.fill"
        case 4...7:
            return "clock"
        default:
            return "calendar"
        }
    }

    /// Returns the appropriate color for the benefit's urgency level
    private func urgencyColor(for benefit: any BenefitDisplayable) -> Color {
        DesignSystem.Colors.urgencyColor(daysRemaining: benefit.daysRemaining)
    }
}

// MARK: - Previews

#Preview("Expiring Benefits - With Benefits") {
    ScrollView {
        VStack(spacing: DesignSystem.Spacing.xl) {
            ExpiringBenefitsSectionView(
                benefits: [
                    PreviewBenefit.expiring(in: 0, value: 15, name: "Uber Credit"),
                    PreviewBenefit.expiring(in: 0, value: 10, name: "Dining Credit"),
                    PreviewBenefit.expiring(in: 2, value: 20, name: "Entertainment Credit"),
                    PreviewBenefit.expiring(in: 5, value: 50, name: "Saks Credit"),
                    PreviewBenefit.expiring(in: 7, value: 100, name: "Travel Credit"),
                    PreviewBenefit.expiring(in: 15, value: 25, name: "Airline Credit"),
                    PreviewBenefit.expiring(in: 20, value: 30, name: "Hotel Credit")
                ],
                onBenefitTap: { benefit in
                    print("Tapped: \(benefit.name)")
                },
                onSeeAll: {
                    print("See all tapped")
                }
            )
        }
        .padding(DesignSystem.Spacing.lg)
    }
    .background(DesignSystem.Colors.backgroundPrimary)
}

#Preview("Expiring Benefits - Few Benefits") {
    ScrollView {
        VStack(spacing: DesignSystem.Spacing.xl) {
            ExpiringBenefitsSectionView(
                benefits: [
                    PreviewBenefit.expiring(in: 0, value: 15, name: "Uber Credit"),
                    PreviewBenefit.expiring(in: 5, value: 50, name: "Saks Credit"),
                    PreviewBenefit.expiring(in: 20, value: 100, name: "Travel Credit")
                ],
                onBenefitTap: { benefit in
                    print("Tapped: \(benefit.name)")
                }
            )
        }
        .padding(DesignSystem.Spacing.lg)
    }
    .background(DesignSystem.Colors.backgroundPrimary)
}

#Preview("Expiring Benefits - Empty State") {
    ScrollView {
        VStack(spacing: DesignSystem.Spacing.xl) {
            ExpiringBenefitsSectionView(
                benefits: []
            )
        }
        .padding(DesignSystem.Spacing.lg)
    }
    .background(DesignSystem.Colors.backgroundPrimary)
}

#Preview("Expiring Benefits - Today Only") {
    ScrollView {
        VStack(spacing: DesignSystem.Spacing.xl) {
            ExpiringBenefitsSectionView(
                benefits: [
                    PreviewBenefit.expiring(in: 0, value: 15, name: "Uber Credit"),
                    PreviewBenefit.expiring(in: 0, value: 10, name: "Dining Credit"),
                    PreviewBenefit.expiring(in: 0, value: 20, name: "Entertainment Credit")
                ],
                onBenefitTap: { benefit in
                    print("Tapped: \(benefit.name)")
                }
            )
        }
        .padding(DesignSystem.Spacing.lg)
    }
    .background(DesignSystem.Colors.backgroundPrimary)
}

#Preview("Expiring Benefits - Dark Mode") {
    ScrollView {
        VStack(spacing: DesignSystem.Spacing.xl) {
            ExpiringBenefitsSectionView(
                benefits: [
                    PreviewBenefit.expiring(in: 0, value: 15, name: "Uber Credit"),
                    PreviewBenefit.expiring(in: 2, value: 20, name: "Entertainment Credit"),
                    PreviewBenefit.expiring(in: 5, value: 50, name: "Saks Credit"),
                    PreviewBenefit.expiring(in: 15, value: 100, name: "Travel Credit")
                ],
                onBenefitTap: { benefit in
                    print("Tapped: \(benefit.name)")
                },
                onSeeAll: {
                    print("See all tapped")
                }
            )
        }
        .padding(DesignSystem.Spacing.lg)
    }
    .background(DesignSystem.Colors.backgroundPrimary)
    .preferredColorScheme(.dark)
}
