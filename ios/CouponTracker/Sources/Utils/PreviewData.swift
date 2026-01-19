// PreviewData.swift
// CouponTracker
//
// Created: January 2026
// Purpose: Mock data and preview helpers for SwiftUI Preview providers.
//          This file enables rapid UI iteration without requiring actual data.
//
// USAGE:
// - Import this file's types in your view previews
// - Use PreviewData.sampleCards, PreviewData.sampleBenefits, etc.
// - All data is static and deterministic for consistent previews

import SwiftUI
import Foundation

// NOTE: BenefitStatus, BenefitFrequency, BenefitCategory are defined in
// Models/Enums/BenefitEnums.swift - imported automatically within module

// MARK: - Preview Benefit Model
/// Lightweight benefit model for UI previews - conforms to BenefitDisplayable (ADR-001)
struct PreviewBenefit: BenefitDisplayable {
    let id: UUID
    let name: String
    let benefitDescription: String
    let value: Decimal
    let frequency: BenefitFrequency
    let category: BenefitCategory
    let status: BenefitStatus
    let expirationDate: Date
    let usedDate: Date?
    let merchant: String?

    init(
        id: UUID = UUID(),
        name: String,
        description: String = "",
        value: Decimal,
        frequency: BenefitFrequency,
        category: BenefitCategory,
        status: BenefitStatus = .available,
        expirationDate: Date,
        usedDate: Date? = nil,
        merchant: String? = nil
    ) {
        self.id = id
        self.name = name
        self.benefitDescription = description
        self.value = value
        self.frequency = frequency
        self.category = category
        self.status = status
        self.expirationDate = expirationDate
        self.usedDate = usedDate
        self.merchant = merchant
    }

    // Legacy accessor for backwards compatibility
    var description: String { benefitDescription }
}

// MARK: - Preview Card Model
/// Lightweight card model for UI previews - conforms to CardDisplayable (ADR-001)
struct PreviewCard: CardDisplayable {
    typealias BenefitType = PreviewBenefit

    let id: UUID
    let name: String
    let issuer: String
    let nickname: String?
    let annualFee: Decimal
    let gradient: DesignSystem.CardGradient
    var benefits: [PreviewBenefit]
    let isCustom: Bool

    /// Number of urgent benefits (3 days or less)
    var urgentBenefitsCount: Int {
        benefits.filter { $0.isUrgent && $0.status == .available }.count
    }

    init(
        id: UUID = UUID(),
        name: String,
        issuer: String,
        nickname: String? = nil,
        annualFee: Decimal = 0,
        gradient: DesignSystem.CardGradient = .obsidian,
        benefits: [PreviewBenefit] = [],
        isCustom: Bool = false
    ) {
        self.id = id
        self.name = name
        self.issuer = issuer
        self.nickname = nickname
        self.annualFee = annualFee
        self.gradient = gradient
        self.benefits = benefits
        self.isCustom = isCustom
    }
}

// MARK: - Preview Card Template
/// Template for card selection in onboarding
struct PreviewCardTemplate: Identifiable, Hashable {
    let id: UUID
    let name: String
    let issuer: String
    let annualFee: Decimal
    let gradient: DesignSystem.CardGradient
    let benefitCount: Int
    let totalAnnualValue: Decimal

    var formattedAnnualFee: String {
        "$\(annualFee)"
    }

    var formattedAnnualValue: String {
        "$\(totalAnnualValue)"
    }
}

// MARK: - Preview Data Namespace
/// Static preview data for SwiftUI previews
enum PreviewData {

    // MARK: - Date Helpers
    /// Today's date for consistent previews
    static let today = Date()

