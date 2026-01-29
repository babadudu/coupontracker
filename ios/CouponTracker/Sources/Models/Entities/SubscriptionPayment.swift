// SubscriptionPayment.swift
// CouponTracker
//
// Created: January 2026
// Purpose: SwiftData entity representing a subscription payment record.
//          Tracks payment history for subscriptions with denormalized snapshots.

import SwiftData
import Foundation

/// Represents a payment record for a subscription.
///
/// Payment records maintain historical data through snapshots,
/// allowing display even after subscription or card deletion.
///
/// Relationships:
/// - SubscriptionPayment -> Subscription: N:1 (nullify on delete)
@Model
final class SubscriptionPayment {

    // MARK: - Primary Key

    /// Unique identifier for the payment record
    @Attribute(.unique)
    var id: UUID = UUID()

    // MARK: - Relationships

    /// The subscription this payment belongs to (may be nil if subscription deleted)
    var subscription: Subscription?

    // MARK: - Payment Details

    /// Date the payment was made
    var paymentDate: Date = Date()

    /// Amount paid
    var amount: Decimal = 0

    /// Start of the period this payment covers
    var periodStart: Date = Date()

    /// End of the period this payment covers
    var periodEnd: Date = Date()

    /// Whether this payment was auto-recorded by the system
    var wasAutoRecorded: Bool = false

    // MARK: - Denormalized Snapshots (Pattern 2)

    /// Snapshot of subscription name at time of payment
    var subscriptionNameSnapshot: String = ""

    /// Snapshot of card name at time of payment
    var cardNameSnapshot: String?

    /// Snapshot of card ID for reference
    var cardIdSnapshot: UUID?

    // MARK: - Metadata

    /// Record creation timestamp
    var createdAt: Date = Date()

    // MARK: - Initialization

    init(
        id: UUID = UUID(),
        subscription: Subscription? = nil,
        paymentDate: Date = Date(),
        amount: Decimal = 0,
        periodStart: Date = Date(),
        periodEnd: Date = Date(),
        wasAutoRecorded: Bool = false,
        subscriptionNameSnapshot: String = "",
        cardNameSnapshot: String? = nil,
        cardIdSnapshot: UUID? = nil
    ) {
        self.id = id
        self.subscription = subscription
        self.paymentDate = paymentDate
        self.amount = amount
        self.periodStart = periodStart
        self.periodEnd = periodEnd
        self.wasAutoRecorded = wasAutoRecorded
        self.subscriptionNameSnapshot = subscriptionNameSnapshot
        self.cardNameSnapshot = cardNameSnapshot
        self.cardIdSnapshot = cardIdSnapshot
        self.createdAt = Date()
    }

    // MARK: - Computed Properties

    /// Formatted payment amount
    var formattedAmount: String {
        Formatters.formatCurrency(amount)
    }

    /// Formatted date for display
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: paymentDate)
    }

    /// Formatted period range
    var formattedPeriod: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .none
        return "\(formatter.string(from: periodStart)) - \(formatter.string(from: periodEnd))"
    }

    /// Display name (subscription name snapshot for orphaned payments)
    var displayName: String {
        subscription?.name ?? subscriptionNameSnapshot
    }

    /// Display card name (snapshot if card no longer linked)
    var displayCardName: String? {
        subscription?.cardNameSnapshot ?? cardNameSnapshot
    }

    /// Number of days the payment period covers
    var periodDays: Int {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.day], from: periodStart, to: periodEnd)
        return (components.day ?? 0) + 1
    }

    // MARK: - Factory Methods

    /// Create a payment record from a subscription
    /// - Parameters:
    ///   - subscription: The subscription being paid
    ///   - amount: Payment amount (defaults to subscription price)
    ///   - periodStart: Start of covered period
    ///   - periodEnd: End of covered period
    ///   - autoRecorded: Whether system auto-recorded this
    /// - Returns: A new SubscriptionPayment with snapshots populated
    static func create(
        for subscription: Subscription,
        amount: Decimal? = nil,
        periodStart: Date,
        periodEnd: Date,
        autoRecorded: Bool = false
    ) -> SubscriptionPayment {
        SubscriptionPayment(
            subscription: subscription,
            paymentDate: Date(),
            amount: amount ?? subscription.price,
            periodStart: periodStart,
            periodEnd: periodEnd,
            wasAutoRecorded: autoRecorded,
            subscriptionNameSnapshot: subscription.name,
            cardNameSnapshot: subscription.cardNameSnapshot,
            cardIdSnapshot: subscription.userCard?.id
        )
    }
}

// MARK: - IdentifiableEntity Conformance

extension SubscriptionPayment: IdentifiableEntity {}
