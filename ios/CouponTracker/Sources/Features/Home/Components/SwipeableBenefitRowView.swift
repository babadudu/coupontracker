//
//  SwipeableBenefitRowView.swift
//  CouponTracker
//
//  Created: January 2026
//  Purpose: A benefit row with built-in swipe actions for mark as done, undo, and snooze.
//

import SwiftUI

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
                .tint(DesignSystem.Colors.warning)
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
