//
//  CardDetailViewModel.swift
//  CouponTracker
//
//  Created by Junior Engineer 2 on 2026-01-17.
//
//  Purpose: ViewModel for CardDetailView that manages card benefits and user actions.
//           Handles loading benefits, marking as used, snoozing, and card deletion.
//

import Foundation
import SwiftUI
import SwiftData
import Observation

/// ViewModel for managing card detail state and actions
@Observable
@MainActor
final class CardDetailViewModel {

    // MARK: - Dependencies

    private let cardRepository: CardRepositoryProtocol
    private let benefitRepository: BenefitRepositoryProtocol
    private let notificationService: NotificationService
    private let modelContext: ModelContext

    // MARK: - State

    /// The card being displayed
    let card: UserCard

    /// All benefits for this card
    private(set) var benefits: [Benefit] = []

    /// Loading state for async operations
    private(set) var isLoading = false

    /// Whether the snooze options sheet is showing
    private(set) var showingSnoozeOptions = false

    /// Currently selected benefit for snooze action
    private(set) var selectedBenefit: Benefit?

    /// Error message to display to user
    private(set) var errorMessage: String?

    /// Whether an error alert should be shown
    private(set) var showingError = false

    // MARK: - Computed Properties

    /// Benefits that are currently available for use
    var availableBenefits: [Benefit] {
        benefits.availableBenefits
            .sorted { $0.daysUntilExpiration < $1.daysUntilExpiration }
    }

    /// Benefits that have been used in the current period
    var usedBenefits: [Benefit] {
        benefits.usedBenefits
    }

    /// Benefits that have expired without being used
    var expiredBenefits: [Benefit] {
        benefits.expiredBenefits
    }

    /// Total monetary value of all available benefits
    var totalAvailableValue: Decimal {
        availableBenefits.reduce(Decimal.zero) { $0 + $1.effectiveValue }
    }

    /// Formatted total available value as currency string
    var formattedTotalValue: String { Formatters.formatCurrency(totalAvailableValue) }

    /// Count of benefits expiring soon (within 7 days)
    var expiringBenefitsCount: Int {
        availableBenefits.filter { $0.isExpiringSoon }.count
    }

    // MARK: - Initialization

    /// Creates a new CardDetailViewModel
    /// - Parameters:
    ///   - card: The user card to display
    ///   - cardRepository: Repository for card operations
    ///   - benefitRepository: Repository for benefit operations
    ///   - notificationService: Service for managing benefit reminders
    ///   - modelContext: SwiftData context for fetching user preferences
    init(
        card: UserCard,
        cardRepository: CardRepositoryProtocol,
        benefitRepository: BenefitRepositoryProtocol,
        notificationService: NotificationService,
        modelContext: ModelContext
    ) {
        self.card = card
        self.cardRepository = cardRepository
        self.benefitRepository = benefitRepository
        self.notificationService = notificationService
        self.modelContext = modelContext
    }

    // MARK: - Actions

    /// Loads all benefits for the card from the repository
    func loadBenefits() {
        isLoading = true
        errorMessage = nil

        do {
            benefits = try benefitRepository.getBenefits(for: card)
            isLoading = false
        } catch {
            isLoading = false
            handleError(error, context: "loading benefits")
        }
    }

    /// Marks a benefit as used and creates a usage history record
    /// - Parameter benefit: The benefit to mark as used
    func markBenefitAsUsed(_ benefit: Benefit) {
        guard benefit.status == .available else {
            showError("This benefit is not available to be marked as used.")
            return
        }

        isLoading = true
        errorMessage = nil

        do {
            try benefitRepository.markBenefitUsed(benefit)

            // Cancel pending notifications for this benefit
            notificationService.cancelNotifications(for: benefit)

            // Reload benefits to reflect the change
            loadBenefits()
        } catch {
            isLoading = false
            handleError(error, context: "marking benefit as used")
        }
    }

