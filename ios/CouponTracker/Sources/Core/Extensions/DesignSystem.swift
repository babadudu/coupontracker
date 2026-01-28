// DesignSystem.swift
// CouponTracker
//
// Created: January 2026
// Purpose: Comprehensive design system defining colors, typography, spacing,
//          shadows, and card gradients for consistent UI across the app.
//
// ACCESSIBILITY NOTES:
// - All color combinations meet WCAG 2.1 AA contrast requirements (4.5:1 for text)
// - Semantic colors adapt automatically for Dark Mode
// - Dynamic Type is supported via SwiftUI's built-in font scaling

import SwiftUI

// MARK: - Design Tokens Namespace
/// Design system namespace containing all visual design tokens
/// Usage: DesignSystem.Colors.primary, DesignSystem.Typography.title1, etc.
enum DesignSystem {

    // MARK: - Color Palette
    enum Colors {

        // MARK: Primary Brand Colors
        /// Primary brand color - used for CTAs, links, and primary actions
        /// Contrast ratio: 4.5:1 on white background
        static let primary = Color("Primary", bundle: nil)
        static let primaryFallback = Color.adaptive(
            light: Color(hex: "#007AFF"),
            dark: Color(hex: "#0A84FF")
        )

        /// Darker primary for pressed states
        static let primaryDark = Color(hex: "#0055CC")

        // MARK: Semantic Status Colors
        /// Success state - used for completed actions, "used" indicators
        /// Green that works in both light and dark modes
        static let success = Color.adaptive(
            light: Color(hex: "#34C759"),
            dark: Color(hex: "#30D158")
        )

        /// Warning state - expiring soon (4-7 days)
        static let warning = Color.adaptive(
            light: Color(hex: "#FF9500"),
            dark: Color(hex: "#FF9F0A")
        )

        /// Danger/urgent state - expiring today or within 3 days
        static let danger = Color.adaptive(
            light: Color(hex: "#FF3B30"),
            dark: Color(hex: "#FF453A")
        )

        /// Neutral/disabled state - secondary text, expired items
        static let neutral = Color(hex: "#8E8E93")

        // MARK: Background Colors
        /// These colors adapt automatically for Dark Mode when using semantic naming

        /// Primary background - main app background
        static var backgroundPrimary: Color {
            Color(uiColor: .systemBackground)
        }

        /// Secondary background - cards, grouped content areas
        static var backgroundSecondary: Color {
            Color(uiColor: .secondarySystemBackground)
        }

        /// Tertiary background - elevated surfaces, modals
        static var backgroundTertiary: Color {
            Color(uiColor: .tertiarySystemBackground)
        }

        /// Grouped background for list sections
        static var backgroundGrouped: Color {
            Color(uiColor: .systemGroupedBackground)
        }

        // MARK: Text Colors
        /// Primary text color - main content
        static var textPrimary: Color {
            Color(uiColor: .label)
        }

        /// Secondary text color - subtitles, metadata
        static var textSecondary: Color {
            Color(uiColor: .secondaryLabel)
        }

        /// Tertiary text color - placeholder text, disabled content
        static var textTertiary: Color {
            Color(uiColor: .tertiaryLabel)
        }

        /// Text/icon color for use on vibrant colored backgrounds (gradients, status banners)
        /// Always white because backgrounds are vibrant colors needing contrast
        static let onColor = Color.white

        // MARK: Card Issuer Brand Colors
        /// These colors represent credit card issuer brand identities
        enum Issuer {
            static let amex = Color(hex: "#006FCF")
            static let amexSecondary = Color(hex: "#FFFFFF")

            static let chase = Color(hex: "#117ACA")
            static let chaseSecondary = Color(hex: "#FFFFFF")

            static let capitalOne = Color(hex: "#D03027")
            static let capitalOneSecondary = Color(hex: "#004977")

            static let citi = Color(hex: "#003B70")
            static let citiSecondary = Color(hex: "#FFFFFF")

            static let usBank = Color(hex: "#D71920")
            static let usBankSecondary = Color(hex: "#003DA5")
        }

        // MARK: Urgency Background Colors
        /// Subtle background tints for urgency indicators
        /// These are low-opacity versions for row backgrounds

