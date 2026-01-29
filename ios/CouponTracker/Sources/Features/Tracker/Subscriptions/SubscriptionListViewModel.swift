// SubscriptionListViewModel.swift
// CouponTracker
//
// Created: January 2026
// Purpose: ViewModel for subscription list managing state and operations.

import Foundation
import Observation

/// ViewModel for the subscription list screen.
///
/// Manages loading subscriptions, calculating totals, and filtering.
/// Uses ID-based navigation pattern (Pattern 3) for detail navigation.
@Observable
@MainActor
final class SubscriptionListViewModel {

    // MARK: - Dependencies

    private let subscriptionRepository: SubscriptionRepositoryProtocol
    private let stateService: SubscriptionStateServiceProtocol

    // MARK: - State

    /// All subscriptions from the repository
    private(set) var subscriptions: [Subscription] = []

    /// Loading state for async operations
    private(set) var isLoading = false

    /// Error message to display
    private(set) var errorMessage: String?

    /// Whether to show error alert
    var showingError = false

    /// Search query for filtering
    var searchQuery: String = ""

    /// Selected category filter
    var selectedCategory: SubscriptionCategory?

    /// Whether to show only active subscriptions
    var showActiveOnly: Bool = true

    // MARK: - Computed Properties

    /// Filtered subscriptions based on search and filters
    var filteredSubscriptions: [Subscription] {
        var result = subscriptions

        // Filter by active status
        if showActiveOnly {
            result = result.filter { $0.isActive }
        }

        // Filter by category
        if let category = selectedCategory {
            result = result.filter { $0.category == category }
        }

        // Filter by search query
        if !searchQuery.isEmpty {
            let query = searchQuery.lowercased()
            result = result.filter {
                $0.name.lowercased().contains(query)
            }
        }

        return result.sorted { $0.nextRenewalDate < $1.nextRenewalDate }
    }

    /// Active subscriptions
    var activeSubscriptions: [Subscription] {
        subscriptions.filter { $0.isActive }
    }

    /// Total monthly cost of active subscriptions
    var totalMonthlyCost: Decimal {
        stateService.calculateProjectedMonthlySpending(subscriptions)
    }

    /// Total annual cost of active subscriptions
    var totalAnnualCost: Decimal {
        stateService.calculateProjectedAnnualSpending(subscriptions)
    }

    /// Formatted monthly cost
    var formattedMonthlyCost: String {
        Formatters.formatCurrency(totalMonthlyCost)
    }

    /// Formatted annual cost
    var formattedAnnualCost: String {
        Formatters.formatCurrency(totalAnnualCost)
    }

    /// Count of subscriptions renewing soon (within 7 days)
    var renewingSoonCount: Int {
        activeSubscriptions.filter { $0.isRenewingSoon }.count
    }

    /// Subscriptions grouped by category
    var subscriptionsByCategory: [SubscriptionCategory: [Subscription]] {
        Dictionary(grouping: filteredSubscriptions, by: { $0.category })
    }

    // MARK: - Initialization

    init(
        subscriptionRepository: SubscriptionRepositoryProtocol,
        stateService: SubscriptionStateServiceProtocol = SubscriptionStateService()
    ) {
        self.subscriptionRepository = subscriptionRepository
        self.stateService = stateService
    }

    // MARK: - Actions

    /// Loads all subscriptions from the repository
    func loadSubscriptions() {
        isLoading = true
        errorMessage = nil

        do {
            subscriptions = try subscriptionRepository.getAllSubscriptions()
            isLoading = false
        } catch {
            isLoading = false
            handleError(error, context: "loading subscriptions")
        }
    }

    /// Refreshes the subscription list
    func refresh() {
        loadSubscriptions()
    }

    /// Deletes a subscription (Close-Before-Delete pattern)
    /// - Parameter id: The ID of the subscription to delete
    /// - Returns: True if deletion was successful
    func deleteSubscription(id: UUID) -> Bool {
        do {
            guard let subscription = try subscriptionRepository.getSubscription(by: id) else {
                return false
            }
            try subscriptionRepository.deleteSubscription(subscription)
            // Remove from local state
            subscriptions.removeAll { $0.id == id }
            return true
        } catch {
            handleError(error, context: "deleting subscription")
            return false
        }
    }

    /// Clears all filters
    func clearFilters() {
        searchQuery = ""
        selectedCategory = nil
        showActiveOnly = true
    }

    // MARK: - Error Handling

    private func handleError(_ error: Error, context: String) {
        errorMessage = "Error \(context): \(error.localizedDescription)"
        showingError = true
    }

    func dismissError() {
        showingError = false
        errorMessage = nil
    }
}

// MARK: - Preview Helper

#if DEBUG
extension SubscriptionListViewModel {
    @MainActor
    static var preview: SubscriptionListViewModel {
        let mockRepo = MockSubscriptionRepository()
        mockRepo.subscriptions = MockSubscriptionFactory.makeSampleSubscriptions()
        return SubscriptionListViewModel(subscriptionRepository: mockRepo)
    }
}
#endif
