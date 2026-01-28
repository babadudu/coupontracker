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
import os

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

    /// Total value redeemed for a specific period.
    /// Queries historical BenefitUsage records for ALL benefits used within the period,
    /// regardless of benefit frequency. An annual benefit used in March counts toward March's total.
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

    /// Monthly metrics for dashboard (only monthly-frequency benefits)
    var monthlyMetrics: PeriodMetrics {
        let monthlyBenefits = allBenefits.filter { $0.frequency == .monthly }
        return PeriodMetrics.calculate(for: monthlyBenefits, period: .monthly, applyMultiplier: false)
    }

    /// Returns metrics for a given period using cumulative roll-up.
    /// - Monthly: only monthly-frequency benefits
    /// - Quarterly: monthly + quarterly benefits
    /// - Annual: all frequency benefits
    /// - Parameter period: The benefit period to calculate metrics for
    /// - Returns: PeriodMetrics with redeemed/available values and counts
    func metrics(for period: BenefitPeriod) -> PeriodMetrics {
        let includedFrequencies = period.includedFrequencies
        let filteredBenefits = allBenefits.filter { includedFrequencies.contains($0.frequency) }
        return PeriodMetrics.calculate(for: filteredBenefits, period: period, applyMultiplier: false)
    }

    /// Historical redeemed value for monthly-frequency benefits only
    var monthlyRedeemedValue: Decimal {
        do {
            return try benefitRepository.getRedeemedValue(for: .monthly, frequency: .monthly, referenceDate: Date())
        } catch {
            return monthlyMetrics.redeemedValue
        }
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

    // MARK: - Category Drill-Down Support

    /// Returns all available benefits for a given category, grouped by card.
    /// Used by CategoryBenefitsView for drill-down from ValueBreakdownView.
    ///
    /// - Parameter category: The benefit category to filter by
    /// - Returns: Array of (card, benefits) tuples sorted by total value descending
    func benefitsForCategory(_ category: BenefitCategory) -> [(card: CardDisplayAdapter, benefits: [BenefitDisplayAdapter])] {
        var result: [(card: CardDisplayAdapter, benefits: [BenefitDisplayAdapter])] = []

        for card in displayCards {
            let categoryBenefits = card.benefits.filter { benefit in
                benefit.category == category && benefit.status == .available
            }
            if !categoryBenefits.isEmpty {
                result.append((card: card, benefits: categoryBenefits))
            }
        }

        // Sort by total value descending
        return result.sorted { lhs, rhs in
            let lhsValue = lhs.benefits.reduce(Decimal.zero) { $0 + $1.value }
            let rhsValue = rhs.benefits.reduce(Decimal.zero) { $0 + $1.value }
            return lhsValue > rhsValue
        }
    }

    /// Returns used benefits for a given category, grouped by card.
    /// Used by CategoryBenefitsView for the "Used This Period" section.
    ///
    /// - Parameter category: The benefit category to filter by
    /// - Returns: Array of (card, benefits) tuples
    func usedBenefitsForCategory(_ category: BenefitCategory) -> [(card: CardDisplayAdapter, benefits: [BenefitDisplayAdapter])] {
        var result: [(card: CardDisplayAdapter, benefits: [BenefitDisplayAdapter])] = []

        for card in displayCards {
            let usedBenefits = card.benefits.filter { benefit in
                benefit.category == category && benefit.status == .used
            }
            if !usedBenefits.isEmpty {
                result.append((card: card, benefits: usedBenefits))
            }
        }

        return result
    }

    /// Returns total value for a category (available benefits only)
    func totalValueForCategory(_ category: BenefitCategory) -> Decimal {
        benefitsByCategory[category] ?? .zero
    }

    /// Returns count of available benefits for a category
    func benefitCountForCategory(_ category: BenefitCategory) -> Int {
        displayCards.flatMap { $0.benefits }
            .filter { $0.category == category && $0.status == .available }
            .count
    }

    // MARK: - Period Drill-Down Support

    /// Returns all available benefits within a time period, grouped by urgency.
    /// Used by PeriodBenefitsView for drill-down from ValueBreakdownView.
    ///
    /// - Parameter period: The time period filter (thisWeek, thisMonth, later)
    /// - Returns: Array of (urgency, benefits with card info) tuples sorted by urgency
    func benefitsForPeriod(_ period: TimePeriodFilter) -> [(urgency: ExpirationUrgency, items: [ExpiringBenefitDisplayAdapter])] {
        // Filter benefits within the period
        let periodBenefits = displayExpiringBenefitsAll.filter { item in
            period.contains(daysRemaining: item.benefit.daysRemaining)
        }

        // Group by urgency
        var grouped: [ExpirationUrgency: [ExpiringBenefitDisplayAdapter]] = [:]
        for item in periodBenefits {
            let urgency = ExpirationUrgency.from(daysRemaining: item.benefit.daysRemaining)
            grouped[urgency, default: []].append(item)
        }

        // Sort each group by expiration date (soonest first)
        for (urgency, items) in grouped {
            grouped[urgency] = items.sorted { $0.benefit.daysRemaining < $1.benefit.daysRemaining }
        }

        // Return as array sorted by urgency order
        let urgencyOrder: [ExpirationUrgency] = [.expiringToday, .within1Day, .within3Days, .within1Week, .later]
        return urgencyOrder.compactMap { urgency in
            guard let items = grouped[urgency], !items.isEmpty else { return nil }
            return (urgency: urgency, items: items)
        }
    }

    /// All expiring benefits as display adapters (not limited to 7 days)
    var displayExpiringBenefitsAll: [ExpiringBenefitDisplayAdapter] {
        cards.flatMap { card -> [ExpiringBenefitDisplayAdapter] in
            let cardTemplate = card.cardTemplateId.flatMap { cardTemplates[$0] }
            let cardAdapter = CardDisplayAdapter(
                card: card,
                cardTemplate: cardTemplate,
                benefitTemplates: benefitTemplates
            )

            return card.benefits
                .filter { $0.status == .available }
                .map { benefit in
                    let benefitTemplate = benefit.templateBenefitId.flatMap { benefitTemplates[$0] }
                    let benefitAdapter = BenefitDisplayAdapter(
                        benefit: benefit,
                        template: benefitTemplate
                    )
                    return ExpiringBenefitDisplayAdapter(benefit: benefitAdapter, card: cardAdapter)
                }
        }
    }

    /// Returns total value for a time period
    func totalValueForPeriod(_ period: TimePeriodFilter) -> Decimal {
        displayExpiringBenefitsAll
            .filter { period.contains(daysRemaining: $0.benefit.daysRemaining) }
            .reduce(Decimal.zero) { $0 + $1.benefit.value }
    }

    /// Returns count of benefits for a time period
    func benefitCountForPeriod(_ period: TimePeriodFilter) -> Int {
        displayExpiringBenefitsAll
            .filter { period.contains(daysRemaining: $0.benefit.daysRemaining) }
            .count
    }

    /// Returns count of cards with benefits in a time period
    func cardCountForPeriod(_ period: TimePeriodFilter) -> Int {
        Set(
            displayExpiringBenefitsAll
                .filter { period.contains(daysRemaining: $0.benefit.daysRemaining) }
                .map { $0.card.id }
        ).count
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
            return
        }

        isLoading = true
        error = nil

        do {
            // Load templates first for display resolution
            loadTemplates()

            // Load cards and expiring benefits in parallel
            async let cardsTask: () = loadCards()
            async let benefitsTask: () = loadExpiringBenefits()

            try await cardsTask
            try await benefitsTask

            // Load recommendations after cards are loaded
            loadRecommendations()

            // Update last refreshed timestamp
            lastRefreshed = Date()

        } catch {
            self.error = error
            AppLogger.data.error("Failed to load home data: \(error.localizedDescription)")
        }

        isLoading = false
    }

    /// Loads templates into cache for display resolution
    private func loadTemplates() {
        do {
            let database = try templateLoader.loadAllTemplates()
            cardTemplates = Dictionary(uniqueKeysWithValues: database.cards.map { ($0.id, $0) })
            benefitTemplates = database.cards.flatMap { card in
                card.benefits.map { ($0.id, $0) }
            }.reduce(into: [:]) { $0[$1.0] = $1.1 }
        } catch {
            // Templates failed to load - app will continue with limited functionality
            AppLogger.templates.error("Failed to load templates: \(error.localizedDescription)")
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
            AppLogger.cards.error("Failed to delete card: \(error.localizedDescription)")
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
            return
        }

        do {
            categoryRecommendations = try service.findBestCardsForAllCategories()
        } catch {
            // Failed to load recommendations
            AppLogger.data.error("Failed to load recommendations: \(error.localizedDescription)")
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