    /// End of current month
    static var endOfMonth: Date {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month], from: today)
        let startOfMonth = calendar.date(from: components)!
        return calendar.date(byAdding: DateComponents(month: 1, day: -1), to: startOfMonth)!
    }

    /// End of current quarter
    static var endOfQuarter: Date {
        let calendar = Calendar.current
        let month = calendar.component(.month, from: today)
        let quarterEndMonth = ((month - 1) / 3 + 1) * 3
        var components = calendar.dateComponents([.year], from: today)
        components.month = quarterEndMonth
        components.day = 1
        let quarterStart = calendar.date(from: components)!
        return calendar.date(byAdding: DateComponents(month: 1, day: -1), to: quarterStart)!
    }

    /// End of current year
    static var endOfYear: Date {
        let calendar = Calendar.current
        var components = calendar.dateComponents([.year], from: today)
        components.month = 12
        components.day = 31
        return calendar.date(from: components)!
    }

    /// Date in N days from today
    static func daysFromNow(_ days: Int) -> Date {
        Calendar.current.date(byAdding: .day, value: days, to: today) ?? today
    }

    /// Date N days ago
    static func daysAgo(_ days: Int) -> Date {
        Calendar.current.date(byAdding: .day, value: -days, to: today) ?? today
    }

    // MARK: - Sample Benefits

    /// Uber credit benefit (monthly, expiring in 3 days)
    static let uberCredit = PreviewBenefit(
        name: "Uber Credit",
        description: "Monthly Uber Cash credit for rides or Uber Eats",
        value: 15,
        frequency: .monthly,
        category: .transportation,
        status: .available,
        expirationDate: daysFromNow(3),
        merchant: "Uber"
    )

    /// Dining credit (monthly, expiring in 10 days)
    static let diningCredit = PreviewBenefit(
        name: "Dining Credit",
        description: "Statement credit at participating restaurants",
        value: 10,
        frequency: .monthly,
        category: .dining,
        status: .available,
        expirationDate: endOfMonth,
        merchant: nil
    )

    /// Saks credit (semi-annual, expiring in 7 days)
    static let saksCredit = PreviewBenefit(
        name: "Saks Fifth Avenue Credit",
        description: "Shopping credit at Saks Fifth Avenue",
        value: 50,
        frequency: .semiAnnual,
        category: .shopping,
        status: .available,
        expirationDate: daysFromNow(7),
        merchant: "Saks Fifth Avenue"
    )

    /// Airline credit (annual, many days remaining)
    static let airlineCredit = PreviewBenefit(
        name: "Airline Fee Credit",
        description: "Credit for incidental airline fees",
        value: 200,
        frequency: .annual,
        category: .travel,
        status: .available,
        expirationDate: endOfYear,
        merchant: nil
    )

    /// Entertainment credit (monthly, used)
    static let entertainmentCreditUsed = PreviewBenefit(
        name: "Digital Entertainment",
        description: "Streaming service credits",
        value: 20,
        frequency: .monthly,
        category: .entertainment,
        status: .used,
        expirationDate: endOfMonth,
        usedDate: daysAgo(5),
        merchant: nil
    )

    /// CLEAR credit (annual, available)
    static let clearCredit = PreviewBenefit(
        name: "CLEAR Plus Credit",
        description: "CLEAR airport security membership",
        value: 189,
        frequency: .annual,
        category: .travel,
        status: .available,
        expirationDate: endOfYear,
        merchant: "CLEAR"
    )

    /// Hotel credit (semi-annual, expired)
    static let hotelCreditExpired = PreviewBenefit(
        name: "Hotel Collection Credit",
        description: "Credit at Fine Hotels + Resorts properties",
        value: 100,
        frequency: .semiAnnual,
        category: .travel,
        status: .expired,
        expirationDate: daysAgo(15),
        merchant: nil
    )

    /// Travel credit (annual)
    static let travelCredit = PreviewBenefit(
        name: "Travel Credit",
        description: "Automatic statement credit for travel purchases",
        value: 300,
        frequency: .annual,
        category: .travel,
        status: .available,
        expirationDate: endOfYear,
        merchant: nil
    )

    /// DoorDash credit (annual)
    static let doorDashCredit = PreviewBenefit(
        name: "DoorDash DashPass",
        description: "Complimentary DashPass membership and credits",
        value: 60,
        frequency: .annual,
        category: .dining,
        status: .available,
        expirationDate: endOfYear,
        merchant: "DoorDash"
    )

    /// Lyft credit (monthly)
    static let lyftCredit = PreviewBenefit(
        name: "Lyft Pink Credit",
        description: "Lyft Pink membership and ride credits",
        value: 5,
        frequency: .monthly,
        category: .transportation,
        status: .available,
        expirationDate: endOfMonth,
        merchant: "Lyft"
    )

    // MARK: - Sample Cards

    /// Amex Platinum with full benefits
    static let amexPlatinum = PreviewCard(
        name: "Platinum Card",
        issuer: "American Express",
        nickname: "Personal Platinum",
        annualFee: 695,
        gradient: .platinum,
        benefits: [
            uberCredit,
            saksCredit,
            airlineCredit,
            entertainmentCreditUsed,
            clearCredit,
            hotelCreditExpired
        ]
    )

    /// Amex Gold with benefits
    static let amexGold = PreviewCard(
        name: "Gold Card",
        issuer: "American Express",
        nickname: nil,
        annualFee: 250,
        gradient: .gold,
        benefits: [
            PreviewBenefit(
                name: "Uber Credit",
                value: 10,
                frequency: .monthly,
                category: .transportation,
                status: .available,
                expirationDate: endOfMonth,
                merchant: "Uber"
            ),
            diningCredit
        ]
    )

    /// Chase Sapphire Reserve
    static let chaseSapphireReserve = PreviewCard(
        name: "Sapphire Reserve",
        issuer: "Chase",
        nickname: nil,
        annualFee: 550,
        gradient: .sapphire,
        benefits: [
            travelCredit,
            doorDashCredit,
            lyftCredit
        ]
    )

    /// Capital One Venture X
    static let capitalOneVentureX = PreviewCard(
        name: "Venture X",
        issuer: "Capital One",
        nickname: "Travel Card",
        annualFee: 395,
        gradient: .obsidian,
        benefits: [
            PreviewBenefit(
                name: "Travel Credit",
                value: 300,
                frequency: .annual,
                category: .travel,
                status: .available,
                expirationDate: endOfYear
            ),
            PreviewBenefit(
                name: "Capital One Travel Experience",
                value: 100,
                frequency: .annual,
                category: .travel,
                status: .used,
                expirationDate: endOfYear,
                usedDate: daysAgo(30)
            )
        ]
    )

    /// Custom card example
    static let customCard = PreviewCard(
        name: "Local Credit Union",
        issuer: "Local Bank",
        nickname: "Everyday Card",
        annualFee: 0,
        gradient: .emerald,
        benefits: [
            PreviewBenefit(
                name: "Cashback Bonus",
                value: 25,
                frequency: .quarterly,
                category: .lifestyle,
                status: .available,
                expirationDate: endOfQuarter
            )
        ],
        isCustom: true
    )

    /// All sample cards for wallet view
    static let sampleCards: [PreviewCard] = [
        amexPlatinum,
        amexGold,
        chaseSapphireReserve,
        capitalOneVentureX
    ]

    /// Cards for empty state testing (empty array)
    static let emptyCards: [PreviewCard] = []

    /// Single card for focused testing
    static let singleCard: [PreviewCard] = [amexPlatinum]

    // MARK: - Sample Benefits Array

    /// All available benefits sorted by urgency
    static var allExpiringBenefits: [PreviewBenefit] {
        sampleCards
            .flatMap { $0.availableBenefits }
            .sorted { $0.daysRemaining < $1.daysRemaining }
    }

    /// Benefits expiring within 7 days
    static var expiringThisWeek: [PreviewBenefit] {
        allExpiringBenefits.filter { $0.isExpiringSoon }
    }

    /// Recently used benefits
    static var recentlyUsedBenefits: [PreviewBenefit] {
        sampleCards
            .flatMap { $0.usedBenefits }
            .sorted { ($0.usedDate ?? .distantPast) > ($1.usedDate ?? .distantPast) }
    }

    // MARK: - Sample Card Templates (for onboarding)

    static let cardTemplates: [PreviewCardTemplate] = [
        PreviewCardTemplate(
            id: UUID(),
            name: "Platinum Card",
            issuer: "American Express",
            annualFee: 695,
            gradient: .platinum,
            benefitCount: 6,
            totalAnnualValue: 1500
        ),
        PreviewCardTemplate(
            id: UUID(),
            name: "Gold Card",
            issuer: "American Express",
            annualFee: 250,
            gradient: .gold,
            benefitCount: 3,
            totalAnnualValue: 480
        ),
        PreviewCardTemplate(
            id: UUID(),
            name: "Green Card",
            issuer: "American Express",
            annualFee: 150,
            gradient: .emerald,
            benefitCount: 2,
            totalAnnualValue: 200
        ),
        PreviewCardTemplate(
            id: UUID(),
            name: "Sapphire Reserve",
            issuer: "Chase",
            annualFee: 550,
            gradient: .sapphire,
            benefitCount: 4,
            totalAnnualValue: 900
        ),
        PreviewCardTemplate(
            id: UUID(),
            name: "Sapphire Preferred",
            issuer: "Chase",
            annualFee: 95,
            gradient: .sapphire,
            benefitCount: 1,
            totalAnnualValue: 50
        ),
        PreviewCardTemplate(
            id: UUID(),
            name: "Venture X",
            issuer: "Capital One",
            annualFee: 395,
            gradient: .obsidian,
            benefitCount: 3,
            totalAnnualValue: 500
        ),
        PreviewCardTemplate(
            id: UUID(),
            name: "Hilton Aspire",
            issuer: "American Express",
            annualFee: 450,
            gradient: .midnight,
            benefitCount: 4,
            totalAnnualValue: 750
        ),
        PreviewCardTemplate(
            id: UUID(),
            name: "Marriott Bonvoy Brilliant",
            issuer: "American Express",
            annualFee: 650,
            gradient: .ruby,
            benefitCount: 3,
            totalAnnualValue: 600
        )
    ]

    /// Card templates grouped by issuer
    static var cardTemplatesByIssuer: [String: [PreviewCardTemplate]] {
        Dictionary(grouping: cardTemplates, by: { $0.issuer })
    }

    /// List of all unique issuers
    static var allIssuers: [String] {
        Array(Set(cardTemplates.map { $0.issuer })).sorted()
    }

    // MARK: - Dashboard Summary Data

    /// Total value available across all cards
    static var totalAvailableValue: Decimal {
        sampleCards.reduce(0) { $0 + $1.totalAvailableValue }
    }

    /// Total cards count
    static var totalCardsCount: Int {
        sampleCards.count
    }

    /// Total expiring benefits count
    static var totalExpiringCount: Int {
        sampleCards.reduce(0) { $0 + $1.expiringBenefitsCount }
    }

    /// Formatted total available value
    static var formattedTotalValue: String { Formatters.formatCurrencyWhole(totalAvailableValue) }
}

