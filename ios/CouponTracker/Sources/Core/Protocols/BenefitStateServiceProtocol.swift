//
//  BenefitStateServiceProtocol.swift
//  CouponTracker
//
//  Created: January 2026
//  Purpose: Protocol for benefit state transition logic extracted from repository.
//

import Foundation

/// Represents calculated period dates for a benefit.
struct PeriodDates: Equatable {
    /// Start date of the period
    let start: Date
    /// End date of the period (inclusive)
    let end: Date
    /// Date when the benefit should reset to a new period
    let nextReset: Date
}

/// Protocol for benefit state management and business logic.
///
/// Extracts pure business logic from BenefitRepository to enable:
/// - Independent testing of state transition rules
/// - Reusability across different contexts (Repository, ViewModel, etc.)
/// - Clear separation between data persistence and business rules
///
/// This service is stateless and operates only on the data provided to its methods.
protocol BenefitStateServiceProtocol {

    // MARK: - State Validation

    /// Determines if a benefit can be marked as used.
    ///
    /// A benefit can only be marked as used if it is currently available.
    /// Expired or already-used benefits cannot transition to used.
    ///
    /// - Parameter benefit: The benefit to check
    /// - Returns: True if the benefit can be marked as used
    func canMarkAsUsed(_ benefit: Benefit) -> Bool

    /// Determines if a benefit's used status can be undone.
    ///
    /// Only benefits with status `.used` can be reverted back to `.available`.
    ///
    /// - Parameter benefit: The benefit to check
    /// - Returns: True if the benefit can be reverted to available
    func canUndo(_ benefit: Benefit) -> Bool

    // MARK: - Period Calculations

    /// Calculates the next period dates for a benefit after reset.
    ///
    /// Uses the benefit's frequency (custom or inferred) to determine
    /// the start, end, and next reset dates for the new period.
    ///
    /// - Parameter benefit: The benefit to calculate next period for
    /// - Returns: PeriodDates containing start, end, and next reset dates
    func calculateNextPeriod(for benefit: Benefit) -> PeriodDates

    /// Infers the benefit frequency from its current period length.
    ///
    /// Used when custom frequency is not set and template lookup is unavailable.
    /// Analyzes the span between currentPeriodStart and currentPeriodEnd to
    /// determine the most likely frequency.
    ///
    /// Period length mapping:
    /// - 0-1 months: monthly
    /// - 2-4 months: quarterly
    /// - 5-7 months: semiAnnual
    /// - 8+ months: annual
    ///
    /// - Parameter benefit: The benefit to infer frequency for
    /// - Returns: The inferred benefit frequency
    func inferFrequency(from benefit: Benefit) -> BenefitFrequency
}
