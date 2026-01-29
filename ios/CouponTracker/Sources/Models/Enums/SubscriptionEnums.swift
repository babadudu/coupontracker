// SubscriptionEnums.swift
// CouponTracker
//
// Created: January 2026
// Purpose: Data model enumerations for subscription tracking

import Foundation
import SwiftUI

// MARK: - SubscriptionFrequency

/// Represents how often a subscription renews and charges.
enum SubscriptionFrequency: String, Codable, CaseIterable, Identifiable {
    var id: String { rawValue }

    case weekly
    case monthly
    case quarterly
    case annual

    /// Human-readable display name
    var displayName: String {
        switch self {
        case .weekly: return "Weekly"
        case .monthly: return "Monthly"
        case .quarterly: return "Quarterly"
        case .annual: return "Annual"
        }
    }

    /// Short label for compact display
    var shortLabel: String {
        switch self {
        case .weekly: return "/wk"
        case .monthly: return "/mo"
        case .quarterly: return "/qtr"
        case .annual: return "/yr"
        }
    }

    /// Multiplier to calculate annual cost from per-period price
    var annualMultiplier: Int {
        switch self {
        case .weekly: return 52
        case .monthly: return 12
        case .quarterly: return 4
        case .annual: return 1
        }
    }

    /// Number of days in one period (approximate)
    var daysInPeriod: Int {
        switch self {
        case .weekly: return 7
        case .monthly: return 30
        case .quarterly: return 91
        case .annual: return 365
        }
    }

    /// Calculate the next renewal date from a given date
    /// - Parameter from: The starting date (usually current renewal date)
    /// - Returns: The next renewal date after adding one period
    func nextRenewalDate(from date: Date) -> Date {
        let calendar = Calendar.current
        switch self {
        case .weekly:
            return calendar.date(byAdding: .weekOfYear, value: 1, to: date) ?? date
        case .monthly:
            return calendar.date(byAdding: .month, value: 1, to: date) ?? date
        case .quarterly:
            return calendar.date(byAdding: .month, value: 3, to: date) ?? date
        case .annual:
            return calendar.date(byAdding: .year, value: 1, to: date) ?? date
        }
    }

    /// Calculate annualized cost from a per-period price
    /// - Parameter price: The price per billing period
    /// - Returns: The estimated annual cost
    func annualizedCost(price: Decimal) -> Decimal {
        price * Decimal(annualMultiplier)
    }
}

// MARK: - SubscriptionCategory

/// Categorizes subscriptions by type for organization and filtering.
///
/// 8 categories covering common subscription types:
/// - `streaming`: Video, music, podcast services
/// - `software`: Apps, productivity tools, cloud services
/// - `gaming`: Game subscriptions, gaming platforms
/// - `news`: News, magazines, publications
/// - `fitness`: Gym memberships, workout apps
/// - `utilities`: Phone, internet, storage plans
/// - `foodDelivery`: Meal kits, delivery services
/// - `other`: Miscellaneous subscriptions
enum SubscriptionCategory: String, Codable, CaseIterable, Identifiable {
    var id: String { rawValue }

    case streaming
    case software
    case gaming
    case news
    case fitness
    case utilities
    case foodDelivery
    case other

    /// Human-readable display name
    var displayName: String {
        switch self {
        case .streaming: return "Streaming"
        case .software: return "Software"
        case .gaming: return "Gaming"
        case .news: return "News & Media"
        case .fitness: return "Fitness"
        case .utilities: return "Utilities"
        case .foodDelivery: return "Food Delivery"
        case .other: return "Other"
        }
    }

    /// Description of what this category includes
    var categoryDescription: String {
        switch self {
        case .streaming: return "Video, music, and podcast services"
        case .software: return "Apps, productivity tools, and cloud services"
        case .gaming: return "Game subscriptions and gaming platforms"
        case .news: return "News, magazines, and publications"
        case .fitness: return "Gym memberships and workout apps"
        case .utilities: return "Phone, internet, and storage plans"
        case .foodDelivery: return "Meal kits and delivery services"
        case .other: return "Miscellaneous subscriptions"
        }
    }

    /// SF Symbol icon name for UI display
    var iconName: String {
        switch self {
        case .streaming: return "play.tv.fill"
        case .software: return "app.fill"
        case .gaming: return "gamecontroller.fill"
        case .news: return "newspaper.fill"
        case .fitness: return "figure.run"
        case .utilities: return "bolt.fill"
        case .foodDelivery: return "takeoutbag.and.cup.and.straw.fill"
        case .other: return "ellipsis.circle.fill"
        }
    }

    /// Color for category display
    var color: Color {
        switch self {
        case .streaming: return .purple
        case .software: return .blue
        case .gaming: return .green
        case .news: return .orange
        case .fitness: return .red
        case .utilities: return .yellow
        case .foodDelivery: return .pink
        case .other: return .gray
        }
    }
}