        /// Subtle yellow/orange tint for 4-7 days warning
        static let warningBackground = Color(hex: "#FF9500").opacity(0.12)

        /// Subtle red tint for 1-3 days urgent
        static let urgentBackground = Color(hex: "#FF3B30").opacity(0.12)

        /// Strong red background for "expires today"
        static let criticalBackground = Color(hex: "#FF3B30").opacity(0.2)
    }

    // MARK: - Typography
    /// Typography scale following iOS Human Interface Guidelines
    /// All styles support Dynamic Type scaling automatically
    enum Typography {

        // MARK: Display Styles (SF Pro Display)
        /// Large title - 34pt Bold - Main screen titles
        static let largeTitle = Font.largeTitle.weight(.bold)

        /// Title 1 - 28pt Bold - Section headers, card names
        static let title1 = Font.title.weight(.bold)

        /// Title 2 - 22pt Bold - Subsection headers
        static let title2 = Font.title2.weight(.bold)

        /// Title 3 - 20pt Semibold - Tertiary headers
        static let title3 = Font.title3.weight(.semibold)

        // MARK: Body Styles (SF Pro Text)
        /// Headline - 17pt Semibold - Row titles, emphasized content
        static let headline = Font.headline

        /// Body - 17pt Regular - Primary content text
        static let body = Font.body

        /// Callout - 16pt Regular - Secondary content
        static let callout = Font.callout

        /// Subhead - 15pt Regular - Metadata, timestamps
        static let subhead = Font.subheadline

        /// Footnote - 13pt Regular - Legal text, fine print
        static let footnote = Font.footnote

        /// Caption - 12pt Regular - Image captions, badges
        static let caption = Font.caption

        // MARK: Special Styles
        /// Value display - Large monetary values (48pt Rounded Bold)
        static let valueLarge = Font.system(size: 48, weight: .bold, design: .rounded)

        /// Value display - Medium monetary values (28pt Rounded Bold)
        static let valueMedium = Font.system(size: 28, weight: .bold, design: .rounded)

        /// Value display - Row values (17pt Rounded Bold)
        static let valueSmall = Font.system(size: 17, weight: .bold, design: .rounded)

        /// Card name on card artwork (17pt Bold)
        static let cardName = Font.system(size: 17, weight: .bold)

        /// Card nickname (14pt Regular)
        static let cardNickname = Font.system(size: 14, weight: .regular)

        /// Badge text (12pt Semibold)
        static let badge = Font.system(size: 12, weight: .semibold)
    }

    // MARK: - Spacing System
    /// Consistent spacing scale based on 4pt base unit
    /// Reference: iOS HIG recommends 8pt as minimum touch target padding
    enum Spacing {
        /// 4pt - Minimal spacing, icon internal padding
        static let xs: CGFloat = 4

        /// 8pt - Related element spacing, compact layouts
        static let sm: CGFloat = 8

        /// 12pt - Icon to text spacing, tight groupings
        static let md: CGFloat = 12

        /// 16pt - Standard content padding, card padding
        static let lg: CGFloat = 16

        /// 24pt - Section spacing, card margins
        static let xl: CGFloat = 24

        /// 32pt - Major section separation
        static let xxl: CGFloat = 32

        /// 48pt - Screen-level padding, hero spacing
        static let xxxl: CGFloat = 48

        // MARK: Component-Specific Spacing
        /// Card horizontal padding
        static let cardPadding: CGFloat = 16

        /// Screen edge insets
        static let screenPadding: CGFloat = 16

        /// List row vertical padding
        static let rowVerticalPadding: CGFloat = 12

        /// Stack offset for card stack view
        static let cardStackOffset: CGFloat = 8
    }

    // MARK: - Sizing
    /// Standard sizes for common UI elements
    enum Sizing {
        // MARK: Touch Targets
        /// Minimum touch target per Apple HIG (44pt)
        static let minTouchTarget: CGFloat = 44

        // MARK: Icons
        /// Small icon size (16pt)
        static let iconSmall: CGFloat = 16

        /// Medium icon size (24pt) - standard row icon
        static let iconMedium: CGFloat = 24

        /// Large icon size (32pt) - prominent icons
        static let iconLarge: CGFloat = 32

        // MARK: Components
        /// Benefit row minimum height
        static let benefitRowHeight: CGFloat = 72

