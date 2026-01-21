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

// MARK: - Benefit Row Style

/// Defines the visual style and behavior of a BenefitRowView.
///
/// - standard: Full-featured row with status icons, expiration badges, and all actions
/// - compact: Simplified layout for dashboard displays with minimal chrome
/// - swipeable: Standard style with swipe actions enabled (use SwipeableBenefitRowView)
enum BenefitRowStyle {
    case standard
    case compact
    case swipeable
}

// MARK: - Benefit Row Configuration

/// Configuration for BenefitRowView appearance and behavior.
///
/// Use static factory methods for common configurations:
/// - `.standard` - Default full-featured row
/// - `.compact(cardName:cardGradient:)` - Dashboard compact style
struct BenefitRowConfiguration {
    let style: BenefitRowStyle
    let showCard: Bool
    let cardGradient: DesignSystem.CardGradient?
    let cardName: String?
    let onMarkAsDone: (() -> Void)?
    let onSnooze: ((Int) -> Void)?
    let onUndo: (() -> Void)?
    let onTap: (() -> Void)?

    /// Standard configuration with all options available
    static let standard = BenefitRowConfiguration(
        style: .standard,
        showCard: false,
        cardGradient: nil,
        cardName: nil,
        onMarkAsDone: nil,
        onSnooze: nil,
        onUndo: nil,
        onTap: nil
    )

    /// Compact configuration for dashboard displays
    static func compact(
        cardName: String,
        cardGradient: DesignSystem.CardGradient? = nil,
        onMarkAsDone: (() -> Void)? = nil,
        onTap: (() -> Void)? = nil
    ) -> BenefitRowConfiguration {
        BenefitRowConfiguration(
            style: .compact,
            showCard: true,
            cardGradient: cardGradient,
            cardName: cardName,
            onMarkAsDone: onMarkAsDone,
            onSnooze: nil,
            onUndo: nil,
            onTap: onTap
        )
    }
}

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
            return "checkmark.seal.fill"  // Distinct from action buttons
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

    // MARK: - Mark as Done Button

    @ViewBuilder
    private var markAsDoneButton: some View {
        Button(action: { onMarkAsDone?() }) {
            HStack(spacing: DesignSystem.Spacing.xs) {
                Image(systemName: "checkmark")
                    .font(.system(size: 12, weight: .semibold))
                Text("Done")
                    .font(DesignSystem.Typography.badge)
            }
            .foregroundStyle(.white)
            .padding(.horizontal, DesignSystem.Spacing.md)
            .padding(.vertical, DesignSystem.Spacing.sm)
            .background(
                Capsule()
                    .fill(DesignSystem.Colors.primaryFallback)
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Mark \(benefit.name) as done")
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

// MARK: - Benefit Row Button Style

/// Custom button style for benefit rows with subtle press feedback
struct BenefitRowButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background(
                configuration.isPressed ?
                    DesignSystem.Colors.backgroundSecondary :
                    Color.clear
            )
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

// MARK: - Swipeable Benefit Row

/// A benefit row with built-in swipe actions
struct SwipeableBenefitRowView: View {
    let benefit: PreviewBenefit
    var cardGradient: DesignSystem.CardGradient? = nil
    var showCard: Bool = false
    var cardName: String? = nil
    var onMarkAsDone: (() -> Void)? = nil
    var onSnooze: ((Int) -> Void)? = nil
    var onUndo: (() -> Void)? = nil
    var onTap: (() -> Void)? = nil

    var body: some View {
        BenefitRowView(
            benefit: benefit,
            cardGradient: cardGradient,
            showCard: showCard,
            cardName: cardName,
            onMarkAsDone: onMarkAsDone,
            onSnooze: onSnooze,
            onUndo: onUndo,
            onTap: onTap
        )
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            if benefit.status == .available {
                Button(action: { onMarkAsDone?() }) {
                    Label("Done", systemImage: "checkmark.circle.fill")
                }
                .tint(DesignSystem.Colors.success)
            } else if benefit.status == .used, onUndo != nil {
                Button(action: { onUndo?() }) {
                    Label("Undo", systemImage: "arrow.uturn.backward.circle.fill")
                }
                .tint(DesignSystem.Colors.primaryFallback)
            }
        }
        .swipeActions(edge: .leading, allowsFullSwipe: false) {
            if benefit.status == .available {
                Button(action: { onSnooze?(1) }) {
                    Label("1 Day", systemImage: "clock")
                }
                .tint(DesignSystem.Colors.primaryFallback)

                Button(action: { onSnooze?(7) }) {
                    Label("1 Week", systemImage: "calendar")
                }
                .tint(Color.orange)
            }
        }
    }
}

// MARK: - Compact Benefit Row

/// A more compact version of the benefit row for dashboard displays.
///
/// This is a convenience wrapper around BenefitRowView with compact configuration.
/// Prefer using `BenefitRowView(benefit:configuration:)` with `.compact(...)` directly.
struct CompactBenefitRowView: View {
    let benefit: PreviewBenefit
    let cardName: String
    var cardGradient: DesignSystem.CardGradient? = nil
    var onMarkAsDone: (() -> Void)? = nil
    var onTap: (() -> Void)? = nil

    var body: some View {
        BenefitRowView(
            benefit: benefit,
            configuration: .compact(
                cardName: cardName,
                cardGradient: cardGradient,
                onMarkAsDone: onMarkAsDone,
                onTap: onTap
            )
        )
    }
}

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
