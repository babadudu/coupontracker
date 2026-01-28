//
//  BenefitEnums.swift
//  CouponTracker
//
//  Created by Junior Engineer 1 on 2026-01-17.
//  Data model enumerations for benefit tracking
//

import Foundation
import SwiftUI

// MARK: - BenefitStatus

/// Represents the current status of a benefit
enum BenefitStatus: String, Codable, CaseIterable, Identifiable {
    var id: String { rawValue }
    /// Benefit is available for use
    case available

    /// Benefit has been used in current period
    case used

    /// Benefit has expired without being used
    case expired

    /// Human-readable display name
    var displayName: String {
        switch self {
        case .available:
            return "Available"
        case .used:
            return "Used"
        case .expired:
            return "Expired"
        }
    }

    /// SF Symbol icon name for UI display
    var iconName: String {
        switch self {
        case .available: return "circle"
        case .used: return "checkmark.seal.fill"  // Distinct from action buttons
        case .expired: return "xmark.circle"
        }
    }

    /// Color for UI display
    var color: Color {
        switch self {
        case .available: return DesignSystem.Colors.success
        case .used: return DesignSystem.Colors.success
        case .expired: return DesignSystem.Colors.neutral
        }
    }
}

// MARK: - BenefitFrequency

/// Represents how often a benefit resets/renews
enum BenefitFrequency: String, Codable, CaseIterable, Identifiable {
    var id: String { rawValue }

    case monthly, quarterly, semiAnnual, annual

    /// Human-readable display name
    var displayName: String {
        switch self {
        case .monthly: return "Monthly"
        case .quarterly: return "Quarterly"
        case .semiAnnual: return "Semi-Annual"
        case .annual: return "Annual"
        }
    }

    /// Short label for compact display
    var shortLabel: String {
        switch self {
        case .monthly: return "/mo"
        case .quarterly: return "/qtr"
        case .semiAnnual: return "/6mo"
        case .annual: return "/yr"
        }
    }

    /// Number of periods per year
    var periodsPerYear: Int {
        switch self {
        case .monthly: return 12
        case .quarterly: return 4
        case .semiAnnual: return 2
        case .annual: return 1
        }
    }

    /// Calculate the next period dates based on frequency and reset day
    /// - Parameters:
    ///   - from: Starting date (usually today or benefit creation date)
    ///   - resetDayOfMonth: Optional day of month to reset (1-31), nil means calendar period start
    /// - Returns: Tuple of (periodStart, periodEnd, nextResetDate)
    func calculatePeriodDates(
        from date: Date = Date(),
        resetDayOfMonth: Int? = nil
    ) -> (start: Date, end: Date, nextReset: Date) {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: date)

        switch self {
        case .monthly:
            let periodStart: Date
            let periodEnd: Date

            if let resetDay = resetDayOfMonth {
                // Reset on specific day of month
                let currentMonth = calendar.component(.month, from: today)
                let currentYear = calendar.component(.year, from: today)

                var startComponents = DateComponents()
                startComponents.year = currentYear
                startComponents.month = currentMonth
                startComponents.day = resetDay

                if let potentialStart = calendar.date(from: startComponents),
                   potentialStart <= today {
                    periodStart = potentialStart
                } else {
                    // Go to previous month
                    let startDate = calendar.date(from: startComponents) ?? today
                    periodStart = calendar.date(byAdding: .month, value: -1, to: startDate) ?? today
                }

                periodEnd = calendar.date(byAdding: .month, value: 1, to: periodStart) ?? today
            } else {
                // Use calendar month
                let components = calendar.dateComponents([.year, .month], from: today)
                periodStart = calendar.date(from: components) ?? today
                periodEnd = calendar.date(byAdding: .month, value: 1, to: periodStart) ?? today
            }

            let nextReset = periodEnd
            let adjustedEnd = calendar.date(byAdding: .day, value: -1, to: periodEnd) ?? periodEnd
            return (periodStart, adjustedEnd, nextReset)

        case .quarterly:
            // Quarters: Jan-Mar, Apr-Jun, Jul-Sep, Oct-Dec
            let month = calendar.component(.month, from: today)
            let quarterStartMonth = ((month - 1) / 3) * 3 + 1

            var startComponents = calendar.dateComponents([.year], from: today)
            startComponents.month = quarterStartMonth
            startComponents.day = 1

            let periodStart = calendar.date(from: startComponents) ?? today
            let periodEnd = calendar.date(byAdding: .month, value: 3, to: periodStart) ?? today
            let nextReset = periodEnd
            let adjustedEnd = calendar.date(byAdding: .day, value: -1, to: periodEnd) ?? periodEnd

            return (periodStart, adjustedEnd, nextReset)

        case .semiAnnual:
            // Semi-annual: Jan-Jun, Jul-Dec
            let month = calendar.component(.month, from: today)
            let halfStartMonth = month <= 6 ? 1 : 7

            var startComponents = calendar.dateComponents([.year], from: today)
            startComponents.month = halfStartMonth
            startComponents.day = 1

            let periodStart = calendar.date(from: startComponents) ?? today
            let periodEnd = calendar.date(byAdding: .month, value: 6, to: periodStart) ?? today
            let nextReset = periodEnd
            let adjustedEnd = calendar.date(byAdding: .day, value: -1, to: periodEnd) ?? periodEnd

            return (periodStart, adjustedEnd, nextReset)

        case .annual:
            // Calendar year: Jan 1 - Dec 31
            let year = calendar.component(.year, from: today)
            var startComponents = DateComponents()
            startComponents.year = year
            startComponents.month = 1
            startComponents.day = 1

            let periodStart = calendar.date(from: startComponents) ?? today
            let periodEnd = calendar.date(byAdding: .year, value: 1, to: periodStart) ?? today
            let nextReset = periodEnd
            let adjustedEnd = calendar.date(byAdding: .day, value: -1, to: periodEnd) ?? periodEnd

            return (periodStart, adjustedEnd, nextReset)
        }
    }
}

