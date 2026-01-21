//
//  AddCardViewModelTests.swift
//  CouponTrackerTests
//
//  Created: January 2026
//  Purpose: Unit tests for AddCardViewModel template loading, filtering, and card creation.
//

import XCTest
import SwiftData
@testable import CouponTracker

/// Unit tests for AddCardViewModel.
/// Tests template loading, filtering, selection, and card creation flow.
@MainActor
final class AddCardViewModelTests: XCTestCase {

    // MARK: - Properties

    var modelContainer: ModelContainer!
    var modelContext: ModelContext!
    var cardRepository: CardRepository!
    var templateLoader: AddCardViewModelTestTemplateLoader!
    var notificationService: NotificationService!
    var viewModel: AddCardViewModel!

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
        templateLoader = AddCardViewModelTestTemplateLoader()
        notificationService = NotificationService()

        viewModel = AddCardViewModel(
            cardRepository: cardRepository,
            templateLoader: templateLoader,
            notificationService: notificationService,
            modelContext: modelContext
        )
    }

    override func tearDown() async throws {
        viewModel = nil
        templateLoader = nil
        notificationService = nil
        cardRepository = nil
        modelContext = nil
        modelContainer = nil
        try await super.tearDown()
    }

    // MARK: - Initial State Tests

    func testInitialState_IsEmpty() {
        // Then
        XCTAssertTrue(viewModel.allTemplates.isEmpty, "Templates should be empty initially")
        XCTAssertTrue(viewModel.filteredTemplates.isEmpty, "Filtered templates should be empty")
        XCTAssertNil(viewModel.selectedTemplate, "No template should be selected")
        XCTAssertEqual(viewModel.nickname, "", "Nickname should be empty")
        XCTAssertEqual(viewModel.searchQuery, "", "Search query should be empty")
        XCTAssertFalse(viewModel.isLoading, "Should not be loading")
        XCTAssertNil(viewModel.error, "Should have no error")
        XCTAssertFalse(viewModel.canAddCard, "Should not be able to add card initially")
    }

    // MARK: - loadTemplates Tests

    func testLoadTemplates_PopulatesTemplates() {
        // Given
        templateLoader.templates = createMockTemplates()

        // When
        viewModel.loadTemplates()

        // Then
        XCTAssertEqual(viewModel.allTemplates.count, 3, "Should have loaded all templates")
        XCTAssertEqual(viewModel.filteredTemplates.count, 3, "Filtered should match all templates")
        XCTAssertFalse(viewModel.isLoading, "Should not be loading after completion")
    }

    func testLoadTemplates_SetsLoadingState() {
        // Given
        templateLoader.templates = createMockTemplates()

        // When/Then - The loading is synchronous in this implementation
        viewModel.loadTemplates()
        XCTAssertFalse(viewModel.isLoading, "Loading should be false after completion")
    }

    func testLoadTemplates_HandlesError() {
        // Given
        templateLoader.shouldThrowError = true

        // When
        viewModel.loadTemplates()

        // Then
        XCTAssertTrue(viewModel.allTemplates.isEmpty, "Templates should be empty on error")
        XCTAssertNotNil(viewModel.error, "Error should be set")
    }

    func testLoadTemplates_WithEmptyDatabase_SetsEmptyState() {
        // Given
        templateLoader.templates = []

        // When
        viewModel.loadTemplates()

        // Then
        XCTAssertTrue(viewModel.allTemplates.isEmpty, "Templates should be empty")
        XCTAssertTrue(viewModel.filteredTemplates.isEmpty, "Filtered should be empty")
        XCTAssertNil(viewModel.error, "Should have no error")
    }

    // MARK: - Search/Filter Tests

    func testSearchQuery_FiltersTemplatesByName() {
        // Given
        templateLoader.templates = createMockTemplates()
        viewModel.loadTemplates()

        // When
        viewModel.searchQuery = "Platinum"

        // Then
        XCTAssertEqual(viewModel.filteredTemplates.count, 1, "Should filter to platinum card")
        XCTAssertEqual(viewModel.filteredTemplates.first?.name, "Platinum Card", "Should match platinum")
    }

    func testSearchQuery_FiltersTemplatesByIssuer() {
        // Given
        templateLoader.templates = createMockTemplates()
        viewModel.loadTemplates()

        // When
        viewModel.searchQuery = "Chase"

        // Then
        XCTAssertEqual(viewModel.filteredTemplates.count, 2, "Should filter to Chase cards")
        XCTAssertTrue(viewModel.filteredTemplates.allSatisfy { $0.issuer == "Chase" }, "All should be Chase")
    }

    func testSearchQuery_IsCaseInsensitive() {
        // Given
        templateLoader.templates = createMockTemplates()
        viewModel.loadTemplates()

        // When
        viewModel.searchQuery = "PLATINUM"

        // Then
        XCTAssertEqual(viewModel.filteredTemplates.count, 1, "Should find platinum case-insensitively")
    }

    func testSearchQuery_EmptyQuery_ShowsAllTemplates() {
        // Given
        templateLoader.templates = createMockTemplates()
        viewModel.loadTemplates()
        viewModel.searchQuery = "Platinum" // Filter first

        // When
        viewModel.searchQuery = ""

        // Then
        XCTAssertEqual(viewModel.filteredTemplates.count, 3, "Should show all templates")
    }

    func testSearchQuery_NoMatch_ReturnsEmptyArray() {
        // Given
        templateLoader.templates = createMockTemplates()
        viewModel.loadTemplates()

        // When
        viewModel.searchQuery = "XYZ123NonExistent"

        // Then
        XCTAssertTrue(viewModel.filteredTemplates.isEmpty, "Should have no matches")
    }

    func testSearchQuery_TrimsWhitespace() {
        // Given
        templateLoader.templates = createMockTemplates()
        viewModel.loadTemplates()

        // When
        viewModel.searchQuery = "   Platinum   "

        // Then
        XCTAssertEqual(viewModel.filteredTemplates.count, 1, "Should find platinum after trimming")
    }

    // MARK: - templatesByIssuer Tests

    func testTemplatesByIssuer_GroupsCorrectly() {
        // Given
        templateLoader.templates = createMockTemplates()
        viewModel.loadTemplates()

        // When
        let byIssuer = viewModel.templatesByIssuer

        // Then
        XCTAssertEqual(byIssuer.keys.count, 2, "Should have 2 issuers")
        XCTAssertEqual(byIssuer["Chase"]?.count, 2, "Chase should have 2 cards")
        XCTAssertEqual(byIssuer["American Express"]?.count, 1, "Amex should have 1 card")
    }

    // MARK: - selectTemplate Tests

    func testSelectTemplate_SetsSelectedTemplate() {
        // Given
        templateLoader.templates = createMockTemplates()
        viewModel.loadTemplates()
        let template = viewModel.allTemplates.first!

        // When
        viewModel.selectTemplate(template)

        // Then
        XCTAssertEqual(viewModel.selectedTemplate?.id, template.id, "Should select the template")
        XCTAssertTrue(viewModel.canAddCard, "Should be able to add card now")
    }

    func testSelectTemplate_ChangesSelection() {
        // Given
        templateLoader.templates = createMockTemplates()
        viewModel.loadTemplates()
        let template1 = viewModel.allTemplates[0]
        let template2 = viewModel.allTemplates[1]
        viewModel.selectTemplate(template1)

        // When
        viewModel.selectTemplate(template2)

        // Then
        XCTAssertEqual(viewModel.selectedTemplate?.id, template2.id, "Should change to new template")
    }

    // MARK: - canAddCard Tests

    func testCanAddCard_FalseWithNoSelection() {
        // Given
        templateLoader.templates = createMockTemplates()
        viewModel.loadTemplates()

        // Then
        XCTAssertFalse(viewModel.canAddCard, "Should not be able to add without selection")
    }

    func testCanAddCard_TrueWithSelection() {
        // Given
        templateLoader.templates = createMockTemplates()
        viewModel.loadTemplates()
        viewModel.selectTemplate(viewModel.allTemplates.first!)

        // Then
        XCTAssertTrue(viewModel.canAddCard, "Should be able to add with selection")
    }

    // MARK: - addCard Tests

    func testAddCard_CreatesCardSuccessfully() throws {
        // Given
        templateLoader.templates = createMockTemplatesWithBenefits()
        viewModel.loadTemplates()
        viewModel.selectTemplate(viewModel.allTemplates.first!)
        viewModel.nickname = "Personal"

        // When
        let card = viewModel.addCard()

        // Then
        XCTAssertNotNil(card, "Card should be created")
        XCTAssertEqual(card?.nickname, "Personal", "Should have correct nickname")
        XCTAssertNotNil(card?.cardTemplateId, "Should have template ID")
    }

    func testAddCard_ReturnsNilWithoutSelection() {
        // Given
        templateLoader.templates = createMockTemplates()
        viewModel.loadTemplates()
        // No template selected

        // When
        let card = viewModel.addCard()

        // Then
        XCTAssertNil(card, "Should return nil without selection")
    }

    func testAddCard_WithEmptyNickname_UsesNil() throws {
        // Given
        templateLoader.templates = createMockTemplatesWithBenefits()
        viewModel.loadTemplates()
        viewModel.selectTemplate(viewModel.allTemplates.first!)
        viewModel.nickname = ""

        // When
        let card = viewModel.addCard()

        // Then
        XCTAssertNotNil(card, "Card should be created")
        XCTAssertNil(card?.nickname, "Nickname should be nil for empty input")
    }

    func testAddCard_TrimsNickname() throws {
        // Given
        templateLoader.templates = createMockTemplatesWithBenefits()
        viewModel.loadTemplates()
        viewModel.selectTemplate(viewModel.allTemplates.first!)
        viewModel.nickname = "   Personal Card   "

        // When
        let card = viewModel.addCard()

        // Then
        XCTAssertEqual(card?.nickname, "Personal Card", "Nickname should be trimmed")
    }

    func testAddCard_ResetsStateAfterSuccess() throws {
        // Given
        templateLoader.templates = createMockTemplatesWithBenefits()
        viewModel.loadTemplates()
        viewModel.selectTemplate(viewModel.allTemplates.first!)
        viewModel.nickname = "Personal"
        viewModel.searchQuery = "test"

        // When
        _ = viewModel.addCard()

        // Then
        XCTAssertNil(viewModel.selectedTemplate, "Selection should be cleared")
        XCTAssertEqual(viewModel.nickname, "", "Nickname should be cleared")
        XCTAssertEqual(viewModel.searchQuery, "", "Search should be cleared")
        XCTAssertNil(viewModel.error, "Error should be cleared")
    }

    func testAddCard_PersistsToRepository() throws {
        // Given
        templateLoader.templates = createMockTemplatesWithBenefits()
        viewModel.loadTemplates()
        viewModel.selectTemplate(viewModel.allTemplates.first!)
        viewModel.nickname = "Test Card"

        // When
        let createdCard = viewModel.addCard()

        // Then
        XCTAssertNotNil(createdCard)

        let allCards = try cardRepository.getAllCards()
        XCTAssertEqual(allCards.count, 1, "Card should be in repository")
        XCTAssertEqual(allCards.first?.id, createdCard?.id, "Should be the same card")
    }

    // MARK: - reset Tests

    func testReset_ClearsAllState() {
        // Given
        templateLoader.templates = createMockTemplates()
        viewModel.loadTemplates()
        viewModel.selectTemplate(viewModel.allTemplates.first!)
        viewModel.nickname = "Test"
        viewModel.searchQuery = "search"

        // When
        viewModel.reset()

        // Then
        XCTAssertNil(viewModel.selectedTemplate, "Selection should be cleared")
        XCTAssertEqual(viewModel.nickname, "", "Nickname should be cleared")
        XCTAssertEqual(viewModel.searchQuery, "", "Search should be cleared")
        XCTAssertNil(viewModel.error, "Error should be cleared")
    }

    func testReset_RestoresFilteredTemplates() {
        // Given
        templateLoader.templates = createMockTemplates()
        viewModel.loadTemplates()
        viewModel.searchQuery = "NonExistent"

        XCTAssertTrue(viewModel.filteredTemplates.isEmpty, "Should have no matches")

        // When
        viewModel.reset()

        // Then
        XCTAssertEqual(viewModel.filteredTemplates.count, 3, "Should show all templates")
    }

    // MARK: - Integration Tests

    func testFullFlow_LoadSearchSelectAdd() throws {
        // Given
        templateLoader.templates = createMockTemplatesWithBenefits()

        // When - Load templates
        viewModel.loadTemplates()
        XCTAssertEqual(viewModel.allTemplates.count, 3)

        // When - Search
        viewModel.searchQuery = "Platinum"
        XCTAssertEqual(viewModel.filteredTemplates.count, 1)

        // When - Select
        viewModel.selectTemplate(viewModel.filteredTemplates.first!)
        XCTAssertTrue(viewModel.canAddCard)

        // When - Add card
        viewModel.nickname = "My Platinum"
        let card = viewModel.addCard()

        // Then
        XCTAssertNotNil(card)
        XCTAssertEqual(card?.nickname, "My Platinum")

        // Verify in repository
        let allCards = try cardRepository.getAllCards()
        XCTAssertEqual(allCards.count, 1)
    }

    // MARK: - Helper Methods

    private func createMockTemplates() -> [CardTemplate] {
        [
            CardTemplate(
                id: UUID(),
                name: "Platinum Card",
                issuer: "American Express",
                artworkAsset: "amex_platinum",
                annualFee: 695,
                primaryColorHex: "#E5E4E2",
                secondaryColorHex: "#A9A9A9",
                isActive: true,
                lastUpdated: Date(),
                benefits: []
            ),
            CardTemplate(
                id: UUID(),
                name: "Sapphire Reserve",
                issuer: "Chase",
                artworkAsset: "chase_sapphire",
                annualFee: 550,
                primaryColorHex: "#1a1a2e",
                secondaryColorHex: "#2d3a6d",
                isActive: true,
                lastUpdated: Date(),
                benefits: []
            ),
            CardTemplate(
                id: UUID(),
                name: "Freedom Unlimited",
                issuer: "Chase",
                artworkAsset: "chase_freedom",
                annualFee: 0,
                primaryColorHex: "#003C71",
                secondaryColorHex: "#0066B2",
                isActive: true,
                lastUpdated: Date(),
                benefits: []
            )
        ]
    }

    private func createMockTemplatesWithBenefits() -> [CardTemplate] {
        [
            CardTemplate(
                id: UUID(),
                name: "Platinum Card",
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
                    )
                ]
            ),
            CardTemplate(
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
                    )
                ]
            ),
            CardTemplate(
                id: UUID(),
                name: "Freedom Unlimited",
                issuer: "Chase",
                artworkAsset: "chase_freedom",
                annualFee: 0,
                primaryColorHex: "#003C71",
                secondaryColorHex: "#0066B2",
                isActive: true,
                lastUpdated: Date(),
                benefits: []
            )
        ]
    }
}

