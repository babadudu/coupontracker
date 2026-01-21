//
//  BenefitExtensions.swift
//  CouponTracker
//
//  Created: January 2026
//  Purpose: Array extensions for filtering and aggregating benefits.
//           Consolidates duplicate filtering patterns across ViewModels and Views.
//

import Foundation

// MARK: - Array Extensions for Benefit Filtering

extension Array where Element: BenefitDisplayable {

    /// Returns only available benefits
    var availableBenefits: [Element] {
        filter { $0.status == .available }
    }

    /// Returns only used benefits
    var usedBenefits: [Element] {
        filter { $0.status == .used }
    }

    /// Returns only expired benefits
    var expiredBenefits: [Element] {
        filter { $0.status == .expired }
    }

    /// Returns benefits expiring within the specified number of days
    func expiring(within days: Int) -> [Element] {
        filter { $0.status == .available && $0.daysRemaining <= days }
    }

    /// Total value of all elements
    var totalValue: Decimal {
        reduce(Decimal.zero) { $0 + $1.value }
    }

    /// Total value of available benefits only
    var totalAvailableValue: Decimal {
        availableBenefits.totalValue
    }

    /// Total value of used benefits only
    var totalUsedValue: Decimal {
        usedBenefits.totalValue
    }
}

// MARK: - Array Extensions for Benefit Entities

extension Array where Element == Benefit {

    /// Returns only available benefits
    var availableBenefits: [Benefit] {
        filter { $0.status == .available }
    }

    /// Returns only used benefits
    var usedBenefits: [Benefit] {
        filter { $0.status == .used }
    }

    /// Returns only expired benefits
    var expiredBenefits: [Benefit] {
        filter { $0.status == .expired }
    }

    /// Returns benefits expiring within the specified number of days
    func expiring(within days: Int) -> [Benefit] {
        filter { $0.status == .available && $0.daysUntilExpiration <= days }
    }

    /// Total effective value of all elements
    var totalEffectiveValue: Decimal {
        reduce(Decimal.zero) { $0 + $1.effectiveValue }
    }

    /// Total effective value of available benefits only
    var totalAvailableValue: Decimal {
        availableBenefits.totalEffectiveValue
    }

    /// Total effective value of used benefits only
    var totalUsedValue: Decimal {
        usedBenefits.totalEffectiveValue
    }
}

// MARK: - Sequence Extensions for Data Grouping

extension Sequence {
    /// Groups elements by a key path into a dictionary
    /// - Parameter keyPath: The key path to group by
    /// - Returns: Dictionary with keys from the key path and arrays of grouped elements
    func grouped<Key: Hashable>(by keyPath: KeyPath<Element, Key>) -> [Key: [Element]] {
        Dictionary(grouping: self, by: { $0[keyPath: keyPath] })
    }
}

// MARK: - Monetary Value Protocol

protocol HasMonetaryValue {
    var monetaryValue: Decimal { get }
}

extension Sequence where Element: HasMonetaryValue {
    var totalMonetaryValue: Decimal {
        reduce(.zero) { $0 + $1.monetaryValue }
    }

    func totalMonetaryValue(where predicate: (Element) -> Bool) -> Decimal {
        filter(predicate).totalMonetaryValue
    }
}
