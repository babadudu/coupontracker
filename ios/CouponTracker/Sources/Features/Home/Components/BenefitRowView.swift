//
//  BenefitRowView.swift
//  CouponTracker
//
//  Created: January 17, 2026
//
//  Purpose: Displays an individual benefit within a card's benefit list.
//           Shows benefit name, value, status indicator, expiration info,
//           and provides quick actions for marking as done or snoozing.
//
//  ACCESSIBILITY:
//  - Full VoiceOver support with descriptive labels and hints
//  - Status conveyed through icons and text, not just color
//  - Minimum 44pt touch targets for all interactive elements
//  - Swipe actions accessible via VoiceOver custom actions
//
//  USAGE:
//  BenefitRowView(benefit: myBenefit, onMarkAsDone: { ... })
//

import SwiftUI

// MARK: - Benefit Row View

/// A list row displaying a single benefit with status, value, and actions.
/// Supports multiple styles via configuration for different contexts.
///
/// Usage:
/// ```swift
/// // Standard style (default)
/// BenefitRowView(benefit: myBenefit, onMarkAsDone: { ... })
///
/// // With configuration
/// BenefitRowView(benefit: myBenefit, configuration: .compact(cardName: "Amex"))
/// ```
struct BenefitRowView: View {

    // MARK: - Properties

    let benefit: PreviewBenefit
    let configuration: BenefitRowConfiguration

    // Legacy initializer properties (for backwards compatibility)
    private var cardGradient: DesignSystem.CardGradient? { configuration.cardGradient }
    private var showCard: Bool { configuration.showCard }
    private var cardName: String? { configuration.cardName }
    private var onMarkAsDone: (() -> Void)? { configuration.onMarkAsDone }
    private var onSnooze: ((Int) -> Void)? { configuration.onSnooze }
    private var onUndo: (() -> Void)? { configuration.onUndo }
    private var onTap: (() -> Void)? { configuration.onTap }

    // MARK: - State

    @State private var isPressed = false
    @State private var showSnoozeOptions = false

    // MARK: - Initializers

    /// Creates a benefit row with full configuration control.
    init(benefit: PreviewBenefit, configuration: BenefitRowConfiguration) {
        self.benefit = benefit
        self.configuration = configuration
    }

    /// Legacy initializer for backwards compatibility.
    init(
        benefit: PreviewBenefit,
        cardGradient: DesignSystem.CardGradient? = nil,
        showCard: Bool = false,
        cardName: String? = nil,
        onMarkAsDone: (() -> Void)? = nil,
        onSnooze: ((Int) -> Void)? = nil,
        onUndo: (() -> Void)? = nil,
        onTap: (() -> Void)? = nil
    ) {
        self.benefit = benefit
        self.configuration = BenefitRowConfiguration(
            style: .standard,
            showCard: showCard,
            cardGradient: cardGradient,
            cardName: cardName,
            onMarkAsDone: onMarkAsDone,
            onSnooze: onSnooze,
            onUndo: onUndo,
            onTap: onTap
        )
    }

    // MARK: - Body

    var body: some View {
        switch configuration.style {
        case .standard, .swipeable:
            standardBody
        case .compact:
            compactBody
        }
    }

    // MARK: - Standard Body

