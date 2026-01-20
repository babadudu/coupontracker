//
//  HomeViewModel.swift
//  CouponTracker
//
//  Created by Junior Engineer 1 on 2026-01-17.
//  Purpose: ViewModel for home screen managing card and benefit data
//

import Foundation
import SwiftUI
import Observation

// MARK: - Dashboard Insight

/// Types of insights that can be shown on the dashboard banner
enum DashboardInsight: Equatable {
    /// Urgent benefits expiring today
    case urgentExpiring(value: Decimal, count: Int)

    /// Celebration for used benefits this month
    case monthlySuccess(value: Decimal)

    /// Total available value to claim
    case availableValue(value: Decimal)

    /// New user onboarding prompt
    case onboarding

    /// Icon for this insight type
    var icon: String {
        switch self {
        case .urgentExpiring:
            return "exclamationmark.triangle.fill"
        case .monthlySuccess:
            return "star.fill"
        case .availableValue:
            return "gift.fill"
        case .onboarding:
            return "sparkles"
        }
    }

    /// Background color for this insight type
    var backgroundColor: Color {
        switch self {
        case .urgentExpiring:
            return DesignSystem.Colors.danger
        case .monthlySuccess:
            return DesignSystem.Colors.success
        case .availableValue:
            return DesignSystem.Colors.primaryFallback
        case .onboarding:
            return DesignSystem.Colors.primaryFallback
        }
    }

    /// Message text for this insight
    var message: String {
        switch self {
        case .urgentExpiring(let value, let count):
            let valueStr = Formatters.formatCurrencyWhole(value)
            return count == 1
                ? "\(valueStr) expires today! Don't miss out."
                : "\(count) benefits (\(valueStr)) expire today!"
        case .monthlySuccess(let value):
            return "You've redeemed \(Formatters.formatCurrencyWhole(value)) this month!"
        case .availableValue(let value):
            return "\(Formatters.formatCurrencyWhole(value)) in benefits waiting for you"
        case .onboarding:
            return "Add your first card to start tracking benefits"
        }
    }
}

/// ViewModel for the home screen.
///
/// Manages the state and business logic for displaying user cards
/// and their associated benefits. Handles data loading, refresh,
/// and provides computed properties for UI display.
///
/// State Management:
/// - Uses @Observable macro for SwiftUI integration
/// - All state updates happen on @MainActor
/// - Provides loading and error states for UI feedback
@Observable
@MainActor
final class HomeViewModel {

    // MARK: - Dependencies

    private let cardRepository: CardRepositoryProtocol
    private let benefitRepository: BenefitRepositoryProtocol
    private let templateLoader: TemplateLoaderProtocol
    private var recommendationService: CardRecommendationServiceProtocol?

    // MARK: - State

    /// All user cards loaded from storage
    private(set) var cards: [UserCard] = []

    /// Benefits expiring within 7 days
    private(set) var expiringBenefits: [Benefit] = []

    /// Cached card templates for display
    private var cardTemplates: [UUID: CardTemplate] = [:]

    /// Cached benefit templates for display
    private var benefitTemplates: [UUID: BenefitTemplate] = [:]

    /// Loading state for async operations
    private(set) var isLoading = false

    /// Error state for failed operations
    private(set) var error: Error?

    /// Last data refresh timestamp (for pull-to-refresh feedback)
    private(set) var lastRefreshed: Date?

    /// Best card recommendations by category
    private(set) var categoryRecommendations: [BenefitCategory: RecommendedCard] = [:]

    // MARK: - Display Adapters (ADR-001)

    /// Cards adapted for display with resolved template data
    var displayCards: [CardDisplayAdapter] {
        cards.map { card in
            let template = card.cardTemplateId.flatMap { cardTemplates[$0] }
            return CardDisplayAdapter(
                card: card,
                cardTemplate: template,
                benefitTemplates: benefitTemplates
            )
        }
    }

    /// Expiring benefits adapted for display
    var displayExpiringBenefits: [ExpiringBenefitDisplayAdapter] {
        expiringBenefits.compactMap { benefit in
            guard let userCard = benefit.userCard else { return nil }
            let cardTemplate = userCard.cardTemplateId.flatMap { cardTemplates[$0] }
            let benefitTemplate = benefit.templateBenefitId.flatMap { benefitTemplates[$0] }

            let cardAdapter = CardDisplayAdapter(
                card: userCard,
                cardTemplate: cardTemplate,
                benefitTemplates: benefitTemplates
            )
            let benefitAdapter = BenefitDisplayAdapter(
                benefit: benefit,
                template: benefitTemplate
            )
            return ExpiringBenefitDisplayAdapter(benefit: benefitAdapter, card: cardAdapter)
        }
    }

