//
//  BenefitStateService.swift
//  CouponTracker
//
//  Created: January 2026
//  Purpose: Implementation of benefit state transition business logic.
//

import Foundation

/// BenefitStateService
///
/// Responsibilities:
/// - Validate benefit state transitions (canMarkAsUsed, canUndo)
/// - Calculate next period dates based on benefit frequency
/// - Infer benefit frequency from period length when not explicitly set
///
/// Dependencies:
/// - None (stateless service with no external dependencies)
///
/// Thread Safety: Sendable (value type)
struct BenefitStateService: BenefitStateServiceProtocol {

    // MARK: - State Validation

    func canMarkAsUsed(_ benefit: Benefit) -> Bool {
        benefit.status == .available
    }

    func canUndo(_ benefit: Benefit) -> Bool {
        benefit.status == .used
    }

    // MARK: - Period Calculations

    func calculateNextPeriod(for benefit: Benefit) -> PeriodDates {
        // Get the frequency from custom override or infer from period length
        let frequency = benefit.customFrequency ?? inferFrequency(from: benefit)

        // Calculate next period dates using the day after current period end
        let calendar = Calendar.current
        let nextStart = calendar.date(byAdding: .day, value: 1, to: benefit.currentPeriodEnd)
            ?? benefit.currentPeriodEnd

        // Use the BenefitFrequency enum's built-in period calculation
        let (newPeriodStart, newPeriodEnd, nextReset) = frequency.calculatePeriodDates(
            from: nextStart,
            resetDayOfMonth: nil // Use calendar boundaries for resets
        )

        return PeriodDates(
            start: newPeriodStart,
            end: newPeriodEnd,
            nextReset: nextReset
        )
    }

    func inferFrequency(from benefit: Benefit) -> BenefitFrequency {
        let calendar = Calendar.current
        let components = calendar.dateComponents(
            [.month],
            from: benefit.currentPeriodStart,
            to: benefit.currentPeriodEnd
        )

        guard let months = components.month else {
            return .monthly // Default fallback
        }

        // Infer based on period length
        switch months {
        case 0...1:
            return .monthly
        case 2...4:
            return .quarterly
        case 5...7:
            return .semiAnnual
        default:
            return .annual
        }
    }
}
