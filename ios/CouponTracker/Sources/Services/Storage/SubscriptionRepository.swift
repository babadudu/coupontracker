// SubscriptionRepository.swift
// CouponTracker
//
// SwiftData implementation of SubscriptionRepositoryProtocol.

import Foundation
import SwiftData

/// SwiftData implementation of SubscriptionRepositoryProtocol.
/// Provides CRUD operations for Subscription entities.
@MainActor
final class SubscriptionRepository: SubscriptionRepositoryProtocol {

    // MARK: - Properties

    private let modelContext: ModelContext

    // MARK: - Initialization

    /// Initializes the repository with a SwiftData model context.
    /// - Parameter modelContext: The SwiftData model context for persistence operations
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    // MARK: - Read Operations

    func getAllSubscriptions() throws -> [Subscription] {
        let descriptor = FetchDescriptor<Subscription>(
            sortBy: [SortDescriptor(\.nextRenewalDate, order: .forward)]
        )
        let subscriptions = try modelContext.fetch(descriptor)

        // Force lazy loading of payment history
        for subscription in subscriptions {
            _ = subscription.paymentHistory.count
        }

        return subscriptions
    }

    func getSubscription(by id: UUID) throws -> Subscription? {
        let subscriptionId = id
        let descriptor = FetchDescriptor<Subscription>(
            predicate: #Predicate<Subscription> { subscription in
                subscription.id == subscriptionId
            }
        )
        return try modelContext.fetch(descriptor).first
    }

    func getActiveSubscriptions() throws -> [Subscription] {
        let descriptor = FetchDescriptor<Subscription>(
            sortBy: [SortDescriptor(\.nextRenewalDate, order: .forward)]
        )
        let all = try modelContext.fetch(descriptor)
        return all.filter { $0.isActive }
    }

    func getSubscriptions(for cardId: UUID) throws -> [Subscription] {
        let descriptor = FetchDescriptor<Subscription>(
            sortBy: [SortDescriptor(\.nextRenewalDate, order: .forward)]
        )
        let all = try modelContext.fetch(descriptor)
        return all.filter { $0.userCard?.id == cardId }
    }

    func getSubscriptionsRenewingSoon(within days: Int) throws -> [Subscription] {
        let calendar = Calendar.current
        let now = Date()
        let threshold = calendar.date(byAdding: .day, value: days, to: now) ?? now

        let descriptor = FetchDescriptor<Subscription>(
            sortBy: [SortDescriptor(\.nextRenewalDate, order: .forward)]
        )
        let all = try modelContext.fetch(descriptor)
        return all.filter {
            $0.isActive && $0.nextRenewalDate <= threshold && $0.nextRenewalDate >= now
        }
    }

    // MARK: - Write Operations

    func addSubscription(_ subscription: Subscription) throws {
        modelContext.insert(subscription)
        try modelContext.save()
    }

    func updateSubscription(_ subscription: Subscription) throws {
        subscription.updatedAt = Date()
        try modelContext.save()
    }

    func deleteSubscription(_ subscription: Subscription) throws {
        modelContext.delete(subscription)
        try modelContext.save()
    }
}