    // MARK: - Computed Properties

    /// Total available value across all cards and benefits
    var totalAvailableValue: Decimal {
        cards.reduce(Decimal.zero) { total, card in
            total + card.totalAvailableValue
        }
    }

    /// Number of cards in wallet
    var cardCount: Int {
        cards.count
    }

    /// Number of benefits expiring within 7 days
    var expiringThisWeekCount: Int {
        expiringBenefits.count
    }

    /// Whether the wallet is empty
    var isEmpty: Bool {
        cards.isEmpty
    }

    /// Total value redeemed for a specific period (uses date overlap, not frequency filter)
    func redeemedValue(for period: BenefitPeriod) -> Decimal {
        PeriodMetrics.calculate(for: allBenefits, period: period).redeemedValue
    }

    /// Total value redeemed this month (convenience for monthly period)
    var redeemedThisMonth: Decimal {
        redeemedValue(for: .monthly)
    }

    /// Total value redeemed this quarter
    var redeemedThisQuarter: Decimal {
        redeemedValue(for: .quarterly)
    }

    /// Total value redeemed this year
    var redeemedThisYear: Decimal {
        redeemedValue(for: .annual)
    }

    /// Count of used benefits
    var usedBenefitsCount: Int {
        cards.reduce(0) { total, card in
            total + card.benefits.filter { $0.status == .used }.count
        }
    }

    /// Total count of all benefits
    var totalBenefitsCount: Int {
        cards.reduce(0) { total, card in
            total + card.benefits.count
        }
    }

    /// All benefits across all cards (for accomplishment rings)
    var allBenefits: [Benefit] {
        cards.flatMap { $0.benefits }
    }

    /// All benefits as displayable for chart
    var allDisplayBenefits: [any BenefitDisplayable] {
        cards.flatMap { card in
            card.benefits
                .filter { $0.status == .available }
                .map { benefit in
                    let template = benefit.templateBenefitId.flatMap { benefitTemplates[$0] }
                    return BenefitDisplayAdapter(
                        benefit: benefit,
                        template: template
                    )
                }
        }
    }

    /// Benefits grouped by category with total value per category
    var benefitsByCategory: [BenefitCategory: Decimal] {
        var result: [BenefitCategory: Decimal] = [:]
        for benefit in allDisplayBenefits {
            let category = benefit.category
            result[category, default: .zero] += benefit.value
        }
        return result
    }

    /// Benefits expiring today (0 days remaining)
    var benefitsExpiringToday: [any BenefitDisplayable] {
        allDisplayBenefits.filter { $0.daysRemaining == 0 }
    }

    /// Benefits expiring this week (1-7 days remaining)
    var benefitsExpiringThisWeek: [any BenefitDisplayable] {
        allDisplayBenefits.filter { $0.daysRemaining > 0 && $0.daysRemaining <= 7 }
    }

    /// Benefits expiring this month (8-30 days remaining)
    var benefitsExpiringThisMonth: [any BenefitDisplayable] {
        allDisplayBenefits.filter { $0.daysRemaining > 7 && $0.daysRemaining <= 30 }
    }

    // MARK: - Urgency-Based Groupings

    /// Benefits grouped by expiration urgency level
    var benefitsByUrgency: [ExpirationUrgency: [any BenefitDisplayable]] {
        Dictionary(grouping: allDisplayBenefits) { benefit in
            ExpirationUrgency.from(daysRemaining: benefit.daysRemaining)
        }
    }

    /// Display benefits grouped by urgency (for UI)
    var displayBenefitsByUrgency: [ExpirationUrgency: [ExpiringBenefitDisplayAdapter]] {
        var result: [ExpirationUrgency: [ExpiringBenefitDisplayAdapter]] = [:]
        for adapter in displayExpiringBenefits {
            let urgency = ExpirationUrgency.from(daysRemaining: adapter.benefit.daysRemaining)
            result[urgency, default: []].append(adapter)
        }
        return result
    }

