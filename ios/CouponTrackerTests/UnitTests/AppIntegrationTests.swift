//
//  AppIntegrationTests.swift
//  CouponTrackerTests
//
//  Created: January 2026
//  Purpose: Integration tests verifying the full application flow from
//           template loading through card creation, benefit tracking, and queries.
//

import XCTest
import SwiftData
@testable import CouponTracker

/// Integration tests for the CouponTracker application.
///
/// These tests verify the complete flow:
/// 1. SwiftData schema registration and model container setup
/// 2. Template loading from bundled JSON
/// 3. Card creation from templates with benefit generation
/// 4. Benefit lifecycle (available -> used -> reset)
/// 5. Relationship persistence and cascade deletes
/// 6. Query operations across entities
@MainActor
final class AppIntegrationTests: XCTestCase {

    // MARK: - Properties

    var modelContainer: ModelContainer!
    var modelContext: ModelContext!
    var appContainer: AppContainer!
    var cardRepository: CardRepository!
    var benefitRepository: BenefitRepository!

    // MARK: - Setup & Teardown

    override func setUp() async throws {
        try await super.setUp()

        // Create in-memory model container with all entity types
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

        modelContext = modelContainer.mainContext
        appContainer = AppContainer(modelContainer: modelContainer)
        cardRepository = CardRepository(modelContext: modelContext)
        benefitRepository = BenefitRepository(modelContext: modelContext)
    }

    override func tearDown() async throws {
        appContainer = nil
        cardRepository = nil
        benefitRepository = nil
        modelContext = nil
        modelContainer = nil
        try await super.tearDown()
    }

    // MARK: - Schema Registration Tests

    func testSchemaRegistration_AllEntitiesRegistered() throws {
        // Given/When - Schema is created in setUp

        // Then - Verify all entities can be fetched
        let cards = try modelContext.fetch(FetchDescriptor<UserCard>())
        let benefits = try modelContext.fetch(FetchDescriptor<Benefit>())
        let usages = try modelContext.fetch(FetchDescriptor<BenefitUsage>())
        let prefs = try modelContext.fetch(FetchDescriptor<UserPreferences>())

        // All should be empty arrays (not crash due to missing registration)
        XCTAssertNotNil(cards)
        XCTAssertNotNil(benefits)
        XCTAssertNotNil(usages)
        XCTAssertNotNil(prefs)
    }

    func testModelContainer_SupportsInMemoryConfiguration() throws {
        // Given - Model container from setUp

        // When - Insert and fetch an entity
        let card = UserCard(nickname: "Test")
        modelContext.insert(card)
        try modelContext.save()

        let fetchedCards = try modelContext.fetch(FetchDescriptor<UserCard>())

        // Then
        XCTAssertEqual(fetchedCards.count, 1)
        XCTAssertEqual(fetchedCards.first?.nickname, "Test")
    }

    // MARK: - Full Flow Integration Tests

    func testFullFlow_AddCardFromTemplate_CreateBenefits_QueryAll() throws {
        // Given - Create a mock template with benefits
        let template = createMockAmexPlatinumTemplate()

        // When - Add card from template
        let card = try cardRepository.addCard(from: template, nickname: "Personal Platinum")

        // Then - Verify card was created
        XCTAssertNotNil(card)
        XCTAssertEqual(card.nickname, "Personal Platinum")
        XCTAssertEqual(card.cardTemplateId, template.id)
        XCTAssertFalse(card.isCustom)

        // Verify benefits were created
        XCTAssertEqual(card.benefits.count, template.benefits.count)

        // Verify all benefits are available
        let allAvailable = card.benefits.allSatisfy { $0.status == .available }
        XCTAssertTrue(allAvailable, "All new benefits should be available")

        // Query through repository
        let queriedBenefits = try benefitRepository.getBenefits(for: card)
        XCTAssertEqual(queriedBenefits.count, template.benefits.count)

        // Verify benefit-card relationship
        for benefit in queriedBenefits {
            XCTAssertEqual(benefit.userCard?.id, card.id)
        }
    }

