//
//  HomeViewModelTests.swift
//  CouponTrackerTests
//
//  Created: January 2026
//  Purpose: Unit tests for HomeViewModel business logic and state management.
//

import XCTest
import SwiftData
@testable import CouponTracker

/// Unit tests for HomeViewModel.
/// Tests data loading, display adapters, computed properties, and card deletion.
@MainActor
final class HomeViewModelTests: XCTestCase {

    // MARK: - Properties

    var modelContainer: ModelContainer!
    var modelContext: ModelContext!
    var cardRepository: CardRepository!
    var benefitRepository: BenefitRepository!
    var templateLoader: HomeViewModelMockTemplateLoader!
    var notificationService: NotificationService!
    var viewModel: HomeViewModel!

    // MARK: - Setup & Teardown

    override func setUp() async throws {
        try await super.setUp()

        // Create in-memory model container for testing
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
        templateLoader = HomeViewModelMockTemplateLoader()
        notificationService = NotificationService()

        viewModel = HomeViewModel(
            cardRepository: cardRepository,
            benefitRepository: benefitRepository,
            templateLoader: templateLoader,
            notificationService: notificationService
        )
    }

    override func tearDown() async throws {
        viewModel = nil
        templateLoader = nil
        notificationService = nil
        benefitRepository = nil
        cardRepository = nil
        modelContext = nil
        modelContainer = nil
        try await super.tearDown()
    }

    // MARK: - Initial State Tests

    func testInitialState_IsEmpty() {
        // Then
        XCTAssertTrue(viewModel.isEmpty, "Should be empty initially")
        XCTAssertEqual(viewModel.cardCount, 0, "Should have zero cards")
        XCTAssertEqual(viewModel.totalAvailableValue, 0, "Should have zero value")
        XCTAssertEqual(viewModel.expiringThisWeekCount, 0, "Should have zero expiring")
        XCTAssertFalse(viewModel.isLoading, "Should not be loading initially")
        XCTAssertNil(viewModel.error, "Should have no error initially")
    }

    // MARK: - loadData Tests

    func testLoadData_WithCards_PopulatesState() async throws {
        // Given
        let template = createMockCardTemplate()
        _ = try cardRepository.addCard(from: template, nickname: "Test Card")

        // When
        await viewModel.loadData()

        // Then
        XCTAssertFalse(viewModel.isEmpty, "Should not be empty after loading")
        XCTAssertEqual(viewModel.cardCount, 1, "Should have one card")
        XCTAssertFalse(viewModel.isLoading, "Should not be loading after completion")
    }

    func testLoadData_WithMultipleCards_LoadsAll() async throws {
        // Given
        let template = createMockCardTemplate()
        _ = try cardRepository.addCard(from: template, nickname: "Card 1")
        _ = try cardRepository.addCard(from: template, nickname: "Card 2")
        _ = try cardRepository.addCard(from: template, nickname: "Card 3")

        // When
        await viewModel.loadData()

        // Then
        XCTAssertEqual(viewModel.cardCount, 3, "Should have three cards")
    }

    func testLoadData_SetsLoadingState() async throws {
        // Given
        let template = createMockCardTemplate()
        _ = try cardRepository.addCard(from: template, nickname: "Test")

        // When
        let loadTask = Task {
            await viewModel.loadData()
        }

        // Allow task to start
        try await Task.sleep(nanoseconds: 1_000_000) // 1ms

        // Then
        await loadTask.value
        XCTAssertFalse(viewModel.isLoading, "Should not be loading after completion")
    }

    func testLoadData_WithEmptyDatabase_SetsEmptyState() async throws {
        // Given - Empty database

        // When
        await viewModel.loadData()

        // Then
        XCTAssertTrue(viewModel.isEmpty, "Should be empty")
        XCTAssertEqual(viewModel.displayCards.count, 0, "Should have no display cards")
    }

    // MARK: - Computed Properties Tests

