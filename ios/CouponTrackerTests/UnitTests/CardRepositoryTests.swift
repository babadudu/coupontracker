//
//  CardRepositoryTests.swift
//  CouponTrackerTests
//
//  Created by Junior Engineer 3 on 2026-01-17.
//

import XCTest
import SwiftData
@testable import CouponTracker

/// Unit tests for CardRepository CRUD operations.
/// Uses in-memory ModelContainer for isolated testing.
@MainActor
final class CardRepositoryTests: XCTestCase {

    // MARK: - Properties

    var modelContainer: ModelContainer!
    var modelContext: ModelContext!
    var repository: CardRepository!

    // MARK: - Setup & Teardown

    override func setUp() async throws {
        try await super.setUp()

        // Create in-memory model container for testing
        let schema = Schema([
            UserCard.self,
            Benefit.self,
            BenefitUsage.self
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
        repository = CardRepository(modelContext: modelContext)
    }

    override func tearDown() async throws {
        modelContainer = nil
        modelContext = nil
        repository = nil
        try await super.tearDown()
    }

    // MARK: - Test Cases

    // MARK: Diagnostic Tests

    func testDiagnostic_SimpleArrayInStruct() throws {
        // Create a simple struct inline with an array
        struct TestStruct {
            let items: [String]
        }

        let array = ["a", "b", "c"]
        XCTAssertEqual(array.count, 3, "Array should have 3 elements")

        let test = TestStruct(items: array)
        XCTAssertEqual(test.items.count, 3, "TestStruct.items should have 3 elements, got \(test.items.count)")
    }

    func testDiagnostic_BenefitTemplateInitWorks() throws {
        // Given
        let benefitTemplate = BenefitTemplate(
            id: UUID(),
            name: "Test Benefit",
            description: "A test benefit",
            value: 50,
            frequency: .monthly,
            category: .travel,
            merchant: nil,
            resetDayOfMonth: nil
        )

        // Then
        XCTAssertEqual(benefitTemplate.name, "Test Benefit", "BenefitTemplate should init correctly")
        XCTAssertEqual(benefitTemplate.value, 50, "Value should be 50")
    }

    func testDiagnostic_CardTemplateInitWithBenefits() throws {
        // Given - Create benefits array directly
        let benefit1 = BenefitTemplate(
            id: UUID(),
            name: "Benefit 1",
            description: "First benefit",
            value: 15,
            frequency: .monthly,
            category: .transportation,
            merchant: nil,
            resetDayOfMonth: 1
        )

        let benefit2 = BenefitTemplate(
            id: UUID(),
            name: "Benefit 2",
            description: "Second benefit",
            value: 200,
            frequency: .annual,
            category: .travel,
            merchant: nil,
            resetDayOfMonth: nil
        )

        // Verify each benefit is valid
        XCTAssertEqual(benefit1.name, "Benefit 1", "Benefit1 should have name")
        XCTAssertEqual(benefit2.name, "Benefit 2", "Benefit2 should have name")

        let benefits: [BenefitTemplate] = [benefit1, benefit2]
        XCTAssertEqual(benefits.count, 2, "Benefits array should have 2 elements")
        XCTAssertEqual(benefits[0].name, "Benefit 1", "First element should be benefit1")

        // Check type of CardTemplate
        let cardTemplateType = type(of: CardTemplate.self)
        print("CardTemplate type: \(cardTemplateType)")

        // When - Create template using explicit initialization
        let templateId = UUID()
        let template = CardTemplate(
            id: templateId,
            name: "Test Card",
            issuer: "Test Bank",
            artworkAsset: "test",
            annualFee: 100,
            primaryColorHex: "#000000",
            secondaryColorHex: "#FFFFFF",
            isActive: true,
            lastUpdated: Date(),
            benefits: benefits
        )

        // Then
        XCTAssertEqual(template.id, templateId, "ID should match")
        XCTAssertEqual(template.name, "Test Card", "Name should be Test Card")
        XCTAssertEqual(template.issuer, "Test Bank", "Issuer should be Test Bank")
        XCTAssertEqual(template.benefits.count, 2, "CardTemplate should have 2 benefits after init, got \(template.benefits.count). Benefits: \(template.benefits.map { $0.name })")
    }

    // MARK: getAllCards Tests

    func testGetAllCards_WhenEmpty_ReturnsEmptyArray() throws {
        // When
        let cards = try repository.getAllCards()

        // Then
        XCTAssertTrue(cards.isEmpty, "Should return empty array when no cards exist")
    }

    func testGetAllCards_WithMultipleCards_ReturnsSortedByOrder() throws {
        // Given
        let card1 = UserCard(nickname: "Card 1", sortOrder: 2)
        let card2 = UserCard(nickname: "Card 2", sortOrder: 0)
        let card3 = UserCard(nickname: "Card 3", sortOrder: 1)

        modelContext.insert(card1)
        modelContext.insert(card2)
        modelContext.insert(card3)
        try modelContext.save()

        // When
        let cards = try repository.getAllCards()

        // Then
        XCTAssertEqual(cards.count, 3, "Should return all 3 cards")
        XCTAssertEqual(cards[0].nickname, "Card 2", "First card should be sorted by order 0")
        XCTAssertEqual(cards[1].nickname, "Card 3", "Second card should be sorted by order 1")
        XCTAssertEqual(cards[2].nickname, "Card 1", "Third card should be sorted by order 2")
    }

    // MARK: getCard Tests

    func testGetCard_WithValidId_ReturnsCard() throws {
        // Given
        let card = UserCard(nickname: "Test Card")
        modelContext.insert(card)
        try modelContext.save()

        // When
        let fetchedCard = try repository.getCard(by: card.id)

        // Then
        XCTAssertNotNil(fetchedCard, "Should find card with valid ID")
        XCTAssertEqual(fetchedCard?.id, card.id, "Should return correct card")
        XCTAssertEqual(fetchedCard?.nickname, "Test Card", "Should have correct nickname")
    }

    func testGetCard_WithInvalidId_ReturnsNil() throws {
        // Given
        let nonExistentId = UUID()

        // When
        let fetchedCard = try repository.getCard(by: nonExistentId)

        // Then
        XCTAssertNil(fetchedCard, "Should return nil for non-existent ID")
    }

    // MARK: addCard Tests

    func testAddCard_FromTemplate_CreatesCardWithBenefits() throws {
        // Given
        let template = createMockCardTemplate()

        // DIAGNOSTIC: Verify template has benefits before using it
        XCTAssertEqual(template.benefits.count, 2, "Template should have 2 benefits, got \(template.benefits.count)")

        // When
        let card = try repository.addCard(from: template, nickname: "My Platinum")

        // Then
        XCTAssertNotNil(card, "Should create card")
        XCTAssertEqual(card.cardTemplateId, template.id, "Should link to template")
        XCTAssertEqual(card.nickname, "My Platinum", "Should set nickname")
        XCTAssertFalse(card.isCustom, "Should not be custom card")
        XCTAssertEqual(card.sortOrder, 0, "Should be first card")
        XCTAssertEqual(card.benefits.count, 2, "Should create 2 benefits from template")
    }

    func testAddCard_WithNilNickname_CreatesCardSuccessfully() throws {
        // Given
        let template = createMockCardTemplate()

        // When
        let card = try repository.addCard(from: template, nickname: nil)

        // Then
        XCTAssertNotNil(card, "Should create card")
        XCTAssertNil(card.nickname, "Should have nil nickname")
    }

    func testAddCard_MultipleTimes_IncrementsSortOrder() throws {
        // Given
        let template1 = createMockCardTemplate()
        let template2 = createMockCardTemplate()

        // When
        let card1 = try repository.addCard(from: template1, nickname: "First")
        let card2 = try repository.addCard(from: template2, nickname: "Second")

        // Then
        XCTAssertEqual(card1.sortOrder, 0, "First card should have order 0")
        XCTAssertEqual(card2.sortOrder, 1, "Second card should have order 1")
    }

    func testAddCard_CreatesMonthlyBenefit_WithCorrectPeriod() throws {
        // Given
        let template = createMockCardTemplate()
        let calendar = Calendar.current
        let now = Date()

        // When
        let card = try repository.addCard(from: template, nickname: nil)

        // Then
        let monthlyBenefit = card.benefits.first { benefit in
            // Find monthly benefit by checking period length
            let components = calendar.dateComponents([.month], from: benefit.currentPeriodStart, to: benefit.currentPeriodEnd)
            return components.month == 0 // Monthly benefits span within same month
        }

        XCTAssertNotNil(monthlyBenefit, "Should have created monthly benefit")

        if let benefit = monthlyBenefit {
            // Verify period is current month
            let startComponents = calendar.dateComponents([.year, .month, .day], from: benefit.currentPeriodStart)
            let currentComponents = calendar.dateComponents([.year, .month], from: now)

            XCTAssertEqual(startComponents.year, currentComponents.year, "Should start in current year")
            XCTAssertEqual(startComponents.month, currentComponents.month, "Should start in current month")
            XCTAssertEqual(startComponents.day, 1, "Should start on first day of month")

            // Verify status is available
            XCTAssertEqual(benefit.status, .available, "Should be available initially")

            // Verify reminder settings
            XCTAssertTrue(benefit.reminderEnabled, "Reminders should be enabled by default")
            XCTAssertEqual(benefit.reminderDaysBefore, 7, "Should have default 7-day reminder")
        }
    }

    // MARK: deleteCard Tests

    func testDeleteCard_RemovesCardFromStorage() throws {
        // Given
        let card = UserCard(nickname: "To Delete")
        modelContext.insert(card)
        try modelContext.save()

        let cardId = card.id

        // When
        try repository.deleteCard(card)

        // Then
        let fetchedCard = try repository.getCard(by: cardId)
        XCTAssertNil(fetchedCard, "Card should be deleted")
    }

    func testDeleteCard_CascadesDeleteToBenefits() throws {
        // Given
        let template = createMockCardTemplate()
        let card = try repository.addCard(from: template, nickname: "Test")

        let benefitCount = card.benefits.count
        XCTAssertGreaterThan(benefitCount, 0, "Card should have benefits")

        // When
        try repository.deleteCard(card)

        // Then
        let allBenefits = try modelContext.fetch(FetchDescriptor<Benefit>())
        XCTAssertTrue(allBenefits.isEmpty, "All benefits should be cascade deleted")
    }

    // MARK: updateCard Tests

    func testUpdateCard_UpdatesTimestamp() throws {
        // Given
        let card = UserCard(nickname: "Original")
        modelContext.insert(card)
        try modelContext.save()

        let originalUpdateTime = card.updatedAt
        Thread.sleep(forTimeInterval: 0.01) // Small delay to ensure timestamp difference

        // When
        card.nickname = "Updated"
        try repository.updateCard(card)

        // Then
        let fetchedCard = try repository.getCard(by: card.id)
        XCTAssertNotNil(fetchedCard, "Card should exist")
        XCTAssertEqual(fetchedCard?.nickname, "Updated", "Nickname should be updated")
        XCTAssertGreaterThan(fetchedCard?.updatedAt ?? Date.distantPast, originalUpdateTime, "Updated timestamp should be newer")
    }

    func testUpdateCard_PersistsChanges() throws {
        // Given
        let card = UserCard(nickname: "Test", sortOrder: 0)
        modelContext.insert(card)
        try modelContext.save()

        // When
        card.nickname = "Modified"
        card.sortOrder = 5
        try repository.updateCard(card)

        // Then
        // Create new context to verify persistence
        let newContext = ModelContext(modelContainer)
        let cardId = card.id
        let descriptor = FetchDescriptor<UserCard>(
            predicate: #Predicate<UserCard> { userCard in
                userCard.id == cardId
            }
        )
        let fetchedCard = try newContext.fetch(descriptor).first

        XCTAssertEqual(fetchedCard?.nickname, "Modified", "Changes should persist")
        XCTAssertEqual(fetchedCard?.sortOrder, 5, "Sort order should persist")
    }

    // MARK: Edge Cases

    func testAddCard_WithEmptyBenefits_CreatesCardOnly() throws {
        // Given
        let template = CardTemplate(
            id: UUID(),
            name: "Test Card",
            issuer: "Test Bank",
            artworkAsset: "",
            annualFee: nil,
            primaryColorHex: "#000000",
            secondaryColorHex: "#FFFFFF",
            isActive: true,
            lastUpdated: Date(),
            benefits: [] // No benefits
        )

        // When
        let card = try repository.addCard(from: template, nickname: nil)

        // Then
        XCTAssertNotNil(card, "Should create card even without benefits")
        XCTAssertTrue(card.benefits.isEmpty, "Should have no benefits")
    }

    // MARK: Helper Methods

    /// Creates a mock card template for testing.
    /// - Returns: A CardTemplate with various benefit frequencies
    private func createMockCardTemplate() -> CardTemplate {
        return CardTemplate(
            id: UUID(),
            name: "Test Platinum Card",
            issuer: "Test Bank",
            artworkAsset: "test_card",
            annualFee: 500,
            primaryColorHex: "#E5E4E2",
            secondaryColorHex: "#A9A9A9",
            isActive: true,
            lastUpdated: Date(),
            benefits: [
                BenefitTemplate(
                    id: UUID(),
                    name: "Monthly Credit",
                    description: "Monthly benefit",
                    value: 15,
                    frequency: .monthly,
                    category: .transportation,
                    merchant: "Test Merchant",
                    resetDayOfMonth: 1
                ),
                BenefitTemplate(
                    id: UUID(),
                    name: "Annual Credit",
                    description: "Annual benefit",
                    value: 200,
                    frequency: .annual,
                    category: .travel,
                    merchant: nil,
                    resetDayOfMonth: nil
                )
            ]
        )
    }
}
