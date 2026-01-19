// BenefitUsage.swift
// CouponTracker
//
// Created: January 2026
// Purpose: SwiftData entity representing a historical record of benefit redemption.
//          Preserves history even when benefits or cards are deleted.

import SwiftData
import Foundation

/// Historical record of benefit redemptions.
///
/// BenefitUsage records track when and how benefits were used.
/// These records are preserved for reporting and statistics.
///
/// Relationships:
/// - BenefitUsage -> Benefit: N:1
@Model
final class BenefitUsage {

    // MARK: - Primary Key

    /// Unique identifier for this usage record
    @Attribute(.unique)
    var id: UUID

    // MARK: - Relationships

    /// The benefit this usage belongs to (may be nil if benefit was deleted)
    var benefit: Benefit?

    // MARK: - Usage Details

    /// When the benefit was marked as used
    var usedDate: Date

    /// Period start for which this usage applies
    var periodStart: Date

    /// Period end for which this usage applies
    var periodEnd: Date

    /// Value that was redeemed
    var valueRedeemed: Decimal

    /// Optional user notes
    var notes: String?

    /// Was this an auto-expiration (vs manual mark as used)
    var wasAutoExpired: Bool

    // MARK: - Denormalized Data (for history display)

    /// Card name at time of usage (preserved if card is later deleted)
    var cardNameSnapshot: String?

    /// Benefit name at time of usage (preserved if benefit data changes)
    var benefitNameSnapshot: String?

    /// Card ID at time of usage (for reference even after deletion)
    var cardIdSnapshot: UUID?

    // MARK: - Metadata

    /// Record creation timestamp
    var createdAt: Date

    // MARK: - Initialization

    init(
        id: UUID = UUID(),
        benefit: Benefit? = nil,
        usedDate: Date = Date(),
        periodStart: Date,
        periodEnd: Date,
        valueRedeemed: Decimal,
        notes: String? = nil,
        wasAutoExpired: Bool = false,
        cardNameSnapshot: String? = nil,
        benefitNameSnapshot: String? = nil,
        cardIdSnapshot: UUID? = nil
    ) {
        self.id = id
        self.benefit = benefit
        self.usedDate = usedDate
        self.periodStart = periodStart
        self.periodEnd = periodEnd
        self.valueRedeemed = valueRedeemed
        self.notes = notes
        self.wasAutoExpired = wasAutoExpired
        self.cardNameSnapshot = cardNameSnapshot
        self.benefitNameSnapshot = benefitNameSnapshot
        self.cardIdSnapshot = cardIdSnapshot
        self.createdAt = Date()
    }

    // MARK: - Computed Properties

    /// Formatted value string
    var formattedValue: String { Formatters.formatCurrency(valueRedeemed) }

    /// Human-readable period description
    var periodDescription: String {
        "\(Formatters.mediumDate.string(from: periodStart)) - \(Formatters.mediumDate.string(from: periodEnd))"
    }

    /// Display name for the benefit (uses snapshot or live data)
    var displayBenefitName: String {
        benefitNameSnapshot ?? benefit?.effectiveName ?? "Unknown Benefit"
    }

    /// Display name for the card (uses snapshot or live data)
    var displayCardName: String {
        cardNameSnapshot ?? benefit?.userCard?.displayName() ?? "Unknown Card"
    }
}

// MARK: - IdentifiableEntity Conformance

extension BenefitUsage: IdentifiableEntity {}

// MARK: - Factory Methods

extension BenefitUsage {

    /// Creates a usage record for when a benefit is marked as used
    static func createForUsage(
        benefit: Benefit,
        cardName: String,
        benefitName: String,
        value: Decimal
    ) -> BenefitUsage {
        BenefitUsage(
            benefit: benefit,
            usedDate: Date(),
            periodStart: benefit.currentPeriodStart,
            periodEnd: benefit.currentPeriodEnd,
            valueRedeemed: value,
            wasAutoExpired: false,
            cardNameSnapshot: cardName,
            benefitNameSnapshot: benefitName,
            cardIdSnapshot: benefit.userCard?.id
        )
    }

    /// Creates a usage record for when a benefit auto-expires
    static func createForExpiration(
        benefit: Benefit,
        cardName: String,
        benefitName: String,
        value: Decimal
    ) -> BenefitUsage {
        BenefitUsage(
            benefit: benefit,
            usedDate: Date(),
            periodStart: benefit.currentPeriodStart,
            periodEnd: benefit.currentPeriodEnd,
            valueRedeemed: value,
            wasAutoExpired: true,
            cardNameSnapshot: cardName,
            benefitNameSnapshot: benefitName,
            cardIdSnapshot: benefit.userCard?.id
        )
    }
}
