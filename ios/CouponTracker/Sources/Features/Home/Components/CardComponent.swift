// CardComponent.swift
// CouponTracker
//
// Created: January 2026
// Purpose: Reusable credit card visual component that displays card information
//          in a wallet-style format with gradient backgrounds, status indicators,
//          and benefit summary badges.
//
// ACCESSIBILITY:
// - Full VoiceOver support with descriptive labels
// - Minimum 44pt touch targets
// - Status information conveyed through both color and text/icons
//
// USAGE:
// CardComponent(card: myCard, size: .regular)
// CardComponent(card: myCard, size: .compact) // For grid displays

import SwiftUI

// MARK: - Card Size Variants
/// Different display sizes for the card component
enum CardComponentSize {
    /// Full-width card for wallet stack view
    case regular

    /// Compact card for grid selection views
    case compact

    /// Mini card for inline displays
    case mini

    /// The card's corner radius for this size
    var cornerRadius: CGFloat {
        switch self {
        case .regular: return DesignSystem.Sizing.cardCornerRadius
        case .compact: return 10
        case .mini: return 8
        }
    }

    /// Scale factor for text elements
    var textScale: CGFloat {
        switch self {
        case .regular: return 1.0
        case .compact: return 0.85
        case .mini: return 0.7
        }
    }
}

// MARK: - Card Component
/// The primary visual representation of a credit card
/// Displays card artwork, name, issuer, and benefit summary
struct CardComponent: View {
    // MARK: Properties
    let card: PreviewCard
    var size: CardComponentSize = .regular
    var showShadow: Bool = true
    var isSelected: Bool = false

    // MARK: State
    @State private var isPressed = false

    // MARK: Computed Properties
    /// Whether the card has urgent benefits (expiring within 3 days)
    private var hasUrgentBenefits: Bool {
        card.urgentBenefitsCount > 0
    }

    /// Whether all benefits have been used this period
    private var allBenefitsUsed: Bool {
        card.availableBenefits.isEmpty && !card.usedBenefits.isEmpty
    }

    // MARK: Body
    var body: some View {
        cardContent
            .aspectRatio(DesignSystem.Sizing.cardAspectRatio, contentMode: .fit)
            .clipShape(RoundedRectangle(cornerRadius: size.cornerRadius, style: .continuous))
            .if(showShadow) { view in
                view.cardShadow()
            }
            .if(isSelected) { view in
                view.overlay(
                    RoundedRectangle(cornerRadius: size.cornerRadius, style: .continuous)
                        .strokeBorder(DesignSystem.Colors.primaryFallback, lineWidth: 3)
                )
            }
            .scaleEffect(isPressed ? 0.98 : 1.0)
            .animation(DesignSystem.Animation.quickSpring, value: isPressed)
            // Accessibility
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(accessibilityLabel)
            .accessibilityHint("Double tap to view card details")
            .accessibilityAddTraits(.isButton)
    }

    // MARK: Card Content
    @ViewBuilder
    private var cardContent: some View {
        GeometryReader { geometry in
            ZStack {
                // Background gradient
                cardBackground

                // Card content overlay
                VStack(alignment: .leading, spacing: 0) {
                    // Top section: Issuer logo area
                    topSection

                    Spacer()

                    // Bottom section: Card name and status
                    bottomSection(width: geometry.size.width)
                }
                .padding(scaledPadding)

                // Urgent indicator overlay
                if hasUrgentBenefits && size == .regular {
                    urgentOverlay
                }

                // All used indicator
                if allBenefitsUsed && size == .regular {
                    allUsedOverlay
                }

                // Selection checkmark for compact size
                if isSelected && size == .compact {
                    selectionIndicator
                }
            }
        }
    }

    // MARK: Card Background
    @ViewBuilder
    private var cardBackground: some View {
        card.gradient.gradient
            .overlay(
                // Subtle noise texture for realism
                Rectangle()
                    .fill(.ultraThinMaterial.opacity(0.03))
            )
    }

    // MARK: Top Section
    @ViewBuilder
    private var topSection: some View {
        HStack(alignment: .top) {
            // Issuer name (placeholder for logo)
            Text(card.issuer.uppercased())
                .font(.system(size: 10 * size.textScale, weight: .semibold))
                .tracking(1.2)
                .foregroundStyle(card.gradient.textColor.opacity(0.8))

            Spacer()

            // Decorative chip element (for regular size)
            if size == .regular {
                chipElement
            }
        }
    }

