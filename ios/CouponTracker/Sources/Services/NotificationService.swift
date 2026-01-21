//
//  NotificationService.swift
//  CouponTracker
//
//  Created: January 2026
//  Purpose: Manages local notifications for benefit expiration reminders.
//           Handles scheduling, cancellation, snooze, and action responses.

import Foundation
import UserNotifications
import SwiftData

// MARK: - NotificationCategory

/// Notification category identifiers and action types
enum NotificationCategory {
    static let benefitExpiring = "BENEFIT_EXPIRING"

    enum Action: String {
        case markUsed = "MARK_USED"
        case snooze1Day = "SNOOZE_1D"
        case snooze3Days = "SNOOZE_3D"
    }
}

// MARK: - NotificationService

/// NotificationService
///
/// Responsibilities:
/// - Request notification permissions from the user
/// - Schedule notifications based on ExpirationUrgency levels and user preferences
/// - Handle notification actions (mark used, snooze 1/3 days)
/// - Cancel notifications when benefits are used/deleted
/// - Reconcile scheduled notifications with current benefit state
///
/// Dependencies:
/// - UNUserNotificationCenter for scheduling and managing notifications
/// - UserPreferences for notification timing and enabled states
///
/// Thread Safety: MainActor
@MainActor
final class NotificationService: NSObject {

    // MARK: - Dependencies

    private let center = UNUserNotificationCenter.current()

    // MARK: - Delegate Callbacks

    /// Called when user taps "Mark as Used" action
    var onMarkAsUsed: ((UUID) -> Void)?

    /// Called when user taps snooze action
    var onSnooze: ((UUID, Int) -> Void)?

    /// Called when user taps notification to open app
    var onOpenBenefit: ((UUID) -> Void)?

    // MARK: - Initialization

    override init() {
        super.init()
        setupNotificationCategories()
    }

    // MARK: - Permission

    /// Requests notification authorization from the user.
    /// - Returns: True if permission was granted
    func requestPermission() async -> Bool {
        do {
            let granted = try await center.requestAuthorization(
                options: [.alert, .sound, .badge]
            )
            return granted
        } catch {
            print("Failed to request notification permission: \(error)")
            return false
        }
    }

    /// Checks current notification authorization status.
    /// - Returns: True if notifications are authorized
    func checkAuthorizationStatus() async -> Bool {
        let settings = await center.notificationSettings()
        return settings.authorizationStatus == .authorized
    }

    // MARK: - Scheduling

    /// Schedules notifications for a benefit based on user preferences.
    ///
    /// - Parameters:
    ///   - benefit: The benefit to schedule notifications for
    ///   - preferences: User preferences containing notification settings
    ///
    /// - Note: This method checks authorization status before scheduling.
    ///         No notifications will be scheduled if permissions are denied.
    func scheduleNotifications(
        for benefit: Benefit,
        preferences: UserPreferences
    ) async {
        // Check notification authorization before attempting to schedule
        guard await checkAuthorizationStatus() else {
            print("⚠️ NotificationService: Cannot schedule - notifications not authorized")
            return
        }

        guard preferences.notificationsEnabled else { return }
        guard benefit.status == .available else { return }
        let periodEnd = benefit.currentPeriodEnd

        let daysRemaining = benefit.daysUntilExpiration

        // Schedule based on enabled urgency levels
        if preferences.notify1DayBefore && daysRemaining >= 1 {
            scheduleNotification(
                for: benefit,
                urgency: .within1Day,
                expirationDate: periodEnd,
                preferences: preferences
            )
        }

        if preferences.notify3DaysBefore && daysRemaining >= 3 {
            scheduleNotification(
                for: benefit,
                urgency: .within3Days,
                expirationDate: periodEnd,
                preferences: preferences
            )
        }

        if preferences.notify1WeekBefore && daysRemaining >= 7 {
            scheduleNotification(
                for: benefit,
                urgency: .within1Week,
                expirationDate: periodEnd,
                preferences: preferences
            )
        }

        // Always schedule same-day notification at 8 AM
        if daysRemaining >= 0 {
            scheduleNotification(
                for: benefit,
                urgency: .expiringToday,
                expirationDate: periodEnd,
                preferences: preferences
            )
        }
    }

