//
//  SettingsViewModel.swift
//  CouponTracker
//
//  Created by Junior Engineer 4 on 2026-01-17.
//  Purpose: ViewModel for settings screen managing user preferences
//

import Foundation
import SwiftUI
import SwiftData
import Observation
import os

/// ViewModel for the settings screen.
///
/// Manages the state and business logic for user preferences including
/// notification settings, quiet hours, and app configuration.
///
/// State Management:
/// - Uses @Observable macro for SwiftUI integration
/// - All state updates happen on @MainActor
/// - Loads and saves UserPreferences singleton from SwiftData
@Observable
@MainActor
final class SettingsViewModel {

    // MARK: - Dependencies

    private let modelContext: ModelContext

    // MARK: - State (from UserPreferences)

    /// Master toggle for all notifications
    var notificationsEnabled: Bool = true

    /// Default reminder lead time in days (7, 3, 1, etc.)
    var defaultReminderDays: Int = 7

    /// Whether to notify 1 day before expiration
    var notify1DayBefore: Bool = true

    /// Whether to notify 3 days before expiration
    var notify3DaysBefore: Bool = true

    /// Whether to notify 1 week before expiration
    var notify1WeekBefore: Bool = false

    /// Whether quiet hours are enabled
    var quietHoursEnabled: Bool = false

    /// Quiet hours start time (as Date for DatePicker)
    var quietHoursStart: Date = Calendar.current.date(from: DateComponents(hour: 22)) ?? Date()

    /// Quiet hours end time (as Date for DatePicker)
    var quietHoursEnd: Date = Calendar.current.date(from: DateComponents(hour: 8)) ?? Date()

    /// Preferred reminder time (as Date for DatePicker)
    var preferredReminderTime: Date = Calendar.current.date(from: DateComponents(hour: 9, minute: 0)) ?? Date()

    /// Appearance mode preference (system, light, dark)
    var appearanceMode: AppearanceMode = .system

    // MARK: - App Info