    /// Urgent expiring benefits (today + tomorrow + next 3 days)
    var urgentExpiringBenefits: [any BenefitDisplayable] {
        ExpirationUrgency.urgentLevels.flatMap { urgency in
            benefitsByUrgency[urgency] ?? []
        }
    }

    /// Count of urgent expiring benefits
    var urgentExpiringCount: Int {
        urgentExpiringBenefits.count
    }

    /// Total value of urgent expiring benefits
    var urgentExpiringValue: Decimal {
        urgentExpiringBenefits.reduce(Decimal.zero) { $0 + $1.value }
    }

    /// Total expired value this month (benefits that were not used)
    var expiredValueThisMonth: Decimal {
        cards.reduce(Decimal.zero) { total, card in
            total + card.benefits
                .filter { $0.status == .expired }
                .reduce(Decimal.zero) { $0 + $1.effectiveValue }
        }
    }

    /// Total available value this month (benefits still available)
    var availableValueThisMonth: Decimal {
        totalAvailableValue
    }

    /// Relative time text for last refresh (e.g., "Updated 2 min ago")
    var lastRefreshedText: String? {
        guard let lastRefreshed = lastRefreshed else { return nil }
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return "Updated \(formatter.localizedString(for: lastRefreshed, relativeTo: Date()))"
    }

    /// Current dashboard insight to display
    var currentInsight: DashboardInsight? {
        // Priority 1: Urgent expiring benefits (today)
        let todayCount = benefitsExpiringToday.count
        if todayCount > 0 {
            let todayValue = benefitsExpiringToday.reduce(Decimal.zero) { $0 + $1.value }
            return .urgentExpiring(value: todayValue, count: todayCount)
        }

        // Priority 2: High value available
        if totalAvailableValue > 100 {
            return .availableValue(value: totalAvailableValue)
        }

        // Priority 3: Monthly success (high redemption rate)
        if !isEmpty && usedBenefitsCount > totalBenefitsCount / 2 {
            return .monthlySuccess(value: redeemedThisMonth)
        }

        // Priority 4: Onboarding
        if isEmpty {
            return .onboarding
        }

        return nil
    }

    // MARK: - Initialization

    /// Initializes the view model with required repositories.
    /// - Parameters:
    ///   - cardRepository: Repository for card operations
    ///   - benefitRepository: Repository for benefit operations
    ///   - templateLoader: Loader for card and benefit templates
    init(
        cardRepository: CardRepositoryProtocol,
        benefitRepository: BenefitRepositoryProtocol,
        templateLoader: TemplateLoaderProtocol
    ) {
        self.cardRepository = cardRepository
        self.benefitRepository = benefitRepository
        self.templateLoader = templateLoader
    }

    /// Sets the recommendation service for lazy initialization
    func setRecommendationService(_ service: CardRecommendationServiceProtocol) {
        self.recommendationService = service
    }

    // MARK: - Actions

    /// Loads initial data (cards, expiring benefits, and templates).
    ///
    /// This method is called when the view appears for the first time.
    /// It loads all cards, benefits expiring within 7 days, and templates.
    func loadData() async {
        guard !isLoading else {
            print("⏭️  HomeViewModel: Already loading, skipping...")
            return
        }

        print("📊 HomeViewModel: Starting data load...")
        isLoading = true
        error = nil

        do {
            // Load templates first for display resolution
            print("  → Loading templates...")
            loadTemplates()

            // Load cards and expiring benefits in parallel
            print("  → Loading cards and benefits...")
            async let cardsTask: () = loadCards()
            async let benefitsTask: () = loadExpiringBenefits()

            try await cardsTask
            try await benefitsTask

            // Load recommendations after cards are loaded
            loadRecommendations()

            // Update last refreshed timestamp
            lastRefreshed = Date()

            print("✅ HomeViewModel: Data loaded successfully")
            print("  → Cards: \(cards.count)")
            print("  → Expiring benefits: \(expiringBenefits.count)")
            print("  → Recommendations: \(categoryRecommendations.count) categories")

        } catch {
            self.error = error
            print("❌ HomeViewModel: Failed to load data: \(error)")
        }

        isLoading = false
    }

