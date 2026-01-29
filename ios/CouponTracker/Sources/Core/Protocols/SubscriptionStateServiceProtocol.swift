// SubscriptionStateServiceProtocol.swift
// CouponTracker
//
// Created: January 2026
// Purpose: Protocol for subscription state management and business logic.

import Foundation

/// Spending summary for subscriptions over a time period.
struct SubscriptionSpendingSummary: Equatable {
    /// Total spent in the period
    let totalSpent: Decimal
    /// Number of payments in the period
    let paymentCount: Int
    /// Spending by category
    let byCategory: [SubscriptionCategory: Decimal]
    /// Spending by card
    let byCard: [UUID: Decimal]
}

/// Protocol for subscription state management and business logic.
///
/// Responsibilities:
/// - Manage subscription state transitions (cancel, reactivate)
/// - Create payment records when subscriptions renew
/// - Advance renewal dates to next period
/// - Update card snapshots when card assignment changes
/// - Calculate spending summaries for reporting
///
/// This service is stateless and operates on provided data.
protocol SubscriptionStateServiceProtocol {

    // MARK: - State Transitions

    /// Determines if a subscription can be cancelled.
    /// - Parameter subscription: The subscription to check
    /// - Returns: True if the subscription is active and can be cancelled
    func canCancel(_ subscription: Subscription) -> Bool

    /// Determines if a subscription can be reactivated.
    /// - Parameter subscription: The subscription to check
    /// - Returns: True if the subscription is inactive and can be reactivated
    func canReactivate(_ subscription: Subscription) -> Bool

    /// Cancels a subscription by setting isActive to false.
    /// Also disables reminders and clears notification state.
    /// - Parameter subscription: The subscription to cancel
    func cancel(_ subscription: Subscription)

    /// Reactivates a cancelled subscription.
    /// Sets isActive to true and optionally updates the next renewal date.
    /// - Parameters:
    ///   - subscription: The subscription to reactivate
    ///   - nextRenewalDate: Optional new renewal date (defaults to today if not provided)
    func reactivate(_ subscription: Subscription, nextRenewalDate: Date?)

    // MARK: - Payment Recording

    /// Creates a payment record for a subscription renewal.
    /// - Parameters:
    ///   - subscription: The subscription being paid
    ///   - amount: Optional override amount (defaults to subscription price)
    ///   - autoRecorded: Whether this was auto-recorded by the system
    /// - Returns: A new SubscriptionPayment with denormalized snapshots
    func createPayment(
        for subscription: Subscription,
        amount: Decimal?,
        autoRecorded: Bool
    ) -> SubscriptionPayment

    /// Advances the subscription to the next renewal period.
    /// Creates a payment record and updates nextRenewalDate.
    /// - Parameters:
    ///   - subscription: The subscription to advance
    ///   - recordPayment: Whether to create a payment record (default true)
    /// - Returns: The payment record if created, nil if recordPayment was false
    func advanceToNextPeriod(
        _ subscription: Subscription,
        recordPayment: Bool
    ) -> SubscriptionPayment?

    // MARK: - Card Management

    /// Updates the card name snapshot when a subscription's card changes.
    /// - Parameters:
    ///   - subscription: The subscription to update
    ///   - cardName: The new card name (or nil if unassigned)
    func updateCardSnapshot(_ subscription: Subscription, cardName: String?)

    /// Updates snapshots for all subscriptions linked to a card.
    /// Call this when a card's name changes.
    /// - Parameters:
    ///   - subscriptions: The subscriptions to update
    ///   - newCardName: The new card name
    func updateAllCardSnapshots(_ subscriptions: [Subscription], newCardName: String)

    // MARK: - Spending Calculations

    /// Calculates spending summary for a date range.
    /// - Parameters:
    ///   - payments: The payment records to analyze
    ///   - startDate: Start of the period (inclusive)
    ///   - endDate: End of the period (inclusive)
    /// - Returns: A spending summary with totals and breakdowns
    func calculateSpending(
        from payments: [SubscriptionPayment],
        startDate: Date,
        endDate: Date
    ) -> SubscriptionSpendingSummary

    /// Calculates projected annual spending based on active subscriptions.
    /// - Parameter subscriptions: The subscriptions to analyze
    /// - Returns: The projected annual spending total
    func calculateProjectedAnnualSpending(_ subscriptions: [Subscription]) -> Decimal

    /// Calculates projected monthly spending based on active subscriptions.
    /// - Parameter subscriptions: The subscriptions to analyze
    /// - Returns: The projected monthly spending total
    func calculateProjectedMonthlySpending(_ subscriptions: [Subscription]) -> Decimal
}