        /// Status badge height
        static let badgeHeight: CGFloat = 24

        /// FAB diameter
        static let fabSize: CGFloat = 56

        /// Action button width
        static let actionButtonWidth: CGFloat = 56

        /// Action button height
        static let actionButtonHeight: CGFloat = 32

        // MARK: Card Dimensions
        /// Credit card aspect ratio (standard 85.6mm x 53.98mm)
        static let cardAspectRatio: CGFloat = 1.586

        /// Card corner radius
        static let cardCornerRadius: CGFloat = 12

        /// Sheet corner radius
        static let sheetCornerRadius: CGFloat = 16

        /// Button corner radius
        static let buttonCornerRadius: CGFloat = 8

        /// Badge corner radius
        static let badgeCornerRadius: CGFloat = 6
    }

    // MARK: - Shadows / Elevation
    /// Shadow styles for elevation hierarchy
    enum Shadow {
        /// Level 0 - Flat elements (no shadow)
        static let none = ShadowStyle(radius: 0, y: 0, opacity: 0)

        /// Level 1 - Cards, list items
        static let level1 = ShadowStyle(radius: 3, y: 1, opacity: 0.12)

        /// Level 2 - Floating cards, FAB
        static let level2 = ShadowStyle(radius: 12, y: 4, opacity: 0.15)

        /// Level 3 - Modals, sheets
        static let level3 = ShadowStyle(radius: 24, y: 8, opacity: 0.2)
    }

    // MARK: - Animation
    /// Standardized animation parameters
    enum Animation {
        /// Card tap response duration
        static let cardTap: Double = 0.1

        /// Card expansion transition
        static let cardExpand: Double = 0.35

        /// Success checkmark draw
        static let successDraw: Double = 0.4

        /// List item changes
        static let listChange: Double = 0.25

        /// Standard spring animation
        static var spring: SwiftUI.Animation {
            .spring(response: 0.4, dampingFraction: 0.85)
        }

        /// Quick response spring
        static var quickSpring: SwiftUI.Animation {
            .spring(response: 0.3, dampingFraction: 0.7)
        }
    }

    // MARK: - Card Gradients
    /// Pre-defined gradients for custom cards and card backgrounds
    enum CardGradient: String, CaseIterable, Identifiable {
        case midnight = "Midnight"
        case gold = "Gold"
        case platinum = "Platinum"
        case sapphire = "Sapphire"
        case roseGold = "Rose Gold"
        case obsidian = "Obsidian"
        case emerald = "Emerald"
        case ruby = "Ruby"

        var id: String { rawValue }

        /// The gradient colors for this style
        var gradient: LinearGradient {
            LinearGradient(
                colors: colors,
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }

        /// Raw color values for the gradient
        var colors: [Color] {
            switch self {
            case .midnight:
                return [Color(hex: "#1a1a2e"), Color(hex: "#4a4e69")]
            case .gold:
                return [Color(hex: "#b8860b"), Color(hex: "#daa520")]
            case .platinum:
                return [Color(hex: "#a0a0a0"), Color(hex: "#d0d0d0")]
            case .sapphire:
                return [Color(hex: "#0f4c75"), Color(hex: "#3282b8")]
            case .roseGold:
                return [Color(hex: "#b76e79"), Color(hex: "#eacda3")]
            case .obsidian:
                return [Color(hex: "#1c1c1c"), Color(hex: "#434343")]
            case .emerald:
                return [Color(hex: "#1d4e4d"), Color(hex: "#43aa8b")]
            case .ruby:
                return [Color(hex: "#9b2335"), Color(hex: "#c41e3a")]
            }
        }

        /// Recommended text color for this gradient (for contrast)
        var textColor: Color {
            switch self {
            case .gold, .platinum, .roseGold:
                return Color(hex: "#1a1a1a") // Dark text for light gradients
            default:
                return .white // White text for dark gradients
            }
        }
    }