    /// Loads templates into cache for display resolution
    private func loadTemplates() {
        do {
            print("  → Loading card templates from TemplateLoader...")
            let database = try templateLoader.loadAllTemplates()
            cardTemplates = Dictionary(uniqueKeysWithValues: database.cards.map { ($0.id, $0) })
            benefitTemplates = database.cards.flatMap { card in
                card.benefits.map { ($0.id, $0) }
            }.reduce(into: [:]) { $0[$1.0] = $1.1 }
            print("  ✅ Loaded \(cardTemplates.count) card templates, \(benefitTemplates.count) benefit templates")
        } catch {
            print("  ⚠️ Failed to load templates: \(error). App will continue with limited functionality.")
        }
    }

    /// Refreshes all data.
    ///
    /// This method is called when the user pulls to refresh.
    /// It reloads both cards and expiring benefits.
    func refresh() async {
        await loadData()
    }

    /// Deletes a card from the wallet.
    ///
    /// This method deletes the card and all associated benefits.
    /// After deletion, it reloads the data to update the UI.
    ///
    /// - Parameter card: The card to delete
    func deleteCard(_ card: UserCard) {
        // CRITICAL: Remove from in-memory state FIRST to prevent UI accessing deleted objects
        removeCardFromState(card.id)

        do {
            try cardRepository.deleteCard(card)

            // Reload data after deletion
            Task {
                await loadData()
            }

        } catch {
            self.error = error
            print("Failed to delete card: \(error)")
        }
    }

    /// Removes a card from in-memory state by ID (Pattern: Close-Before-Delete)
    /// Call this BEFORE deleting from repository to prevent UI crashes
    func removeCardFromState(_ cardId: UUID) {
        cards.removeAll { $0.id == cardId }
        expiringBenefits.removeAll { $0.userCard?.id == cardId }
    }

    // MARK: - Private Helpers

    /// Loads all cards from repository
    private func loadCards() async throws {
        cards = try cardRepository.getAllCards()
    }

    /// Loads benefits expiring within 7 days
    private func loadExpiringBenefits() async throws {
        expiringBenefits = try benefitRepository.getExpiringBenefits(within: 7)
    }

    /// Loads best card recommendations by category
    private func loadRecommendations() {
        guard let service = recommendationService else {
            print("  ⚠️ Recommendation service not available")
            return
        }

        do {
            categoryRecommendations = try service.findBestCardsForAllCategories()
        } catch {
            print("  ⚠️ Failed to load recommendations: \(error)")
        }
    }
}

// MARK: - Preview Support

extension HomeViewModel {

    /// Creates a preview instance with mock data
    static var preview: HomeViewModel {
        let mockCardRepo = HomeViewMockCardRepository()
        let mockBenefitRepo = HomeViewMockBenefitRepository()
        let mockTemplateLoader = HomeViewMockTemplateLoader()
        let viewModel = HomeViewModel(
            cardRepository: mockCardRepo,
            benefitRepository: mockBenefitRepo,
            templateLoader: mockTemplateLoader
        )
        Task { @MainActor in
            await viewModel.loadData()
        }
        return viewModel
    }
}

// MARK: - Mock Template Loader for Preview

@MainActor
private final class HomeViewMockTemplateLoader: TemplateLoaderProtocol {
    func loadAllTemplates() throws -> CardDatabase {
        CardDatabase(schemaVersion: 1, dataVersion: "1.0", lastUpdated: Date(), cards: [])
    }

    func getTemplate(by id: UUID) throws -> CardTemplate? { nil }
    func getBenefitTemplate(by id: UUID) throws -> BenefitTemplate? { nil }
    func searchTemplates(query: String) throws -> [CardTemplate] { [] }
    func getActiveTemplates() throws -> [CardTemplate] { [] }
    func getTemplatesByIssuer() throws -> [String: [CardTemplate]] { [:] }
}

// MARK: - Mock Repositories for Preview

/// Mock card repository for SwiftUI previews
@MainActor
private final class HomeViewMockCardRepository: CardRepositoryProtocol {

    private var mockCards: [UserCard] = []

    init() {
        setupMockData()
    }

    func getAllCards() throws -> [UserCard] {
        mockCards
    }

    func getCard(by id: UUID) throws -> UserCard? {
        mockCards.first { $0.id == id }
    }

    func addCard(from template: CardTemplate, nickname: String?) throws -> UserCard {
        fatalError("Not implemented in mock")
    }

    func deleteCard(_ card: UserCard) throws {
        mockCards.removeAll { $0.id == card.id }
    }

    func updateCard(_ card: UserCard) throws {
        // No-op for mock
    }

