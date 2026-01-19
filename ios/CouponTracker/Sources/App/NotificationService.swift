// NotificationService.swift
// CouponTracker
//
// Created: January 2026
// Purpose: Service for managing user notifications and notification permissions

import Foundation
import UserNotifications

/// Service responsible for managing notifications throughout the app
@MainActor
final class NotificationService: NSObject, UNUserNotificationCenterDelegate {
    
    // MARK: - Properties
    
    private let notificationCenter = UNUserNotificationCenter.current()
    
    // MARK: - Initialization
    
    override init() {
        super.init()
    }
    
    // MARK: - Permission Management
    
    /// Requests notification permissions from the user
    func requestAuthorization() async throws -> Bool {
        try await notificationCenter.requestAuthorization(options: [.alert, .sound, .badge])
    }
    
    /// Checks current notification authorization status
    func checkAuthorizationStatus() async -> UNAuthorizationStatus {
        await notificationCenter.notificationSettings().authorizationStatus
    }
    
    // MARK: - Scheduling Notifications
    
    /// Schedules a notification for a benefit expiration
    func scheduleBenefitExpirationNotification(
        benefitName: String,
        cardName: String,
        expirationDate: Date,
        identifier: String
    ) async throws {
        let content = UNMutableNotificationContent()
        content.title = "Benefit Expiring Soon"
        content.body = "\(benefitName) on your \(cardName) card expires soon!"
        content.sound = .default
        
        let components = Calendar.current.dateComponents(
            [.year, .month, .day, .hour, .minute],
            from: expirationDate
        )
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        
        let request = UNNotificationRequest(
            identifier: identifier,
            content: content,
            trigger: trigger
        )
        
        try await notificationCenter.add(request)
    }
    
    /// Cancels a scheduled notification
    func cancelNotification(withIdentifier identifier: String) {
        notificationCenter.removePendingNotificationRequests(withIdentifiers: [identifier])
    }
    
    /// Cancels all scheduled notifications
    func cancelAllNotifications() {
        notificationCenter.removeAllPendingNotificationRequests()
    }
    
    // MARK: - UNUserNotificationCenterDelegate
    
    /// Called when a notification is received while the app is in the foreground
    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        // Show notification even when app is in foreground
        completionHandler([.banner, .sound, .badge])
    }
    
    /// Called when the user interacts with a notification
    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        // Handle notification tap
        // You can extract the notification identifier and navigate to relevant content
        let identifier = response.notification.request.identifier
        
        // TODO: Add navigation logic based on identifier
        print("User tapped notification: \(identifier)")
        
        completionHandler()
    }
}
