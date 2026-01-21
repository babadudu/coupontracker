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
    private let notificationService: NotificationService
    private var recommendationService: CardRecommendationServiceProtocol?
    private let insightResolver = DashboardInsightResolver()

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

    /// Total value redeemed for a specific period (queries historical BenefitUsage records)
    func redeemedValue(for period: BenefitPeriod) -> Decimal {
        do {
            return try benefitRepository.getRedeemedValue(for: period, referenceDate: Date())
        } catch {
            // Fallback to current status-based calculation
            return PeriodMetrics.calculate(for: allBenefits, period: period).redeemedValue
        }
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
        insightResolver.resolve(
            benefitsExpiringToday: benefitsExpiringToday,
            totalAvailableValue: totalAvailableValue,
            usedCount: usedBenefitsCount,
            totalCount: totalBenefitsCount,
            redeemedThisMonth: redeemedThisMonth
        )
    }

    // MARK: - Initialization

    /// Initializes the view model with required repositories.
    /// - Parameters:
    ///   - cardRepository: Repository for card operations
    ///   - benefitRepository: Repository for benefit operations
    ///   - templateLoader: Loader for card and benefit templates
    ///   - notificationService: Service for managing benefit reminders
    init(
        cardRepository: CardRepositoryProtocol,
        benefitRepository: BenefitRepositoryProtocol,
        templateLoader: TemplateLoaderProtocol,
        notificationService: NotificationService
    ) {
        self.cardRepository = cardRepository
        self.benefitRepository = benefitRepository
        self.templateLoader = templateLoader
        self.notificationService = notificationService
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

        // Cancel notifications for all benefits on this card
        notificationService.cancelNotifications(
            forCardId: card.id,
            benefits: Array(card.benefits)
        )

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

#if DEBUG
extension HomeViewModel {

    /// Creates a preview instance with mock data
    @MainActor
    static var preview: HomeViewModel {
        let mockCardRepo = MockCardRepository()
        mockCardRepo.cards = MockDataFactory.makeWallet()

        let mockBenefitRepo = MockBenefitRepository()
        mockBenefitRepo.benefits = mockCardRepo.cards.flatMap { $0.benefits }

        let mockTemplateLoader = MockTemplateLoader()
        let container = AppContainer.preview

        let viewModel = HomeViewModel(
            cardRepository: mockCardRepo,
            benefitRepository: mockBenefitRepo,
            templateLoader: mockTemplateLoader,
            notificationService: container.notificationService
        )
        Task { @MainActor in
            await viewModel.loadData()
        }
        return viewModel
    }
}
#endif