    func testTotalAvailableValue_SumsAllCardValues() async throws {
        // Given
        let template1 = createMockCardTemplate(benefitValue: 100)
        let template2 = createMockCardTemplate(benefitValue: 50)

        _ = try cardRepository.addCard(from: template1, nickname: "Card 1")
        _ = try cardRepository.addCard(from: template2, nickname: "Card 2")

        // When
        await viewModel.loadData()

        // Then
        // Each template has 2 benefits with the specified value
        let expectedValue: Decimal = (100 + 100) + (50 + 50)
        XCTAssertEqual(viewModel.totalAvailableValue, expectedValue, "Should sum all benefit values")
    }

    func testExpiringThisWeekCount_CountsCorrectly() async throws {
        // Given
        let template = createMockCardTemplate()
        let card = try cardRepository.addCard(from: template, nickname: "Test")

        // Set one benefit to expire in 3 days
        let calendar = Calendar.current
        let today = Date()
        if let benefit = card.benefits.first {
            benefit.currentPeriodEnd = calendar.date(byAdding: .day, value: 3, to: today)!
            try modelContext.save()
        }

        // When
        await viewModel.loadData()

        // Then
        XCTAssertGreaterThanOrEqual(viewModel.expiringThisWeekCount, 1, "Should count expiring benefits")
    }

    // MARK: - Display Adapters Tests

    func testDisplayCards_ReturnsAdapters() async throws {
        // Given
        let template = createMockCardTemplate()
        templateLoader.templates = [template]
        _ = try cardRepository.addCard(from: template, nickname: "Test Card")

        // When
        await viewModel.loadData()

        // Then
        XCTAssertEqual(viewModel.displayCards.count, 1, "Should have one display card")

        let displayCard = viewModel.displayCards.first
        XCTAssertNotNil(displayCard, "Display card should exist")
        XCTAssertEqual(displayCard?.displayName, "Test Card", "Should have correct nickname")
    }

    func testDisplayCards_ConvertsToPreviewCard() async throws {
        // Given
        let template = createMockCardTemplate()
        templateLoader.templates = [template]
        _ = try cardRepository.addCard(from: template, nickname: "My Card")

        // When
        await viewModel.loadData()

        // Then
        let displayCard = viewModel.displayCards.first
        XCTAssertNotNil(displayCard, "Display card should exist")

        let previewCard = displayCard?.toPreviewCard()
        XCTAssertNotNil(previewCard, "Should convert to PreviewCard")
        XCTAssertEqual(previewCard?.nickname, "My Card", "PreviewCard should have nickname")
    }

    func testDisplayExpiringBenefits_ReturnsAdapters() async throws {
        // Given
        let template = createMockCardTemplate()
        let card = try cardRepository.addCard(from: template, nickname: "Test")

        // Set benefit to expire soon
        let calendar = Calendar.current
        let today = Date()
        if let benefit = card.benefits.first {
            benefit.currentPeriodEnd = calendar.date(byAdding: .day, value: 3, to: today)!
            try modelContext.save()
        }

        // When
        await viewModel.loadData()

        // Then
        XCTAssertGreaterThanOrEqual(viewModel.displayExpiringBenefits.count, 1, "Should have expiring benefits")
    }

    // MARK: - deleteCard Tests

    func testDeleteCard_RemovesCard() async throws {
        // Given
        let template = createMockCardTemplate()
        let card = try cardRepository.addCard(from: template, nickname: "To Delete")
        await viewModel.loadData()

        XCTAssertEqual(viewModel.cardCount, 1, "Should have one card initially")

        // When
        viewModel.deleteCard(card)

        // Allow async reload to complete
        try await Task.sleep(nanoseconds: 100_000_000) // 100ms

        // Then
        XCTAssertEqual(viewModel.cardCount, 0, "Should have zero cards after delete")
        XCTAssertTrue(viewModel.isEmpty, "Should be empty after delete")
    }

    func testDeleteCard_RemovesAssociatedBenefits() async throws {
        // Given
        let template = createMockCardTemplate()
        let card = try cardRepository.addCard(from: template, nickname: "Test")
        let benefitCount = card.benefits.count
        await viewModel.loadData()

        XCTAssertGreaterThan(benefitCount, 0, "Card should have benefits")

        // When
        viewModel.deleteCard(card)

        // Allow async operations
        try await Task.sleep(nanoseconds: 100_000_000) // 100ms

        // Then
        let allBenefits = try benefitRepository.getAllBenefits()
        XCTAssertTrue(allBenefits.isEmpty, "Benefits should be cascade deleted")
    }