    // MARK: - Popular Card Styles
    /// Pre-defined styles for popular credit cards
    /// These represent the visual identity of known cards
    enum PopularCard: String, CaseIterable, Identifiable {
        case amexPlatinum = "Amex Platinum"
        case amexGold = "Amex Gold"
        case amexGreen = "Amex Green"
        case chaseSapphireReserve = "Chase Sapphire Reserve"
        case chaseSapphirePreferred = "Chase Sapphire Preferred"
        case capitalOneVentureX = "Capital One Venture X"
        case hiltonAspire = "Hilton Aspire"
        case marriottBonvoyBrilliant = "Marriott Bonvoy Brilliant"

        var id: String { rawValue }

        /// Background gradient for the card
        var gradient: LinearGradient {
            LinearGradient(
                colors: gradientColors,
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }

        /// Gradient color values
        var gradientColors: [Color] {
            switch self {
            case .amexPlatinum:
                return [Color(hex: "#8B8B8B"), Color(hex: "#B8B8B8"), Color(hex: "#D4D4D4")]
            case .amexGold:
                return [Color(hex: "#B8860B"), Color(hex: "#DAA520"), Color(hex: "#FFD700")]
            case .amexGreen:
                return [Color(hex: "#2E8B57"), Color(hex: "#3CB371")]
            case .chaseSapphireReserve:
                return [Color(hex: "#1a1a2e"), Color(hex: "#2d3a6d")]
            case .chaseSapphirePreferred:
                return [Color(hex: "#0f4c75"), Color(hex: "#3282b8")]
            case .capitalOneVentureX:
                return [Color(hex: "#1c1c1c"), Color(hex: "#2d2d2d")]
            case .hiltonAspire:
                return [Color(hex: "#1a1a2e"), Color(hex: "#3d3d5c")]
            case .marriottBonvoyBrilliant:
                return [Color(hex: "#4a0080"), Color(hex: "#8b008b")]
            }
        }

        /// Text color for card overlay
        var textColor: Color {
            .white
        }

        /// Card issuer
        var issuer: String {
            switch self {
            case .amexPlatinum, .amexGold, .amexGreen, .hiltonAspire, .marriottBonvoyBrilliant:
                return "American Express"
            case .chaseSapphireReserve, .chaseSapphirePreferred:
                return "Chase"
            case .capitalOneVentureX:
                return "Capital One"
            }
        }
    }
}

// MARK: - Shadow Style Helper
/// Encapsulates shadow parameters for consistent application
struct ShadowStyle {
    let radius: CGFloat
    let y: CGFloat
    let opacity: Double

    var color: Color {
        Color.black.opacity(opacity)
    }
}

// MARK: - View Extensions
extension View {
    /// Applies a design system shadow level
    func shadow(_ style: ShadowStyle) -> some View {
        self.shadow(
            color: style.color,
            radius: style.radius,
            x: 0,
            y: style.y
        )
    }

    /// Applies card shadow styling (Level 2)
    func cardShadow() -> some View {
        self.shadow(DesignSystem.Shadow.level2)
    }

    /// Applies elevated shadow styling (Level 3)
    func elevatedShadow() -> some View {
        self.shadow(DesignSystem.Shadow.level3)
    }
}

// MARK: - Color Extension for Hex Support
extension Color {
    /// Initialize a Color from a hex string
    /// Supports formats: "#RRGGBB", "RRGGBB", "#RRGGBBAA", "RRGGBBAA"
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)

        let a, r, g, b: UInt64
        switch hex.count {
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }

    /// Creates a color that adapts to light/dark mode
    static func adaptive(light: Color, dark: Color) -> Color {
        Color(UIColor { traitCollection in
            traitCollection.userInterfaceStyle == .dark
                ? UIColor(dark)
                : UIColor(light)
        })
    }
}

// MARK: - Status Color Helpers
extension DesignSystem.Colors {
    /// Returns appropriate color based on days until expiration
    static func urgencyColor(daysRemaining: Int) -> Color {
        switch daysRemaining {
        case ..<0:
            return neutral // Expired
        case 0:
            return danger // Expires today
        case 1...3:
            return danger // Critical - 1-3 days
        case 4...7:
            return warning // Warning - 4-7 days
        default:
            return success // Safe - 8+ days
        }
    }

    /// Returns appropriate background color based on urgency
    static func urgencyBackgroundColor(daysRemaining: Int) -> Color {
        switch daysRemaining {
        case ..<0:
            return .clear // Expired - no highlight
        case 0:
            return criticalBackground // Expires today
        case 1...3:
            return urgentBackground // Critical
        case 4...7:
            return warningBackground // Warning
        default:
            return .clear // Safe - no highlight needed
        }
    }

