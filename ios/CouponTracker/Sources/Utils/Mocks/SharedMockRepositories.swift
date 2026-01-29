//
//  SharedMockRepositories.swift
//  CouponTracker
//
//  Created: January 2026
//  Purpose: Shared mock implementations for protocols used in SwiftUI previews and tests.
//           Consolidates duplicate mock code from ViewModels into reusable classes.
//

import Foundation

#if DEBUG

// MARK: - Mock Error

/// Standard error for mock failure testing
enum MockError: LocalizedError {
    case operationFailed
    case notFound

    var errorDescription: String? {
        switch self {
        case .operationFailed:
            return "The operation failed"
        case .notFound:
            return "The requested item was not found"
        }
    }
}

// MARK: - Mock Card Repository

/// Reusable mock card repository for SwiftUI previews and unit tests.
/// Configurable to simulate success or failure scenarios.
@MainActor
final class MockCardRepository: CardRepositoryProtocol {
    var cards: [UserCard] = []
    var shouldThrowError = false

    func getAllCards() throws -> [UserCard] {
        if shouldThrowError { throw MockError.operationFailed }
        return cards
    }

    func getCard(by id: UUID) throws -> UserCard? {
        if shouldThrowError { throw MockError.operationFailed }
        return cards.first { $0.id == id }
    }

    func addCard(from template: CardTemplate, nickname: String?) throws -> UserCard {
        if shouldThrowError { throw MockError.operationFailed }
        let card = UserCard(
            cardTemplateId: template.id,
            nickname: nickname,
            isCustom: false,
            sortOrder: cards.count
        )
        cards.append(card)
        return card
    }

    func deleteCard(_ card: UserCard) throws {
        if shouldThrowError { throw MockError.operationFailed }
        cards.removeAll { $0.id == card.id }
    }

    func updateCard(_ card: UserCard) throws {
        if shouldThrowError { throw MockError.operationFailed }
        // In a real implementation, this would persist changes
    }
}

// MARK: - Mock Benefit Repository

/// Reusable mock benefit repository for SwiftUI previews and unit tests.
/// Configurable to simulate success or failure scenarios.
@MainActor
final class MockBenefitRepository: BenefitRepositoryProtocol {
    var benefits: [Benefit] = []
    var shouldThrowError = false

    func getBenefit(by id: UUID) throws -> Benefit? {
        if shouldThrowError { throw MockError.operationFailed }
        return benefits.first { $0.id == id }
    }

    func getBenefits(for card: UserCard) throws -> [Benefit] {
        if shouldThrowError { throw MockError.operationFailed }
        return benefits.filter { $0.userCard?.id == card.id }
    }

    func getAllBenefits() throws -> [Benefit] {
        if shouldThrowError { throw MockError.operationFailed }
        return benefits
    }

    func getAvailableBenefits() throws -> [Benefit] {
        if shouldThrowError { throw MockError.operationFailed }
        return benefits.filter { $0.status == .available }
    }

    func getExpiringBenefits(within days: Int) throws -> [Benefit] {
        if shouldThrowError { throw MockError.operationFailed }
        let threshold = Calendar.current.date(
            byAdding: .day,
            value: days,
            to: Date()
        ) ?? Date()

        return benefits.filter { benefit in
            benefit.status == .available &&
            benefit.currentPeriodEnd <= threshold
        }
    }

    func markBenefitUsed(_ benefit: Benefit) throws {
        if shouldThrowError { throw MockError.operationFailed }
        benefit.markAsUsed()
    }

    func resetBenefitForNewPeriod(_ benefit: Benefit) throws {
        if shouldThrowError { throw MockError.operationFailed }
        let frequency = benefit.customFrequency ?? .monthly
        let dates = frequency.calculatePeriodDates()
        benefit.resetToNewPeriod(
            periodStart: dates.start,
            periodEnd: dates.end,
            nextReset: dates.nextReset
        )
    }

    func snoozeBenefit(_ benefit: Benefit, until date: Date) throws {
        if shouldThrowError { throw MockError.operationFailed }
        benefit.lastReminderDate = date
        benefit.updatedAt = Date()
    }

    func undoMarkBenefitUsed(_ benefit: Benefit) throws {
        if shouldThrowError { throw MockError.operationFailed }
        benefit.undoMarkAsUsed()
    }