// MARK: - Preview Helpers
extension PreviewBenefit {
    /// Create a benefit that expires in a specific number of days
    static func expiring(in days: Int, value: Decimal = 50, name: String = "Sample Benefit") -> PreviewBenefit {
        PreviewBenefit(
            name: name,
            value: value,
            frequency: .monthly,
            category: .lifestyle,
            status: .available,
            expirationDate: PreviewData.daysFromNow(days)
        )
    }

    /// Create an already used benefit
    static func used(value: Decimal = 50, name: String = "Sample Benefit") -> PreviewBenefit {
        PreviewBenefit(
            name: name,
            value: value,
            frequency: .monthly,
            category: .lifestyle,
            status: .used,
            expirationDate: PreviewData.endOfMonth,
            usedDate: PreviewData.daysAgo(2)
        )
    }

    /// Create an expired benefit
    static func expired(value: Decimal = 50, name: String = "Sample Benefit") -> PreviewBenefit {
        PreviewBenefit(
            name: name,
            value: value,
            frequency: .monthly,
            category: .lifestyle,
            status: .expired,
            expirationDate: PreviewData.daysAgo(5)
        )
    }
}

// MARK: - Preview
#Preview("Preview Data Overview") {
    NavigationStack {
        List {
            Section("Sample Cards") {
                ForEach(PreviewData.sampleCards) { card in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(card.name)
                            .font(DesignSystem.Typography.headline)
                        Text("\(card.issuer) - \(card.formattedTotalValue) available")
                            .font(DesignSystem.Typography.subhead)
                            .foregroundStyle(DesignSystem.Colors.textSecondary)
                        Text("\(card.benefits.count) benefits, \(card.expiringBenefitsCount) expiring soon")
                            .font(DesignSystem.Typography.caption)
                            .foregroundStyle(DesignSystem.Colors.textTertiary)
                    }
                    .padding(.vertical, 4)
                }
            }

            Section("Expiring Benefits") {
                ForEach(PreviewData.expiringThisWeek) { benefit in
                    HStack {
                        Text(benefit.name)
                        Spacer()
                        Text(benefit.urgencyText)
                            .foregroundStyle(DesignSystem.Colors.urgencyColor(daysRemaining: benefit.daysRemaining))
                    }
                }
            }

            Section("Summary") {
                LabeledContent("Total Value", value: PreviewData.formattedTotalValue)
                LabeledContent("Total Cards", value: "\(PreviewData.totalCardsCount)")
                LabeledContent("Expiring This Week", value: "\(PreviewData.totalExpiringCount)")
            }
        }
        .navigationTitle("Preview Data")
    }
}