    /// Snoozes a benefit's reminder for a specified number of days
    /// - Parameters:
    ///   - benefit: The benefit to snooze
    ///   - days: Number of days to snooze (1, 3, or 7)
    func snoozeBenefit(_ benefit: Benefit, days: Int) {
        guard benefit.status == .available else {
            showError("Only available benefits can be snoozed.")
            return
        }

        isLoading = true
        errorMessage = nil
        showingSnoozeOptions = false
        selectedBenefit = nil

        let calendar = Calendar.current
        guard let snoozeUntil = calendar.date(byAdding: .day, value: days, to: Date()) else {
            showError("Failed to calculate snooze date.")
            isLoading = false
            return
        }

        do {
            try benefitRepository.snoozeBenefit(benefit, until: snoozeUntil)

            // Schedule snoozed notification
            if let preferences = fetchUserPreferences() {
                notificationService.scheduleSnoozedNotification(
                    for: benefit,
                    snoozeDate: snoozeUntil,
                    preferences: preferences
                )
            }

            // Reload benefits to reflect the change
            loadBenefits()
        } catch {
            isLoading = false
            handleError(error, context: "snoozing benefit")
        }
    }

    /// Reverts a benefit from used back to available status
    /// - Parameter benefit: The benefit to undo
    func undoMarkBenefitUsed(_ benefit: Benefit) {
        guard benefit.status == .used else {
            showError("This benefit is not marked as used.")
            return
        }

        isLoading = true
        errorMessage = nil

        do {
            try benefitRepository.undoMarkBenefitUsed(benefit)

            // Reschedule notifications for the restored benefit
            Task {
                guard let preferences = fetchUserPreferences() else { return }
                await notificationService.scheduleNotifications(
                    for: benefit,
                    preferences: preferences
                )
            }

            // Reload benefits to reflect the change
            loadBenefits()
        } catch {
            isLoading = false
            handleError(error, context: "undoing benefit usage")
        }
    }

    /// Shows snooze options for a specific benefit
    /// - Parameter benefit: The benefit to show snooze options for
    func showSnoozeOptions(for benefit: Benefit) {
        selectedBenefit = benefit
        showingSnoozeOptions = true
    }

    /// Hides the snooze options sheet
    func hideSnoozeOptions() {
        showingSnoozeOptions = false
        selectedBenefit = nil
    }

    /// Deletes the card and all its associated benefits
    /// - Throws: Repository error if deletion fails
    func deleteCard() throws {
        isLoading = true
        errorMessage = nil

        // Cancel notifications for all benefits before deletion
        notificationService.cancelNotifications(
            forCardId: card.id,
            benefits: Array(card.benefits)
        )

        do {
            try cardRepository.deleteCard(card)
            isLoading = false
        } catch {
            isLoading = false
            throw error
        }
    }

    // MARK: - Error Handling

    /// Handles errors by setting appropriate error messages
    /// - Parameters:
    ///   - error: The error that occurred
    ///   - context: Context description for the error
    private func handleError(_ error: Error, context: String) {
        errorMessage = "Error \(context): \(error.localizedDescription)"
        showingError = true
    }

    /// Shows a custom error message
    /// - Parameter message: The error message to display
    private func showError(_ message: String) {
        errorMessage = message
        showingError = true
    }

    /// Dismisses the error alert
    func dismissError() {
        showingError = false
        errorMessage = nil
    }

    // MARK: - Private Helpers

    /// Fetches the singleton UserPreferences from SwiftData
    private func fetchUserPreferences() -> UserPreferences? {
        let descriptor = FetchDescriptor<UserPreferences>()
        return try? modelContext.fetch(descriptor).first
    }
}

// MARK: - Preview Helper

#if DEBUG
extension CardDetailViewModel {
    /// Creates a mock view model for previews
    @MainActor
    static var preview: CardDetailViewModel {
        let card = MockDataFactory.makeCard(nickname: "Personal Platinum", benefitCount: 4)

        let cardRepo = MockCardRepository()
        cardRepo.cards = [card]

        let benefitRepo = MockBenefitRepository()
        benefitRepo.benefits = card.benefits

        // Customize benefit statuses for variety
        if card.benefits.count >= 4 {
            card.benefits[2].status = .used
            card.benefits[3].status = .expired
        }

        let container = AppContainer.preview

        let viewModel = CardDetailViewModel(
            card: card,
            cardRepository: cardRepo,
            benefitRepository: benefitRepo,
            notificationService: container.notificationService,
            modelContext: container.modelContext
        )

        viewModel.loadBenefits()

        return viewModel
    }
}
#endif
