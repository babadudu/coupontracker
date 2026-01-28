// NotificationExtensions.swift
// CouponTracker
//
// Extensions for Notification names and keys used for deep linking

import Foundation

// MARK: - Notification Names

extension Notification.Name {
    /// Posted when user taps notification to navigate to a specific benefit
    static let navigateToBenefit = Notification.Name("CouponTracker.navigateToBenefit")

    /// Posted when user taps "Mark Used" from notification action
    static let markBenefitUsed = Notification.Name("CouponTracker.markBenefitUsed")

    /// Posted when user taps "Snooze" from notification action
    static let snoozeBenefit = Notification.Name("CouponTracker.snoozeBenefit")

    /// Posted when user preferences are changed (appearance, notifications, etc.)
    static let userPreferencesChanged = Notification.Name("CouponTracker.userPreferencesChanged")
}

// MARK: - Notification UserInfo Keys

/// Keys used in notification userInfo dictionaries
enum NotificationUserInfoKey {
    /// Key for benefit UUID (value type: UUID)
    static let benefitId = "benefitId"

    /// Key for snooze duration in days (value type: Int)
    static let snoozeDays = "snoozeDays"

    /// Key for card UUID (value type: UUID)
    static let cardId = "cardId"
}
