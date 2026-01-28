//
//  BenefitRowConfiguration.swift
//  CouponTracker
//
//  Created: January 2026
//  Purpose: Configuration types for BenefitRowView appearance and behavior.
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