    func getRedeemedValue(for period: BenefitPeriod, referenceDate: Date) throws -> Decimal {
        if shouldThrowError { throw MockError.operationFailed }
        return benefits
            .filter { $0.status == .used }
            .reduce(Decimal.zero) { $0 + $1.effectiveValue }
    }

    func getRedeemedValue(for period: BenefitPeriod, frequency: BenefitFrequency, referenceDate: Date) throws -> Decimal {
        if shouldThrowError { throw MockError.operationFailed }
        return benefits
            .filter { $0.status == .used && $0.frequency == frequency }
            .reduce(Decimal.zero) { $0 + $1.effectiveValue }
    }
}

// MARK: - Mock Template Loader

/// Reusable mock template loader for SwiftUI previews and unit tests.
/// Configurable with custom template data.
@MainActor
final class MockTemplateLoader: TemplateLoaderProtocol {
    var templates: [CardTemplate]
    var shouldThrowError = false

    init(templates: [CardTemplate] = []) {
        self.templates = templates
    }

    func loadAllTemplates() throws -> CardDatabase {
        if shouldThrowError { throw MockError.operationFailed }
        return CardDatabase(
            schemaVersion: 1,
            dataVersion: "1.0",
            lastUpdated: Date(),
            cards: templates
        )
    }

    func getTemplate(by id: UUID) throws -> CardTemplate? {
        if shouldThrowError { throw MockError.operationFailed }
        return templates.first { $0.id == id }
    }

    func getBenefitTemplate(by id: UUID) throws -> BenefitTemplate? {
        if shouldThrowError { throw MockError.operationFailed }
        return templates.flatMap { $0.benefits }.first { $0.id == id }
    }

    func searchTemplates(query: String) throws -> [CardTemplate] {
        if shouldThrowError { throw MockError.operationFailed }
        guard !query.isEmpty else { return templates }
        let lowercasedQuery = query.lowercased()
        return templates.filter { template in
            template.name.lowercased().contains(lowercasedQuery) ||
            template.issuer.lowercased().contains(lowercasedQuery)
        }
    }

    func getActiveTemplates() throws -> [CardTemplate] {
        if shouldThrowError { throw MockError.operationFailed }
        return templates
    }

    func getTemplatesByIssuer() throws -> [String: [CardTemplate]] {
        if shouldThrowError { throw MockError.operationFailed }
        return Dictionary(grouping: templates, by: { $0.issuer })
    }
}

// MARK: - Mock Subscription Repository

/// Reusable mock subscription repository for SwiftUI previews and unit tests.
@MainActor
final class MockSubscriptionRepository: SubscriptionRepositoryProtocol {
    var subscriptions: [Subscription] = []
    var shouldThrowError = false

    func getAllSubscriptions() throws -> [Subscription] {
        if shouldThrowError { throw MockError.operationFailed }
        return subscriptions.sorted { $0.nextRenewalDate < $1.nextRenewalDate }
    }

    func getSubscription(by id: UUID) throws -> Subscription? {
        if shouldThrowError { throw MockError.operationFailed }
        return subscriptions.first { $0.id == id }
    }

    func getActiveSubscriptions() throws -> [Subscription] {
        if shouldThrowError { throw MockError.operationFailed }
        return subscriptions.filter { $0.isActive }
    }

    func getSubscriptions(for cardId: UUID) throws -> [Subscription] {
        if shouldThrowError { throw MockError.operationFailed }
        return subscriptions.filter { $0.userCard?.id == cardId }
    }

    func getSubscriptionsRenewingSoon(within days: Int) throws -> [Subscription] {
        if shouldThrowError { throw MockError.operationFailed }
        return subscriptions.filter { $0.daysUntilRenewal <= days && $0.isActive }
    }

    func addSubscription(_ subscription: Subscription) throws {
        if shouldThrowError { throw MockError.operationFailed }
        subscriptions.append(subscription)
    }

    func updateSubscription(_ subscription: Subscription) throws {
        if shouldThrowError { throw MockError.operationFailed }
        subscription.markAsUpdated()
    }