    // MARK: Chip Element
    @ViewBuilder
    private var chipElement: some View {
        RoundedRectangle(cornerRadius: 4)
            .fill(
                LinearGradient(
                    colors: [Color(hex: "#D4AF37"), Color(hex: "#C5A028")],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .frame(width: 36, height: 28)
            .overlay(
                // Chip lines
                VStack(spacing: 3) {
                    ForEach(0..<4, id: \.self) { _ in
                        Rectangle()
                            .fill(Color(hex: "#B8960F").opacity(0.5))
                            .frame(height: 1)
                    }
                }
                .padding(.horizontal, 4)
                .padding(.vertical, 6)
            )
    }

    // MARK: Bottom Section
    @ViewBuilder
    private func bottomSection(width: CGFloat) -> some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs * size.textScale) {
            // Card name
            Text(card.name)
                .font(.system(size: 17 * size.textScale, weight: .bold))
                .foregroundStyle(card.gradient.textColor)

            // Nickname if present
            if let nickname = card.nickname, size == .regular {
                Text(nickname)
                    .font(.system(size: 14 * size.textScale, weight: .regular))
                    .foregroundStyle(card.gradient.textColor.opacity(0.8))
            }

            // Status pills (for regular size)
            if size == .regular {
                statusPills
            } else if size == .compact {
                // Compact summary
                compactSummary
            }
        }
    }

    // MARK: Status Pills
    @ViewBuilder
    private var statusPills: some View {
        HStack(spacing: DesignSystem.Spacing.sm) {
            // Available value pill
            StatusPill(
                text: card.formattedTotalValue + " Available",
                backgroundColor: DesignSystem.Colors.success.opacity(0.2),
                textColor: card.gradient.textColor
            )

            // Expiring count pill (if any)
            if card.expiringBenefitsCount > 0 {
                StatusPill(
                    text: "\(card.expiringBenefitsCount) Expiring",
                    backgroundColor: expiringPillColor.opacity(0.2),
                    textColor: card.gradient.textColor,
                    icon: "exclamationmark.circle.fill"
                )
            }
        }
        .padding(.top, DesignSystem.Spacing.xs)
    }

    // MARK: Compact Summary
    @ViewBuilder
    private var compactSummary: some View {
        Text(card.formattedTotalValue)
            .font(.system(size: 12 * size.textScale, weight: .semibold))
            .foregroundStyle(card.gradient.textColor.opacity(0.9))
    }

    // MARK: Urgent Overlay
    @ViewBuilder
    private var urgentOverlay: some View {
        VStack {
            HStack {
                Spacer()
                // Pulsing urgent indicator
                Circle()
                    .fill(DesignSystem.Colors.danger)
                    .frame(width: 12, height: 12)
                    .overlay(
                        Circle()
                            .stroke(DesignSystem.Colors.danger.opacity(0.5), lineWidth: 2)
                            .scaleEffect(1.5)
                    )
                    .padding(DesignSystem.Spacing.md)
            }
            Spacer()
        }
    }

    // MARK: All Used Overlay
    @ViewBuilder
    private var allUsedOverlay: some View {
        VStack {
            HStack {
                Spacer()
                Image(systemName: "checkmark.seal.fill")
                    .font(.system(size: 24))
                    .foregroundStyle(DesignSystem.Colors.success)
                    .padding(DesignSystem.Spacing.md)
            }
            Spacer()
        }
    }

    // MARK: Selection Indicator
    @ViewBuilder
    private var selectionIndicator: some View {
        VStack {
            HStack {
                Spacer()
                ZStack {
                    Circle()
                        .fill(DesignSystem.Colors.primaryFallback)
                        .frame(width: 24, height: 24)

                    Image(systemName: "checkmark")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(DesignSystem.Colors.onColor)
                }
                .padding(DesignSystem.Spacing.sm)
            }
            Spacer()
        }
    }

    // MARK: Helper Properties
    private var scaledPadding: CGFloat {
        DesignSystem.Spacing.lg * size.textScale
    }

    private var expiringPillColor: Color {
        if card.urgentBenefitsCount > 0 {
            return DesignSystem.Colors.danger
        }
        return DesignSystem.Colors.warning
    }

    private var accessibilityLabel: String {
        var label = "\(card.name) from \(card.issuer)"
        if let nickname = card.nickname {
            label += ", nicknamed \(nickname)"
        }
        label += ". \(card.formattedTotalValue) available"
        if card.expiringBenefitsCount > 0 {
            label += ". \(card.expiringBenefitsCount) benefits expiring soon"
        }
        if allBenefitsUsed {
            label += ". All benefits used this period"
        }
        return label
    }
}

// MARK: - Status Pill Component
/// A small pill-shaped badge for displaying status information
struct StatusPill: View {
    let text: String
    let backgroundColor: Color
    let textColor: Color
    var icon: String? = nil

