// Coupon.swift
// CouponTracker
//
// Created: January 2026
// Purpose: SwiftData entity representing a standalone coupon or discount code.
//          Coupons are independent of cards and track expiration and usage.

import SwiftData
import Foundation

/// Represents a standalone coupon or discount code.
///
/// Coupons are not linked to credit cards - they're general purpose
/// discount codes, vouchers, or coupons that users want to track.
///
/// Relationships: None (standalone entity)
@Model
final class Coupon {

    // MARK: - Primary Key

    /// Unique identifier for the coupon
    @Attribute(.unique)
    var id: UUID = UUID()

    // MARK: - Core Properties

    /// Name or title of the coupon
    var name: String = ""

    /// Optional description of the coupon
    var couponDescription: String?

    /// When the coupon expires
    var expirationDate: Date = Date()

    /// Category for organization (stored as raw value for SwiftData)
    var categoryRawValue: String = CouponCategory.other.rawValue

    /// Category accessor
    var category: CouponCategory {
        get { CouponCategory(rawValue: categoryRawValue) ?? .other }
        set { categoryRawValue = newValue.rawValue }
    }

    /// Monetary value of the coupon (if applicable)
    var value: Decimal?

    /// Merchant or store the coupon is for
    var merchant: String?

    /// Coupon code (if applicable)
    var code: String?

    // MARK: - Usage Tracking

    /// Whether the coupon has been used
    var isUsed: Bool = false

    /// When the coupon was used
    var usedDate: Date?

    // MARK: - Notification Settings

    /// Whether reminders are enabled for expiration
    var reminderEnabled: Bool = true

    /// Days before expiration to send reminder
    var reminderDaysBefore: Int = 3

    /// Last time a reminder was sent
    var lastReminderDate: Date?

    /// Scheduled notification identifier
    var scheduledNotificationId: String?

    // MARK: - Additional Info

    /// User notes
    var notes: String?

    // MARK: - Metadata

    /// Record creation timestamp
    var createdAt: Date = Date()

    /// Last modification timestamp
    var updatedAt: Date = Date()

    // MARK: - Initialization

    init(
        id: UUID = UUID(),
        name: String = "",
        couponDescription: String? = nil,
        expirationDate: Date = Date(),
        category: CouponCategory? = nil,
        value: Decimal? = nil,
        merchant: String? = nil,
        code: String? = nil,
        isUsed: Bool = false,
        usedDate: Date? = nil,
        reminderEnabled: Bool = true,
        reminderDaysBefore: Int = 3,
        notes: String? = nil
    ) {
        self.id = id
        self.name = name
        self.couponDescription = couponDescription
        self.expirationDate = expirationDate
        if let category = category {
            self.categoryRawValue = category.rawValue
        }
        self.value = value
        self.merchant = merchant
        self.code = code
        self.isUsed = isUsed
        self.usedDate = usedDate
        self.reminderEnabled = reminderEnabled
        self.reminderDaysBefore = reminderDaysBefore
        self.notes = notes
        self.createdAt = Date()
        self.updatedAt = Date()
    }

    // MARK: - Computed Properties

    /// Days until the coupon expires
    var daysUntilExpiration: Int {
        let calendar = Calendar.current
        let components = calendar.dateComponents(
            [.day],
            from: calendar.startOfDay(for: Date()),
            to: calendar.startOfDay(for: expirationDate)
        )
        return components.day ?? 0
    }

    /// Whether coupon is expiring soon (within reminder days)
    var isExpiringSoon: Bool {
        daysUntilExpiration <= reminderDaysBefore && !isUsed && !isExpired
    }

    /// Whether coupon is urgent (expiring within 1 day)
    var isUrgent: Bool {
        daysUntilExpiration <= 1 && daysUntilExpiration >= 0 && !isUsed
    }

    /// Whether the coupon has expired
    var isExpired: Bool {
        expirationDate < Date() && !isUsed
    }

    /// Whether the coupon is still valid (not used and not expired)
    var isValid: Bool {
        !isUsed && !isExpired
    }

    /// Formatted value string (if value exists)
    var formattedValue: String? {
        guard let value = value else { return nil }
        return Formatters.formatCurrency(value)
    }

    /// Formatted expiration date
    var formattedExpirationDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: expirationDate)
    }

    /// Display subtitle (merchant or category)
    var displaySubtitle: String {
        merchant ?? category.displayName
    }

    /// Status text for display
    var statusText: String {
        if isUsed {
            return "Used"
        } else if isExpired {
            return "Expired"
        } else if isUrgent {
            return "Expires today!"
        } else if isExpiringSoon {
            return "Expires in \(daysUntilExpiration) days"
        } else {
            return "Valid"
        }
    }

    // MARK: - Methods

    /// Mark the coupon as used
    func markAsUsed() {
        guard !isUsed else { return }
        isUsed = true
        usedDate = Date()
        reminderEnabled = false
        scheduledNotificationId = nil
        updatedAt = Date()
    }

    /// Undo marking as used
    func undoMarkAsUsed() {
        guard isUsed else { return }
        isUsed = false
        usedDate = nil
        updatedAt = Date()
    }

    /// Update the expiration date
    func updateExpiration(_ newDate: Date) {
        expirationDate = newDate
        lastReminderDate = nil
        scheduledNotificationId = nil
        updatedAt = Date()
    }

    /// Mark the coupon as updated
    func markAsUpdated() {
        updatedAt = Date()
    }
}

// MARK: - IdentifiableEntity Conformance

extension Coupon: IdentifiableEntity {}
