// SubscriptionStateService.swift
// CouponTracker
//
// Created: January 2026
// Purpose: Implementation of subscription state management business logic.

import Foundation

/// SubscriptionStateService
///
/// Responsibilities:
/// - Manage subscription state transitions (cancel, reactivate)
/// - Create payment records when subscriptions renew
/// - Advance renewal dates to next period
/// - Update card snapshots when card assignment changes
/// - Calculate spending summaries for reporting
///
/// Dependencies:
/// - None (stateless service with no external dependencies)
///
/// Thread Safety: Sendable (value type)
struct SubscriptionStateService: SubscriptionStateServiceProtocol {

    // MARK: - State Transitions

    func canCancel(_ subscription: Subscription) -> Bool {
        subscription.isActive
    }

    func canReactivate(_ subscription: Subscription) -> Bool {
        !subscription.isActive
    }

    func cancel(_ subscription: Subscription) {
        guard canCancel(subscription) else { return }
        subscription.cancel()
    }

    func reactivate(_ subscription: Subscription, nextRenewalDate: Date?) {
        guard canReactivate(subscription) else { return }
        subscription.reactivate(nextRenewal: nextRenewalDate ?? Date())
    }

    // MARK: - Payment Recording

    func createPayment(
        for subscription: Subscription,
        amount: Decimal?,
        autoRecorded: Bool
    ) -> SubscriptionPayment {
        let periodStart = subscription.nextRenewalDate
        let periodEnd = subscription.frequency.nextRenewalDate(from: periodStart)

        return SubscriptionPayment.create(
            for: subscription,
            amount: amount,
            periodStart: periodStart,
            periodEnd: Calendar.current.date(byAdding: .day, value: -1, to: periodEnd) ?? periodEnd,
            autoRecorded: autoRecorded
        )
    }

    func advanceToNextPeriod(
        _ subscription: Subscription,
        recordPayment: Bool
    ) -> SubscriptionPayment? {
        guard subscription.isActive else { return nil }

        var payment: SubscriptionPayment?

        if recordPayment {
            payment = createPayment(
                for: subscription,
                amount: nil,
                autoRecorded: true
            )
            subscription.paymentHistory.append(payment!)
        }

        subscription.advanceToNextPeriod()
        return payment
    }

    // MARK: - Card Management

    func updateCardSnapshot(_ subscription: Subscription, cardName: String?) {
        subscription.updateCardSnapshot(cardName: cardName)
    }

    func updateAllCardSnapshots(_ subscriptions: [Subscription], newCardName: String) {
        for subscription in subscriptions {
            subscription.updateCardSnapshot(cardName: newCardName)
        }
    }

    // MARK: - Spending Calculations

    func calculateSpending(
        from payments: [SubscriptionPayment],
        startDate: Date,
        endDate: Date
    ) -> SubscriptionSpendingSummary {
        let calendar = Calendar.current
        let startOfStart = calendar.startOfDay(for: startDate)
        let startOfEnd = calendar.startOfDay(for: endDate)

        // Filter payments within date range
        let filteredPayments = payments.filter { payment in
            let paymentDay = calendar.startOfDay(for: payment.paymentDate)
            return paymentDay >= startOfStart && paymentDay <= startOfEnd
        }

        // Calculate total
        let total = filteredPayments.reduce(Decimal.zero) { $0 + $1.amount }

        // Group by category
        var byCategory: [SubscriptionCategory: Decimal] = [:]
        for payment in filteredPayments {
            let category = payment.subscription?.category ?? .other
            byCategory[category, default: 0] += payment.amount
        }

        // Group by card
        var byCard: [UUID: Decimal] = [:]
        for payment in filteredPayments {
            if let cardId = payment.cardIdSnapshot {
                byCard[cardId, default: 0] += payment.amount
            }
        }

        return SubscriptionSpendingSummary(
            totalSpent: total,
            paymentCount: filteredPayments.count,
            byCategory: byCategory,
            byCard: byCard
        )
    }

    func calculateProjectedAnnualSpending(_ subscriptions: [Subscription]) -> Decimal {
        subscriptions
            .filter { $0.isActive }
            .reduce(Decimal.zero) { $0 + $1.annualizedCost }
    }

    func calculateProjectedMonthlySpending(_ subscriptions: [Subscription]) -> Decimal {
        subscriptions
            .filter { $0.isActive }
            .reduce(Decimal.zero) { $0 + $1.monthlyCost }
    }
}
