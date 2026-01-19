//
//  CardRepository.swift
//  CouponTracker
//
//  Created by Junior Engineer 3 on 2026-01-17.
//

import Foundation
import SwiftData

/// SwiftData implementation of CardRepositoryProtocol.
/// Provides CRUD operations for UserCard entities using SwiftData's ModelContext.
@MainActor
final class CardRepository: CardRepositoryProtocol {

    // MARK: - Properties

    private let modelContext: ModelContext

    // MARK: - Initialization

    /// Initializes the repository with a SwiftData model context.
    /// - Parameter modelContext: The SwiftData model context for persistence operations
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    // MARK: - CardRepositoryProtocol Implementation

    func getAllCards() throws -> [UserCard] {
        let descriptor = FetchDescriptor<UserCard>(
            sortBy: [SortDescriptor(\.sortOrder, order: .forward)]
        )
        let cards = try modelContext.fetch(descriptor)

        // Force benefits relationship to fully load (trigger lazy loading)
        // This ensures card.benefits and their properties are populated before UI access
        // Critical: Must access properties to ensure SwiftData loads them from storage
        for card in cards {
            for benefit in card.benefits {
                // Access key properties to force SwiftData to fully hydrate the object
                _ = benefit.customValue
                _ = benefit.customName
                _ = benefit.status
                _ = benefit.currentPeriodEnd
            }
        }

        return cards
    }

    func getCard(by id: UUID) throws -> UserCard? {
        let cardId = id
        let descriptor = FetchDescriptor<UserCard>(
            predicate: #Predicate<UserCard> { card in
                card.id == cardId
            }
        )
        return try modelContext.fetch(descriptor).first
    }

    func addCard(from template: CardTemplate, nickname: String?) throws -> UserCard {
        // Create the user card linked to the template
        let card = UserCard(
            cardTemplateId: template.id,
            nickname: nickname,
            isCustom: false
        )

        // Calculate sort order (append to end)
        let allCards = try getAllCards()
        card.sortOrder = allCards.count

        // Insert the card first
        modelContext.insert(card)

        // Create benefits from template and add to card
        for benefitTemplate in template.benefits {
            let benefit = try createBenefit(from: benefitTemplate, for: card)
            card.benefits.append(benefit)
            modelContext.insert(benefit)
        }

        // Save all changes
        try modelContext.save()

        return card
    }

    func deleteCard(_ card: UserCard) throws {
        modelContext.delete(card)
        try modelContext.save()
    }

    func updateCard(_ card: UserCard) throws {
        card.updatedAt = Date()
        try modelContext.save()
    }

    // MARK: - Private Helper Methods

    /// Creates a Benefit entity from a template with calculated initial period dates.
    /// - Parameters:
    ///   - template: The benefit template to create from
    ///   - card: The parent user card
    /// - Returns: A configured Benefit entity
    /// - Throws: Error if period calculation fails
    private func createBenefit(from template: BenefitTemplate, for card: UserCard) throws -> Benefit {
        // Use the BenefitFrequency enum's built-in period calculation
        let (periodStart, periodEnd, nextReset) = template.frequency.calculatePeriodDates(
            from: Date(),
            resetDayOfMonth: template.resetDayOfMonth
        )

        let benefit = Benefit(
            userCard: card,
            templateBenefitId: template.id,
            customName: template.name,
            customValue: template.value,
            status: .available,
            currentPeriodStart: periodStart,
            currentPeriodEnd: periodEnd,
            nextResetDate: nextReset,
            reminderEnabled: true,
            reminderDaysBefore: 7
        )

        // Denormalize frequency and category from template (Pattern 2: Denormalize at Creation)
        benefit.customFrequency = template.frequency
        benefit.customCategory = template.category

        return benefit
    }
}
