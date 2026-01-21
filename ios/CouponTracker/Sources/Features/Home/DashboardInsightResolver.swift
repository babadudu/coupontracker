import Foundation

/// Resolves which dashboard insight to display based on current state.
///
/// Applies priority logic to select the most relevant insight for the user:
/// 1. Urgent: Benefits expiring today with high value
/// 2. High available value (> $100)
/// 3. Monthly success (> 50% used)
/// 4. Onboarding (empty state)
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
        let isEmpty = totalCount == 0
        if !isEmpty && usedCount > totalCount / 2 {
            return .monthlySuccess(value: redeemedThisMonth)
        }

        // Priority 4: Onboarding
        if isEmpty {
            return .onboarding
        }

        return nil
    }
}