    /// Schedules a single notification for a specific urgency level.
    private func scheduleNotification(
        for benefit: Benefit,
        urgency: ExpirationUrgency,
        expirationDate: Date,
        preferences: UserPreferences
    ) {
        let content = createNotificationContent(for: benefit, urgency: urgency)
        let trigger = createTrigger(
            for: urgency,
            expirationDate: expirationDate,
            preferences: preferences
        )

        guard let trigger = trigger else { return }

        let identifier = notificationId(for: benefit, urgency: urgency)
        let request = UNNotificationRequest(
            identifier: identifier,
            content: content,
            trigger: trigger
        )

        center.add(request) { error in
            if let error = error {
                print("Failed to schedule notification: \(error)")
            }
        }
    }

    /// Schedules a snoozed notification for a specific date/time.
    ///
    /// - Parameters:
    ///   - benefit: The benefit to schedule
    ///   - snoozeDate: When to fire the notification
    ///   - preferences: User preferences for notification time
    func scheduleSnoozedNotification(
        for benefit: Benefit,
        snoozeDate: Date,
        preferences: UserPreferences
    ) {
        // Cancel any existing notifications for this benefit
        cancelNotifications(for: benefit)

        let content = createNotificationContent(for: benefit, urgency: .expiringToday)
        content.subtitle = "Snoozed reminder"

        // Use preferred time on snooze date
        var dateComponents = Calendar.current.dateComponents(
            [.year, .month, .day],
            from: snoozeDate
        )
        dateComponents.hour = preferences.preferredReminderHour
        dateComponents.minute = preferences.preferredReminderMinute

        let trigger = UNCalendarNotificationTrigger(
            dateMatching: dateComponents,
            repeats: false
        )

        let identifier = "snoozed_\(benefit.id.uuidString)"
        let request = UNNotificationRequest(
            identifier: identifier,
            content: content,
            trigger: trigger
        )

        center.add(request)
    }

    // MARK: - Cancellation

    /// Cancels all notifications for a specific benefit.
    func cancelNotifications(for benefit: Benefit) {
        let identifiers = ExpirationUrgency.allCases.map { urgency in
            notificationId(for: benefit, urgency: urgency)
        } + ["snoozed_\(benefit.id.uuidString)"]

        center.removePendingNotificationRequests(withIdentifiers: identifiers)
        center.removeDeliveredNotifications(withIdentifiers: identifiers)
    }

    /// Cancels all notifications for benefits on a card.
    func cancelNotifications(forCardId cardId: UUID, benefits: [Benefit]) {
        let identifiers = benefits.flatMap { benefit in
            ExpirationUrgency.allCases.map { urgency in
                notificationId(for: benefit, urgency: urgency)
            } + ["snoozed_\(benefit.id.uuidString)"]
        }

        center.removePendingNotificationRequests(withIdentifiers: identifiers)
        center.removeDeliveredNotifications(withIdentifiers: identifiers)
    }

    /// Cancels all scheduled notifications.
    func cancelAllNotifications() {
        center.removeAllPendingNotificationRequests()
        center.removeAllDeliveredNotifications()
    }

    // MARK: - Reconciliation

    /// Reconciles scheduled notifications with current benefit state.
    ///
    /// Call this when app enters foreground to ensure notifications
    /// match actual benefit status.
    func reconcileNotifications(
        benefits: [Benefit],
        preferences: UserPreferences
    ) async {
        // Cancel all existing and reschedule based on current state
        cancelAllNotifications()

        for benefit in benefits where benefit.status == .available {
            await scheduleNotifications(for: benefit, preferences: preferences)
        }
    }

    // MARK: - Private Helpers