    func testFullFlow_MarkBenefitUsed_CreatesUsageHistory() throws {
        // Given - Card with benefits
        let template = createMockAmexPlatinumTemplate()
        let card = try cardRepository.addCard(from: template, nickname: "Test")
        let benefit = card.benefits.first!
        benefit.customValue = 15 // Set value for tracking

        // When - Mark benefit as used
        try benefitRepository.markBenefitUsed(benefit)

        // Then - Verify status changed
        XCTAssertEqual(benefit.status, .used)

        // Verify usage history was created
        let usages = try modelContext.fetch(FetchDescriptor<BenefitUsage>())
        XCTAssertEqual(usages.count, 1)

        let usage = usages.first!
        XCTAssertEqual(usage.benefit?.id, benefit.id)
        XCTAssertEqual(usage.valueRedeemed, benefit.effectiveValue)
        XCTAssertFalse(usage.wasAutoExpired)
        XCTAssertNotNil(usage.cardNameSnapshot)
    }

    func testFullFlow_ResetBenefit_NewPeriodCreated() throws {
        // Given - Card with expired benefit
        let template = createMockAmexPlatinumTemplate()
        let card = try cardRepository.addCard(from: template, nickname: "Test")
        let benefit = card.benefits.first!
        benefit.customFrequency = .monthly

        // Mark as used first
        try benefitRepository.markBenefitUsed(benefit)
        XCTAssertEqual(benefit.status, .used)

        let oldPeriodEnd = benefit.currentPeriodEnd

        // When - Reset benefit for new period
        try benefitRepository.resetBenefitForNewPeriod(benefit)

        // Then - Verify reset
        XCTAssertEqual(benefit.status, .available)
        XCTAssertGreaterThan(benefit.currentPeriodStart, oldPeriodEnd)
        XCTAssertNil(benefit.lastReminderDate)
        XCTAssertNil(benefit.scheduledNotificationId)
    }

    func testFullFlow_MultipleCards_QueryAcrossAll() throws {
        // Given - Multiple cards with benefits
        let template1 = createMockAmexPlatinumTemplate()
        let template2 = createMockChaseSapphireTemplate()

        let card1 = try cardRepository.addCard(from: template1, nickname: "Amex")
        let card2 = try cardRepository.addCard(from: template2, nickname: "Chase")

        // When - Query all benefits across cards
        let allBenefits = try benefitRepository.getAllBenefits()
        let availableBenefits = try benefitRepository.getAvailableBenefits()

        // Then
        let expectedTotal = template1.benefits.count + template2.benefits.count
        XCTAssertEqual(allBenefits.count, expectedTotal)
        XCTAssertEqual(availableBenefits.count, expectedTotal) // All should be available initially

        // Verify cards are sorted by sort order
        let allCards = try cardRepository.getAllCards()
        XCTAssertEqual(allCards.count, 2)
        XCTAssertEqual(allCards[0].sortOrder, 0) // First added
        XCTAssertEqual(allCards[1].sortOrder, 1) // Second added
    }

    // MARK: - Relationship Persistence Tests

    func testRelationships_BenefitToCard_PersistsCorrectly() throws {
        // Given
        let template = createMockAmexPlatinumTemplate()
        let card = try cardRepository.addCard(from: template, nickname: "Test")

        // When - Create new context to verify persistence
        let newContext = ModelContext(modelContainer)
        let descriptor = FetchDescriptor<Benefit>()
        let benefits = try newContext.fetch(descriptor)

        // Then - All benefits should have card relationship
        XCTAssertTrue(benefits.allSatisfy { $0.userCard != nil })

        for benefit in benefits {
            XCTAssertEqual(benefit.userCard?.id, card.id)
        }
    }

    func testRelationships_CascadeDelete_RemovesBenefits() throws {
        // Given - Card with benefits
        let template = createMockAmexPlatinumTemplate()
        let card = try cardRepository.addCard(from: template, nickname: "Test")
        let benefitCount = card.benefits.count
        XCTAssertGreaterThan(benefitCount, 0)

        // When - Delete card
        try cardRepository.deleteCard(card)

        // Then - Benefits should be cascade deleted
        let remainingBenefits = try modelContext.fetch(FetchDescriptor<Benefit>())
        XCTAssertTrue(remainingBenefits.isEmpty)
    }

    func testRelationships_UsageIsCascadeDeletedWithCard() throws {
        // Given - Card with used benefit
        let template = createMockAmexPlatinumTemplate()
        let card = try cardRepository.addCard(from: template, nickname: "My Card")
        guard let benefit = card.benefits.first else {
            XCTFail("Card should have benefits")
            return
        }

        // Mark as used to create usage record
        try benefitRepository.markBenefitUsed(benefit)

        // Verify usage exists
        var usages = try modelContext.fetch(FetchDescriptor<BenefitUsage>())
        XCTAssertEqual(usages.count, 1, "Usage should be created")

        // When - Delete card (cascades to benefits and usage history)
        try cardRepository.deleteCard(card)

        // Then - Usage records are also cascade deleted
        usages = try modelContext.fetch(FetchDescriptor<BenefitUsage>())
        XCTAssertEqual(usages.count, 0, "Usage should be cascade deleted with card")
    }