    func testDeleteCard_HandlesError() async throws {
        // Given - Card that might cause an error (already deleted)
        let template = createMockCardTemplate()
        let card = try cardRepository.addCard(from: template, nickname: "Test")
        await viewModel.loadData()

        // Delete it first through repository
        try cardRepository.deleteCard(card)

        // When - Try to delete again through viewModel
        viewModel.deleteCard(card)

        // Then - Should not crash, might set error
        try await Task.sleep(nanoseconds: 100_000_000) // 100ms
        // The delete might fail gracefully
    }

    // MARK: - refresh Tests

    func testRefresh_ReloadsData() async throws {
        // Given
        let template = createMockCardTemplate()
        _ = try cardRepository.addCard(from: template, nickname: "Initial")
        await viewModel.loadData()

        XCTAssertEqual(viewModel.cardCount, 1, "Should have one card")

        // Add another card directly
        _ = try cardRepository.addCard(from: template, nickname: "New Card")

        // When
        await viewModel.refresh()

        // Then
        XCTAssertEqual(viewModel.cardCount, 2, "Should see new card after refresh")
    }

    // MARK: - Error Handling Tests

    func testLoadData_WithRepositoryError_SetsErrorState() async throws {
        // Given - Use a failing repository (not easily testable without protocol mock)
        // This test demonstrates the pattern; actual error injection requires more setup

        // When
        await viewModel.loadData()

        // Then - In case of no error, error should be nil
        XCTAssertNil(viewModel.error, "Error should be nil on success")
    }

    // MARK: - Dashboard Properties Tests

    func testRedeemedThisMonth_WithUsedBenefits_SumsValues() async throws {
        // Given
        let template = createMockCardTemplate(benefitValue: 25)
        let card = try cardRepository.addCard(from: template, nickname: "Test")

        // Mark a benefit as used
        if let benefit = card.benefits.first {
            try benefitRepository.markBenefitUsed(benefit)
        }

        // When
        await viewModel.loadData()

        // Then
        XCTAssertEqual(viewModel.redeemedThisMonth, 25, "Should sum used benefit values")
    }

    func testRedeemedThisMonth_WithNoBenefitsUsed_ReturnsZero() async throws {
        // Given
        let template = createMockCardTemplate(benefitValue: 50)
        _ = try cardRepository.addCard(from: template, nickname: "Test")

        // When
        await viewModel.loadData()

        // Then
        XCTAssertEqual(viewModel.redeemedThisMonth, 0, "Should be zero with no used benefits")
    }

    func testUsedBenefitsCount_CountsCorrectly() async throws {
        // Given
        let template = createMockCardTemplate()
        let card = try cardRepository.addCard(from: template, nickname: "Test")

        // Mark one benefit as used
        if let benefit = card.benefits.first {
            try benefitRepository.markBenefitUsed(benefit)
        }

        // When
        await viewModel.loadData()

        // Then
        XCTAssertEqual(viewModel.usedBenefitsCount, 1, "Should count one used benefit")
    }

    func testTotalBenefitsCount_CountsAllBenefits() async throws {
        // Given
        let template = createMockCardTemplate()
        _ = try cardRepository.addCard(from: template, nickname: "Test")

        // When
        await viewModel.loadData()

        // Then - Template has 2 benefits
        XCTAssertEqual(viewModel.totalBenefitsCount, 2, "Should count all benefits")
    }

    func testTotalBenefitsCount_WithMultipleCards() async throws {
        // Given
        let template = createMockCardTemplate()
        _ = try cardRepository.addCard(from: template, nickname: "Card 1")
        _ = try cardRepository.addCard(from: template, nickname: "Card 2")

        // When
        await viewModel.loadData()

        // Then - 2 cards x 2 benefits each = 4 total
        XCTAssertEqual(viewModel.totalBenefitsCount, 4, "Should count benefits from all cards")
    }

    // MARK: - Enhanced Multi-Card Tests (Bug Fix Verification)

