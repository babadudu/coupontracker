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
import os

// MARK: - NotificationCategory

/// Notification category identifiers and action types
enum NotificationCategory {
    static let benefitExpiring = "BENEFIT_EXPIRING"
    static let subscriptionRenewing = "SUBSCRIPTION_RENEWING"
    static let couponExpiring = "COUPON_EXPIRING"
    static let annualFeeReminder = "ANNUAL_FEE_REMINDER"

    enum Action: String {
        case markUsed = "MARK_USED"
        case snooze1Day = "SNOOZE_1D"
        case snooze3Days = "SNOOZE_3D"
        case viewSubscription = "VIEW_SUBSCRIPTION"
        case viewCoupon = "VIEW_COUPON"
        case viewCard = "VIEW_CARD"
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

    /// Called when user taps subscription notification
    var onOpenSubscription: ((UUID) -> Void)?

    /// Called when user taps coupon notification
    var onOpenCoupon: ((UUID) -> Void)?

    /// Called when user taps annual fee notification
    var onOpenCard: ((UUID) -> Void)?

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
            AppLogger.notifications.error("Failed to request notification permission: \(error.localizedDescription)")
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

        center.add(request)
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

    // MARK: - Subscription Notifications

    /// Schedules a notification for subscription renewal.
    ///
    /// - Parameters:
    ///   - subscription: The subscription to schedule notification for
    ///   - preferences: User preferences containing notification settings
    func scheduleSubscriptionRenewalNotification(
        for subscription: Subscription,
        preferences: UserPreferences
    ) async {
        guard await checkAuthorizationStatus() else { return }
        guard preferences.notificationsEnabled else { return }
        guard subscription.isActive && subscription.reminderEnabled else { return }

        let daysRemaining = subscription.daysUntilRenewal
        guard daysRemaining >= 0 && daysRemaining <= subscription.reminderDaysBefore else { return }

        let content = UNMutableNotificationContent()
        content.title = "Subscription Renewing Soon"
        content.body = "\(subscription.name) renews in \(daysRemaining) days - \(subscription.formattedPrice)"
        content.sound = .default
        content.categoryIdentifier = NotificationCategory.subscriptionRenewing
        content.userInfo = [
            "subscriptionId": subscription.id.uuidString,
            "type": "subscription_renewal"
        ]

        // Schedule for reminder days before renewal
        let notificationDate = Calendar.current.date(
            byAdding: .day,
            value: -subscription.reminderDaysBefore,
            to: subscription.nextRenewalDate
        ) ?? subscription.nextRenewalDate

        guard notificationDate >= Date() else { return }

        var dateComponents = Calendar.current.dateComponents(
            [.year, .month, .day],
            from: notificationDate
        )
        dateComponents.hour = preferences.preferredReminderHour
        dateComponents.minute = preferences.preferredReminderMinute

        let trigger = UNCalendarNotificationTrigger(
            dateMatching: dateComponents,
            repeats: false
        )

        let identifier = subscriptionNotificationId(for: subscription)
        let request = UNNotificationRequest(
            identifier: identifier,
            content: content,
            trigger: trigger
        )

        subscription.scheduledNotificationId = identifier
        try? await center.add(request)
    }

    /// Cancels notifications for a subscription.
    func cancelSubscriptionNotification(for subscription: Subscription) {
        let identifier = subscriptionNotificationId(for: subscription)
        center.removePendingNotificationRequests(withIdentifiers: [identifier])
        center.removeDeliveredNotifications(withIdentifiers: [identifier])
        subscription.scheduledNotificationId = nil
    }

    private func subscriptionNotificationId(for subscription: Subscription) -> String {
        "subscription_\(subscription.id.uuidString)"
    }

    // MARK: - Coupon Notifications