    /// Creates notification content for a benefit.
    private func createNotificationContent(
        for benefit: Benefit,
        urgency: ExpirationUrgency
    ) -> UNMutableNotificationContent {
        let content = UNMutableNotificationContent()

        let benefitName = benefit.effectiveName
        let timeframe = urgency.displayTitle.lowercased()

        content.title = "\(benefitName) expires \(timeframe)!"
        content.body = "\(benefit.formattedValue) - \(benefit.userCard?.displayName(templateName: nil) ?? "Card")"
        content.sound = .default
        content.categoryIdentifier = NotificationCategory.benefitExpiring

        // Store benefit ID for action handling
        content.userInfo = [
            "benefitId": benefit.id.uuidString,
            "urgency": urgency.rawValue
        ]

        return content
    }

    /// Creates a trigger for the notification based on urgency.
    private func createTrigger(
        for urgency: ExpirationUrgency,
        expirationDate: Date,
        preferences: UserPreferences
    ) -> UNCalendarNotificationTrigger? {
        let calendar = Calendar.current

        // Calculate notification date based on urgency
        let daysBeforeExpiration: Int
        switch urgency {
        case .expiringToday:
            daysBeforeExpiration = 0
        case .within1Day:
            daysBeforeExpiration = 1
        case .within3Days:
            daysBeforeExpiration = 3
        case .within1Week:
            daysBeforeExpiration = 7
        case .later:
            return nil
        }

        guard let notificationDate = calendar.date(
            byAdding: .day,
            value: -daysBeforeExpiration,
            to: expirationDate
        ) else { return nil }

        // Check if notification date is in the past
        if notificationDate < Date() { return nil }

        // Set time based on urgency
        var dateComponents = calendar.dateComponents(
            [.year, .month, .day],
            from: notificationDate
        )

        if urgency == .expiringToday {
            // Same-day notifications at 8 AM fixed
            dateComponents.hour = 8
            dateComponents.minute = 0
        } else {
            // Other notifications at user's preferred time
            dateComponents.hour = preferences.preferredReminderHour
            dateComponents.minute = preferences.preferredReminderMinute
        }

        return UNCalendarNotificationTrigger(
            dateMatching: dateComponents,
            repeats: false
        )
    }

    /// Generates a unique notification identifier.
    private func notificationId(
        for benefit: Benefit,
        urgency: ExpirationUrgency
    ) -> String {
        "benefit_\(benefit.id.uuidString)_\(urgency.rawValue)"
    }

    /// Sets up notification action categories.
    private func setupNotificationCategories() {
        let markUsedAction = UNNotificationAction(
            identifier: NotificationCategory.Action.markUsed.rawValue,
            title: "Mark as Used",
            options: [.foreground]
        )

        let snooze1DayAction = UNNotificationAction(
            identifier: NotificationCategory.Action.snooze1Day.rawValue,
            title: "Snooze 1 Day",
            options: []
        )

        let snooze3DaysAction = UNNotificationAction(
            identifier: NotificationCategory.Action.snooze3Days.rawValue,
            title: "Snooze 3 Days",
            options: []
        )

        let category = UNNotificationCategory(
            identifier: NotificationCategory.benefitExpiring,
            actions: [markUsedAction, snooze1DayAction, snooze3DaysAction],
            intentIdentifiers: [],
            options: [.customDismissAction]
        )

        center.setNotificationCategories([category])
    }
}

// MARK: - UNUserNotificationCenterDelegate

extension NotificationService: UNUserNotificationCenterDelegate {

    /// Called when notification is delivered while app is in foreground.
    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        // Show notification even when app is in foreground
        [.banner, .sound, .badge]
    }

    /// Called when user interacts with notification.
    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse
    ) async {
        let userInfo = response.notification.request.content.userInfo

        guard let benefitIdString = userInfo["benefitId"] as? String,
              let benefitId = UUID(uuidString: benefitIdString) else {
            return
        }

        await MainActor.run {
            switch response.actionIdentifier {
            case NotificationCategory.Action.markUsed.rawValue:
                onMarkAsUsed?(benefitId)

            case NotificationCategory.Action.snooze1Day.rawValue:
                onSnooze?(benefitId, 1)

            case NotificationCategory.Action.snooze3Days.rawValue:
                onSnooze?(benefitId, 3)

            case UNNotificationDefaultActionIdentifier:
                // User tapped notification body - open benefit
                onOpenBenefit?(benefitId)

            default:
                break
            }
        }
    }
}