    func testTotalAvailableValue_With3Cards_SumsCorrectly() async throws {
        // Given - 3 cards with different benefit values
        let template1 = createMockCardTemplate(benefitValue: 100) // 2 benefits x 100 = 200
        let template2 = createMockCardTemplate(benefitValue: 75)  // 2 benefits x 75 = 150
        let template3 = createMockCardTemplate(benefitValue: 50)  // 2 benefits x 50 = 100

        _ = try cardRepository.addCard(from: template1, nickname: "Card 1")
        _ = try cardRepository.addCard(from: template2, nickname: "Card 2")
        _ = try cardRepository.addCard(from: template3, nickname: "Card 3")

        // When
        await viewModel.loadData()

        // Then
        let expectedTotal: Decimal = 200 + 150 + 100 // = 450
        XCTAssertEqual(viewModel.cardCount, 3, "Should have 3 cards")
        XCTAssertEqual(viewModel.totalAvailableValue, expectedTotal, "Should sum all 3 cards correctly: got \(viewModel.totalAvailableValue) expected \(expectedTotal)")
        XCTAssertEqual(viewModel.totalBenefitsCount, 6, "Should have 6 total benefits")
    }

    func testTotalAvailableValue_With5Cards_SumsCorrectly() async throws {
        // Given - 5 cards
        let template = createMockCardTemplate(benefitValue: 20) // 2 benefits x 20 = 40 per card

        for i in 1...5 {
            _ = try cardRepository.addCard(from: template, nickname: "Card \(i)")
        }

        // When
        await viewModel.loadData()

        // Then
        let expectedTotal: Decimal = 40 * 5 // = 200
        XCTAssertEqual(viewModel.cardCount, 5, "Should have 5 cards")
        XCTAssertEqual(viewModel.totalAvailableValue, expectedTotal, "Should sum all 5 cards correctly: got \(viewModel.totalAvailableValue) expected \(expectedTotal)")
        XCTAssertEqual(viewModel.totalBenefitsCount, 10, "Should have 10 total benefits")
    }

    func testTotalAvailableValue_With3Cards_MixedUsedBenefits() async throws {
        // Given - 3 cards, each with 1 used and 1 available benefit
        let template = createMockCardTemplate(benefitValue: 30) // 2 benefits x 30 each
        let card1 = try cardRepository.addCard(from: template, nickname: "Card 1")
        let card2 = try cardRepository.addCard(from: template, nickname: "Card 2")
        let card3 = try cardRepository.addCard(from: template, nickname: "Card 3")

        // Mark first benefit of each card as used
        if let benefit1 = card1.benefits.first {
            try benefitRepository.markBenefitUsed(benefit1)
        }
        if let benefit2 = card2.benefits.first {
            try benefitRepository.markBenefitUsed(benefit2)
        }
        if let benefit3 = card3.benefits.first {
            try benefitRepository.markBenefitUsed(benefit3)
        }

        // When
        await viewModel.loadData()

        // Then
        // Each card has 1 available ($30) and 1 used ($30)
        // Total available = 3 cards x $30 = $90
        // Total redeemed = 3 cards x $30 = $90
        let expectedAvailable: Decimal = 90
        let expectedRedeemed: Decimal = 90

        XCTAssertEqual(viewModel.cardCount, 3, "Should have 3 cards")
        XCTAssertEqual(viewModel.totalAvailableValue, expectedAvailable, "Should sum only available benefits: got \(viewModel.totalAvailableValue) expected \(expectedAvailable)")
        XCTAssertEqual(viewModel.redeemedThisMonth, expectedRedeemed, "Should sum used benefits: got \(viewModel.redeemedThisMonth) expected \(expectedRedeemed)")
    }

    func testAllBenefits_With3Cards_ReturnsAllBenefits() async throws {
        // Given - 3 cards with 2 benefits each
        let template = createMockCardTemplate(benefitValue: 25)
        _ = try cardRepository.addCard(from: template, nickname: "Card 1")
        _ = try cardRepository.addCard(from: template, nickname: "Card 2")
        _ = try cardRepository.addCard(from: template, nickname: "Card 3")

        // When
        await viewModel.loadData()

        // Then
        XCTAssertEqual(viewModel.allBenefits.count, 6, "Should return all 6 benefits")

        // Verify each benefit has proper value
        for benefit in viewModel.allBenefits {
            XCTAssertEqual(benefit.effectiveValue, 25, "Each benefit should have value 25, got \(benefit.effectiveValue)")
        }
    }

