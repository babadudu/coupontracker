// SubscriptionRepositoryProtocol.swift
// CouponTracker
//
// Protocol defining subscription repository operations.

import Foundation

/// Protocol defining subscription repository operations for managing subscriptions.
/// Abstracts the data layer to allow for different implementations and testing.
@MainActor
protocol SubscriptionRepositoryProtocol {

    // MARK: - Read Operations

    /// Retrieves all subscriptions from storage, sorted by next renewal date.
    /// - Returns: Array of all subscriptions
    /// - Throws: Repository error if fetch fails
    func getAllSubscriptions() throws -> [Subscription]

    /// Retrieves a specific subscription by its unique identifier.
    /// - Parameter id: The UUID of the subscription to retrieve
    /// - Returns: The subscription if found, nil otherwise
    /// - Throws: Repository error if fetch fails
    func getSubscription(by id: UUID) throws -> Subscription?

    /// Retrieves all active subscriptions.
    /// - Returns: Array of active subscriptions sorted by renewal date
    /// - Throws: Repository error if fetch fails
    func getActiveSubscriptions() throws -> [Subscription]

    /// Retrieves subscriptions for a specific card.
    /// - Parameter cardId: The UUID of the card
    /// - Returns: Array of subscriptions linked to the card
    /// - Throws: Repository error if fetch fails
    func getSubscriptions(for cardId: UUID) throws -> [Subscription]

    /// Retrieves subscriptions renewing within a specified number of days.
    /// - Parameter days: Number of days to look ahead
    /// - Returns: Array of subscriptions renewing within the timeframe
    /// - Throws: Repository error if fetch fails
    func getSubscriptionsRenewingSoon(within days: Int) throws -> [Subscription]

    // MARK: - Write Operations

    /// Adds a new subscription to storage.
    /// - Parameter subscription: The subscription to add
    /// - Throws: Repository error if creation fails
    func addSubscription(_ subscription: Subscription) throws

    /// Updates an existing subscription in storage.
    /// - Parameter subscription: The subscription with updated properties
    /// - Throws: Repository error if update fails
    func updateSubscription(_ subscription: Subscription) throws

    /// Deletes a subscription from storage.
    /// This will cascade delete all associated payment history.
    /// - Parameter subscription: The subscription to delete
    /// - Throws: Repository error if deletion fails
    func deleteSubscription(_ subscription: Subscription) throws
}
