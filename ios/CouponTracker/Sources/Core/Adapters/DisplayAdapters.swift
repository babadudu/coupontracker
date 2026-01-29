// DisplayAdapters.swift
// CouponTracker
//
// Created: January 2026
// Purpose: Adapter types that combine SwiftData entities with template data
//          to implement display protocols (ADR-001).
//
// These adapters bridge the gap between:
// - SwiftData entities (UserCard, Benefit) that store template references
// - Display protocols that require resolved display values

import Foundation

// MARK: - Benefit Display Adapter

/// Adapts a Benefit entity with template data to implement BenefitDisplayable.
struct BenefitDisplayAdapter: BenefitDisplayable {
    private let benefit: Benefit
    private let template: BenefitTemplate?

    var id: UUID { benefit.id }

    var name: String {
        benefit.customName ?? template?.name ?? "Unknown Benefit"
    }

    var benefitDescription: String {
        benefit.customDescription ?? template?.description ?? ""
    }

    var value: Decimal {
        benefit.customValue ?? template?.value ?? 0
    }

    var frequency: BenefitFrequency {
        benefit.customFrequency ?? template?.frequency ?? .monthly
    }

    var category: BenefitCategory {
        benefit.customCategory ?? template?.category ?? .lifestyle
    }

    var status: BenefitStatus {
        benefit.status
    }

    var expirationDate: Date {
        benefit.currentPeriodEnd
    }

    var usedDate: Date? {
        // Get most recent usage from history
        benefit.usageHistory.max(by: { $0.usedDate < $1.usedDate })?.usedDate
    }

    var merchant: String? {
        template?.merchant
    }

    init(benefit: Benefit, template: BenefitTemplate?) {
        self.benefit = benefit
        self.template = template
    }
}

// MARK: - Card Display Adapter

/// Adapts a UserCard entity with template data to implement CardDisplayable.
struct CardDisplayAdapter: CardDisplayable {
    typealias BenefitType = BenefitDisplayAdapter

    private let card: UserCard
    private let cardTemplate: CardTemplate?
    private let benefitTemplates: [UUID: BenefitTemplate]

    var id: UUID { card.id }

    var name: String {
        card.customName ?? cardTemplate?.name ?? "Unknown Card"
    }

    var issuer: String {
        card.customIssuer ?? cardTemplate?.issuer ?? "Unknown Issuer"
    }

    var nickname: String? {
        card.nickname
    }

    var gradient: DesignSystem.CardGradient {
        if let colorHex = card.customColorHex {
            return DesignSystem.CardGradient.fromHex(colorHex)
        }
        if let template = cardTemplate {
            return DesignSystem.CardGradient.fromHex(template.primaryColorHex)
        }
        return .obsidian
    }

    var benefits: [BenefitDisplayAdapter] {
        card.benefits.map { benefit in
            let template = benefit.templateBenefitId.flatMap { benefitTemplates[$0] }
            return BenefitDisplayAdapter(benefit: benefit, template: template)
        }
    }

    var displayName: String {
        if let nickname = card.nickname, !nickname.isEmpty {
            return nickname
        }
        return name
    }

    // MARK: - Annual Fee Properties (for ROI Card)

    var annualFee: Decimal { card.annualFee }
    var annualFeeDate: Date? { card.annualFeeDate }
    var daysUntilAnnualFee: Int { card.daysUntilAnnualFee }

    // MARK: - Subscription Properties

    var subscriptions: [Subscription] {
        Array(card.subscriptions)
    }

    var totalAnnualSubscriptionCost: Decimal {
        card.totalAnnualSubscriptionCost
    }

    // MARK: - Underlying Card Access

    var userCard: UserCard { card }

    init(
        card: UserCard,
        cardTemplate: CardTemplate?,
        benefitTemplates: [UUID: BenefitTemplate] = [:]
    ) {
        self.card = card
        self.cardTemplate = cardTemplate
        self.benefitTemplates = benefitTemplates
    }
}

// MARK: - Hashable Conformance

extension BenefitDisplayAdapter: Hashable {
    static func == (lhs: BenefitDisplayAdapter, rhs: BenefitDisplayAdapter) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

extension CardDisplayAdapter: Hashable {
    static func == (lhs: CardDisplayAdapter, rhs: CardDisplayAdapter) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

// MARK: - Card Gradient Extension

extension DesignSystem.CardGradient {
    /// Creates a gradient from a hex color string
    static func fromHex(_ hex: String) -> DesignSystem.CardGradient {
        // Map common card colors to gradients
        let normalizedHex = hex.lowercased()
        switch normalizedHex {
        case let h where h.contains("c0c0c0") || h.contains("8b8b8b") || h.contains("d4d4d4"):
            return .platinum
        case let h where h.contains("d4af37") || h.contains("ffd700") || h.contains("b8860b"):
            return .gold
        case let h where h.contains("003c71") || h.contains("0066b2") || h.contains("1a365d"):
            return .sapphire
        case let h where h.contains("004977") || h.contains("1e3a5f"):
            return .midnight
        case let h where h.contains("2d5016") || h.contains("228b22"):
            return .emerald
        case let h where h.contains("8b0000") || h.contains("dc143c"):
            return .ruby
        default:
            return .obsidian
        }
    }
}

// MARK: - Expiring Benefit Display Adapter

/// Pairs a benefit with its parent card for expiring benefits lists.
struct ExpiringBenefitDisplayAdapter: ExpiringBenefitDisplayable, Identifiable {
    typealias BenefitType = BenefitDisplayAdapter
    typealias CardType = CardDisplayAdapter

    let benefit: BenefitDisplayAdapter
    let card: CardDisplayAdapter

    var id: UUID { benefit.id }
}

// MARK: - Preview Type Conversion (Interim MVP Solution)
// These extensions provide conversion to PreviewCard/PreviewBenefit
// so existing views can work with real data without immediate refactoring.

extension BenefitDisplayAdapter {
    /// Converts to PreviewBenefit for view compatibility
    func toPreviewBenefit() -> PreviewBenefit {
        PreviewBenefit(
            id: id,
            name: name,
            description: benefitDescription,
            value: value,
            frequency: frequency,
            category: category,
            status: status,
            expirationDate: expirationDate,
            usedDate: usedDate,
            merchant: merchant
        )
    }
}

extension CardDisplayAdapter {
    /// Converts to PreviewCard for view compatibility
    func toPreviewCard() -> PreviewCard {
        PreviewCard(
            id: id,
            name: name,
            issuer: issuer,
            nickname: nickname,
            annualFee: annualFee,
            gradient: gradient,
            benefits: benefits.map { $0.toPreviewBenefit() },
            isCustom: false,
            annualFeeDate: annualFeeDate,
            totalSubscriptionCost: totalAnnualSubscriptionCost
        )
    }
}

extension ExpiringBenefitDisplayAdapter {
    /// Converts to ExpiringBenefitItem for view compatibility
    func toExpiringBenefitItem() -> ExpiringBenefitItem {
        ExpiringBenefitItem(
            benefit: benefit.toPreviewBenefit(),
            card: card.toPreviewCard()
        )
    }
}
