// Subscription.swift
// CouponTracker
//
// Created: January 2026
// Purpose: SwiftData entity representing a recurring subscription.
//          Subscriptions track renewal dates, costs, and payment history.

import SwiftData
import Foundation

/// Represents a recurring subscription service.
///
/// Subscriptions can be linked to a credit card for tracking which card is used
/// for payment. They track renewal schedules, costs, and maintain payment history.
///
/// Relationships:
/// - Subscription -> UserCard: N:1 (nullify on delete)
/// - Subscription -> SubscriptionPayment: 1:N (cascade delete)
@Model
final class Subscription {

    // MARK: - Primary Key

    /// Unique identifier for the subscription
    @Attribute(.unique)
    var id: UUID = UUID()

    // MARK: - Relationships

    /// The card used for this subscription (optional)
    var userCard: UserCard?

    // MARK: - Template Reference

    /// Reference to subscription template if created from one
    var templateId: UUID?

    // MARK: - Core Properties

    /// Name of the subscription service
    var name: String = ""

    /// Optional description or notes about the subscription
    var subscriptionDescription: String?

    /// Price per billing period
    var price: Decimal = 0

    /// How often the subscription renews (stored as raw value for SwiftData)
    var frequencyRawValue: String = SubscriptionFrequency.monthly.rawValue

    /// Category for organization (stored as raw value for SwiftData)
    var categoryRawValue: String = SubscriptionCategory.other.rawValue

    /// Frequency accessor
    var frequency: SubscriptionFrequency {
        get { SubscriptionFrequency(rawValue: frequencyRawValue) ?? .monthly }
        set { frequencyRawValue = newValue.rawValue }
    }

    /// Category accessor
    var category: SubscriptionCategory {
        get { SubscriptionCategory(rawValue: categoryRawValue) ?? .other }
        set { categoryRawValue = newValue.rawValue }
    }

    // MARK: - Renewal Tracking

    /// When the subscription started
    var startDate: Date = Date()

    /// Next scheduled renewal date
    var nextRenewalDate: Date = Date()

    /// Whether the subscription is currently active
    var isActive: Bool = true

    // MARK: - Notification Settings

    /// Whether reminders are enabled for renewals
    var reminderEnabled: Bool = true

    /// Days before renewal to send reminder
    var reminderDaysBefore: Int = 7

    /// Last time a reminder was sent
    var lastReminderDate: Date?

    /// Scheduled notification identifier
    var scheduledNotificationId: String?

    // MARK: - Display Properties

    /// SF Symbol icon name for the subscription
    var iconName: String?

    /// Website URL for the subscription service
    var websiteUrl: String?

    /// User notes
    var notes: String?

    // MARK: - Denormalized Snapshots (Pattern 2)

    /// Snapshot of card name for display without lookup
    var cardNameSnapshot: String?

    // MARK: - Metadata

    /// Record creation timestamp
    var createdAt: Date = Date()

    /// Last modification timestamp
    var updatedAt: Date = Date()

    // MARK: - Relationships

    /// Payment history for this subscription
    @Relationship(deleteRule: .cascade, inverse: \SubscriptionPayment.subscription)
    var paymentHistory: [SubscriptionPayment] = []

    // MARK: - Initialization

    init(
        id: UUID = UUID(),
        userCard: UserCard? = nil,
        templateId: UUID? = nil,
        name: String = "",
        subscriptionDescription: String? = nil,
        price: Decimal = 0,
        frequency: SubscriptionFrequency? = nil,
        category: SubscriptionCategory? = nil,
        startDate: Date = Date(),
        nextRenewalDate: Date? = nil,
        isActive: Bool = true,
        reminderEnabled: Bool = true,
        reminderDaysBefore: Int = 7,
        iconName: String? = nil,
        websiteUrl: String? = nil,
        notes: String? = nil,
        cardNameSnapshot: String? = nil
    ) {
        self.id = id
        self.userCard = userCard
        self.templateId = templateId
        self.name = name
        self.subscriptionDescription = subscriptionDescription
        self.price = price
        if let frequency = frequency {
            self.frequencyRawValue = frequency.rawValue
        }
        if let category = category {
            self.categoryRawValue = category.rawValue
        }
        self.startDate = startDate
        self.nextRenewalDate = nextRenewalDate ?? startDate
        self.isActive = isActive
        self.reminderEnabled = reminderEnabled
        self.reminderDaysBefore = reminderDaysBefore
        self.iconName = iconName
        self.websiteUrl = websiteUrl
        self.notes = notes
        self.cardNameSnapshot = cardNameSnapshot
        self.createdAt = Date()
        self.updatedAt = Date()
    }

    // MARK: - Computed Properties

    /// Days until the next renewal
    var daysUntilRenewal: Int {
        let calendar = Calendar.current
        let components = calendar.dateComponents(
            [.day],
            from: calendar.startOfDay(for: Date()),
            to: calendar.startOfDay(for: nextRenewalDate)
        )
        return components.day ?? 0
    }

    /// Annualized cost based on frequency
    var annualizedCost: Decimal {
        frequency.annualizedCost(price: price)
    }

    /// Monthly cost (for comparison)
    var monthlyCost: Decimal {
        annualizedCost / 12
    }

    /// Whether renewal is coming soon (within reminder days)
    var isRenewingSoon: Bool {
        daysUntilRenewal <= reminderDaysBefore && isActive
    }

    /// Whether renewal is urgent (within 3 days)
    var isUrgent: Bool {
        daysUntilRenewal <= 3 && daysUntilRenewal >= 0 && isActive
    }

    /// Whether the subscription is past due (renewal date has passed)
    var isPastDue: Bool {
        nextRenewalDate < Date() && isActive
    }

    /// Formatted price with frequency label
    var formattedPrice: String {
        Formatters.formatCurrency(price) + frequency.shortLabel
    }

    /// Formatted annual cost
    var formattedAnnualCost: String {
        Formatters.formatCurrency(annualizedCost) + "/yr"
    }

    /// Total amount paid (sum of payment history)
    var totalPaid: Decimal {
        paymentHistory.reduce(Decimal.zero) { $0 + $1.amount }
    }

    /// Display icon name (custom or category default)
    var displayIconName: String {
        iconName ?? category.iconName
    }

    // MARK: - Methods

    /// Advance the subscription to the next renewal period
    func advanceToNextPeriod() {
        nextRenewalDate = frequency.nextRenewalDate(from: nextRenewalDate)
        lastReminderDate = nil
        scheduledNotificationId = nil
        updatedAt = Date()
    }

    /// Cancel the subscription
    func cancel() {
        isActive = false
        reminderEnabled = false
        scheduledNotificationId = nil
        updatedAt = Date()
    }

    /// Reactivate a cancelled subscription
    func reactivate(nextRenewal: Date? = nil) {
        isActive = true
        if let nextRenewal = nextRenewal {
            nextRenewalDate = nextRenewal
        }
        updatedAt = Date()
    }

    /// Update the card name snapshot when card changes
    func updateCardSnapshot(cardName: String?) {
        cardNameSnapshot = cardName
        updatedAt = Date()
    }

    /// Mark the subscription as updated
    func markAsUpdated() {
        updatedAt = Date()
    }
}

// MARK: - IdentifiableEntity Conformance

extension Subscription: IdentifiableEntity {}