    /// Schedules a notification for coupon expiration.
    ///
    /// - Parameters:
    ///   - coupon: The coupon to schedule notification for
    ///   - preferences: User preferences containing notification settings
    func scheduleCouponExpirationNotification(
        for coupon: Coupon,
        preferences: UserPreferences
    ) async {
        guard await checkAuthorizationStatus() else { return }
        guard preferences.notificationsEnabled else { return }
        guard !coupon.isUsed && coupon.reminderEnabled else { return }

        let daysRemaining = coupon.daysUntilExpiration
        guard daysRemaining >= 0 && daysRemaining <= coupon.reminderDaysBefore else { return }

        let content = UNMutableNotificationContent()
        content.title = "Coupon Expiring Soon"

        let valueText = coupon.formattedValue.map { " - \($0)" } ?? ""
        content.body = "\(coupon.name) expires in \(daysRemaining) days\(valueText)"
        content.sound = .default
        content.categoryIdentifier = NotificationCategory.couponExpiring
        content.userInfo = [
            "couponId": coupon.id.uuidString,
            "type": "coupon_expiration"
        ]

        // Schedule for reminder days before expiration
        let notificationDate = Calendar.current.date(
            byAdding: .day,
            value: -coupon.reminderDaysBefore,
            to: coupon.expirationDate
        ) ?? coupon.expirationDate

        guard notificationDate >= Date() else { return }

        var dateComponents = Calendar.current.dateComponents(
            [.year, .month, .day],
            from: notificationDate
        )
        dateComponents.hour = preferences.preferredReminderHour
        dateComponents.minute = preferences.preferredReminderMinute

        let trigger = UNCalendarNotificationTrigger(
            dateMatching: dateComponents,
            repeats: false
        )

        let identifier = couponNotificationId(for: coupon)
        let request = UNNotificationRequest(
            identifier: identifier,
            content: content,
            trigger: trigger
        )

        coupon.scheduledNotificationId = identifier
        try? await center.add(request)
    }

    /// Cancels notifications for a coupon.
    func cancelCouponNotification(for coupon: Coupon) {
        let identifier = couponNotificationId(for: coupon)
        center.removePendingNotificationRequests(withIdentifiers: [identifier])
        center.removeDeliveredNotifications(withIdentifiers: [identifier])
        coupon.scheduledNotificationId = nil
    }

    private func couponNotificationId(for coupon: Coupon) -> String {
        "coupon_\(coupon.id.uuidString)"
    }

    // MARK: - Annual Fee Notifications

    /// Schedules a notification for annual fee reminder.
    ///
    /// - Parameters:
    ///   - card: The card to schedule notification for
    ///   - cardName: Display name for the card
    ///   - preferences: User preferences containing notification settings
    func scheduleAnnualFeeNotification(
        for card: UserCard,
        cardName: String,
        preferences: UserPreferences
    ) async {
        guard await checkAuthorizationStatus() else { return }
        guard preferences.notificationsEnabled else { return }
        guard card.annualFee > 0, let feeDate = card.annualFeeDate else { return }

        let daysRemaining = card.daysUntilAnnualFee
        guard daysRemaining >= 0 && daysRemaining <= card.feeReminderDaysBefore else { return }

        let content = UNMutableNotificationContent()
        content.title = "Annual Fee Coming Up"
        content.body = "\(cardName) - \(card.formattedAnnualFee) due in \(daysRemaining) days"
        content.sound = .default
        content.categoryIdentifier = NotificationCategory.annualFeeReminder
        content.userInfo = [
            "cardId": card.id.uuidString,
            "type": "annual_fee"
        ]

        // Schedule for reminder days before fee date
        let notificationDate = Calendar.current.date(
            byAdding: .day,
            value: -card.feeReminderDaysBefore,
            to: feeDate
        ) ?? feeDate

        guard notificationDate >= Date() else { return }

        var dateComponents = Calendar.current.dateComponents(
            [.year, .month, .day],
            from: notificationDate
        )
        dateComponents.hour = preferences.preferredReminderHour
        dateComponents.minute = preferences.preferredReminderMinute

        let trigger = UNCalendarNotificationTrigger(
            dateMatching: dateComponents,
            repeats: false
        )

        let identifier = annualFeeNotificationId(for: card)
        let request = UNNotificationRequest(
            identifier: identifier,
            content: content,
            trigger: trigger
        )

        card.feeReminderNotificationId = identifier
        try? await center.add(request)
    }

    /// Cancels annual fee notification for a card.
    func cancelAnnualFeeNotification(for card: UserCard) {
        let identifier = annualFeeNotificationId(for: card)
        center.removePendingNotificationRequests(withIdentifiers: [identifier])
        center.removeDeliveredNotifications(withIdentifiers: [identifier])
        card.feeReminderNotificationId = nil
    }

