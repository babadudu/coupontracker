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
import Observation

/// ViewModel for managing card detail state and actions
@Observable
@MainActor
final class CardDetailViewModel {

    // MARK: - Dependencies

    private let cardRepository: CardRepositoryProtocol
    private let benefitRepository: BenefitRepositoryProtocol

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
        benefits
            .filter { $0.status == .available }
            .sorted { $0.daysUntilExpiration < $1.daysUntilExpiration }
    }

    /// Benefits that have been used in the current period
    var usedBenefits: [Benefit] {
        benefits.filter { $0.status == .used }
    }

    /// Benefits that have expired without being used
    var expiredBenefits: [Benefit] {
        benefits.filter { $0.status == .expired }
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
    init(
        card: UserCard,
        cardRepository: CardRepositoryProtocol,
        benefitRepository: BenefitRepositoryProtocol
    ) {
        self.card = card
        self.cardRepository = cardRepository
        self.benefitRepository = benefitRepository
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
            // Reload benefits to reflect the change
            loadBenefits()
        } catch {
            isLoading = false
            handleError(error, context: "snoozing benefit")
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
}

// MARK: - Preview Mock Repository

#if DEBUG

/// Mock card repository for SwiftUI previews
final class CardDetailMockCardRepository: CardRepositoryProtocol {
    var cards: [UserCard] = []
    var shouldThrowError = false

    func getAllCards() throws -> [UserCard] {
        if shouldThrowError { throw MockError.operationFailed }
        return cards
    }

    func getCard(by id: UUID) throws -> UserCard? {
        if shouldThrowError { throw MockError.operationFailed }
        return cards.first { $0.id == id }
    }

    func addCard(from template: CardTemplate, nickname: String?) throws -> UserCard {
        if shouldThrowError { throw MockError.operationFailed }
        let card = UserCard(
            cardTemplateId: template.id,
            nickname: nickname,
            isCustom: false,
            sortOrder: cards.count
        )
        cards.append(card)
        return card
    }

    func deleteCard(_ card: UserCard) throws {
        if shouldThrowError { throw MockError.operationFailed }
        cards.removeAll { $0.id == card.id }
    }

    func updateCard(_ card: UserCard) throws {
        if shouldThrowError { throw MockError.operationFailed }
        // In a real implementation, this would persist changes
    }
}

/// Mock benefit repository for SwiftUI previews
final class CardDetailMockBenefitRepository: BenefitRepositoryProtocol {
    var benefits: [Benefit] = []
    var shouldThrowError = false

    func getBenefits(for card: UserCard) throws -> [Benefit] {
        if shouldThrowError { throw MockError.operationFailed }
        return benefits.filter { $0.userCard?.id == card.id }
    }

    func getAllBenefits() throws -> [Benefit] {
        if shouldThrowError { throw MockError.operationFailed }
        return benefits
    }

    func getAvailableBenefits() throws -> [Benefit] {
        if shouldThrowError { throw MockError.operationFailed }
        return benefits.filter { $0.status == .available }
    }

    func getExpiringBenefits(within days: Int) throws -> [Benefit] {
        if shouldThrowError { throw MockError.operationFailed }
        return benefits.filter { benefit in
            benefit.status == .available && benefit.daysUntilExpiration <= days
        }
    }

    func markBenefitUsed(_ benefit: Benefit) throws {
        if shouldThrowError { throw MockError.operationFailed }
        benefit.markAsUsed()
    }

    func resetBenefitForNewPeriod(_ benefit: Benefit) throws {
        if shouldThrowError { throw MockError.operationFailed }
        let frequency = benefit.customFrequency ?? .monthly
        let dates = frequency.calculatePeriodDates()
        benefit.resetToNewPeriod(
            periodStart: dates.start,
            periodEnd: dates.end,
            nextReset: dates.nextReset
        )
    }

    func snoozeBenefit(_ benefit: Benefit, until date: Date) throws {
        if shouldThrowError { throw MockError.operationFailed }
        benefit.lastReminderDate = date
        benefit.updatedAt = Date()
    }
}

/// Mock error for testing
enum MockError: LocalizedError {
    case operationFailed

    var errorDescription: String? {
        switch self {
        case .operationFailed:
            return "The operation failed"
        }
    }
}

// MARK: - Preview Helper

extension CardDetailViewModel {
    /// Creates a mock view model for previews
    static var preview: CardDetailViewModel {
        let card = UserCard(
            cardTemplateId: UUID(),
            nickname: "Personal Platinum",
            isCustom: false,
            sortOrder: 0
        )

        let cardRepo = CardDetailMockCardRepository()
        cardRepo.cards = [card]

        let benefitRepo = CardDetailMockBenefitRepository()

        // Create mock benefits
        let calendar = Calendar.current
        let today = Date()

        // Available benefit expiring soon
        let uberCredit = Benefit(
            userCard: card,
            customName: "Uber Credit",
            customValue: 15,
            status: .available,
            currentPeriodStart: calendar.startOfDay(for: today),
            currentPeriodEnd: calendar.date(byAdding: .day, value: 3, to: today)!
        )

        // Available benefit with more time
        let airlineCredit = Benefit(
            userCard: card,
            customName: "Airline Fee Credit",
            customValue: 200,
            status: .available,
            currentPeriodStart: calendar.startOfDay(for: today),
            currentPeriodEnd: calendar.date(byAdding: .day, value: 90, to: today)!
        )

        // Used benefit
        let entertainmentCredit = Benefit(
            userCard: card,
            customName: "Entertainment Credit",
            customValue: 20,
            status: .used,
            currentPeriodStart: calendar.startOfDay(for: today),
            currentPeriodEnd: calendar.date(byAdding: .day, value: 15, to: today)!
        )

        // Expired benefit
        let hotelCredit = Benefit(
            userCard: card,
            customName: "Hotel Credit",
            customValue: 100,
            status: .expired,
            currentPeriodStart: calendar.date(byAdding: .day, value: -30, to: today)!,
            currentPeriodEnd: calendar.date(byAdding: .day, value: -1, to: today)!
        )

        benefitRepo.benefits = [uberCredit, airlineCredit, entertainmentCredit, hotelCredit]

        let viewModel = CardDetailViewModel(
            card: card,
            cardRepository: cardRepo,
            benefitRepository: benefitRepo
        )

        viewModel.loadBenefits()

        return viewModel
    }
}

#endif