    var body: some View {
        HStack(spacing: DesignSystem.Spacing.xs) {
            if let icon {
                Image(systemName: icon)
                    .font(.system(size: 10, weight: .semibold))
            }
            Text(text)
                .font(DesignSystem.Typography.badge)
        }
        .foregroundStyle(textColor)
        .padding(.horizontal, DesignSystem.Spacing.sm)
        .padding(.vertical, DesignSystem.Spacing.xs)
        .background(
            Capsule()
                .fill(backgroundColor)
        )
    }
}

// MARK: - Conditional View Modifier
extension View {
    /// Applies a transformation if a condition is true
    @ViewBuilder
    func `if`<Transform: View>(_ condition: Bool, transform: (Self) -> Transform) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
}

// MARK: - Card Component Button Style
/// Custom button style for card interactions with press feedback
struct CardPressStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(DesignSystem.Animation.quickSpring, value: configuration.isPressed)
    }
}

// MARK: - Mini Card Component
/// A minimal card representation for inline use
struct MiniCardIcon: View {
    let card: PreviewCard
    var size: CGFloat = 32

    var body: some View {
        RoundedRectangle(cornerRadius: 4)
            .fill(card.gradient.gradient)
            .frame(width: size * DesignSystem.Sizing.cardAspectRatio, height: size)
            .overlay(
                Text(String(card.issuer.prefix(1)))
                    .font(.system(size: size * 0.4, weight: .bold))
                    .foregroundStyle(card.gradient.textColor)
            )
    }
}

// MARK: - Previews
#Preview("Card Component - Regular") {
    VStack(spacing: DesignSystem.Spacing.lg) {
        CardComponent(card: PreviewData.amexPlatinum)
            .padding(.horizontal)

        CardComponent(card: PreviewData.chaseSapphireReserve)
            .padding(.horizontal)
    }
    .padding(.vertical)
    .background(DesignSystem.Colors.backgroundSecondary)
}

#Preview("Card Component - States") {
    ScrollView {
        VStack(spacing: DesignSystem.Spacing.xl) {
            // Normal card
            VStack(alignment: .leading) {
                Text("Normal State")
                    .font(DesignSystem.Typography.headline)
                CardComponent(card: PreviewData.amexGold)
            }

            // Card with urgent benefits
            VStack(alignment: .leading) {
                Text("Urgent Benefits (pulsing indicator)")
                    .font(DesignSystem.Typography.headline)
                CardComponent(card: PreviewData.amexPlatinum)
            }

            // Card with all benefits used
            VStack(alignment: .leading) {
                Text("All Benefits Used")
                    .font(DesignSystem.Typography.headline)

                // Create a card with all benefits used
                let allUsedCard = PreviewCard(
                    name: "Test Card",
                    issuer: "Bank",
                    gradient: .emerald,
                    benefits: [.used(), .used()]
                )
                CardComponent(card: allUsedCard)
            }

            // Custom card
            VStack(alignment: .leading) {
                Text("Custom Card")
                    .font(DesignSystem.Typography.headline)
                CardComponent(card: PreviewData.customCard)
            }
        }
        .padding()
    }
    .background(DesignSystem.Colors.backgroundSecondary)
}

#Preview("Card Component - Compact") {
    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: DesignSystem.Spacing.md) {
        CardComponent(card: PreviewData.amexPlatinum, size: .compact)
        CardComponent(card: PreviewData.amexGold, size: .compact, isSelected: true)
        CardComponent(card: PreviewData.chaseSapphireReserve, size: .compact)
        CardComponent(card: PreviewData.capitalOneVentureX, size: .compact)
    }
    .padding()
    .background(DesignSystem.Colors.backgroundSecondary)
}

#Preview("Card Gradients Gallery") {
    ScrollView {
        VStack(spacing: DesignSystem.Spacing.md) {
            ForEach(DesignSystem.CardGradient.allCases) { gradient in
                let card = PreviewCard(
                    name: gradient.rawValue,
                    issuer: "Sample Issuer",
                    gradient: gradient,
                    benefits: [
                        PreviewBenefit(
                            name: "Test Benefit",
                            value: 100,
                            frequency: .monthly,
                            category: .lifestyle,
                            expirationDate: PreviewData.endOfMonth
                        )
                    ]
                )
                CardComponent(card: card)
            }
        }
        .padding()
    }
    .background(DesignSystem.Colors.backgroundSecondary)
}

#Preview("Mini Card Icons") {
    HStack(spacing: DesignSystem.Spacing.md) {
        ForEach(PreviewData.sampleCards) { card in
            MiniCardIcon(card: card)
        }
    }
    .padding()
}