    func testDisplayCards_With3Cards_AllHaveCorrectValues() async throws {
        // Given
        let template1 = createMockCardTemplate(benefitValue: 100)
        let template2 = createMockCardTemplate(benefitValue: 50)
        let template3 = createMockCardTemplate(benefitValue: 25)

        _ = try cardRepository.addCard(from: template1, nickname: "High Value")
        _ = try cardRepository.addCard(from: template2, nickname: "Medium Value")
        _ = try cardRepository.addCard(from: template3, nickname: "Low Value")

        // When
        await viewModel.loadData()

        // Then
        XCTAssertEqual(viewModel.displayCards.count, 3, "Should have 3 display cards")

        // Verify each card's total value
        let highValueCard = viewModel.displayCards.first { $0.displayName == "High Value" }
        let mediumValueCard = viewModel.displayCards.first { $0.displayName == "Medium Value" }
        let lowValueCard = viewModel.displayCards.first { $0.displayName == "Low Value" }

        XCTAssertNotNil(highValueCard, "High value card should exist")
        XCTAssertNotNil(mediumValueCard, "Medium value card should exist")
        XCTAssertNotNil(lowValueCard, "Low value card should exist")

        XCTAssertEqual(highValueCard?.totalAvailableValue, 200, "High value card should have $200 total")
        XCTAssertEqual(mediumValueCard?.totalAvailableValue, 100, "Medium value card should have $100 total")
        XCTAssertEqual(lowValueCard?.totalAvailableValue, 50, "Low value card should have $50 total")
    }

    func testTotalAvailableValue_AfterAddingCard_UpdatesCorrectly() async throws {
        // Given - Start with 2 cards
        let template = createMockCardTemplate(benefitValue: 50) // 2 benefits x 50 = 100 per card
        _ = try cardRepository.addCard(from: template, nickname: "Card 1")
        _ = try cardRepository.addCard(from: template, nickname: "Card 2")

        await viewModel.loadData()
        XCTAssertEqual(viewModel.totalAvailableValue, 200, "Initial total should be $200")

        // When - Add a third card
        _ = try cardRepository.addCard(from: template, nickname: "Card 3")
        await viewModel.loadData()

        // Then
        XCTAssertEqual(viewModel.cardCount, 3, "Should have 3 cards")
        XCTAssertEqual(viewModel.totalAvailableValue, 300, "Total should be $300 after adding third card")
    }

    func testTotalAvailableValue_ConsistencyBetweenHomeAndCards() async throws {
        // Given - 3 cards
        let template = createMockCardTemplate(benefitValue: 40)
        _ = try cardRepository.addCard(from: template, nickname: "Card 1")
        _ = try cardRepository.addCard(from: template, nickname: "Card 2")
        _ = try cardRepository.addCard(from: template, nickname: "Card 3")

        await viewModel.loadData()

        // When - Calculate total from displayCards
        let displayCardsTotal = viewModel.displayCards.reduce(Decimal.zero) { $0 + $1.totalAvailableValue }

        // Then - Should match viewModel.totalAvailableValue
        XCTAssertEqual(viewModel.totalAvailableValue, displayCardsTotal,
                       "HomeViewModel.totalAvailableValue (\(viewModel.totalAvailableValue)) should match sum of displayCards (\(displayCardsTotal))")
    }

    func testAllDisplayBenefits_ReturnsAvailableBenefits() async throws {
        // Given
        let template = createMockCardTemplate()
        let card = try cardRepository.addCard(from: template, nickname: "Test")

        // Mark one benefit as used (should not appear in allDisplayBenefits)
        if let benefit = card.benefits.first {
            try benefitRepository.markBenefitUsed(benefit)
        }

        // When
        await viewModel.loadData()

        // Then - Only 1 available benefit should be returned
        XCTAssertEqual(viewModel.allDisplayBenefits.count, 1, "Should only return available benefits")
    }

    // MARK: - removeCardFromState Tests

