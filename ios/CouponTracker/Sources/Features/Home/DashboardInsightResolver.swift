import Foundation

/// Input data for subscription-related insights.
struct SubscriptionInsightData {
    let subscriptionsRenewingThisWeek: [Subscription]

    var renewingSoonCount: Int { subscriptionsRenewingThisWeek.count }
    var renewingSoonTotalCost: Decimal {
        subscriptionsRenewingThisWeek.reduce(Decimal.zero) { $0 + $1.price }
    }
}

/// Input data for coupon-related insights.
struct CouponInsightData {
    let couponsExpiringSoon: [Coupon]

    var expiringSoonCount: Int { couponsExpiringSoon.count }
    var expiringSoonTotalValue: Decimal {
        couponsExpiringSoon.reduce(Decimal.zero) { $0 + ($1.value ?? 0) }
    }
}

/// Input data for annual fee insights.
struct AnnualFeeInsightData {
    let cardName: String
    let annualFee: Decimal
    let daysUntilFee: Int
}

/// Resolves which dashboard insight to display based on current state.
///
/// Applies priority logic to select the most relevant insight for the user:
/// 1. Urgent: Benefits expiring today with high value
/// 2. Annual fee due soon (within 7 days)
/// 3. Subscriptions renewing this week
/// 4. Coupons expiring soon
/// 5. High available value (> $100)
/// 6. Monthly success (> 50% used)
/// 7. Onboarding (empty state)
struct DashboardInsightResolver {

    /// Resolves the current dashboard insight to display.
    ///
    /// - Parameters:
    ///   - benefitsExpiringToday: Array of benefits expiring today
    ///   - totalAvailableValue: Total value available across all benefits
    ///   - usedCount: Number of benefits marked as used
    ///   - totalCount: Total number of benefits
    ///   - redeemedThisMonth: Total value redeemed in current month
    /// - Returns: The highest priority insight to display, or nil if no insight applies
    func resolve(
        benefitsExpiringToday: [any BenefitDisplayable],
        totalAvailableValue: Decimal,
        usedCount: Int,
        totalCount: Int,
        redeemedThisMonth: Decimal
    ) -> DashboardInsight? {
        resolve(
            benefitsExpiringToday: benefitsExpiringToday,
            totalAvailableValue: totalAvailableValue,
            usedCount: usedCount,
            totalCount: totalCount,
            redeemedThisMonth: redeemedThisMonth,
            subscriptionData: nil,
            couponData: nil,
            annualFeeData: nil
        )
    }

    /// Resolves the current dashboard insight with extended subscription/coupon data.
    ///
    /// - Parameters:
    ///   - benefitsExpiringToday: Array of benefits expiring today
    ///   - totalAvailableValue: Total value available across all benefits
    ///   - usedCount: Number of benefits marked as used
    ///   - totalCount: Total number of benefits
    ///   - redeemedThisMonth: Total value redeemed in current month
    ///   - subscriptionData: Subscription insight data (optional)
    ///   - couponData: Coupon insight data (optional)
    ///   - annualFeeData: Annual fee insight data for the most urgent card (optional)
    /// - Returns: The highest priority insight to display, or nil if no insight applies
    func resolve(
        benefitsExpiringToday: [any BenefitDisplayable],
        totalAvailableValue: Decimal,
        usedCount: Int,
        totalCount: Int,
        redeemedThisMonth: Decimal,
        subscriptionData: SubscriptionInsightData?,
        couponData: CouponInsightData?,
        annualFeeData: AnnualFeeInsightData?
    ) -> DashboardInsight? {
        // Priority 1: Urgent expiring benefits (today)
        let todayCount = benefitsExpiringToday.count
        if todayCount > 0 {
            let todayValue = benefitsExpiringToday.reduce(Decimal.zero) { $0 + $1.value }
            return .urgentExpiring(value: todayValue, count: todayCount)
        }

        // Priority 2: Annual fee due soon (within 7 days, fee > $0)
        if let feeData = annualFeeData,
           feeData.annualFee > 0,
           feeData.daysUntilFee >= 0,
           feeData.daysUntilFee <= 7 {
            return .annualFeeDue(
                cardName: feeData.cardName,
                fee: feeData.annualFee,
                daysUntil: feeData.daysUntilFee
            )
        }

        // Priority 3: Subscriptions renewing this week
        if let subData = subscriptionData, subData.renewingSoonCount > 0 {
            return .subscriptionsRenewing(
                count: subData.renewingSoonCount,
                totalCost: subData.renewingSoonTotalCost
            )
        }

        // Priority 4: Coupons expiring soon (within 3 days)
        if let couponData = couponData, couponData.expiringSoonCount > 0 {
            return .couponsExpiring(
                count: couponData.expiringSoonCount,
                totalValue: couponData.expiringSoonTotalValue
            )
        }

        // Priority 5: High value available
        if totalAvailableValue > 100 {
            return .availableValue(value: totalAvailableValue)
        }

        // Priority 6: Monthly success (high redemption rate)
        let isEmpty = totalCount == 0
        if !isEmpty && usedCount > totalCount / 2 {
            return .monthlySuccess(value: redeemedThisMonth)
        }

        // Priority 7: Onboarding
        if isEmpty {
            return .onboarding
        }

        return nil
    }
}