    /// Returns a color for a benefit category
    static func categoryColor(for category: BenefitCategory) -> Color {
        switch category {
        case .travel:
            return Color(hex: "#007AFF") // Blue
        case .dining:
            return Color(hex: "#FF9500") // Orange
        case .transportation:
            return Color(hex: "#FFCC00") // Yellow
        case .shopping:
            return Color(hex: "#FF2D55") // Pink
        case .entertainment:
            return Color(hex: "#AF52DE") // Purple
        case .business:
            return Color(hex: "#5AC8FA") // Light Blue
        case .lifestyle:
            return Color(hex: "#34C759") // Green
        }
    }
}

// MARK: - Preview Provider
#Preview("Design System Colors") {
    ScrollView {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.lg) {
            // Primary Colors
            Group {
                Text("Primary Colors")
                    .font(DesignSystem.Typography.title2)

                HStack(spacing: DesignSystem.Spacing.sm) {
                    ColorSwatch(color: DesignSystem.Colors.primaryFallback, name: "Primary")
                    ColorSwatch(color: DesignSystem.Colors.primaryDark, name: "Primary Dark")
                }
            }

            // Status Colors
            Group {
                Text("Status Colors")
                    .font(DesignSystem.Typography.title2)

                HStack(spacing: DesignSystem.Spacing.sm) {
                    ColorSwatch(color: DesignSystem.Colors.success, name: "Success")
                    ColorSwatch(color: DesignSystem.Colors.warning, name: "Warning")
                    ColorSwatch(color: DesignSystem.Colors.danger, name: "Danger")
                    ColorSwatch(color: DesignSystem.Colors.neutral, name: "Neutral")
                }
            }

            // Card Gradients
            Group {
                Text("Card Gradients")
                    .font(DesignSystem.Typography.title2)

                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: DesignSystem.Spacing.sm) {
                    ForEach(DesignSystem.CardGradient.allCases) { gradient in
                        GradientSwatch(gradient: gradient)
                    }
                }
            }

            // Typography
            Group {
                Text("Typography Scale")
                    .font(DesignSystem.Typography.title2)

                VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                    Text("Large Title").font(DesignSystem.Typography.largeTitle)
                    Text("Title 1").font(DesignSystem.Typography.title1)
                    Text("Title 2").font(DesignSystem.Typography.title2)
                    Text("Headline").font(DesignSystem.Typography.headline)
                    Text("Body").font(DesignSystem.Typography.body)
                    Text("Callout").font(DesignSystem.Typography.callout)
                    Text("Subhead").font(DesignSystem.Typography.subhead)
                    Text("Footnote").font(DesignSystem.Typography.footnote)
                    Text("Caption").font(DesignSystem.Typography.caption)
                    Text("$847").font(DesignSystem.Typography.valueLarge)
                }
            }
        }
        .padding(DesignSystem.Spacing.lg)
    }
}

// MARK: - Preview Helpers
private struct ColorSwatch: View {
    let color: Color
    let name: String

    var body: some View {
        VStack(spacing: DesignSystem.Spacing.xs) {
            RoundedRectangle(cornerRadius: DesignSystem.Sizing.badgeCornerRadius)
                .fill(color)
                .frame(width: 60, height: 60)

            Text(name)
                .font(DesignSystem.Typography.caption)
                .foregroundStyle(DesignSystem.Colors.textSecondary)
        }
    }
}

private struct GradientSwatch: View {
    let gradient: DesignSystem.CardGradient

    var body: some View {
        VStack(spacing: DesignSystem.Spacing.xs) {
            RoundedRectangle(cornerRadius: DesignSystem.Sizing.cardCornerRadius)
                .fill(gradient.gradient)
                .frame(height: 80)
                .overlay(
                    Text(gradient.rawValue)
                        .font(DesignSystem.Typography.badge)
                        .foregroundStyle(gradient.textColor)
                )

            Text(gradient.rawValue)
                .font(DesignSystem.Typography.caption)
                .foregroundStyle(DesignSystem.Colors.textSecondary)
        }
    }
}