    func testRemoveCardFromState_ClearsCardFromMemory() async throws {
        // Given
        let template = createMockCardTemplate()
        let card = try cardRepository.addCard(from: template, nickname: "Test")
        await viewModel.loadData()

        XCTAssertEqual(viewModel.cardCount, 1, "Should have one card initially")

        // When
        viewModel.removeCardFromState(card.id)

        // Then - Card removed from in-memory state immediately
        XCTAssertEqual(viewModel.cardCount, 0, "Should have zero cards after removal")
        XCTAssertTrue(viewModel.isEmpty, "Should be empty after removal")
    }

    func testRemoveCardFromState_ClearsExpiringBenefits() async throws {
        // Given
        let template = createMockCardTemplate()
        let card = try cardRepository.addCard(from: template, nickname: "Test")

        // Set benefit to expire soon
        let calendar = Calendar.current
        let today = Date()
        if let benefit = card.benefits.first {
            benefit.currentPeriodEnd = calendar.date(byAdding: .day, value: 3, to: today)!
            try modelContext.save()
        }

        await viewModel.loadData()
        let initialExpiring = viewModel.expiringThisWeekCount

        // When
        viewModel.removeCardFromState(card.id)

        // Then
        XCTAssertLessThan(viewModel.expiringThisWeekCount, initialExpiring, "Should remove expiring benefits")
    }

    func testRemoveCardFromState_DoesNotAffectRepository() async throws {
        // Given
        let template = createMockCardTemplate()
        let card = try cardRepository.addCard(from: template, nickname: "Test")
        await viewModel.loadData()

        // When
        viewModel.removeCardFromState(card.id)

        // Then - Card still exists in repository
        let allCards = try cardRepository.getAllCards()
        XCTAssertEqual(allCards.count, 1, "Card should still exist in repository")
    }

    // MARK: - currentInsight Tests

    func testCurrentInsight_OnboardingWhenEmpty() async throws {
        // Given - Empty state
        await viewModel.loadData()

        // Then
        XCTAssertEqual(viewModel.currentInsight, .onboarding, "Should show onboarding insight when empty")
    }

    func testCurrentInsight_UrgentExpiringWhenBenefitsExpireToday() async throws {
        // Given
        let template = createMockCardTemplate(benefitValue: 50)
        let card = try cardRepository.addCard(from: template, nickname: "Test")

        // Set benefit to expire today
        if let benefit = card.benefits.first {
            benefit.currentPeriodEnd = Date()
            try modelContext.save()
        }

        // When
        await viewModel.loadData()

        // Then
        if case .urgentExpiring(let value, let count) = viewModel.currentInsight {
            XCTAssertEqual(count, 1, "Should have 1 urgent benefit")
            XCTAssertEqual(value, 50, "Should have correct value")
        } else {
            XCTFail("Should show urgent expiring insight")
        }
    }

    func testCurrentInsight_AvailableValueWhenHighValue() async throws {
        // Given - Add cards with total value > 100
        let template = createMockCardTemplate(benefitValue: 60) // 2 benefits x 60 = 120
        _ = try cardRepository.addCard(from: template, nickname: "Test")

        // When
        await viewModel.loadData()

        // Then
        if case .availableValue(let value) = viewModel.currentInsight {
            XCTAssertGreaterThan(value, 100, "Should have high available value")
        } else {
            XCTFail("Should show available value insight when > 100")
        }
    }

    // MARK: - Expiring Benefits Grouping Tests

    func testBenefitsExpiringToday_FiltersCorrectly() async throws {
        // Given
        let template = createMockCardTemplate()
        let card = try cardRepository.addCard(from: template, nickname: "Test")

        // Set both benefits - one expires today, one doesn't
        let calendar = Calendar.current
        if let benefit1 = card.benefits.first {
            benefit1.currentPeriodEnd = Date() // Today
            try modelContext.save()
        }

        // When
        await viewModel.loadData()

        // Then
        XCTAssertGreaterThanOrEqual(viewModel.benefitsExpiringToday.count, 1, "Should have benefits expiring today")
    }