// MARK: - Test Template Loader

@MainActor
final class AddCardViewModelTestTemplateLoader: TemplateLoaderProtocol {

    var templates: [CardTemplate] = []
    var shouldThrowError = false

    func loadAllTemplates() throws -> CardDatabase {
        if shouldThrowError {
            throw NSError(domain: "TestError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Test error"])
        }

        return CardDatabase(
            schemaVersion: 1,
            dataVersion: "1.0",
            lastUpdated: Date(),
            cards: templates
        )
    }

    func getTemplate(by id: UUID) throws -> CardTemplate? {
        if shouldThrowError {
            throw NSError(domain: "TestError", code: 1)
        }
        return templates.first { $0.id == id }
    }

    func getBenefitTemplate(by id: UUID) throws -> BenefitTemplate? {
        if shouldThrowError {
            throw NSError(domain: "TestError", code: 1)
        }
        for card in templates {
            if let benefit = card.benefits.first(where: { $0.id == id }) {
                return benefit
            }
        }
        return nil
    }

    func getActiveTemplates() throws -> [CardTemplate] {
        if shouldThrowError {
            throw NSError(domain: "TestError", code: 1)
        }
        return templates.filter { $0.isActive }
    }

    func searchTemplates(query: String) throws -> [CardTemplate] {
        if shouldThrowError {
            throw NSError(domain: "TestError", code: 1)
        }
        guard !query.isEmpty else { return templates }
        let lowercasedQuery = query.lowercased()
        return templates.filter {
            $0.name.lowercased().contains(lowercasedQuery) ||
            $0.issuer.lowercased().contains(lowercasedQuery)
        }
    }

    func getTemplatesByIssuer() throws -> [String: [CardTemplate]] {
        if shouldThrowError {
            throw NSError(domain: "TestError", code: 1)
        }
        return Dictionary(grouping: templates, by: { $0.issuer })
    }
}