    // MARK: - Query Operation Tests

    func testQuery_ExpiringBenefits_ReturnsCorrectSubset() throws {
        // Given - Create card and manipulate benefit dates
        let template = createMockAmexPlatinumTemplate()
        let card = try cardRepository.addCard(from: template, nickname: "Test")

        let calendar = Calendar.current
        let today = Date()

        // Set varying expiration dates on benefits
        if card.benefits.count >= 2 {
            card.benefits[0].currentPeriodEnd = calendar.date(byAdding: .day, value: 3, to: today)!
            card.benefits[1].currentPeriodEnd = calendar.date(byAdding: .day, value: 30, to: today)!
        }
        try modelContext.save()

        // When - Query expiring within 7 days
        let expiringBenefits = try benefitRepository.getExpiringBenefits(within: 7)

        // Then - Only benefit expiring in 3 days should be returned
        XCTAssertEqual(expiringBenefits.count, 1)
        XCTAssertEqual(expiringBenefits.first?.id, card.benefits[0].id)
    }

    func testQuery_AvailableBenefits_ExcludesUsedAndExpired() throws {
        // Given - Card with benefits in different states
        let template = createMockAmexPlatinumTemplate()
        let card = try cardRepository.addCard(from: template, nickname: "Test")

        // Mark first benefit as used
        if let firstBenefit = card.benefits.first {
            try benefitRepository.markBenefitUsed(firstBenefit)
        }

        // Mark second benefit as expired (if exists)
        if card.benefits.count > 1 {
            card.benefits[1].status = .expired
            try modelContext.save()
        }

        // When
        let availableBenefits = try benefitRepository.getAvailableBenefits()

        // Then - Should exclude used and expired
        XCTAssertTrue(availableBenefits.allSatisfy { $0.status == .available })
        XCTAssertEqual(availableBenefits.count, template.benefits.count - 2)
    }

    // MARK: - AppContainer Integration Tests

    func testAppContainer_ProvidesRepositories() {
        // Given - AppContainer from setUp

        // When - Access repositories
        let cardRepo = appContainer.cardRepository
        let benefitRepo = appContainer.benefitRepository

        // Then - Should return valid repositories
        XCTAssertNotNil(cardRepo)
        XCTAssertNotNil(benefitRepo)
    }

    func testAppContainer_RepositoriesShareModelContext() throws {
        // Given - AppContainer

        // When - Insert through one repository
        let template = createMockAmexPlatinumTemplate()
        _ = try appContainer.cardRepository.addCard(from: template, nickname: "Test")

        // Then - Query through another should find it
        let benefits = try appContainer.benefitRepository.getAllBenefits()
        XCTAssertEqual(benefits.count, template.benefits.count)
    }

    func testAppContainer_TemplateLoaderAccess() {
        // Given - AppContainer

        // When - Access template loader
        let loader = appContainer.templateLoader

        // Then - Should be valid (even if bundle doesn't have templates yet)
        XCTAssertNotNil(loader)
    }

    // MARK: - User Preferences Integration Tests

    func testUserPreferences_SingletonPattern() throws {
        // Given - Empty database

        // When - Create first preferences
        let prefs1 = UserPreferences()
        modelContext.insert(prefs1)
        try modelContext.save()

        // Try to fetch all
        let allPrefs = try modelContext.fetch(FetchDescriptor<UserPreferences>())

        // Then - Should have exactly one
        XCTAssertEqual(allPrefs.count, 1)
        XCTAssertEqual(allPrefs.first?.id, "user_preferences")
    }

    func testUserPreferences_OnboardingFlow() throws {
        // Given - New preferences (onboarding not complete)
        let prefs = UserPreferences()
        modelContext.insert(prefs)
        try modelContext.save()

        XCTAssertFalse(prefs.hasCompletedOnboarding)

        // When - Complete onboarding
        prefs.completeOnboarding()
        try modelContext.save()

        // Then - Verify persistence
        let fetchedPrefs = try modelContext.fetch(FetchDescriptor<UserPreferences>()).first
        XCTAssertTrue(fetchedPrefs?.hasCompletedOnboarding ?? false)
    }

    // MARK: - Edge Cases