    private func setupMockData() {
        // Create mock card 1
        let card1 = UserCard(
            cardTemplateId: UUID(uuidString: "550e8400-e29b-41d4-a716-446655440001"),
            nickname: "Personal",
            isCustom: false,
            sortOrder: 0
        )

        // Create mock card 2
        let card2 = UserCard(
            cardTemplateId: UUID(uuidString: "550e8400-e29b-41d4-a716-446655440002"),
            nickname: "Business",
            isCustom: false,
            sortOrder: 1
        )

        // Add benefits to card 1
        let calendar = Calendar.current
        let now = Date()
        let periodStart = calendar.date(from: calendar.dateComponents([.year, .month], from: now))!
        let periodEnd = calendar.date(byAdding: DateComponents(month: 1, day: -1), to: periodStart)!

        let benefit1 = Benefit(
            userCard: card1,
            templateBenefitId: UUID(uuidString: "550e8400-e29b-41d4-a716-446655440101"),
            customName: "Uber Credits",
            customValue: 15,
            status: .available,
            currentPeriodStart: periodStart,
            currentPeriodEnd: periodEnd
        )

        let benefit2 = Benefit(
            userCard: card1,
            templateBenefitId: UUID(uuidString: "550e8400-e29b-41d4-a716-446655440102"),
            customName: "Dining Credit",
            customValue: 10,
            status: .used,
            currentPeriodStart: periodStart,
            currentPeriodEnd: periodEnd
        )

        // Add benefits to card 2
        let benefit3 = Benefit(
            userCard: card2,
            templateBenefitId: UUID(uuidString: "550e8400-e29b-41d4-a716-446655440201"),
            customName: "Travel Credit",
            customValue: 300,
            status: .available,
            currentPeriodStart: periodStart,
            currentPeriodEnd: periodEnd
        )

        card1.benefits = [benefit1, benefit2]
        card2.benefits = [benefit3]

        mockCards = [card1, card2]
    }
}

/// Mock benefit repository for SwiftUI previews
@MainActor
private final class HomeViewMockBenefitRepository: BenefitRepositoryProtocol {

    private var mockBenefits: [Benefit] = []

    init() {
        setupMockData()
    }

    func getBenefits(for card: UserCard) throws -> [Benefit] {
        mockBenefits.filter { $0.userCard?.id == card.id }
    }

    func getAllBenefits() throws -> [Benefit] {
        mockBenefits
    }

    func getAvailableBenefits() throws -> [Benefit] {
        mockBenefits.filter { $0.status == .available }
    }

    func getExpiringBenefits(within days: Int) throws -> [Benefit] {
        let threshold = Calendar.current.date(
            byAdding: .day,
            value: days,
            to: Date()
        ) ?? Date()

        return mockBenefits.filter { benefit in
            benefit.status == .available &&
            benefit.currentPeriodEnd <= threshold
        }
    }

    func markBenefitUsed(_ benefit: Benefit) throws {
        benefit.markAsUsed()
    }

    func resetBenefitForNewPeriod(_ benefit: Benefit) throws {
        // No-op for mock
    }

    func snoozeBenefit(_ benefit: Benefit, until date: Date) throws {
        // No-op for mock
    }

    func undoMarkBenefitUsed(_ benefit: Benefit) throws {
        benefit.status = .available
    }

    private func setupMockData() {
        let calendar = Calendar.current
        let now = Date()
        let periodStart = calendar.date(from: calendar.dateComponents([.year, .month], from: now))!

        // Benefit expiring in 5 days
        let expiringDate1 = calendar.date(byAdding: .day, value: 5, to: now)!
        let benefit1 = Benefit(
            templateBenefitId: UUID(uuidString: "550e8400-e29b-41d4-a716-446655440101"),
            customName: "Uber Credits",
            customValue: 15,
            status: .available,
            currentPeriodStart: periodStart,
            currentPeriodEnd: expiringDate1
        )

        // Benefit expiring in 2 days
        let expiringDate2 = calendar.date(byAdding: .day, value: 2, to: now)!
        let benefit2 = Benefit(
            templateBenefitId: UUID(uuidString: "550e8400-e29b-41d4-a716-446655440102"),
            customName: "Dining Credit",
            customValue: 10,
            status: .available,
            currentPeriodStart: periodStart,
            currentPeriodEnd: expiringDate2
        )

        mockBenefits = [benefit1, benefit2]
    }
}