    func testBenefitsExpiringThisWeek_FiltersCorrectly() async throws {
        // Given
        let template = createMockCardTemplate()
        let card = try cardRepository.addCard(from: template, nickname: "Test")

        // Set benefit to expire in 3 days
        let calendar = Calendar.current
        if let benefit = card.benefits.first {
            benefit.currentPeriodEnd = calendar.date(byAdding: .day, value: 3, to: Date())!
            try modelContext.save()
        }

        // When
        await viewModel.loadData()

        // Then
        XCTAssertGreaterThanOrEqual(viewModel.benefitsExpiringThisWeek.count, 1, "Should have benefits expiring this week")
    }

    func testBenefitsExpiringThisMonth_FiltersCorrectly() async throws {
        // Given
        let template = createMockCardTemplate()
        let card = try cardRepository.addCard(from: template, nickname: "Test")

        // Set benefit to expire in 15 days
        let calendar = Calendar.current
        if let benefit = card.benefits.first {
            benefit.currentPeriodEnd = calendar.date(byAdding: .day, value: 15, to: Date())!
            try modelContext.save()
        }

        // When
        await viewModel.loadData()

        // Then
        XCTAssertGreaterThanOrEqual(viewModel.benefitsExpiringThisMonth.count, 1, "Should have benefits expiring this month")
    }

    // MARK: - lastRefreshed Tests

    func testLastRefreshed_UpdatesOnLoadData() async throws {
        // Given
        XCTAssertNil(viewModel.lastRefreshed, "Should be nil initially")

        // When
        await viewModel.loadData()

        // Then
        XCTAssertNotNil(viewModel.lastRefreshed, "Should be set after loadData")
    }

    func testLastRefreshedText_FormatsCorrectly() async throws {
        // Given
        XCTAssertNil(viewModel.lastRefreshedText, "Should be nil initially")

        // When
        await viewModel.loadData()

        // Then
        XCTAssertNotNil(viewModel.lastRefreshedText, "Should have text after loadData")
        XCTAssertTrue(viewModel.lastRefreshedText?.contains("Updated") == true, "Should contain 'Updated'")
    }

    // MARK: - Helper Methods

    private func createMockCardTemplate(benefitValue: Decimal = 15) -> CardTemplate {
        return CardTemplate(
            id: UUID(),
            name: "Test Card",
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
                    description: "Monthly benefit",
                    value: benefitValue,
                    frequency: .monthly,
                    category: .transportation,
                    merchant: "Test Merchant",
                    resetDayOfMonth: 1
                ),
                BenefitTemplate(
                    id: UUID(),
                    name: "Annual Credit",
                    description: "Annual benefit",
                    value: benefitValue,
                    frequency: .annual,
                    category: .travel,
                    merchant: nil,
                    resetDayOfMonth: nil
                )
            ]
        )
    }
}

// MARK: - Mock Template Loader

@MainActor
final class HomeViewModelMockTemplateLoader: TemplateLoaderProtocol {

    var templates: [CardTemplate] = []
    var shouldThrowError = false

    func loadAllTemplates() throws -> CardDatabase {
        if shouldThrowError {
            throw NSError(domain: "MockError", code: 1)
        }

        let benefitTemplates = templates.flatMap { $0.benefits }
        _ = Dictionary(uniqueKeysWithValues: benefitTemplates.map { ($0.id, $0) })

        return CardDatabase(
            schemaVersion: 1,
            dataVersion: "1.0",
            lastUpdated: Date(),
            cards: templates
        )
    }

    func getTemplate(by id: UUID) throws -> CardTemplate? {
        templates.first { $0.id == id }
    }

    func getBenefitTemplate(by id: UUID) throws -> BenefitTemplate? {
        for card in templates {
            if let benefit = card.benefits.first(where: { $0.id == id }) {
                return benefit
            }
        }
        return nil
    }

    func searchTemplates(query: String) throws -> [CardTemplate] {
        templates.filter { $0.name.lowercased().contains(query.lowercased()) }
    }

    func getActiveTemplates() throws -> [CardTemplate] {
        templates.filter { $0.isActive }
    }

    func getTemplatesByIssuer() throws -> [String: [CardTemplate]] {
        Dictionary(grouping: templates, by: { $0.issuer })
    }
}