    /// Current app version from bundle
    var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
    }

    /// Current build number from bundle
    var buildNumber: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
    }

    // MARK: - Loading State

    /// Whether we're currently loading or saving preferences
    private(set) var isLoading = false

    /// Error state for failed operations
    private(set) var error: Error?

    // MARK: - Private State

    /// Reference to the singleton UserPreferences entity
    private var userPreferences: UserPreferences?

    // MARK: - Initialization

    /// Initializes the view model with a model context.
    /// - Parameter modelContext: The SwiftData model context for persistence
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    // MARK: - Actions

    /// Loads preferences from SwiftData.
    ///
    /// Fetches the singleton UserPreferences record and populates
    /// the view model state. Creates a new preferences record if none exists.
    func loadPreferences() {
        isLoading = true
        error = nil

        do {
            // Fetch the singleton UserPreferences
            let prefsId = "user_preferences"
            let descriptor = FetchDescriptor<UserPreferences>(
                predicate: #Predicate<UserPreferences> { prefs in
                    prefs.id == prefsId
                }
            )

            let preferences = try modelContext.fetch(descriptor)

            if let prefs = preferences.first {
                // Load existing preferences
                userPreferences = prefs
                populateStateFromPreferences(prefs)
            } else {
                // Create new preferences with defaults
                let newPrefs = UserPreferences()
                modelContext.insert(newPrefs)
                try modelContext.save()

                userPreferences = newPrefs
                populateStateFromPreferences(newPrefs)
            }

        } catch {
            self.error = error
            AppLogger.settings.error("Failed to load preferences: \(error.localizedDescription)")
        }

        isLoading = false
    }

    /// Saves current view model state to UserPreferences.
    ///
    /// Updates the singleton UserPreferences entity with current state
    /// and persists to SwiftData.
    func savePreferences() {
        guard let prefs = userPreferences else {
            return
        }

        // Update preferences from view model state
        prefs.notificationsEnabled = notificationsEnabled
        prefs.defaultReminderDays = defaultReminderDays
        prefs.notify1DayBefore = notify1DayBefore
        prefs.notify3DaysBefore = notify3DaysBefore
        prefs.notify1WeekBefore = notify1WeekBefore
        prefs.quietHoursEnabled = quietHoursEnabled
        prefs.appearanceMode = appearanceMode

        // Convert Date objects to hour/minute integers
        let calendar = Calendar.current

        let quietStartComponents = calendar.dateComponents([.hour], from: quietHoursStart)
        prefs.quietHoursStart = quietStartComponents.hour ?? 22

        let quietEndComponents = calendar.dateComponents([.hour], from: quietHoursEnd)
        prefs.quietHoursEnd = quietEndComponents.hour ?? 8

        let reminderComponents = calendar.dateComponents([.hour, .minute], from: preferredReminderTime)
        prefs.preferredReminderHour = reminderComponents.hour ?? 9
        prefs.preferredReminderMinute = reminderComponents.minute ?? 0

        prefs.appVersion = appVersion
        prefs.markAsUpdated()

        do {
            try modelContext.save()
            // Notify ContentView to reload appearance mode
            NotificationCenter.default.post(name: .userPreferencesChanged, object: nil)
        } catch {
            self.error = error
            AppLogger.settings.error("Failed to save preferences: \(error.localizedDescription)")
        }
    }

    /// Resets all preferences to default values.
    ///
    /// Resets both the view model state and the persisted UserPreferences
    /// to their default values.
    func resetToDefaults() {
        guard let prefs = userPreferences else {
            return
        }

        // Reset to default values
        prefs.notificationsEnabled = true
        prefs.preferredReminderHour = 9
        prefs.preferredReminderMinute = 0
        prefs.defaultReminderDays = 7
        prefs.notify1DayBefore = true
        prefs.notify3DaysBefore = true
        prefs.notify1WeekBefore = false
        prefs.quietHoursEnabled = false
        prefs.quietHoursStart = 22
        prefs.quietHoursEnd = 8
        prefs.showBenefitValues = true
        prefs.sortCardsByUrgency = true
        prefs.appearanceMode = .system
        prefs.markAsUpdated()

        do {
            try modelContext.save()
            // Reload state from saved preferences
            populateStateFromPreferences(prefs)
        } catch {
            self.error = error
            AppLogger.settings.error("Failed to reset preferences to defaults: \(error.localizedDescription)")
        }
    }

    /// Requests notification permission from the system.
    ///
    /// This method requests permission to send local notifications.
    /// Should be called when the user enables notifications.
    ///
    /// - Returns: True if permission was granted, false otherwise
    func requestNotificationPermission() async -> Bool {
        // Request notification authorization
        do {
            let center = UNUserNotificationCenter.current()
            let granted = try await center.requestAuthorization(options: [.alert, .badge, .sound])
            return granted
        } catch {
            self.error = error
            AppLogger.notifications.error("Failed to request notification permission: \(error.localizedDescription)")
            return false
        }
    }

    // MARK: - Private Helpers

    /// Populates view model state from a UserPreferences entity.
    /// - Parameter prefs: The UserPreferences entity to load from
    private func populateStateFromPreferences(_ prefs: UserPreferences) {
        notificationsEnabled = prefs.notificationsEnabled
        defaultReminderDays = prefs.defaultReminderDays
        notify1DayBefore = prefs.notify1DayBefore
        notify3DaysBefore = prefs.notify3DaysBefore
        notify1WeekBefore = prefs.notify1WeekBefore
        quietHoursEnabled = prefs.quietHoursEnabled
        appearanceMode = prefs.appearanceMode

        // Convert hour integers to Date objects for DatePicker
        let calendar = Calendar.current

        quietHoursStart = calendar.date(from: DateComponents(hour: prefs.quietHoursStart)) ?? Date()
        quietHoursEnd = calendar.date(from: DateComponents(hour: prefs.quietHoursEnd)) ?? Date()
        preferredReminderTime = calendar.date(from: DateComponents(
            hour: prefs.preferredReminderHour,
            minute: prefs.preferredReminderMinute
        )) ?? Date()
    }
}

// MARK: - Preview Support

extension SettingsViewModel {

    /// Creates a preview instance with mock data
    static var preview: SettingsViewModel {
        let schema = Schema([
            UserCard.self,
            Benefit.self,
            BenefitUsage.self,
            UserPreferences.self
        ])

        let configuration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: true
        )

        guard let container = try? ModelContainer(
            for: schema,
            configurations: [configuration]
        ) else {
            fatalError("Failed to create preview ModelContainer")
        }

        let context = container.mainContext

        // Create and insert preview preferences
        let prefs = UserPreferences()
        prefs.hasCompletedOnboarding = true
        context.insert(prefs)
        try? context.save()

        let viewModel = SettingsViewModel(modelContext: context)
        viewModel.loadPreferences()
        return viewModel
    }
}