    func testEdgeCase_EmptyDatabase_QueriesReturnEmpty() throws {
        // Given - Empty database (from setUp)

        // When - Query all entities
        let cards = try cardRepository.getAllCards()
        let benefits = try benefitRepository.getAllBenefits()
        let available = try benefitRepository.getAvailableBenefits()

        // Then - All should return empty arrays, not nil or crash
        XCTAssertTrue(cards.isEmpty)
        XCTAssertTrue(benefits.isEmpty)
        XCTAssertTrue(available.isEmpty)
    }

    func testEdgeCase_CardWithNoBenefits() throws {
        // Given - Template with no benefits
        let emptyTemplate = CardTemplate(
            id: UUID(),
            name: "Empty Card",
            issuer: "Test Bank",
            artworkAsset: "",
            annualFee: nil,
            primaryColorHex: "#000000",
            secondaryColorHex: "#FFFFFF",
            isActive: true,
            lastUpdated: Date(),
            benefits: []
        )

        // When - Add card
        let card = try cardRepository.addCard(from: emptyTemplate, nickname: nil)

        // Then - Card should be created without benefits
        XCTAssertNotNil(card)
        XCTAssertTrue(card.benefits.isEmpty)
    }

    func testEdgeCase_MultipleMarkAsUsed_ThrowsError() throws {
        // Given - Card with benefit already marked as used
        let template = createMockAmexPlatinumTemplate()
        let card = try cardRepository.addCard(from: template, nickname: "Test")
        let benefit = card.benefits.first!

        // Mark as used once
        try benefitRepository.markBenefitUsed(benefit)

        // When/Then - Second mark should throw
        XCTAssertThrowsError(try benefitRepository.markBenefitUsed(benefit)) { error in
            XCTAssertTrue(error is BenefitRepositoryError)
        }
    }

    // MARK: - Performance Tests

    func testPerformance_FetchAllBenefits_WithManyCards() throws {
        // Given - Create multiple cards with benefits
        let template = createMockAmexPlatinumTemplate()
        for i in 0..<10 {
            _ = try cardRepository.addCard(from: template, nickname: "Card \(i)")
        }

        // When/Then - Measure fetch performance
        measure {
            _ = try? benefitRepository.getAllBenefits()
        }
    }

    // MARK: - Helper Methods

    /// Creates a mock Amex Platinum template for testing
    private func createMockAmexPlatinumTemplate() -> CardTemplate {
        return CardTemplate(
            id: UUID(),
            name: "The Platinum Card",
            issuer: "American Express",
            artworkAsset: "amex_platinum",
            annualFee: 695,
            primaryColorHex: "#E5E4E2",
            secondaryColorHex: "#A9A9A9",
            isActive: true,
            lastUpdated: Date(),
            benefits: [
                BenefitTemplate(
                    id: UUID(),
                    name: "Uber Credits",
                    description: "Monthly Uber credit",
                    value: 15,
                    frequency: .monthly,
                    category: .transportation,
                    merchant: "Uber",
                    resetDayOfMonth: 1
                ),
                BenefitTemplate(
                    id: UUID(),
                    name: "Digital Entertainment Credit",
                    description: "Monthly streaming credit",
                    value: 20,
                    frequency: .monthly,
                    category: .entertainment,
                    merchant: nil,
                    resetDayOfMonth: 1
                ),
                BenefitTemplate(
                    id: UUID(),
                    name: "Airline Fee Credit",
                    description: "Annual airline incidental credit",
                    value: 200,
                    frequency: .annual,
                    category: .travel,
                    merchant: nil,
                    resetDayOfMonth: nil
                )
            ]
        )
    }

    /// Creates a mock Chase Sapphire Reserve template for testing
    private func createMockChaseSapphireTemplate() -> CardTemplate {
        return CardTemplate(
            id: UUID(),
            name: "Sapphire Reserve",
            issuer: "Chase",
            artworkAsset: "chase_sapphire",
            annualFee: 550,
            primaryColorHex: "#1a1a2e",
            secondaryColorHex: "#2d3a6d",
            isActive: true,
            lastUpdated: Date(),
            benefits: [
                BenefitTemplate(
                    id: UUID(),
                    name: "Travel Credit",
                    description: "Annual travel credit",
                    value: 300,
                    frequency: .annual,
                    category: .travel,
                    merchant: nil,
                    resetDayOfMonth: nil
                ),
                BenefitTemplate(
                    id: UUID(),
                    name: "DoorDash DashPass",
                    description: "DashPass membership",
                    value: 0,
                    frequency: .annual,
                    category: .dining,
                    merchant: "DoorDash",
                    resetDayOfMonth: nil
                )
            ]
        )
    }
}