// MARK: - ExpirationUrgency

/// Defines explicit expiration time periods aligned with snooze options
enum ExpirationUrgency: String, CaseIterable, Identifiable {
    var id: String { rawValue }

    case expiringToday     // 0 days
    case within1Day        // 1 day (snooze: 1 day)
    case within3Days       // 2-3 days (snooze: 3 days)
    case within1Week       // 4-7 days (snooze: 1 week)
    case later             // > 7 days

    /// Display title for section headers
    var displayTitle: String {
        switch self {
        case .expiringToday: return "Today"
        case .within1Day: return "Tomorrow"
        case .within3Days: return "Next 3 Days"
        case .within1Week: return "This Week"
        case .later: return "Later"
        }
    }

    /// Subtitle describing the time range
    var subtitle: String {
        switch self {
        case .expiringToday: return "Expires at midnight"
        case .within1Day: return "1 day remaining"
        case .within3Days: return "2-3 days remaining"
        case .within1Week: return "4-7 days remaining"
        case .later: return "More than 1 week"
        }
    }

    /// Color for urgency display
    var color: Color {
        switch self {
        case .expiringToday: return DesignSystem.Colors.danger
        case .within1Day: return DesignSystem.Colors.danger.opacity(0.8)
        case .within3Days: return DesignSystem.Colors.warning
        case .within1Week: return DesignSystem.Colors.warning.opacity(0.7)
        case .later: return DesignSystem.Colors.neutral
        }
    }

    /// Determines urgency level from days remaining
    static func from(daysRemaining: Int) -> ExpirationUrgency {
        switch daysRemaining {
        case ..<0: return .expiringToday // Treat negative as expired today
        case 0: return .expiringToday
        case 1: return .within1Day
        case 2...3: return .within3Days
        case 4...7: return .within1Week
        default: return .later
        }
    }

    /// Urgency levels considered "urgent" (shown prominently)
    static var urgentLevels: [ExpirationUrgency] {
        [.expiringToday, .within1Day, .within3Days]
    }

    /// All levels except "later" for expiring views
    static var expiringLevels: [ExpirationUrgency] {
        [.expiringToday, .within1Day, .within3Days, .within1Week]
    }
}

// MARK: - BenefitPeriod

/// Represents time periods for accomplishment ring visualization.
///
/// Used in the period carousel to filter and display progress
/// for different time ranges (monthly, quarterly, etc.)
enum BenefitPeriod: String, CaseIterable, Identifiable {
    var id: String { rawValue }

    case monthly
    case quarterly
    case semiAnnual
    case annual

    /// Display label for period selector
    var displayName: String {
        switch self {
        case .monthly: return "Monthly"
        case .quarterly: return "Quarterly"
        case .semiAnnual: return "Semi-Annual"
        case .annual: return "Annual"
        }
    }

