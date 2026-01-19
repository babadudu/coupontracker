//
//  AddCardViewModel.swift
//  CouponTracker
//
//  Created by Junior Engineer 3 on 2026-01-17.
//

import Foundation
import SwiftUI
import Observation

/// ViewModel for managing the card addition flow.
///
/// This view model handles:
/// - Loading card templates from the template loader
/// - Searching and filtering templates by name or issuer
/// - Grouping templates by issuer for display
/// - Creating new user cards from selected templates
/// - Managing state for the add card UI
@Observable
@MainActor
final class AddCardViewModel {

    // MARK: - Dependencies

    private let cardRepository: CardRepositoryProtocol
    private let templateLoader: TemplateLoaderProtocol

    // MARK: - State

    /// All available card templates loaded from the template loader
    private(set) var allTemplates: [CardTemplate] = []

    /// Templates after applying search filter
    private(set) var filteredTemplates: [CardTemplate] = []

    /// Current search query for filtering templates
    var searchQuery: String = "" {
        didSet { filterTemplates() }
    }

    /// Currently selected template for adding a card
    var selectedTemplate: CardTemplate?

    /// Optional user-provided nickname for the card being added
    var nickname: String = ""

    /// Indicates if templates are currently being loaded
    private(set) var isLoading = false

    /// Error encountered during template loading or card creation
    private(set) var error: Error?

    // MARK: - Computed Properties

    /// Groups filtered templates by issuer name for organized display
    var templatesByIssuer: [String: [CardTemplate]] {
        Dictionary(grouping: filteredTemplates, by: { $0.issuer })
    }

    /// Indicates if all requirements are met to add a card
    var canAddCard: Bool {
        selectedTemplate != nil
    }

    // MARK: - Initialization

    /// Initialize the view model with required dependencies
    /// - Parameters:
    ///   - cardRepository: Repository for managing user cards
    ///   - templateLoader: Service for loading card templates
    init(
        cardRepository: CardRepositoryProtocol,
        templateLoader: TemplateLoaderProtocol
    ) {
        self.cardRepository = cardRepository
        self.templateLoader = templateLoader
    }

    // MARK: - Actions

    /// Load all active card templates from the template loader
    ///
    /// This method will:
    /// 1. Set loading state
    /// 2. Fetch active templates from the template loader
    /// 3. Initialize filtered templates
    /// 4. Handle any errors that occur
    func loadTemplates() {
        isLoading = true
        error = nil

        do {
            allTemplates = try templateLoader.getActiveTemplates()
            filteredTemplates = allTemplates
        } catch {
            self.error = error
            allTemplates = []
            filteredTemplates = []
        }

        isLoading = false
    }

    /// Filter templates based on current search query
    ///
    /// Filters by card name or issuer name (case-insensitive).
    /// If search query is empty, shows all templates.
    func filterTemplates() {
        let trimmedQuery = searchQuery.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedQuery.isEmpty else {
            filteredTemplates = allTemplates
            return
        }

        let lowercasedQuery = trimmedQuery.lowercased()

        filteredTemplates = allTemplates.filter { template in
            template.name.lowercased().contains(lowercasedQuery) ||
            template.issuer.lowercased().contains(lowercasedQuery)
        }
    }

    /// Select a template for card creation
    /// - Parameter template: The template to select
    func selectTemplate(_ template: CardTemplate) {
        selectedTemplate = template
    }

    /// Add a new card based on the selected template
    ///
    /// This method will:
    /// 1. Validate that a template is selected
    /// 2. Create a new user card using the repository
    /// 3. Reset the view model state on success
    /// 4. Return the created card
    ///
    /// - Returns: The newly created UserCard, or nil if creation fails
    func addCard() -> UserCard? {
        guard let template = selectedTemplate else {
            return nil
        }

        error = nil

        do {
            // Create card with optional nickname (nil if empty)
            let nicknameToUse = nickname.trimmingCharacters(in: .whitespacesAndNewlines)
            let finalNickname = nicknameToUse.isEmpty ? nil : nicknameToUse

            let newCard = try cardRepository.addCard(
                from: template,
                nickname: finalNickname
            )

            // Reset state after successful creation
            reset()

            return newCard
        } catch {
            self.error = error
            return nil
        }
    }

    /// Reset the view model to initial state
    ///
    /// Clears:
    /// - Selected template
    /// - Nickname input
    /// - Search query (which resets filtered templates)
    /// - Any errors
    func reset() {
        selectedTemplate = nil
        nickname = ""
        searchQuery = ""
        error = nil
    }
}

