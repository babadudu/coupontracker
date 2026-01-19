// DisplayProtocols.swift
// CouponTracker
//
// Created: January 2026
// Purpose: Protocol definitions for display layer abstraction (ADR-001).
//          These protocols enable views to work with both SwiftData entities
//          and preview data types without coupling to concrete implementations.

import SwiftUI

// MARK: - Benefit Displayable Protocol

/// Protocol for types that can be displayed as benefits in the UI.
///
/// This protocol abstracts the display requirements for benefits, allowing
/// views to work with both SwiftData `Benefit` entities and `PreviewBenefit`
/// types used in SwiftUI previews.
protocol BenefitDisplayable: Identifiable, Hashable {
    var id: UUID { get }
    var name: String { get }
    var benefitDescription: String { get }
    var value: Decimal { get }
    var frequency: BenefitFrequency { get }
    var category: BenefitCategory { get }
    var status: BenefitStatus { get }
    var expirationDate: Date { get }
    var usedDate: Date? { get }
    var merchant: String? { get }

    /// Days remaining until expiration (negative if expired)
    var daysRemaining: Int { get }

    /// Whether this benefit is expiring soon (within 7 days)
    var isExpiringSoon: Bool { get }

    /// Whether this benefit is urgent (within 3 days)
    var isUrgent: Bool { get }

    /// Formatted value string (e.g., "$15")
    var formattedValue: String { get }

    /// Urgency display text (e.g., "3 days left", "Expires today")
    var urgencyText: String { get }
}

// MARK: - Default Implementations

extension BenefitDisplayable {
    var daysRemaining: Int {
        Calendar.current.dateComponents([.day], from: Date(), to: expirationDate).day ?? 0
    }

    var isExpiringSoon: Bool {
        daysRemaining >= 0 && daysRemaining <= 7
    }

    var isUrgent: Bool {
        daysRemaining >= 0 && daysRemaining <= 3
    }

    var formattedValue: String {
        Formatters.formatCurrencyWhole(value)
    }

    var urgencyText: String {
        switch daysRemaining {
        case ..<0:
            return "Expired"
        case 0:
            return "Expires today"
        case 1:
            return "1 day left"
        default:
            return "\(daysRemaining) days left"
        }
    }
}

// MARK: - Card Displayable Protocol

/// Protocol for types that can be displayed as cards in the UI.
///
/// This protocol abstracts the display requirements for cards, allowing
/// views to work with both SwiftData `UserCard` entities and `PreviewCard`
/// types used in SwiftUI previews.
protocol CardDisplayable: Identifiable, Hashable {
    associatedtype BenefitType: BenefitDisplayable

    var id: UUID { get }
    var name: String { get }
    var issuer: String { get }
    var nickname: String? { get }
    var gradient: DesignSystem.CardGradient { get }
    var benefits: [BenefitType] { get }

    /// Total available value across all benefits
    var totalAvailableValue: Decimal { get }

    /// Number of benefits expiring soon
    var expiringBenefitsCount: Int { get }

    /// Available benefits only
    var availableBenefits: [BenefitType] { get }

    /// Used benefits only
    var usedBenefits: [BenefitType] { get }

    /// Expired benefits only
    var expiredBenefits: [BenefitType] { get }

    /// Formatted total available value
    var formattedTotalValue: String { get }

    /// Display name (nickname if set, otherwise card name)
    var displayName: String { get }
}

// MARK: - Default Implementations

extension CardDisplayable {
    var totalAvailableValue: Decimal {
        benefits
            .filter { $0.status == .available }
            .reduce(0) { $0 + $1.value }
    }

    var expiringBenefitsCount: Int {
        benefits.filter { $0.isExpiringSoon && $0.status == .available }.count
    }

    var availableBenefits: [BenefitType] {
        benefits.filter { $0.status == .available }
    }

    var usedBenefits: [BenefitType] {
        benefits.filter { $0.status == .used }
    }

    var expiredBenefits: [BenefitType] {
        benefits.filter { $0.status == .expired }
    }

    var formattedTotalValue: String {
        Formatters.formatCurrencyWhole(totalAvailableValue)
    }

    var displayName: String {
        nickname ?? name
    }
}

// MARK: - Expiring Benefit Item Protocol

/// Protocol for items displayed in the expiring benefits list,
/// pairing a benefit with its parent card information.
protocol ExpiringBenefitDisplayable: Identifiable {
    associatedtype BenefitType: BenefitDisplayable
    associatedtype CardType: CardDisplayable

    var benefit: BenefitType { get }
    var card: CardType { get }
}
