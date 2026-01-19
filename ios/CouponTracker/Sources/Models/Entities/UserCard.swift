// UserCard.swift
// CouponTracker
//
// Created: January 2026
// Purpose: SwiftData entity representing a credit card in the user's wallet.
//          Cards can be created from templates or as custom cards.

import SwiftData
import Foundation

/// Represents a credit card in the user's wallet.
///
/// Cards can be created from pre-defined templates or as custom cards.
/// Each card has associated benefits that are tracked for usage.
///
/// Relationships:
/// - UserCard -> Benefit: 1:N (cascade delete)
@Model
final class UserCard {

    // MARK: - Primary Key

    /// Unique identifier for the card
    @Attribute(.unique)
    var id: UUID

    // MARK: - Template Reference

    /// Reference to CardTemplate.id for pre-populated cards.
    /// nil for custom cards.
    var cardTemplateId: UUID?

    // MARK: - User Customization

    /// User-defined nickname (e.g., "Personal", "Business")
    var nickname: String?

    // MARK: - Custom Card Properties

    /// True if this is a user-created custom card
    var isCustom: Bool

    /// Name for custom cards (ignored if isCustom = false)
    var customName: String?

    /// Issuer for custom cards
    var customIssuer: String?

    /// Hex color for custom card gradient (e.g., "#1a1a2e")
    var customColorHex: String?

    // MARK: - Metadata

    /// Date card was added to wallet
    var addedDate: Date

    /// Sort order in wallet view (lower = first)
    var sortOrder: Int

    /// Record creation timestamp
    var createdAt: Date

    /// Last modification timestamp
    var updatedAt: Date

    // MARK: - Relationships

    /// Benefits associated with this card
    @Relationship(deleteRule: .cascade, inverse: \Benefit.userCard)
    var benefits: [Benefit] = []

    // MARK: - Initialization

    init(
        id: UUID = UUID(),
        cardTemplateId: UUID? = nil,
        nickname: String? = nil,
        isCustom: Bool = false,
        customName: String? = nil,
        customIssuer: String? = nil,
        customColorHex: String? = nil,
        sortOrder: Int = 0
    ) {
        self.id = id
        self.cardTemplateId = cardTemplateId
        self.nickname = nickname
        self.isCustom = isCustom
        self.customName = customName
        self.customIssuer = customIssuer
        self.customColorHex = customColorHex
        self.sortOrder = sortOrder
        self.addedDate = Date()
        self.createdAt = Date()
        self.updatedAt = Date()
    }

    // MARK: - Computed Properties

    /// Returns the display name for this card.
    /// Priority: nickname > customName > (requires template lookup)
    func displayName(templateName: String? = nil) -> String {
        if let nickname = nickname, !nickname.isEmpty {
            return nickname
        }
        if isCustom, let customName = customName, !customName.isEmpty {
            return customName
        }
        return templateName ?? "Unknown Card"
    }

    /// Returns the issuer name.
    func issuerName(templateIssuer: String? = nil) -> String {
        if isCustom {
            return customIssuer ?? ""
        }
        return templateIssuer ?? ""
    }

    /// Total available value across all benefits
    var totalAvailableValue: Decimal {
        benefits
            .filter { $0.status == .available }
            .reduce(Decimal.zero) { $0 + $1.effectiveValue }
    }

    /// Count of benefits expiring within specified days
    func expiringCount(withinDays days: Int) -> Int {
        let threshold = Calendar.current.date(
            byAdding: .day,
            value: days,
            to: Date()
        ) ?? Date()

        return benefits.filter { benefit in
            benefit.status == .available &&
            benefit.currentPeriodEnd <= threshold
        }.count
    }

    /// Whether this card has any urgent benefits (expiring within 3 days)
    var hasUrgentBenefits: Bool {
        benefits.contains { $0.isUrgent }
    }

    /// Whether this card has any benefits expiring soon (within 7 days)
    var hasExpiringSoonBenefits: Bool {
        benefits.contains { $0.isExpiringSoon }
    }

    // MARK: - Methods

    /// Updates the timestamp when card is modified
    func markAsUpdated() {
        updatedAt = Date()
    }
}

// MARK: - IdentifiableEntity Conformance

extension UserCard: IdentifiableEntity {}