    /// Formatted label for the current period.
    /// - Parameter date: The reference date (defaults to today)
    /// - Returns: Formatted string like "January 2026", "Q1 2026", etc.
    func periodLabel(for date: Date = Date()) -> String {
        let calendar = Calendar.current
        let year = calendar.component(.year, from: date)

        switch self {
        case .monthly:
            let formatter = DateFormatter()
            formatter.dateFormat = "MMMM yyyy"
            return formatter.string(from: date)

        case .quarterly:
            let month = calendar.component(.month, from: date)
            let quarter = ((month - 1) / 3) + 1
            return "Q\(quarter) \(year)"

        case .semiAnnual:
            let month = calendar.component(.month, from: date)
            let half = month <= 6 ? 1 : 2
            return "H\(half) \(year)"

        case .annual:
            return "\(year)"
        }
    }

    /// Calculates the start and end dates for this period.
    /// - Parameter date: The reference date (defaults to today)
    /// - Returns: Tuple of (start, end) dates for the period
    func periodDates(for date: Date = Date()) -> (start: Date, end: Date) {
        let calendar = Calendar.current
        let year = calendar.component(.year, from: date)

        switch self {
        case .monthly:
            let components = calendar.dateComponents([.year, .month], from: date)
            let start = calendar.date(from: components) ?? date
            let end = calendar.date(byAdding: DateComponents(month: 1, day: -1), to: start) ?? date
            return (start, end)

        case .quarterly:
            let month = calendar.component(.month, from: date)
            let quarterStartMonth = ((month - 1) / 3) * 3 + 1
            var startComponents = DateComponents()
            startComponents.year = year
            startComponents.month = quarterStartMonth
            startComponents.day = 1
            let start = calendar.date(from: startComponents) ?? date
            let end = calendar.date(byAdding: DateComponents(month: 3, day: -1), to: start) ?? date
            return (start, end)

        case .semiAnnual:
            let month = calendar.component(.month, from: date)
            let halfStartMonth = month <= 6 ? 1 : 7
            var startComponents = DateComponents()
            startComponents.year = year
            startComponents.month = halfStartMonth
            startComponents.day = 1
            let start = calendar.date(from: startComponents) ?? date
            let end = calendar.date(byAdding: DateComponents(month: 6, day: -1), to: start) ?? date
            return (start, end)

        case .annual:
            var startComponents = DateComponents()
            startComponents.year = year
            startComponents.month = 1
            startComponents.day = 1
            let start = calendar.date(from: startComponents) ?? date
            let end = calendar.date(byAdding: DateComponents(year: 1, day: -1), to: start) ?? date
            return (start, end)
        }
    }

    /// Maps to the corresponding BenefitFrequency for filtering
    var correspondingFrequency: BenefitFrequency {
        switch self {
        case .monthly: return .monthly
        case .quarterly: return .quarterly
        case .semiAnnual: return .semiAnnual
        case .annual: return .annual
        }
    }

    /// Checks if a benefit's current period overlaps with this view period.
    /// - Parameters:
    ///   - benefitStart: The benefit's currentPeriodStart
    ///   - benefitEnd: The benefit's currentPeriodEnd
    ///   - referenceDate: The date to calculate the view period from
    /// - Returns: True if the benefit period overlaps with this view period
    func containsBenefitPeriod(
        benefitStart: Date,
        benefitEnd: Date,
        for referenceDate: Date = Date()
    ) -> Bool {
        let (viewStart, viewEnd) = periodDates(for: referenceDate)
        return benefitStart <= viewEnd && benefitEnd >= viewStart
    }

    /// Calculates how many times a benefit contributes to this period.
    /// Monthly benefits contribute 3x to quarterly, 12x to annual, etc.
    /// - Parameter frequency: The benefit's reset frequency
    /// - Returns: Multiplier for aggregation
    func aggregationMultiplier(for frequency: BenefitFrequency) -> Int {
        let viewPeriodsPerYear = correspondingFrequency.periodsPerYear
        let benefitPeriodsPerYear = frequency.periodsPerYear
        return max(1, benefitPeriodsPerYear / viewPeriodsPerYear)
    }

    /// Returns frequencies included in this period view (cumulative roll-up).
    /// - Monthly: only monthly
    /// - Quarterly: monthly + quarterly
    /// - SemiAnnual: monthly + quarterly + semiAnnual
    /// - Annual: all frequencies
    var includedFrequencies: Set<BenefitFrequency> {
        switch self {
        case .monthly:
            return [.monthly]
        case .quarterly:
            return [.monthly, .quarterly]
        case .semiAnnual:
            return [.monthly, .quarterly, .semiAnnual]
        case .annual:
            return [.monthly, .quarterly, .semiAnnual, .annual]
        }
    }
}

// MARK: - PeriodMetrics