    private func annualFeeNotificationId(for card: UserCard) -> String {
        "annual_fee_\(card.id.uuidString)"
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
        // Benefit expiring category
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

        let benefitCategory = UNNotificationCategory(
            identifier: NotificationCategory.benefitExpiring,
            actions: [markUsedAction, snooze1DayAction, snooze3DaysAction],
            intentIdentifiers: [],
            options: [.customDismissAction]
        )

        // Subscription renewing category
        let viewSubscriptionAction = UNNotificationAction(
            identifier: NotificationCategory.Action.viewSubscription.rawValue,
            title: "View Details",
            options: [.foreground]
        )

        let subscriptionCategory = UNNotificationCategory(
            identifier: NotificationCategory.subscriptionRenewing,
            actions: [viewSubscriptionAction, snooze1DayAction],
            intentIdentifiers: [],
            options: [.customDismissAction]
        )

        // Coupon expiring category
        let viewCouponAction = UNNotificationAction(
            identifier: NotificationCategory.Action.viewCoupon.rawValue,
            title: "View Coupon",
            options: [.foreground]
        )

        let couponCategory = UNNotificationCategory(
            identifier: NotificationCategory.couponExpiring,
            actions: [viewCouponAction, snooze1DayAction],
            intentIdentifiers: [],
            options: [.customDismissAction]
        )

        // Annual fee reminder category
        let viewCardAction = UNNotificationAction(
            identifier: NotificationCategory.Action.viewCard.rawValue,
            title: "View Card",
            options: [.foreground]
        )

        let annualFeeCategory = UNNotificationCategory(
            identifier: NotificationCategory.annualFeeReminder,
            actions: [viewCardAction, snooze1DayAction],
            intentIdentifiers: [],
            options: [.customDismissAction]
        )

        center.setNotificationCategories([
            benefitCategory,
            subscriptionCategory,
            couponCategory,
            annualFeeCategory
        ])
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
        let notificationType = userInfo["type"] as? String ?? "benefit"

        await MainActor.run {
            switch notificationType {
            case "subscription_renewal":
                handleSubscriptionNotification(response: response, userInfo: userInfo)
            case "coupon_expiration":
                handleCouponNotification(response: response, userInfo: userInfo)
            case "annual_fee":
                handleAnnualFeeNotification(response: response, userInfo: userInfo)
            default:
                handleBenefitNotification(response: response, userInfo: userInfo)
            }
        }
    }

    // MARK: - Notification Response Handlers

    private func handleBenefitNotification(
        response: UNNotificationResponse,
        userInfo: [AnyHashable: Any]
    ) {
        guard let benefitIdString = userInfo["benefitId"] as? String,
              let benefitId = UUID(uuidString: benefitIdString) else {
            return
        }

        switch response.actionIdentifier {
        case NotificationCategory.Action.markUsed.rawValue:
            onMarkAsUsed?(benefitId)
        case NotificationCategory.Action.snooze1Day.rawValue:
            onSnooze?(benefitId, 1)
        case NotificationCategory.Action.snooze3Days.rawValue:
            onSnooze?(benefitId, 3)
        case UNNotificationDefaultActionIdentifier:
            onOpenBenefit?(benefitId)
        default:
            break
        }
    }

    private func handleSubscriptionNotification(
        response: UNNotificationResponse,
        userInfo: [AnyHashable: Any]
    ) {
        guard let subscriptionIdString = userInfo["subscriptionId"] as? String,
              let subscriptionId = UUID(uuidString: subscriptionIdString) else {
            return
        }

        switch response.actionIdentifier {
        case NotificationCategory.Action.viewSubscription.rawValue,
             UNNotificationDefaultActionIdentifier:
            onOpenSubscription?(subscriptionId)
        default:
            break
        }
    }

    private func handleCouponNotification(
        response: UNNotificationResponse,
        userInfo: [AnyHashable: Any]
    ) {
        guard let couponIdString = userInfo["couponId"] as? String,
              let couponId = UUID(uuidString: couponIdString) else {
            return
        }

        switch response.actionIdentifier {
        case NotificationCategory.Action.viewCoupon.rawValue,
             UNNotificationDefaultActionIdentifier:
            onOpenCoupon?(couponId)
        default:
            break
        }
    }

    private func handleAnnualFeeNotification(
        response: UNNotificationResponse,
        userInfo: [AnyHashable: Any]
    ) {
        guard let cardIdString = userInfo["cardId"] as? String,
              let cardId = UUID(uuidString: cardIdString) else {
            return
        }

        switch response.actionIdentifier {
        case NotificationCategory.Action.viewCard.rawValue,
             UNNotificationDefaultActionIdentifier:
            onOpenCard?(cardId)
        default:
            break
        }
    }
}
