//
//  AppLoggerTests.swift
//  CouponTrackerTests
//
//  Created: January 2026
//  Purpose: Unit tests for AppLogger utility to verify logger categories
//           are properly configured and accessible.

import XCTest
import os
@testable import CouponTracker

final class AppLoggerTests: XCTestCase {

    // MARK: - Logger Accessibility Tests

    func testAllLoggersAccessible() {
        // Verify all logger categories can be accessed
        XCTAssertNotNil(AppLogger.benefits)
        XCTAssertNotNil(AppLogger.notifications)
        XCTAssertNotNil(AppLogger.data)
        XCTAssertNotNil(AppLogger.cards)
        XCTAssertNotNil(AppLogger.settings)
        XCTAssertNotNil(AppLogger.templates)
        XCTAssertNotNil(AppLogger.app)
    }

    // MARK: - Individual Logger Tests

    func testBenefitsLoggerAccessible() {
        let logger = AppLogger.benefits
        XCTAssertNotNil(logger)
    }

    func testNotificationsLoggerAccessible() {
        let logger = AppLogger.notifications
        XCTAssertNotNil(logger)
    }

    func testDataLoggerAccessible() {
        let logger = AppLogger.data
        XCTAssertNotNil(logger)
    }

    func testCardsLoggerAccessible() {
        let logger = AppLogger.cards
        XCTAssertNotNil(logger)
    }

    func testSettingsLoggerAccessible() {
        let logger = AppLogger.settings
        XCTAssertNotNil(logger)
    }

    func testTemplatesLoggerAccessible() {
        let logger = AppLogger.templates
        XCTAssertNotNil(logger)
    }

    func testAppLoggerAccessible() {
        let logger = AppLogger.app
        XCTAssertNotNil(logger)
    }

    // MARK: - Smoke Tests (Verify Logging Calls Don't Crash)

    func testBenefitsLoggerSmokeTest() {
        // Verify logging calls don't crash
        AppLogger.benefits.error("Test error message")
        AppLogger.benefits.warning("Test warning message")
        AppLogger.benefits.info("Test info message")
        AppLogger.benefits.debug("Test debug message")

        // If we get here without crashing, the test passes
        XCTAssertTrue(true)
    }

    func testNotificationsLoggerSmokeTest() {
        AppLogger.notifications.error("Test error message")
        AppLogger.notifications.warning("Test warning message")
        AppLogger.notifications.info("Test info message")
        AppLogger.notifications.debug("Test debug message")

        XCTAssertTrue(true)
    }

    func testDataLoggerSmokeTest() {
        AppLogger.data.error("Test error message")
        AppLogger.data.warning("Test warning message")
        AppLogger.data.info("Test info message")
        AppLogger.data.debug("Test debug message")

        XCTAssertTrue(true)
    }

    func testCardsLoggerSmokeTest() {
        AppLogger.cards.error("Test error message")
        AppLogger.cards.warning("Test warning message")
        AppLogger.cards.info("Test info message")
        AppLogger.cards.debug("Test debug message")

        XCTAssertTrue(true)
    }

    func testSettingsLoggerSmokeTest() {
        AppLogger.settings.error("Test error message")
        AppLogger.settings.warning("Test warning message")
        AppLogger.settings.info("Test info message")
        AppLogger.settings.debug("Test debug message")

        XCTAssertTrue(true)
    }

    func testTemplatesLoggerSmokeTest() {
        AppLogger.templates.error("Test error message")
        AppLogger.templates.warning("Test warning message")
        AppLogger.templates.info("Test info message")
        AppLogger.templates.debug("Test debug message")

        XCTAssertTrue(true)
    }

    func testAppLoggerSmokeTest() {
        AppLogger.app.error("Test error message")
        AppLogger.app.warning("Test warning message")
        AppLogger.app.info("Test info message")
        AppLogger.app.debug("Test debug message")

        XCTAssertTrue(true)
    }

    // MARK: - Logging with Interpolation Tests

    func testLoggingWithStringInterpolation() {
        let testValue = "interpolated value"
        let testNumber = 42

        // Verify logging with string interpolation doesn't crash
        AppLogger.benefits.info("Test with string: \(testValue)")
        AppLogger.benefits.info("Test with number: \(testNumber)")
        AppLogger.benefits.info("Test with multiple values: \(testValue), \(testNumber)")

        XCTAssertTrue(true)
    }

    func testLoggingWithComplexMessages() {
        struct TestError: Error, CustomStringConvertible {
            var description: String { "Test error description" }
        }

        let error = TestError()

        // Verify logging with complex types doesn't crash
        AppLogger.data.error("Error occurred: \(error)")
        AppLogger.data.error("Error description: \(error.description)")

        XCTAssertTrue(true)
    }

    // MARK: - All Log Levels Test

    func testAllLogLevelsForAllCategories() {
        // Comprehensive smoke test for all loggers and all levels
        let loggers = [
            AppLogger.benefits,
            AppLogger.notifications,
            AppLogger.data,
            AppLogger.cards,
            AppLogger.settings,
            AppLogger.templates,
            AppLogger.app
        ]

        for logger in loggers {
            logger.error("Test error")
            logger.warning("Test warning")
            logger.info("Test info")
            logger.debug("Test debug")
        }

        // If we get here without crashing, all loggers work
        XCTAssertTrue(true)
    }
}
