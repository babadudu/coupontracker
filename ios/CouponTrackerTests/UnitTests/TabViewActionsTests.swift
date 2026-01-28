//
//  TabViewActionsTests.swift
//  CouponTrackerTests
//
//  Created: January 2026
//  Purpose: Tests for action patterns used in HomeTabView and WalletTabView.
//           Verifies mark as done, snooze, undo, and delete operations.
//

import XCTest
import SwiftData
@testable import CouponTracker

/// Tests for the action patterns used in tab views.
/// These tests verify the repository operations that back the UI actions.
@MainActor
final class TabViewActionsTests: XCTestCase {

    // MARK: - Properties

    var modelContainer: ModelContainer!
    var modelContext: ModelContext!
    var cardRepository: CardRepository!
    var benefitRepository: BenefitRepository!
    var notificationService: NotificationService!

    // MARK: - Setup & Teardown

    override func setUp() async throws {
        try await super.setUp()

        let schema = Schema([
            UserCard.self,
            Benefit.self,
            BenefitUsage.self,
            UserPreferences.self
        ])

        let modelConfiguration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: true
        )

        modelContainer = try ModelContainer(
            for: schema,
            configurations: [modelConfiguration]
        )

        modelContext = ModelContext(modelContainer)
        cardRepository = CardRepository(modelContext: modelContext)
        benefitRepository = BenefitRepository(modelContext: modelContext)
        notificationService = NotificationService()
    }

    override func tearDown() async throws {
        notificationService = nil
        benefitRepository = nil
        cardRepository = nil
        modelContext = nil
        modelContainer = nil
        try await super.tearDown()
    }

    // MARK: - Mark Benefit As Done Tests

    func testMarkBenefitAsDone_ByPreviewBenefitId_MarksBenefit() async throws {
        // Given - Simulate the pattern from HomeTabView.markBenefitAsDone
        let template = createMockCardTemplate(benefitValue: 50)
        let card = try cardRepository.addCard(from: template, nickname: "Test Card")

        guard let benefit = card.benefits.first else {
            XCTFail("Card should have benefits")
            return
        }

        let benefitId = benefit.id

        // When - Find benefit by ID and mark as done (pattern from tab views)
        let allBenefits = try benefitRepository.getAllBenefits()
        if let matchingBenefit = allBenefits.first(where: { $0.id == benefitId }) {
            try benefitRepository.markBenefitUsed(matchingBenefit)
        }

        // Then
        XCTAssertEqual(benefit.status, .used, "Benefit should be marked as used")
    }

    func testMarkBenefitAsDone_NonExistentId_DoesNotCrash() async throws {
        // Given
        let template = createMockCardTemplate()
        _ = try cardRepository.addCard(from: template, nickname: "Test Card")

        let nonExistentId = UUID()

        // When - Try to find and mark non-existent benefit
        let allBenefits = try benefitRepository.getAllBenefits()
        let matchingBenefit = allBenefits.first(where: { $0.id == nonExistentId })

        // Then
        XCTAssertNil(matchingBenefit, "Should not find non-existent benefit")
        // No crash means success
    }

    // MARK: - Snooze Benefit Tests

    func testSnoozeBenefit_SetsLastReminderDate() async throws {
        // Given
        let template = createMockCardTemplate()
        let card = try cardRepository.addCard(from: template, nickname: "Test Card")

        guard let benefit = card.benefits.first else {
            XCTFail("Card should have benefits")
            return
        }

        let snoozeDate = Calendar.current.date(byAdding: .day, value: 3, to: Date())!

        // When - Pattern from tab views (snoozeBenefit sets lastReminderDate)
        try benefitRepository.snoozeBenefit(benefit, until: snoozeDate)

        // Then - lastReminderDate is updated to the snooze date
        XCTAssertNotNil(benefit.lastReminderDate, "Last reminder date should be set")
        XCTAssertEqual(
            Calendar.current.startOfDay(for: benefit.lastReminderDate!),
            Calendar.current.startOfDay(for: snoozeDate),
            "Last reminder date should match snooze date"
        )
    }

    func testSnoozeBenefit_1Day_SetsCorrectDate() async throws {
        // Given
        let template = createMockCardTemplate()
        let card = try cardRepository.addCard(from: template, nickname: "Test Card")

        guard let benefit = card.benefits.first else {
            XCTFail("Card should have benefits")
            return
        }

        let days = 1
        let snoozeDate = Calendar.current.date(byAdding: .day, value: days, to: Date()) ?? Date()

        // When
        try benefitRepository.snoozeBenefit(benefit, until: snoozeDate)

        // Then
        XCTAssertNotNil(benefit.lastReminderDate, "Should have last reminder date set")

        let daysDifference = Calendar.current.dateComponents(
            [.day],
            from: Calendar.current.startOfDay(for: Date()),
            to: Calendar.current.startOfDay(for: benefit.lastReminderDate!)
        ).day ?? 0

        XCTAssertEqual(daysDifference, 1, "Should be snoozed for 1 day")
    }

    func testSnoozeBenefit_7Days_SetsCorrectDate() async throws {
        // Given
        let template = createMockCardTemplate()
        let card = try cardRepository.addCard(from: template, nickname: "Test Card")

        guard let benefit = card.benefits.first else {
            XCTFail("Card should have benefits")
            return
        }

        let days = 7
        let snoozeDate = Calendar.current.date(byAdding: .day, value: days, to: Date()) ?? Date()

        // When
        try benefitRepository.snoozeBenefit(benefit, until: snoozeDate)

        // Then
        let daysDifference = Calendar.current.dateComponents(
            [.day],
            from: Calendar.current.startOfDay(for: Date()),
            to: Calendar.current.startOfDay(for: benefit.lastReminderDate!)
        ).day ?? 0

        XCTAssertEqual(daysDifference, 7, "Should be snoozed for 7 days")
    }

    // MARK: - Undo Mark Benefit Used Tests

    func testUndoMarkBenefitUsed_RestoresAvailableStatus() async throws {
        // Given
        let template = createMockCardTemplate()
        let card = try cardRepository.addCard(from: template, nickname: "Test Card")

        guard let benefit = card.benefits.first else {
            XCTFail("Card should have benefits")
            return
        }

        try benefitRepository.markBenefitUsed(benefit)
        XCTAssertEqual(benefit.status, .used, "Should be used after marking")

        // When - Pattern from tab views
        try benefitRepository.undoMarkBenefitUsed(benefit)

        // Then
        XCTAssertEqual(benefit.status, .available, "Should be available after undo")
    }

    func testUndoMarkBenefitUsed_OnUsedBenefit_Succeeds() async throws {
        // Given
        let template = createMockCardTemplate(benefitValue: 100)
        let card = try cardRepository.addCard(from: template, nickname: "Test Card")

        guard let benefit = card.benefits.first else {
            XCTFail("Card should have benefits")
            return
        }

        let benefitId = benefit.id
        try benefitRepository.markBenefitUsed(benefit)

        // When - Find by ID and undo (pattern from tab views)
        let allBenefits = try benefitRepository.getAllBenefits()
        if let matchingBenefit = allBenefits.first(where: { $0.id == benefitId }) {
            try benefitRepository.undoMarkBenefitUsed(matchingBenefit)
        }

        // Then
        XCTAssertEqual(benefit.status, .available, "Benefit should be available after undo")
    }

    // MARK: - Delete Card Tests

    func testDeleteCard_RemovesCardFromRepository() async throws {
        // Given
        let template = createMockCardTemplate()
        let card = try cardRepository.addCard(from: template, nickname: "To Delete")
        let cardId = card.id

        // Verify card exists
        let cardsBefore = try cardRepository.getAllCards()
        XCTAssertEqual(cardsBefore.count, 1, "Should have one card")

        // When - Pattern from tab views: find by ID and delete
        let allCards = try cardRepository.getAllCards()
        if let matchingCard = allCards.first(where: { $0.id == cardId }) {
            try cardRepository.deleteCard(matchingCard)
        }

        // Then
        let cardsAfter = try cardRepository.getAllCards()
        XCTAssertEqual(cardsAfter.count, 0, "Should have no cards after delete")
    }

    func testDeleteCard_CascadeDeletesBenefits() async throws {
        // Given
        let template = createMockCardTemplate()
        let card = try cardRepository.addCard(from: template, nickname: "Test Card")
        let cardId = card.id
        let benefitCount = card.benefits.count

        XCTAssertGreaterThan(benefitCount, 0, "Card should have benefits")

        // When
        let allCards = try cardRepository.getAllCards()
        if let matchingCard = allCards.first(where: { $0.id == cardId }) {
            try cardRepository.deleteCard(matchingCard)
        }

        // Then
        let remainingBenefits = try benefitRepository.getAllBenefits()
        XCTAssertEqual(remainingBenefits.count, 0, "All benefits should be deleted with card")
    }

    func testDeleteCard_WithUsedBenefits_DeletesUsageRecords() async throws {
        // Given
        let template = createMockCardTemplate()
        let card = try cardRepository.addCard(from: template, nickname: "Test Card")

        // Mark a benefit as used
        if let benefit = card.benefits.first {
            try benefitRepository.markBenefitUsed(benefit)
        }

        // Verify usage exists
        let usagesBefore = try modelContext.fetch(FetchDescriptor<BenefitUsage>())
        XCTAssertEqual(usagesBefore.count, 1, "Should have one usage record")

        // When
        try cardRepository.deleteCard(card)

        // Then
        let usagesAfter = try modelContext.fetch(FetchDescriptor<BenefitUsage>())
        XCTAssertEqual(usagesAfter.count, 0, "Usage records should be deleted with card")
    }

    // MARK: - Find Benefit by ID Pattern Tests

    func testFindBenefitById_WithValidId_FindsBenefit() async throws {
        // Given
        let template = createMockCardTemplate()
        let card = try cardRepository.addCard(from: template, nickname: "Test Card")

        guard let benefit = card.benefits.first else {
            XCTFail("Card should have benefits")
            return
        }

        let searchId = benefit.id

        // When - Pattern from tab views
        let allBenefits = try benefitRepository.getAllBenefits()
        let foundBenefit = allBenefits.first(where: { $0.id == searchId })

        // Then
        XCTAssertNotNil(foundBenefit, "Should find benefit by ID")
        XCTAssertEqual(foundBenefit?.id, searchId, "Found benefit should have correct ID")
    }

    func testFindBenefitById_WithMultipleCards_FindsCorrectBenefit() async throws {
        // Given
        let template1 = createMockCardTemplate(benefitValue: 100)
        let template2 = createMockCardTemplate(benefitValue: 200)

        let card1 = try cardRepository.addCard(from: template1, nickname: "Card 1")
        let card2 = try cardRepository.addCard(from: template2, nickname: "Card 2")

        guard let benefit1 = card1.benefits.first,
              let benefit2 = card2.benefits.first else {
            XCTFail("Cards should have benefits")
            return
        }

        let searchId = benefit2.id

        // When
        let allBenefits = try benefitRepository.getAllBenefits()
        let foundBenefit = allBenefits.first(where: { $0.id == searchId })

        // Then
        XCTAssertNotNil(foundBenefit, "Should find benefit from second card")
        XCTAssertEqual(foundBenefit?.customValue ?? foundBenefit?.effectiveValue, 200, "Should find benefit with correct value")
    }

    // MARK: - Integration Pattern Tests

    func testFullMarkUndoFlowWithIdLookup() async throws {
        // Given - Simulate complete flow from tab view
        let template = createMockCardTemplate(benefitValue: 75)
        let card = try cardRepository.addCard(from: template, nickname: "Test Card")

        guard let benefit = card.benefits.first else {
            XCTFail("Card should have benefits")
            return
        }

        let benefitId = benefit.id

        // When - Mark as done via ID lookup
        var allBenefits = try benefitRepository.getAllBenefits()
        if let matchingBenefit = allBenefits.first(where: { $0.id == benefitId }) {
            try benefitRepository.markBenefitUsed(matchingBenefit)
        }

        XCTAssertEqual(benefit.status, .used, "Should be marked as used")

        // When - Undo via ID lookup
        allBenefits = try benefitRepository.getAllBenefits()
        if let matchingBenefit = allBenefits.first(where: { $0.id == benefitId }) {
            try benefitRepository.undoMarkBenefitUsed(matchingBenefit)
        }

        // Then
        XCTAssertEqual(benefit.status, .available, "Should be available after undo")
    }

    func testFullSnoozeFlowWithIdLookup() async throws {
        // Given
        let template = createMockCardTemplate()
        let card = try cardRepository.addCard(from: template, nickname: "Test Card")

        guard let benefit = card.benefits.first else {
            XCTFail("Card should have benefits")
            return
        }

        let benefitId = benefit.id
        let snoozeDays = 3

        // When - Snooze via ID lookup (pattern from tab views)
        let allBenefits = try benefitRepository.getAllBenefits()
        if let matchingBenefit = allBenefits.first(where: { $0.id == benefitId }) {
            let snoozeDate = Calendar.current.date(byAdding: .day, value: snoozeDays, to: Date()) ?? Date()
            try benefitRepository.snoozeBenefit(matchingBenefit, until: snoozeDate)
        }

        // Then - lastReminderDate is set when benefit is snoozed
        XCTAssertNotNil(benefit.lastReminderDate, "Benefit should have lastReminderDate set after snooze")
    }

    // MARK: - Helper Methods

    private func createMockCardTemplate(benefitValue: Decimal = 50) -> CardTemplate {
        CardTemplate(
            id: UUID(),
            name: "Test Card \(UUID().uuidString.prefix(4))",
            issuer: "Test Bank",
            artworkAsset: "test_card",
            annualFee: 100,
            primaryColorHex: "#000000",
            secondaryColorHex: "#FFFFFF",
            isActive: true,
            lastUpdated: Date(),
            benefits: [
                BenefitTemplate(
                    id: UUID(),
                    name: "Monthly Credit",
                    description: "Test benefit",
                    value: benefitValue,
                    frequency: .monthly,
                    category: .transportation,
                    merchant: "Test Merchant",
                    resetDayOfMonth: 1
                )
            ]
        )
    }
}
