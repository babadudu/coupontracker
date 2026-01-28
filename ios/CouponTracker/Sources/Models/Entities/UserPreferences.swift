// UserPreferences.swift
// CouponTracker
//
// Created: January 2026
// Purpose: SwiftData entity for user settings and preferences.
//          Uses singleton pattern with fixed ID for single record.

import SwiftData
import Foundation

/// User settings and preferences.
///
/// This entity uses a singleton pattern - there is only one record
/// per user/device. The id field is fixed to ensure uniqueness.
///
/// Preferences include notification settings, quiet hours, and app state.
@Model
final class UserPreferences {

    // MARK: - Singleton Key

    /// Fixed identifier for singleton pattern
    @Attribute(.unique)
    var id: String = "user_preferences"

    // MARK: - Notification Preferences

    /// Master toggle for all notifications
    var notificationsEnabled: Bool

    /// Preferred time for notifications (hour component, 0-23)
    var preferredReminderHour: Int

    /// Preferred time for notifications (minute component, 0-59)
    var preferredReminderMinute: Int

    /// Default reminder lead time in days
    var defaultReminderDays: Int

    /// Whether to notify 1 day before expiration (default: ON)
    var notify1DayBefore: Bool = true

    /// Whether to notify 3 days before expiration (default: ON)
    var notify3DaysBefore: Bool = true

    /// Whether to notify 1 week before expiration (default: OFF)
    var notify1WeekBefore: Bool = false

    // MARK: - Quiet Hours

    /// Whether quiet hours are enabled
    var quietHoursEnabled: Bool

    /// Quiet hours start (hour, 0-23)
    var quietHoursStart: Int

    /// Quiet hours end (hour, 0-23)
    var quietHoursEnd: Int

    // MARK: - App State

    /// Whether user has completed onboarding
    var hasCompletedOnboarding: Bool

    /// Last sync date (for future cloud sync)
    var lastSyncDate: Date?

    /// App version when preferences were last updated
    var appVersion: String?

    // MARK: - Display Preferences

    /// Whether to show benefit values on card
    var showBenefitValues: Bool

    /// Whether to sort cards by urgency
    var sortCardsByUrgency: Bool

    /// Appearance mode (system, light, dark) - raw storage
    var appearanceModeRaw: String = AppearanceMode.system.rawValue

    /// Appearance mode preference
    var appearanceMode: AppearanceMode {
        get { AppearanceMode(rawValue: appearanceModeRaw) ?? .system }
        set { appearanceModeRaw = newValue.rawValue }
    }

    // MARK: - Metadata

    /// Last modification timestamp
    var updatedAt: Date

    // MARK: - Initialization

    init() {
        self.notificationsEnabled = true
        self.preferredReminderHour = 9
        self.preferredReminderMinute = 0
        self.defaultReminderDays = 7
        self.notify1DayBefore = true
        self.notify3DaysBefore = true
        self.notify1WeekBefore = false
        self.quietHoursEnabled = false
        self.quietHoursStart = 22
        self.quietHoursEnd = 8
        self.hasCompletedOnboarding = false
        self.showBenefitValues = true
        self.sortCardsByUrgency = true
        self.updatedAt = Date()
    }

    // MARK: - Computed Properties

    /// Preferred reminder time as DateComponents
    var preferredReminderTime: DateComponents {
        var components = DateComponents()
        components.hour = preferredReminderHour
        components.minute = preferredReminderMinute
        return components
    }

    /// Quiet hours start time as DateComponents
    var quietHoursStartTime: DateComponents {
        var components = DateComponents()
        components.hour = quietHoursStart
        return components
    }

    /// Quiet hours end time as DateComponents
    var quietHoursEndTime: DateComponents {
        var components = DateComponents()
        components.hour = quietHoursEnd
        return components
    }

    /// Whether we are currently in quiet hours
    var isInQuietHours: Bool {
        guard quietHoursEnabled else { return false }

        let calendar = Calendar.current
        let now = Date()
        let currentHour = calendar.component(.hour, from: now)

        // Handle overnight quiet hours (e.g., 22:00 to 08:00)
        if quietHoursStart > quietHoursEnd {
            return currentHour >= quietHoursStart || currentHour < quietHoursEnd
        } else {
            return currentHour >= quietHoursStart && currentHour < quietHoursEnd
        }
    }

    // MARK: - Methods

    /// Updates the timestamp when preferences are modified
    func markAsUpdated() {
        updatedAt = Date()
    }

    /// Sets the preferred reminder time
    func setPreferredReminderTime(hour: Int, minute: Int) {
        guard (0...23).contains(hour) else { return }
        guard (0...59).contains(minute) else { return }

        preferredReminderHour = hour
        preferredReminderMinute = minute
        markAsUpdated()
    }

    /// Sets the quiet hours range
    func setQuietHours(start: Int, end: Int) {
        guard (0...23).contains(start) else { return }
        guard (0...23).contains(end) else { return }

        quietHoursStart = start
        quietHoursEnd = end
        markAsUpdated()
    }

    /// Marks onboarding as completed
    func completeOnboarding() {
        hasCompletedOnboarding = true
        markAsUpdated()
    }
}

// MARK: - Default Values

extension UserPreferences {

    /// Creates preferences with default values
    static func defaultPreferences() -> UserPreferences {
        UserPreferences()
    }

    /// Standard quiet hours preset (10 PM to 8 AM)
    static let standardQuietHours = (start: 22, end: 8)

    /// Standard reminder time (9:00 AM)
    static let standardReminderTime = (hour: 9, minute: 0)
}