/// Calculates period-scoped metrics for benefits.
/// Centralizes logic for redeemed/available value calculations by period.
struct PeriodMetrics {
    let redeemedValue: Decimal
    let availableValue: Decimal
    let totalValue: Decimal
    let usedCount: Int
    let availableCount: Int
    let totalCount: Int

    var percentageUsed: Int {
        guard totalValue > 0 else { return 0 }
        return NSDecimalNumber(decimal: redeemedValue / totalValue * 100).intValue
    }

    var isEmpty: Bool { totalCount == 0 }

    /// Calculates metrics for benefits within a given period.
    /// - Parameters:
    ///   - benefits: All benefits to evaluate
    ///   - period: The view period (monthly/quarterly/annual)
    ///   - referenceDate: The reference date for period calculation
    ///   - applyMultiplier: Whether to apply aggregation multiplier for smaller-frequency benefits.
    ///     Set to false when using cumulative roll-up with pre-filtered benefit instances.
    /// - Returns: Aggregated metrics for benefits overlapping the period
    static func calculate(
        for benefits: [Benefit],
        period: BenefitPeriod,
        referenceDate: Date = Date(),
        applyMultiplier: Bool = true
    ) -> PeriodMetrics {
        let (viewStart, viewEnd) = period.periodDates(for: referenceDate)

        // Filter benefits whose period overlaps with view period
        let overlapping = benefits.filter { benefit in
            benefit.currentPeriodStart <= viewEnd &&
            benefit.currentPeriodEnd >= viewStart
        }

        let used = overlapping.filter { $0.status == .used }
        let available = overlapping.filter { $0.status == .available }

        // Calculate total potential value (with optional aggregation multiplier)
        var totalValue: Decimal = 0
        var redeemedValue: Decimal = 0
        var availableValue: Decimal = 0

        for benefit in overlapping {
            let multiplier = applyMultiplier
                ? Decimal(period.aggregationMultiplier(for: benefit.frequency))
                : 1
            let benefitTotal = benefit.effectiveValue * multiplier
            totalValue += benefitTotal

            if benefit.status == .used {
                redeemedValue += benefit.effectiveValue
            } else if benefit.status == .available {
                availableValue += benefit.effectiveValue
            }
        }

        return PeriodMetrics(
            redeemedValue: redeemedValue,
            availableValue: availableValue,
            totalValue: totalValue,
            usedCount: used.count,
            availableCount: available.count,
            totalCount: overlapping.count
        )
    }

    /// Calculates metrics using pre-fetched historical redeemed value.
    /// Use this for quarterly/annual views that need actual BenefitUsage records.
    ///
    /// - Parameters:
    ///   - benefits: All benefits to evaluate for totalValue calculation
    ///   - historicalRedeemed: Pre-fetched sum from BenefitUsage records
    ///   - period: The view period (monthly/quarterly/annual)
    ///   - referenceDate: The reference date for period calculation
    /// - Returns: Metrics with historical redeemedValue instead of current status
    static func calculateWithHistory(
        for benefits: [Benefit],
        historicalRedeemed: Decimal,
        period: BenefitPeriod,
        referenceDate: Date = Date()
    ) -> PeriodMetrics {
        let (viewStart, viewEnd) = period.periodDates(for: referenceDate)

        // Filter benefits whose period overlaps with view period
        let overlapping = benefits.filter { benefit in
            benefit.currentPeriodStart <= viewEnd &&
            benefit.currentPeriodEnd >= viewStart
        }

        let used = overlapping.filter { $0.status == .used }
        let available = overlapping.filter { $0.status == .available }

        // Calculate total potential value with aggregation multiplier
        var totalValue: Decimal = 0
        var availableValue: Decimal = 0

        for benefit in overlapping {
            let multiplier = Decimal(period.aggregationMultiplier(for: benefit.frequency))
            let benefitTotal = benefit.effectiveValue * multiplier
            totalValue += benefitTotal

            if benefit.status == .available {
                availableValue += benefit.effectiveValue
            }
        }

        return PeriodMetrics(
            redeemedValue: historicalRedeemed,
            availableValue: availableValue,
            totalValue: totalValue,
            usedCount: used.count,
            availableCount: available.count,
            totalCount: overlapping.count
        )
    }
}

// MARK: - TimePeriodFilter

/// Represents time periods for the ValueBreakdown drill-down views.
/// Maps to the 3 rows in "By Time Period" section.
enum TimePeriodFilter: String, CaseIterable, Identifiable {
    var id: String { rawValue }

