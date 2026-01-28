//
//  AppLogger.swift
//  CouponTracker
//
//  Created: January 2026
//  Purpose: Centralized logging utility using os.Logger for structured,
//           production-safe logging with category-based filtering.

import os

/// Centralized logging for CouponTracker app.
///
/// Usage:
/// ```swift
/// AppLogger.benefits.error("Failed to mark benefit: \(error.localizedDescription)")
/// AppLogger.notifications.info("Scheduled reminder for \(benefitName)")
/// ```
///
/// View logs in Console.app by filtering:
/// - Subsystem: com.coupontracker.app
/// - Category: benefits, notifications, data, ui, etc.
enum AppLogger {

    private static let subsystem = "com.coupontracker.app"

    // MARK: - Category Loggers

    /// Benefit-related operations (mark used, snooze, reset)
    static let benefits = Logger(subsystem: subsystem, category: "benefits")

    /// Notification scheduling and permissions
    static let notifications = Logger(subsystem: subsystem, category: "notifications")

    /// Data loading, saving, and migration
    static let data = Logger(subsystem: subsystem, category: "data")

    /// Card operations (add, delete, update)
    static let cards = Logger(subsystem: subsystem, category: "cards")

    /// User preferences and settings
    static let settings = Logger(subsystem: subsystem, category: "settings")

    /// Template loading and parsing
    static let templates = Logger(subsystem: subsystem, category: "templates")

    /// General app lifecycle events
    static let app = Logger(subsystem: subsystem, category: "app")
}