// MARK: - Preview Support

#if DEBUG
extension AddCardViewModel {
    /// Create a view model with mock data for previews
    /// - Parameter templates: Optional array of templates to use (defaults to mock templates)
    /// - Returns: Configured view model for previews
    static func preview(templates: [CardTemplate]? = nil) -> AddCardViewModel {
        let mockRepository = AddCardMockCardRepository()
        let mockLoader = MockTemplateLoader(templates: templates ?? CardTemplate.mockTemplates)
        let viewModel = AddCardViewModel(
            cardRepository: mockRepository,
            templateLoader: mockLoader
        )
        viewModel.loadTemplates()
        return viewModel
    }
}

// MARK: - Mock Template Loader

private final class MockTemplateLoader: TemplateLoaderProtocol {
    private let mockTemplates: [CardTemplate]

    init(templates: [CardTemplate]) {
        self.mockTemplates = templates
    }

    func loadAllTemplates() throws -> CardDatabase {
        CardDatabase(schemaVersion: 1, dataVersion: "1.0", lastUpdated: Date(), cards: mockTemplates)
    }

    func getTemplate(by id: UUID) throws -> CardTemplate? {
        mockTemplates.first { $0.id == id }
    }

    func getBenefitTemplate(by id: UUID) throws -> BenefitTemplate? {
        mockTemplates.flatMap { $0.benefits }.first { $0.id == id }
    }

    func getActiveTemplates() throws -> [CardTemplate] {
        mockTemplates
    }

    func searchTemplates(query: String) throws -> [CardTemplate] {
        guard !query.isEmpty else { return mockTemplates }
        let lowercasedQuery = query.lowercased()
        return mockTemplates.filter { template in
            template.name.lowercased().contains(lowercasedQuery) ||
            template.issuer.lowercased().contains(lowercasedQuery)
        }
    }

    func getTemplatesByIssuer() throws -> [String: [CardTemplate]] {
        Dictionary(grouping: mockTemplates, by: { $0.issuer })
    }
}

// MARK: - Mock Card Repository

private final class AddCardMockCardRepository: CardRepositoryProtocol {
    private var cards: [UserCard] = []

    func getAllCards() throws -> [UserCard] {
        return cards
    }

    func getCard(by id: UUID) throws -> UserCard? {
        return cards.first { $0.id == id }
    }

    func addCard(from template: CardTemplate, nickname: String?) throws -> UserCard {
        let card = UserCard(
            cardTemplateId: template.id,
            nickname: nickname,
            sortOrder: cards.count
        )
        cards.append(card)
        return card
    }

    func deleteCard(_ card: UserCard) throws {
        cards.removeAll { $0.id == card.id }
    }

    func updateCard(_ card: UserCard) throws {
        // Mock implementation - in real repository this would persist changes
    }
}

// MARK: - Mock CardTemplate Data

extension CardTemplate {
    static var mockTemplates: [CardTemplate] {
        [
            CardTemplate(
                id: UUID(),
                name: "Sapphire Preferred",
                issuer: "Chase",
                artworkAsset: "chase_sapphire_preferred",
                annualFee: 95,
                primaryColorHex: "#003C71",
                secondaryColorHex: "#0066B2",
                isActive: true,
                lastUpdated: Date(),
                benefits: []
            ),
            CardTemplate(
                id: UUID(),
                name: "Gold Card",
                issuer: "American Express",
                artworkAsset: "amex_gold",
                annualFee: 250,
                primaryColorHex: "#D4AF37",
                secondaryColorHex: "#FFD700",
                isActive: true,
                lastUpdated: Date(),
                benefits: []
            ),
            CardTemplate(
                id: UUID(),
                name: "Freedom Unlimited",
                issuer: "Chase",
                artworkAsset: "chase_freedom_unlimited",
                annualFee: 0,
                primaryColorHex: "#003C71",
                secondaryColorHex: "#0066B2",
                isActive: true,
                lastUpdated: Date(),
                benefits: []
            ),
            CardTemplate(
                id: UUID(),
                name: "Venture X",
                issuer: "Capital One",
                artworkAsset: "capitalone_venturex",
                annualFee: 395,
                primaryColorHex: "#004977",
                secondaryColorHex: "#006CB7",
                isActive: true,
                lastUpdated: Date(),
                benefits: []
            )
        ]
    }
}
#endif
