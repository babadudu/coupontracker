// Benefit.swift
// CouponTracker
//
// Created: January 2026
// Purpose: SwiftData entity representing an individual trackable benefit/reward.
//          Benefits belong to a card and track usage across periods.

import SwiftData
import Foundation

/// Represents an individual trackable benefit/reward.
///
/// Benefits are the core tracking unit in CouponTracker.
/// Each benefit has a status, period dates, and notification settings.
///
/// Relationships:
/// - Benefit -> UserCard: N:1
/// - Benefit -> BenefitUsage: 1:N (cascade delete)
@Model
final class Benefit {

    // MARK: - Primary Key

    /// Unique identifier for the benefit
    @Attribute(.unique)
    var id: UUID

    // MARK: - Relationships

    /// The card this benefit belongs to
    var userCard: UserCard?

    // MARK: - Template Reference

    /// Reference to BenefitTemplate.id for template-based benefits.
    /// nil for custom benefits.
    var templateBenefitId: UUID?

    // MARK: - Custom/Override Values

    /// Overrides template name
    var customName: String?

    /// Overrides template value
    var customValue: Decimal?

    /// Overrides template description
    var customDescription: String?

    /// Overrides template frequency
    var customFrequency: BenefitFrequency?

    /// Overrides template category
    var customCategory: BenefitCategory?

    // MARK: - Tracking State

    /// Current status of the benefit
    var status: BenefitStatus

    /// Start of current benefit period
    var currentPeriodStart: Date

    /// End of current benefit period (expiration date)
    var currentPeriodEnd: Date

    /// When the benefit will reset to a new period
    var nextResetDate: Date

    // MARK: - Notification Settings

    /// Whether reminders are enabled for this benefit
    var reminderEnabled: Bool

    /// Days before expiration to send reminder (default: 7)
    var reminderDaysBefore: Int

    /// Last time a reminder was sent (for follow-up logic)
    var lastReminderDate: Date?

    /// Scheduled notification identifier
    var scheduledNotificationId: String?

    // MARK: - Metadata

    /// Record creation timestamp
    var createdAt: Date

    /// Last modification timestamp
    var updatedAt: Date

    // MARK: - Relationships

    /// Usage history for this benefit
    @Relationship(deleteRule: .cascade, inverse: \BenefitUsage.benefit)
    var usageHistory: [BenefitUsage] = []

    // MARK: - Initialization

    init(
        id: UUID = UUID(),
        userCard: UserCard? = nil,
        templateBenefitId: UUID? = nil,
        customName: String? = nil,
        customValue: Decimal? = nil,
        status: BenefitStatus = .available,
        currentPeriodStart: Date,
        currentPeriodEnd: Date,
        nextResetDate: Date? = nil,
        reminderEnabled: Bool = true,
        reminderDaysBefore: Int = 7
    ) {
        self.id = id
        self.userCard = userCard
        self.templateBenefitId = templateBenefitId
        self.customName = customName
        self.customValue = customValue
        self.status = status
        self.currentPeriodStart = currentPeriodStart
        self.currentPeriodEnd = currentPeriodEnd
        self.nextResetDate = nextResetDate ?? currentPeriodEnd
        self.reminderEnabled = reminderEnabled
        self.reminderDaysBefore = reminderDaysBefore
        self.createdAt = Date()
        self.updatedAt = Date()
    }

    // MARK: - Computed Properties

    /// Effective name (custom override or empty - requires template lookup)
    var effectiveName: String {
        customName ?? ""
    }

    /// Effective value (custom override or zero - requires template lookup)
    var effectiveValue: Decimal {
        customValue ?? Decimal.zero
    }

    /// Days until benefit expires
    var daysUntilExpiration: Int {
        let calendar = Calendar.current
        let components = calendar.dateComponents(
            [.day],
            from: calendar.startOfDay(for: Date()),
            to: calendar.startOfDay(for: currentPeriodEnd)
        )
        return max(0, components.day ?? 0)
    }

    /// Whether benefit is expiring soon (within 7 days)
    var isExpiringSoon: Bool {
        daysUntilExpiration <= 7 && status == .available
    }

    /// Whether benefit is urgent (expiring within 3 days)
    var isUrgent: Bool {
        daysUntilExpiration <= 3 && status == .available
    }

    /// Whether benefit period has expired
    var isPeriodExpired: Bool {
        Date() > currentPeriodEnd
    }

    /// Whether benefit needs to be reset to new period
    var needsReset: Bool {
        Date() >= nextResetDate
    }

    /// Formatted value string
    var formattedValue: String { Formatters.formatCurrency(effectiveValue) }

    /// Effective frequency (custom or defaults to monthly)
    var frequency: BenefitFrequency {
        customFrequency ?? .monthly
    }

    /// Effective category (custom or defaults to lifestyle)
    var category: BenefitCategory {
        customCategory ?? .lifestyle
    }

    // MARK: - Methods

    /// Mark the benefit as used
    func markAsUsed() {
        guard status == .available else { return }
        status = .used
        updatedAt = Date()
    }

    /// Mark the benefit as expired
    func markAsExpired() {
        guard status == .available else { return }
        status = .expired
        updatedAt = Date()
    }

    /// Reset benefit to a new period
    func resetToNewPeriod(
        periodStart: Date,
        periodEnd: Date,
        nextReset: Date
    ) {
        status = .available
        currentPeriodStart = periodStart
        currentPeriodEnd = periodEnd
        nextResetDate = nextReset
        lastReminderDate = nil
        scheduledNotificationId = nil
        updatedAt = Date()
    }

    /// Undo marking as used (if within grace period or correction needed)
    func undoMarkAsUsed() {
        guard status == .used else { return }
        status = .available
        updatedAt = Date()
    }
}

// MARK: - IdentifiableEntity Conformance

extension Benefit: IdentifiableEntity {}
