// CardROIService.swift
// CouponTracker
//
// Created: January 2026
// Purpose: Implementation of card ROI calculations and retention analysis.

import Foundation

/// CardROIService
///
/// Responsibilities:
/// - Calculate annual fee ROI (benefits value vs fee)
/// - Calculate subscription costs per card
/// - Provide "worth it" analysis for card retention decisions
///
/// Dependencies:
/// - None (stateless service with no external dependencies)
///
/// Thread Safety: Sendable (value type)
struct CardROIService: CardROIServiceProtocol {

    // MARK: - ROI Calculations

    func calculateROI(
        for card: UserCard,
        redeemedBenefitsValue: Decimal,
        includeSubscriptions: Bool
    ) -> CardROIAnalysis {
        let fee = card.annualFee
        let subscriptionCosts = includeSubscriptions ? card.totalAnnualSubscriptionCost : 0

        // Net value = benefits - fee (subscriptions are costs but separate from ROI calculation)
        let netValue = redeemedBenefitsValue - fee

        // ROI percentage (avoid division by zero)
        let roiPercentage: Decimal
        if fee > 0 {
            roiPercentage = (netValue / fee) * 100
        } else {
            // No fee means infinite ROI if benefits > 0, or 0 if no benefits
            roiPercentage = redeemedBenefitsValue > 0 ? 100 : 0
        }

        // Worth keeping if benefits >= fee
        let isWorthKeeping = redeemedBenefitsValue >= fee

        // Months to break even
        let monthsToBreakEven = calculateMonthsToBreakEven(
            fee: fee,
            currentValue: redeemedBenefitsValue,
            monthlyRate: redeemedBenefitsValue / 12
        )

        return CardROIAnalysis(
            cardId: card.id,
            annualFee: fee,
            benefitsValue: redeemedBenefitsValue,
            subscriptionCosts: subscriptionCosts,
            netValue: netValue,
            roiPercentage: roiPercentage,
            isWorthKeeping: isWorthKeeping,
            monthsToBreakEven: monthsToBreakEven
        )
    }

    func calculatePotentialROI(
        for card: UserCard,
        availableBenefitsValue: Decimal
    ) -> CardROIAnalysis {
        calculateROI(
            for: card,
            redeemedBenefitsValue: availableBenefitsValue,
            includeSubscriptions: false
        )
    }

    // MARK: - Cost Analysis

    func calculateSubscriptionCosts(
        for card: UserCard,
        period: CostPeriod
    ) -> Decimal {
        switch period {
        case .monthly:
            return card.totalMonthlySubscriptionCost
        case .annual:
            return card.totalAnnualSubscriptionCost
        }
    }

    func generateCostBreakdown(for card: UserCard) -> CardCostBreakdown {
        var subscriptionsByCategory: [SubscriptionCategory: Decimal] = [:]

        for subscription in card.subscriptions where subscription.isActive {
            let category = subscription.category
            subscriptionsByCategory[category, default: 0] += subscription.annualizedCost
        }

        let subscriptionCosts = card.totalAnnualSubscriptionCost
        let totalCost = card.annualFee + subscriptionCosts

        return CardCostBreakdown(
            annualFee: card.annualFee,
            subscriptionCosts: subscriptionCosts,
            subscriptionsByCategory: subscriptionsByCategory,
            totalCost: totalCost
        )
    }

    // MARK: - Worth-It Analysis

    func generateRetentionRecommendation(
        for card: UserCard,
        redeemedBenefitsValue: Decimal,
        periodMonths: Int
    ) -> CardRetentionRecommendation {
        let fee = card.annualFee

        // No fee cards are always worth keeping
        guard fee > 0 else {
            return .strongKeep(reason: "No annual fee - keep for available benefits")
        }

        // Annualize the redeemed value if period is less than 12 months
        let annualizedValue: Decimal
        if periodMonths < 12 && periodMonths > 0 {
            annualizedValue = (redeemedBenefitsValue / Decimal(periodMonths)) * 12
        } else {
            annualizedValue = redeemedBenefitsValue
        }

        // Calculate ROI
        let netValue = annualizedValue - fee
        let roiPercentage = (netValue / fee) * 100

        // Generate recommendation based on ROI
        if roiPercentage >= 50 {
            let formattedValue = Formatters.formatCurrency(annualizedValue)
            return .strongKeep(
                reason: "Getting \(formattedValue) in value vs \(Formatters.formatCurrency(fee)) fee"
            )
        } else if roiPercentage >= 0 {
            let surplus = Formatters.formatCurrency(netValue)
            return .marginalKeep(
                reason: "Earning \(surplus) above the annual fee"
            )
        } else if roiPercentage >= -20 {
            let shortfall = Formatters.formatCurrency(abs(netValue))
            return .evaluate(
                reason: "Currently \(shortfall) short of breaking even on the fee"
            )
        } else {
            let shortfall = Formatters.formatCurrency(abs(netValue))
            return .considerCancelling(
                reason: "Losing \(shortfall) after accounting for the annual fee"
            )
        }
    }

    func calculateBreakEvenValue(for card: UserCard) -> Decimal {
        card.annualFee
    }

    func calculateRequiredMonthlyRate(
        for card: UserCard,
        currentRedeemedValue: Decimal
    ) -> Decimal? {
        guard card.annualFee > 0 else { return nil }
        guard let feeDate = card.annualFeeDate else { return nil }

        // Calculate remaining value needed
        let remainingValue = card.annualFee - currentRedeemedValue
        guard remainingValue > 0 else { return nil }

        // Calculate months remaining until fee date
        let calendar = Calendar.current
        let now = Date()
        let components = calendar.dateComponents([.month], from: now, to: feeDate)
        let monthsRemaining = max(1, components.month ?? 1)

        return remainingValue / Decimal(monthsRemaining)
    }

    // MARK: - Private Helpers

    private func calculateMonthsToBreakEven(
        fee: Decimal,
        currentValue: Decimal,
        monthlyRate: Decimal
    ) -> Int? {
        guard fee > 0 else { return 0 }
        guard currentValue < fee else { return 0 }
        guard monthlyRate > 0 else { return nil }

        let remaining = fee - currentValue
        let months = remaining / monthlyRate

        // Convert to Int, rounding up
        let monthsDouble = NSDecimalNumber(decimal: months).doubleValue
        return Int(ceil(monthsDouble))
    }
}
