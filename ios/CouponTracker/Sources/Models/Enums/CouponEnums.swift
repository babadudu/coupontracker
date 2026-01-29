// CouponEnums.swift
// CouponTracker
//
// Created: January 2026
// Purpose: Data model enumerations for coupon tracking

import Foundation
import SwiftUI

// MARK: - CouponCategory

/// Categorizes coupons by type for organization and filtering.
///
/// 7 categories covering common coupon types:
/// - `dining`: Restaurants, cafes, food establishments
/// - `shopping`: Retail stores, online shopping
/// - `travel`: Hotels, flights, travel services
/// - `entertainment`: Movies, events, attractions
/// - `services`: Professional services, repairs
/// - `grocery`: Supermarkets, grocery stores
/// - `other`: Miscellaneous coupons
enum CouponCategory: String, Codable, CaseIterable, Identifiable {
    var id: String { rawValue }

    case dining
    case shopping
    case travel
    case entertainment
    case services
    case grocery
    case other

    /// Human-readable display name
    var displayName: String {
        switch self {
        case .dining: return "Dining"
        case .shopping: return "Shopping"
        case .travel: return "Travel"
        case .entertainment: return "Entertainment"
        case .services: return "Services"
        case .grocery: return "Grocery"
        case .other: return "Other"
        }
    }

    /// Description of what this category includes
    var categoryDescription: String {
        switch self {
        case .dining: return "Restaurants, cafes, and food establishments"
        case .shopping: return "Retail stores and online shopping"
        case .travel: return "Hotels, flights, and travel services"
        case .entertainment: return "Movies, events, and attractions"
        case .services: return "Professional services and repairs"
        case .grocery: return "Supermarkets and grocery stores"
        case .other: return "Miscellaneous coupons"
        }
    }

    /// SF Symbol icon name for UI display
    var iconName: String {
        switch self {
        case .dining: return "fork.knife"
        case .shopping: return "bag.fill"
        case .travel: return "airplane"
        case .entertainment: return "ticket.fill"
        case .services: return "wrench.and.screwdriver.fill"
        case .grocery: return "cart.fill"
        case .other: return "tag.fill"
        }
    }

    /// Color for category display
    var color: Color {
        switch self {
        case .dining: return .orange
        case .shopping: return .purple
        case .travel: return .blue
        case .entertainment: return .pink
        case .services: return .brown
        case .grocery: return .green
        case .other: return .gray
        }
    }
}
