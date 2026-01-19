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
                    periodStart = calendar.date(byAdding: .month, value: -1, to: calendar.date(from: startComponents)!)!
                }

                periodEnd = calendar.date(byAdding: .month, value: 1, to: periodStart)!
            } else {
                // Use calendar month
                let components = calendar.dateComponents([.year, .month], from: today)
                periodStart = calendar.date(from: components)!
                periodEnd = calendar.date(byAdding: .month, value: 1, to: periodStart)!
            }

            let nextReset = periodEnd
            return (periodStart, calendar.date(byAdding: .day, value: -1, to: periodEnd)!, nextReset)

        case .quarterly:
            // Quarters: Jan-Mar, Apr-Jun, Jul-Sep, Oct-Dec
            let month = calendar.component(.month, from: today)
            let quarterStartMonth = ((month - 1) / 3) * 3 + 1

            var startComponents = calendar.dateComponents([.year], from: today)
            startComponents.month = quarterStartMonth
            startComponents.day = 1

            let periodStart = calendar.date(from: startComponents)!
            let periodEnd = calendar.date(byAdding: .month, value: 3, to: periodStart)!
            let nextReset = periodEnd

            return (periodStart, calendar.date(byAdding: .day, value: -1, to: periodEnd)!, nextReset)

        case .semiAnnual:
            // Semi-annual: Jan-Jun, Jul-Dec
            let month = calendar.component(.month, from: today)
            let halfStartMonth = month <= 6 ? 1 : 7

            var startComponents = calendar.dateComponents([.year], from: today)
            startComponents.month = halfStartMonth
            startComponents.day = 1

            let periodStart = calendar.date(from: startComponents)!
            let periodEnd = calendar.date(byAdding: .month, value: 6, to: periodStart)!
            let nextReset = periodEnd

            return (periodStart, calendar.date(byAdding: .day, value: -1, to: periodEnd)!, nextReset)

        case .annual:
            // Calendar year: Jan 1 - Dec 31
            let year = calendar.component(.year, from: today)
            var startComponents = DateComponents()
            startComponents.year = year
            startComponents.month = 1
            startComponents.day = 1

            let periodStart = calendar.date(from: startComponents)!
            let periodEnd = calendar.date(byAdding: .year, value: 1, to: periodStart)!
            let nextReset = periodEnd

            return (periodStart, calendar.date(byAdding: .day, value: -1, to: periodEnd)!, nextReset)
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
            let start = calendar.date(from: components)!
            let end = calendar.date(byAdding: DateComponents(month: 1, day: -1), to: start)!
            return (start, end)

        case .quarterly:
            let month = calendar.component(.month, from: date)
            let quarterStartMonth = ((month - 1) / 3) * 3 + 1
            var startComponents = DateComponents()
            startComponents.year = year
            startComponents.month = quarterStartMonth
            startComponents.day = 1
            let start = calendar.date(from: startComponents)!
            let end = calendar.date(byAdding: DateComponents(month: 3, day: -1), to: start)!
            return (start, end)

        case .semiAnnual:
            let month = calendar.component(.month, from: date)
            let halfStartMonth = month <= 6 ? 1 : 7
            var startComponents = DateComponents()
            startComponents.year = year
            startComponents.month = halfStartMonth
            startComponents.day = 1
            let start = calendar.date(from: startComponents)!
            let end = calendar.date(byAdding: DateComponents(month: 6, day: -1), to: start)!
            return (start, end)

        case .annual:
            var startComponents = DateComponents()
            startComponents.year = year
            startComponents.month = 1
            startComponents.day = 1
            let start = calendar.date(from: startComponents)!
            let end = calendar.date(byAdding: DateComponents(year: 1, day: -1), to: start)!
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