    @ViewBuilder
    private var standardBody: some View {
        Button(action: { onTap?() }) {
            rowContent
        }
        .buttonStyle(BenefitRowButtonStyle())
        .background(urgencyBackground)
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Sizing.buttonCornerRadius))
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityHint(accessibilityHint)
        .accessibilityAddTraits(accessibilityTraits)
        .accessibilityActions {
            if benefit.status == .available {
                Button("Mark as done") {
                    onMarkAsDone?()
                }
                Button("Snooze 1 day") {
                    onSnooze?(1)
                }
                Button("Snooze 1 week") {
                    onSnooze?(7)
                }
            } else if benefit.status == .used, onUndo != nil {
                Button("Undo mark as used") {
                    onUndo?()
                }
            }
        }
        .confirmationDialog("Snooze Reminder", isPresented: $showSnoozeOptions) {
            Button("1 Day") { onSnooze?(1) }
            Button("3 Days") { onSnooze?(3) }
            Button("1 Week") { onSnooze?(7) }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Snooze the reminder for this benefit?")
        }
    }

    // MARK: - Compact Body

    @ViewBuilder
    private var compactBody: some View {
        HStack(spacing: DesignSystem.Spacing.md) {
            // Card mini icon
            if let gradient = cardGradient {
                RoundedRectangle(cornerRadius: 3)
                    .fill(gradient.gradient)
                    .frame(width: 24, height: 16)
            }

            // Benefit info
            VStack(alignment: .leading, spacing: 2) {
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

                HStack {
                    if let cardName {
                        Text(cardName)
                            .font(DesignSystem.Typography.caption)
                            .foregroundStyle(DesignSystem.Colors.textTertiary)
                            .lineLimit(1)
                    }

                    Spacer()

                    Text(benefit.urgencyText)
                        .font(DesignSystem.Typography.caption)
                        .foregroundStyle(
                            DesignSystem.Colors.urgencyColor(daysRemaining: benefit.daysRemaining)
                        )
                }
            }

            // Action button
            if onMarkAsDone != nil {
                Button(action: { onMarkAsDone?() }) {
                    Image(systemName: "checkmark.circle")
                        .font(.system(size: 22))
                        .foregroundStyle(DesignSystem.Colors.primaryFallback)
                }
                .buttonStyle(.plain)
                .frame(width: DesignSystem.Sizing.minTouchTarget,
                       height: DesignSystem.Sizing.minTouchTarget)
            }
        }
        .padding(.horizontal, DesignSystem.Spacing.lg)
        .padding(.vertical, DesignSystem.Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: DesignSystem.Sizing.buttonCornerRadius)
                .fill(DesignSystem.Colors.backgroundTertiary)
        )
        .onTapGesture {
            onTap?()
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(compactAccessibilityLabel)
        .accessibilityHint("Double tap to view details")
    }

    private var compactAccessibilityLabel: String {
        var label = "\(benefit.formattedValue) \(benefit.name)"
        if let cardName {
            label += " from \(cardName)"
        }
        label += ", \(benefit.urgencyText)"
        return label
    }

    // MARK: - Row Content

    @ViewBuilder
    private var rowContent: some View {
        HStack(alignment: .center, spacing: DesignSystem.Spacing.md) {
            // Status icon
            statusIcon

            // Benefit info
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                // Name row
                HStack {
                    Text(benefit.name)
                        .font(DesignSystem.Typography.headline)
                        .foregroundStyle(primaryTextColor)
                        .strikethrough(benefit.status == .expired)

                    Spacer()

                    // Value
                    Text(benefit.formattedValue)
                        .font(DesignSystem.Typography.valueSmall)
                        .foregroundStyle(valueTextColor)
                }

                // Secondary info row
                HStack {
                    // Card mini icon and name (if showing card)
                    if showCard, let cardName {
                        HStack(spacing: DesignSystem.Spacing.xs) {
                            if let gradient = cardGradient {
                                RoundedRectangle(cornerRadius: 2)
                                    .fill(gradient.gradient)
                                    .frame(width: 16, height: 10)
                            }
                            Text(cardName)
                                .font(DesignSystem.Typography.caption)
                                .foregroundStyle(DesignSystem.Colors.textSecondary)
                        }
                    }

                    // Expiration or status text
                    expirationBadge

                    Spacer()
                }
            }

            // Chevron disclosure indicator (tap to expand)
            if onTap != nil {
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(DesignSystem.Colors.textTertiary)
                    .frame(width: 20, height: 20)
            }
        }
        .padding(.horizontal, DesignSystem.Spacing.lg)
        .padding(.vertical, DesignSystem.Spacing.rowVerticalPadding)
        .contentShape(Rectangle())
    }

    // MARK: - Status Icon

    @ViewBuilder
    private var statusIcon: some View {
        if benefit.status == .available, onMarkAsDone != nil {
            // Tappable status icon - marks benefit as done
            Button(action: { onMarkAsDone?() }) {
                Image(systemName: statusIconName)
                    .font(.system(size: DesignSystem.Sizing.iconMedium, weight: .medium))
                    .foregroundStyle(statusIconColor)
                    .frame(width: DesignSystem.Sizing.minTouchTarget, height: DesignSystem.Sizing.minTouchTarget)
                    .contentShape(Circle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Mark \(benefit.name) as done")
            .accessibilityHint("Double tap to mark this benefit as used")
        } else {
            // Non-interactive status indicator
            Image(systemName: statusIconName)
                .font(.system(size: DesignSystem.Sizing.iconMedium, weight: .medium))
                .foregroundStyle(statusIconColor)
                .frame(width: DesignSystem.Sizing.iconMedium, height: DesignSystem.Sizing.iconMedium)
                .accessibilityHidden(true)
        }
    }

    private var statusIconName: String {
        switch benefit.status {
        case .available:
            if benefit.daysRemaining <= 0 {
                return "exclamationmark.circle.fill"
            } else if benefit.daysRemaining <= 3 {
                return "exclamationmark.circle.fill"
            } else if benefit.daysRemaining <= 7 {
                return "clock"
            }
            return "circle"
        case .used:
            return "checkmark.seal.fill"
        case .expired:
            return "xmark.circle"
        }
    }

    private var statusIconColor: Color {
        switch benefit.status {
        case .available:
            return DesignSystem.Colors.urgencyColor(daysRemaining: benefit.daysRemaining)
        case .used:
            return DesignSystem.Colors.success
        case .expired:
            return DesignSystem.Colors.neutral
        }
    }

    // MARK: - Expiration Badge

    @ViewBuilder
    private var expirationBadge: some View {
        if benefit.status == .available {
            HStack(spacing: DesignSystem.Spacing.xs) {
                if benefit.daysRemaining <= 7 {
                    Image(systemName: "clock")
                        .font(.system(size: 10))
                }
                Text(benefit.urgencyText)
                    .font(DesignSystem.Typography.caption)
            }
            .foregroundStyle(expirationTextColor)
            .padding(.horizontal, DesignSystem.Spacing.sm)
            .padding(.vertical, DesignSystem.Spacing.xs - 2)
            .background(
                Capsule()
                    .fill(expirationBadgeBackground)
            )
        } else if benefit.status == .used, let usedDate = benefit.usedDate {
            Text("Used \(formattedDate(usedDate))")
                .font(DesignSystem.Typography.caption)
                .foregroundStyle(DesignSystem.Colors.textTertiary)
        } else if benefit.status == .expired {
            Text("Expired")
                .font(DesignSystem.Typography.caption)
                .foregroundStyle(DesignSystem.Colors.textTertiary)
        }
    }

    private var expirationTextColor: Color {
        if benefit.daysRemaining <= 3 {
            return DesignSystem.Colors.danger
        } else if benefit.daysRemaining <= 7 {
            return DesignSystem.Colors.warning
        }
        return DesignSystem.Colors.textSecondary
    }

    private var expirationBadgeBackground: Color {
        if benefit.daysRemaining <= 0 {
            return DesignSystem.Colors.danger.opacity(0.15)
        } else if benefit.daysRemaining <= 3 {
            return DesignSystem.Colors.danger.opacity(0.1)
        } else if benefit.daysRemaining <= 7 {
            return DesignSystem.Colors.warning.opacity(0.1)
        }
        return Color.clear
    }

    // MARK: - Urgency Background

    @ViewBuilder
    private var urgencyBackground: some View {
        if benefit.status == .available {
            DesignSystem.Colors.urgencyBackgroundColor(daysRemaining: benefit.daysRemaining)
        } else {
            Color.clear
        }
    }

    // MARK: - Text Colors

    private var primaryTextColor: Color {
        switch benefit.status {
        case .available:
            return DesignSystem.Colors.textPrimary
        case .used:
            return DesignSystem.Colors.textSecondary
        case .expired:
            return DesignSystem.Colors.textTertiary
        }
    }

    private var valueTextColor: Color {
        switch benefit.status {
        case .available:
            return DesignSystem.Colors.textPrimary
        case .used:
            return DesignSystem.Colors.success
        case .expired:
            return DesignSystem.Colors.textTertiary
        }
    }

    // MARK: - Accessibility

    private var accessibilityLabel: String {
        var label = "\(benefit.formattedValue) \(benefit.name)"

        switch benefit.status {
        case .available:
            label += ", available"
            if benefit.daysRemaining == 0 {
                label += ", expires today"
            } else if benefit.daysRemaining == 1 {
                label += ", expires tomorrow"
            } else if benefit.daysRemaining > 0 {
                label += ", \(benefit.daysRemaining) days remaining"
            }
        case .used:
            label += ", used"
            if let usedDate = benefit.usedDate {
                label += " on \(formattedDate(usedDate))"
            }
        case .expired:
            label += ", expired"
        }

        if let cardName, showCard {
            label += ", from \(cardName)"
        }

        return label
    }

    private var accessibilityHint: String {
        if benefit.status == .available {
            return "Double tap to view details. Swipe right to mark as done."
        }
        return "Double tap to view details."
    }

    private var accessibilityTraits: AccessibilityTraits {
        if onTap != nil {
            return .isButton
        }
        return []
    }

    // MARK: - Helper Methods

    private func formattedDate(_ date: Date) -> String {
        Formatters.shortDate.string(from: date)
    }
}