    func deleteSubscription(_ subscription: Subscription) throws {
        if shouldThrowError { throw MockError.operationFailed }
        subscriptions.removeAll { $0.id == subscription.id }
    }
}

// MARK: - Mock Coupon Repository

/// Reusable mock coupon repository for SwiftUI previews and unit tests.
@MainActor
final class MockCouponRepository: CouponRepositoryProtocol {
    var coupons: [Coupon] = []
    var shouldThrowError = false

    func getAllCoupons() throws -> [Coupon] {
        if shouldThrowError { throw MockError.operationFailed }
        return coupons.sorted { $0.expirationDate < $1.expirationDate }
    }

    func getCoupon(by id: UUID) throws -> Coupon? {
        if shouldThrowError { throw MockError.operationFailed }
        return coupons.first { $0.id == id }
    }

    func getValidCoupons() throws -> [Coupon] {
        if shouldThrowError { throw MockError.operationFailed }
        return coupons.filter { $0.isValid }
    }

    func getCouponsExpiringSoon(within days: Int) throws -> [Coupon] {
        if shouldThrowError { throw MockError.operationFailed }
        return coupons.filter { $0.daysUntilExpiration <= days && $0.isValid }
    }

    func getCoupons(by category: CouponCategory) throws -> [Coupon] {
        if shouldThrowError { throw MockError.operationFailed }
        return coupons.filter { $0.category == category }
    }

    func addCoupon(_ coupon: Coupon) throws {
        if shouldThrowError { throw MockError.operationFailed }
        coupons.append(coupon)
    }

    func updateCoupon(_ coupon: Coupon) throws {
        if shouldThrowError { throw MockError.operationFailed }
        coupon.markAsUpdated()
    }

    func deleteCoupon(_ coupon: Coupon) throws {
        if shouldThrowError { throw MockError.operationFailed }
        coupons.removeAll { $0.id == coupon.id }
    }
}

// MARK: - Mock Data Factory

/// Factory for creating common mock data scenarios
enum MockDataFactory {

    /// Creates a mock card with benefits for testing
    /// - Parameters:
    ///   - nickname: Optional nickname for the card
    ///   - benefitCount: Number of mock benefits to create
    /// - Returns: A configured UserCard with benefits
    @MainActor
    static func makeCard(
        nickname: String? = nil,
        benefitCount: Int = 3
    ) -> UserCard {
        let card = UserCard(
            cardTemplateId: UUID(),
            nickname: nickname,
            isCustom: false,
            sortOrder: 0
        )

        let calendar = Calendar.current
        let today = Date()
        let periodStart = calendar.startOfDay(for: today)
        _ = calendar.date(byAdding: .month, value: 1, to: periodStart) ?? today

        var benefits: [Benefit] = []
        for i in 0..<benefitCount {
            let expirationDays = [3, 15, 30][i % 3]
            let expDate = calendar.date(byAdding: .day, value: expirationDays, to: today) ?? today

            let benefit = Benefit(
                userCard: card,
                customName: "Benefit \(i + 1)",
                customValue: Decimal(10 * (i + 1)),
                status: .available,
                currentPeriodStart: periodStart,
                currentPeriodEnd: expDate
            )
            benefits.append(benefit)
        }

        card.benefits = benefits
        return card
    }

    /// Creates a set of mock cards simulating a real wallet
    @MainActor
    static func makeWallet() -> [UserCard] {
        let calendar = Calendar.current
        let today = Date()
        let periodStart = calendar.date(from: calendar.dateComponents([.year, .month], from: today)) ?? today
        let periodEnd = calendar.date(byAdding: DateComponents(month: 1, day: -1), to: periodStart) ?? today

        // Card 1 - Multiple benefits
        let card1 = UserCard(
            cardTemplateId: UUID(),
            nickname: "Personal",
            isCustom: false,
            sortOrder: 0
        )

        let benefit1 = Benefit(
            userCard: card1,
            customName: "Uber Credits",
            customValue: 15,
            status: .available,
            currentPeriodStart: periodStart,
            currentPeriodEnd: periodEnd
        )

        let benefit2 = Benefit(
            userCard: card1,
            customName: "Dining Credit",
            customValue: 10,
            status: .used,
            currentPeriodStart: periodStart,
            currentPeriodEnd: periodEnd
        )

        card1.benefits = [benefit1, benefit2]

        // Card 2 - High value benefit
        let card2 = UserCard(
            cardTemplateId: UUID(),
            nickname: "Business",
            isCustom: false,
            sortOrder: 1
        )

        let benefit3 = Benefit(
            userCard: card2,
            customName: "Travel Credit",
            customValue: 300,
            status: .available,
            currentPeriodStart: periodStart,
            currentPeriodEnd: periodEnd
        )

        card2.benefits = [benefit3]

        return [card1, card2]
    }
}

