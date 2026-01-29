// CardROIServiceProtocol.swift
// CouponTracker
//
// Created: January 2026
// Purpose: Protocol for card ROI calculations and retention analysis.

import Foundation

/// ROI analysis result for a credit card.
struct CardROIAnalysis: Equatable {
    /// The card being analyzed
    let cardId: UUID
    /// Annual fee for the card
    let annualFee: Decimal
    /// Total value from benefits (redeemed in the analysis period)
    let benefitsValue: Decimal
    /// Total subscription costs charged to this card
    let subscriptionCosts: Decimal
    /// Net value (benefits - fee - subscriptions, or just benefits - fee depending on context)
    let netValue: Decimal
    /// ROI percentage ((benefitsValue - annualFee) / annualFee * 100)
    let roiPercentage: Decimal
    /// Whether the card is "worth it" (benefits >= fee)
    let isWorthKeeping: Bool
    /// Months until break-even at current redemption rate
    let monthsToBreakEven: Int?
}

/// Breakdown of costs by category for a card.
struct CardCostBreakdown: Equatable {
    /// Total annual fee
    let annualFee: Decimal
    /// Total annual subscription costs
    let subscriptionCosts: Decimal
    /// Subscription costs by category
    let subscriptionsByCategory: [SubscriptionCategory: Decimal]
    /// Total cost (fee + subscriptions)
    let totalCost: Decimal
}

/// Worth-it recommendation for card retention.
enum CardRetentionRecommendation: Equatable {
    /// Card is clearly worth keeping (ROI > 50%)
    case strongKeep(reason: String)
    /// Card is marginally worth keeping (ROI 0-50%)
    case marginalKeep(reason: String)
    /// Card is break-even or slightly negative (-20% to 0%)
    case evaluate(reason: String)
    /// Card is not worth the fee (ROI < -20%)
    case considerCancelling(reason: String)

    var displayTitle: String {
        switch self {
        case .strongKeep: return "Definitely Keep"
        case .marginalKeep: return "Worth Keeping"
        case .evaluate: return "Evaluate"
        case .considerCancelling: return "Consider Cancelling"
        }
    }

    var iconName: String {
        switch self {
        case .strongKeep: return "checkmark.circle.fill"
        case .marginalKeep: return "checkmark.circle"
        case .evaluate: return "questionmark.circle"
        case .considerCancelling: return "xmark.circle"
        }
    }
}

/// Protocol for card ROI calculations and retention analysis.
///
/// Responsibilities:
/// - Calculate annual fee ROI (benefits value vs fee)
/// - Calculate subscription costs per card
/// - Provide "worth it" analysis for card retention decisions
///
/// This service is stateless and operates on provided data.
protocol CardROIServiceProtocol {

    // MARK: - ROI Calculations

    /// Calculates ROI analysis for a card.
    /// - Parameters:
    ///   - card: The card to analyze
    ///   - redeemedBenefitsValue: Total value of benefits redeemed in the period
    ///   - includeSubscriptions: Whether to factor subscription costs into analysis
    /// - Returns: ROI analysis with metrics and recommendation
    func calculateROI(
        for card: UserCard,
        redeemedBenefitsValue: Decimal,
        includeSubscriptions: Bool
    ) -> CardROIAnalysis

    /// Calculates ROI for a card based on potential (available) benefit value.
    /// Useful for projected ROI if all benefits were redeemed.
    /// - Parameters:
    ///   - card: The card to analyze
    ///   - availableBenefitsValue: Total value of available benefits
    /// - Returns: ROI analysis based on potential value
    func calculatePotentialROI(
        for card: UserCard,
        availableBenefitsValue: Decimal
    ) -> CardROIAnalysis

    // MARK: - Cost Analysis

    /// Calculates subscription costs for a card.
    /// - Parameters:
    ///   - card: The card to analyze
    ///   - period: Time period for the calculation (annual or monthly)
    /// - Returns: Total subscription cost for the period
    func calculateSubscriptionCosts(
        for card: UserCard,
        period: CostPeriod
    ) -> Decimal

    /// Generates a cost breakdown for a card.
    /// - Parameter card: The card to analyze
    /// - Returns: Breakdown of all costs (annual fee + subscriptions by category)
    func generateCostBreakdown(for card: UserCard) -> CardCostBreakdown

    // MARK: - Worth-It Analysis

    /// Generates a retention recommendation for a card.
    /// - Parameters:
    ///   - card: The card to analyze
    ///   - redeemedBenefitsValue: Value redeemed in the analysis period
    ///   - periodMonths: Number of months in the analysis period (default 12)
    /// - Returns: Retention recommendation with reasoning
    func generateRetentionRecommendation(
        for card: UserCard,
        redeemedBenefitsValue: Decimal,
        periodMonths: Int
    ) -> CardRetentionRecommendation

    /// Calculates the minimum value needed to break even on the annual fee.
    /// - Parameter card: The card to analyze
    /// - Returns: The minimum benefit value needed to justify the fee
    func calculateBreakEvenValue(for card: UserCard) -> Decimal

    /// Calculates the monthly redemption rate needed to break even by fee date.
    /// - Parameters:
    ///   - card: The card to analyze
    ///   - currentRedeemedValue: Value already redeemed this period
    /// - Returns: Monthly rate needed, or nil if fee date not set or already achieved
    func calculateRequiredMonthlyRate(
        for card: UserCard,
        currentRedeemedValue: Decimal
    ) -> Decimal?
}

/// Period for cost calculations.
enum CostPeriod {
    case monthly
    case annual
}