    case thisWeek       // 0-7 days remaining
    case thisMonth      // 8-30 days remaining
    case later          // 30+ days remaining

    /// Display title for navigation and headers
    var displayTitle: String {
        switch self {
        case .thisWeek: return "This Week"
        case .thisMonth: return "This Month"
        case .later: return "Later"
        }
    }

    /// Subtitle describing the time range
    var subtitle: String {
        switch self {
        case .thisWeek: return "Expires within 7 days"
        case .thisMonth: return "Expires within 8-30 days"
        case .later: return "Expires in 30+ days"
        }
    }

    /// Color for the period indicator
    var color: Color {
        switch self {
        case .thisWeek: return DesignSystem.Colors.danger
        case .thisMonth: return DesignSystem.Colors.warning
        case .later: return DesignSystem.Colors.success
        }
    }

    /// Icon name for the period
    var iconName: String {
        switch self {
        case .thisWeek: return "exclamationmark.circle.fill"
        case .thisMonth: return "clock.fill"
        case .later: return "calendar"
        }
    }

    /// Day range boundaries for this period
    var dayRange: ClosedRange<Int> {
        switch self {
        case .thisWeek: return 0...7
        case .thisMonth: return 8...30
        case .later: return 31...Int.max
        }
    }

    /// Checks if a benefit with given days remaining falls into this period
    /// - Parameter daysRemaining: Number of days until benefit expires
    /// - Returns: true if the benefit belongs to this period
    func contains(daysRemaining: Int) -> Bool {
        dayRange.contains(daysRemaining)
    }

    /// Determines which period a benefit belongs to based on days remaining
    static func from(daysRemaining: Int) -> TimePeriodFilter {
        switch daysRemaining {
        case ...7: return .thisWeek
        case 8...30: return .thisMonth
        default: return .later
        }
    }
}

// MARK: - BenefitCategory

/// Categorizes benefits by type for organization and filtering.
///
/// Consolidated to 7 categories based on user mental models and industry standards:
/// - `travel`: Flights, hotels, travel credits, CLEAR, miles
/// - `dining`: Restaurants, food delivery, reservations
/// - `transportation`: Rideshare, transit, car-related
/// - `shopping`: Retail, online shopping
/// - `entertainment`: Streaming, events, digital content
/// - `business`: Office, wireless, professional services
/// - `lifestyle`: Wellness, subscriptions, other perks
enum BenefitCategory: String, Codable, CaseIterable, Identifiable {
    var id: String { rawValue }

    case travel
    case dining
    case transportation
    case shopping
    case entertainment
    case business
    case lifestyle

    /// Human-readable display name
    var displayName: String {
        switch self {
        case .travel: return "Travel"
        case .dining: return "Dining"
        case .transportation: return "Transportation"
        case .shopping: return "Shopping"
        case .entertainment: return "Entertainment"
        case .business: return "Business"
        case .lifestyle: return "Lifestyle"
        }
    }

    /// Description of what this category includes
    var categoryDescription: String {
        switch self {
        case .travel: return "Flights, hotels, and travel expenses"
        case .dining: return "Restaurants, food delivery, and reservations"
        case .transportation: return "Rideshare, transit, and local travel"
        case .shopping: return "Retail stores and online purchases"
        case .entertainment: return "Streaming, events, and digital content"
        case .business: return "Office, wireless, and professional services"
        case .lifestyle: return "Wellness, subscriptions, and other perks"
        }
    }

    /// SF Symbol icon name for UI display
    var iconName: String {
        switch self {
        case .travel: return "airplane"
        case .dining: return "fork.knife"
        case .transportation: return "car.fill"
        case .shopping: return "bag.fill"
        case .entertainment: return "tv.fill"
        case .business: return "briefcase.fill"
        case .lifestyle: return "sparkles"
        }
    }

    // MARK: - Migration Support

    /// Custom decoder that handles migration from old category values.
    /// Maps deprecated categories to their new equivalents:
    /// - rideshare → transportation
    /// - streaming → entertainment
    /// - hotel, airline → travel
    /// - wellness, other → lifestyle
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let rawValue = try container.decode(String.self)

        // Try standard initialization first
        if let category = BenefitCategory(rawValue: rawValue) {
            self = category
            return
        }

        // Handle legacy category migration
        switch rawValue {
        case "rideshare":
            self = .transportation
        case "streaming":
            self = .entertainment
        case "hotel", "airline":
            self = .travel
        case "wellness", "other":
            self = .lifestyle
        default:
            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "Unknown category: \(rawValue)"
            )
        }
    }
}