// MARK: - Mock Subscription Factory

/// Factory for creating mock subscription data
enum MockSubscriptionFactory {

    @MainActor
    static func makeSampleSubscriptions() -> [Subscription] {
        let calendar = Calendar.current
        let today = Date()

        // Netflix - renewing in 5 days
        let netflix = Subscription(
            name: "Netflix",
            price: 15.99,
            frequency: .monthly,
            category: .streaming,
            startDate: calendar.date(byAdding: .month, value: -6, to: today) ?? today,
            nextRenewalDate: calendar.date(byAdding: .day, value: 5, to: today) ?? today,
            isActive: true,
            iconName: "play.tv.fill"
        )

        // Spotify - renewing in 12 days
        let spotify = Subscription(
            name: "Spotify",
            price: 10.99,
            frequency: .monthly,
            category: .streaming,
            startDate: calendar.date(byAdding: .month, value: -3, to: today) ?? today,
            nextRenewalDate: calendar.date(byAdding: .day, value: 12, to: today) ?? today,
            isActive: true,
            iconName: "music.note"
        )

        // Adobe CC - annual, canceled
        let adobe = Subscription(
            name: "Adobe Creative Cloud",
            price: 599.88,
            frequency: .annual,
            category: .software,
            startDate: calendar.date(byAdding: .year, value: -1, to: today) ?? today,
            nextRenewalDate: calendar.date(byAdding: .month, value: 2, to: today) ?? today,
            isActive: false,
            iconName: "paintbrush.fill"
        )

        // Gym - past due
        let gym = Subscription(
            name: "Planet Fitness",
            price: 24.99,
            frequency: .monthly,
            category: .fitness,
            startDate: calendar.date(byAdding: .month, value: -12, to: today) ?? today,
            nextRenewalDate: calendar.date(byAdding: .day, value: -2, to: today) ?? today,
            isActive: true,
            iconName: "figure.run"
        )

        return [netflix, spotify, adobe, gym]
    }
}

// MARK: - Mock Coupon Factory

/// Factory for creating mock coupon data
enum MockCouponFactory {

    @MainActor
    static func makeSampleCoupons() -> [Coupon] {
        let calendar = Calendar.current
        let today = Date()

        // Target - expiring in 2 days
        let target = Coupon(
            name: "Target 20% Off",
            couponDescription: "20% off any single item",
            expirationDate: calendar.date(byAdding: .day, value: 2, to: today) ?? today,
            category: .shopping,
            value: nil,
            merchant: "Target",
            code: "TARGET20",
            reminderEnabled: true
        )

        // Restaurant - expiring in 10 days
        let restaurant = Coupon(
            name: "$10 Off Dinner",
            couponDescription: "Valid for orders over $40",
            expirationDate: calendar.date(byAdding: .day, value: 10, to: today) ?? today,
            category: .dining,
            value: 10,
            merchant: "Olive Garden",
            code: nil,
            reminderEnabled: true
        )

        // Amazon - used
        let amazon = Coupon(
            name: "Amazon $5 Credit",
            expirationDate: calendar.date(byAdding: .day, value: 30, to: today) ?? today,
            category: .shopping,
            value: 5,
            merchant: "Amazon",
            code: "AMZN5OFF",
            isUsed: true,
            usedDate: calendar.date(byAdding: .day, value: -3, to: today)
        )

        // Movie - expired
        let movie = Coupon(
            name: "Free Popcorn",
            expirationDate: calendar.date(byAdding: .day, value: -5, to: today) ?? today,
            category: .entertainment,
            value: nil,
            merchant: "AMC Theaters",
            code: "POPCORN2026"
        )

        return [target, restaurant, amazon, movie]
    }
}

#endif
