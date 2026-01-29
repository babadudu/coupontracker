// SubscriptionDetailViewModel.swift
// CouponTracker
//
// Created: January 2026
// Purpose: ViewModel for subscription detail view managing single subscription operations.

import Foundation
import Observation

/// ViewModel for subscription detail screen.
///
/// Manages viewing subscription details, marking as paid,
/// canceling, and reactivating subscriptions.
@Observable
@MainActor
final class SubscriptionDetailViewModel {

    // MARK: - Dependencies

    private let subscriptionRepository: SubscriptionRepositoryProtocol
    private let stateService: SubscriptionStateServiceProtocol
    private let notificationService: NotificationService

    // MARK: - State

    /// The subscription ID being managed
    let subscriptionId: UUID

    /// The subscription data (fetched fresh)
    private(set) var subscription: Subscription?

    /// Loading state
    private(set) var isLoading = false

    /// Error message
    private(set) var errorMessage: String?

    /// Whether to show error alert
    var showingError = false

    /// Whether to show cancel confirmation
    var showingCancelConfirmation = false

    /// Whether to show payment confirmation
    var showingPaymentConfirmation = false

    // MARK: - Computed Properties

    /// Whether the subscription can be canceled
    var canCancel: Bool {
        guard let subscription = subscription else { return false }
        return stateService.canCancel(subscription)
    }

    /// Whether the subscription can be reactivated
    var canReactivate: Bool {
        guard let subscription = subscription else { return false }
        return stateService.canReactivate(subscription)
    }

    /// Total amount paid for this subscription
    var totalPaid: Decimal {
        subscription?.totalPaid ?? 0
    }

    /// Formatted total paid
    var formattedTotalPaid: String {
        Formatters.formatCurrency(totalPaid)
    }

    /// Payment count
    var paymentCount: Int {
        subscription?.paymentHistory.count ?? 0
    }

    // MARK: - Initialization

    init(
        subscriptionId: UUID,
        subscriptionRepository: SubscriptionRepositoryProtocol,
        stateService: SubscriptionStateServiceProtocol = SubscriptionStateService(),
        notificationService: NotificationService
    ) {
        self.subscriptionId = subscriptionId
        self.subscriptionRepository = subscriptionRepository
        self.stateService = stateService
        self.notificationService = notificationService
    }

    // MARK: - Actions

    /// Loads the subscription from repository (fetches fresh - Pattern 3)
    func loadSubscription() {
        isLoading = true
        errorMessage = nil

        do {
            subscription = try subscriptionRepository.getSubscription(by: subscriptionId)
            isLoading = false
        } catch {
            isLoading = false
            handleError(error, context: "loading subscription")
        }
    }

    /// Records a manual payment and advances to next period
    func markAsPaid() {
        guard let subscription = subscription else { return }

        isLoading = true
        errorMessage = nil

        do {
            // Create payment and advance period
            _ = stateService.advanceToNextPeriod(subscription, recordPayment: true)

            // Update repository
            try subscriptionRepository.updateSubscription(subscription)

            // Reschedule notification - async call wrapped in Task
            Task {
                await notificationService.scheduleSubscriptionRenewalNotification(
                    for: subscription,
                    preferences: UserPreferences()
                )
            }

            isLoading = false
        } catch {
            isLoading = false
            handleError(error, context: "recording payment")
        }
    }

    /// Cancels the subscription
    func cancelSubscription() {
        guard let subscription = subscription else { return }

        isLoading = true
        errorMessage = nil

        do {
            stateService.cancel(subscription)
            try subscriptionRepository.updateSubscription(subscription)

            // Cancel any scheduled notifications
            notificationService.cancelSubscriptionNotification(for: subscription)

            isLoading = false
        } catch {
            isLoading = false
            handleError(error, context: "canceling subscription")
        }
    }

    /// Reactivates a canceled subscription
    func reactivateSubscription() {
        guard let subscription = subscription else { return }

        isLoading = true
        errorMessage = nil

        do {
            stateService.reactivate(subscription, nextRenewalDate: Date())
            try subscriptionRepository.updateSubscription(subscription)

            // Schedule notification for reactivated subscription
            Task {
                await notificationService.scheduleSubscriptionRenewalNotification(
                    for: subscription,
                    preferences: UserPreferences()
                )
            }

            isLoading = false
        } catch {
            isLoading = false
            handleError(error, context: "reactivating subscription")
        }
    }

    /// Deletes the subscription
    /// - Returns: True if successful
    func deleteSubscription() -> Bool {
        guard let subscription = subscription else { return false }

        isLoading = true
        errorMessage = nil

        do {
            notificationService.cancelSubscriptionNotification(for: subscription)
            try subscriptionRepository.deleteSubscription(subscription)
            isLoading = false
            return true
        } catch {
            isLoading = false
            handleError(error, context: "deleting subscription")
            return false
        }
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
extension SubscriptionDetailViewModel {
    @MainActor
    static var preview: SubscriptionDetailViewModel {
        let mockRepo = MockSubscriptionRepository()
        let sample = MockSubscriptionFactory.makeSampleSubscriptions().first!
        mockRepo.subscriptions = [sample]

        let vm = SubscriptionDetailViewModel(
            subscriptionId: sample.id,
            subscriptionRepository: mockRepo,
            notificationService: NotificationService()
        )
        vm.loadSubscription()
        return vm
    }
}
#endif
