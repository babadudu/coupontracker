//
//  DateExtensionsTests.swift
//  CouponTrackerTests
//
//  Critical tests for date logic - date bugs cause incorrect benefit expiration.
//

import XCTest
@testable import CouponTracker

final class DateExtensionsTests: XCTestCase {

    // MARK: - adding(days:) Tests

    func testAddingPositiveDays() {
        let calendar = Calendar.current
        let baseDate = calendar.date(from: DateComponents(year: 2024, month: 1, day: 15))!

        let result = baseDate.adding(days: 5)
        let expected = calendar.date(from: DateComponents(year: 2024, month: 1, day: 20))!

        XCTAssertEqual(result, expected, "Adding 5 days should move from Jan 15 to Jan 20")
    }

    func testAddingNegativeDays() {
        let calendar = Calendar.current
        let baseDate = calendar.date(from: DateComponents(year: 2024, month: 1, day: 15))!

        let result = baseDate.adding(days: -5)
        let expected = calendar.date(from: DateComponents(year: 2024, month: 1, day: 10))!

        XCTAssertEqual(result, expected, "Adding -5 days should move from Jan 15 to Jan 10")
    }

    func testAddingZeroDays() {
        let calendar = Calendar.current
        let baseDate = calendar.date(from: DateComponents(year: 2024, month: 1, day: 15))!

        let result = baseDate.adding(days: 0)

        XCTAssertEqual(result, baseDate, "Adding 0 days should return the same date")
    }

    // MARK: - Month Boundary Tests

    func testMonthBoundaryJanToFeb() {
        let calendar = Calendar.current
        let jan31 = calendar.date(from: DateComponents(year: 2024, month: 1, day: 31))!

        let result = jan31.adding(days: 1)
        let expected = calendar.date(from: DateComponents(year: 2024, month: 2, day: 1))!

        XCTAssertEqual(result, expected, "Jan 31 + 1 day should be Feb 1")
    }

    func testMonthBoundaryFebToMar() {
        let calendar = Calendar.current
        let feb28 = calendar.date(from: DateComponents(year: 2025, month: 2, day: 28))!

        let result = feb28.adding(days: 1)
        let expected = calendar.date(from: DateComponents(year: 2025, month: 3, day: 1))!

        XCTAssertEqual(result, expected, "Feb 28 + 1 day (non-leap year) should be Mar 1")
    }

    func testMonthBoundaryDecToJan() {
        let calendar = Calendar.current
        let dec31 = calendar.date(from: DateComponents(year: 2024, month: 12, day: 31))!

        let result = dec31.adding(days: 1)
        let expected = calendar.date(from: DateComponents(year: 2025, month: 1, day: 1))!

        XCTAssertEqual(result, expected, "Dec 31 + 1 day should be Jan 1 of next year")
    }

    // MARK: - Year Boundary Tests

    func testYearBoundaryBackward() {
        let calendar = Calendar.current
        let jan1 = calendar.date(from: DateComponents(year: 2024, month: 1, day: 1))!

        let result = jan1.adding(days: -1)
        let expected = calendar.date(from: DateComponents(year: 2023, month: 12, day: 31))!

        XCTAssertEqual(result, expected, "Jan 1 - 1 day should be Dec 31 of previous year")
    }

    // MARK: - Leap Year Tests

    func testLeapYearFeb29() {
        let calendar = Calendar.current
        let feb29 = calendar.date(from: DateComponents(year: 2024, month: 2, day: 29))!

        let result = feb29.adding(days: 1)
        let expected = calendar.date(from: DateComponents(year: 2024, month: 3, day: 1))!

        XCTAssertEqual(result, expected, "Feb 29 + 1 day (leap year) should be Mar 1")
    }

    func testLeapYearFeb28ToFeb29() {
        let calendar = Calendar.current
        let feb28 = calendar.date(from: DateComponents(year: 2024, month: 2, day: 28))!

        let result = feb28.adding(days: 1)
        let expected = calendar.date(from: DateComponents(year: 2024, month: 2, day: 29))!

        XCTAssertEqual(result, expected, "Feb 28 + 1 day (leap year) should be Feb 29")
    }

    // MARK: - startOfMonth() Tests

    func testStartOfMonthMiddleOfMonth() {
        let calendar = Calendar.current
        let midMonth = calendar.date(from: DateComponents(year: 2024, month: 6, day: 15, hour: 14, minute: 30))!

        let result = midMonth.startOfMonth()
        let expected = calendar.date(from: DateComponents(year: 2024, month: 6, day: 1))!

        XCTAssertEqual(result, expected, "Start of month for Jun 15 should be Jun 1 at midnight")
    }

    func testStartOfMonthFirstDay() {
        let calendar = Calendar.current
        let firstDay = calendar.date(from: DateComponents(year: 2024, month: 3, day: 1))!

        let result = firstDay.startOfMonth()

        XCTAssertEqual(result, firstDay, "Start of month for first day should return the same date")
    }

    func testStartOfMonthLastDay() {
        let calendar = Calendar.current
        let lastDay = calendar.date(from: DateComponents(year: 2024, month: 1, day: 31))!

        let result = lastDay.startOfMonth()
        let expected = calendar.date(from: DateComponents(year: 2024, month: 1, day: 1))!

        XCTAssertEqual(result, expected, "Start of month for Jan 31 should be Jan 1")
    }

    // MARK: - endOfMonth() Tests

    func testEndOfMonthMiddleOfMonth() {
        let calendar = Calendar.current
        let midMonth = calendar.date(from: DateComponents(year: 2024, month: 6, day: 15))!

        let result = midMonth.endOfMonth()

        let components = calendar.dateComponents([.year, .month, .day], from: result)
        XCTAssertEqual(components.year, 2024, "End of month year should be 2024")
        XCTAssertEqual(components.month, 6, "End of month should be in June")
        XCTAssertEqual(components.day, 30, "End of June should be day 30")
    }

    func testEndOfMonthJanuary() {
        let calendar = Calendar.current
        let jan15 = calendar.date(from: DateComponents(year: 2024, month: 1, day: 15))!

        let result = jan15.endOfMonth()

        let components = calendar.dateComponents([.year, .month, .day], from: result)
        XCTAssertEqual(components.day, 31, "End of January should be day 31")
    }

    func testEndOfMonthFebruaryNonLeapYear() {
        let calendar = Calendar.current
        let feb15 = calendar.date(from: DateComponents(year: 2025, month: 2, day: 15))!

        let result = feb15.endOfMonth()

        let components = calendar.dateComponents([.year, .month, .day], from: result)
        XCTAssertEqual(components.day, 28, "End of February (non-leap year) should be day 28")
    }

    func testEndOfMonthFebruaryLeapYear() {
        let calendar = Calendar.current
        let feb15 = calendar.date(from: DateComponents(year: 2024, month: 2, day: 15))!

        let result = feb15.endOfMonth()

        let components = calendar.dateComponents([.year, .month, .day], from: result)
        XCTAssertEqual(components.day, 29, "End of February (leap year) should be day 29")
    }

    // MARK: - days(until:) Tests

    func testDaysUntilFutureDate() {
        let calendar = Calendar.current
        let start = calendar.date(from: DateComponents(year: 2024, month: 1, day: 1))!
        let end = calendar.date(from: DateComponents(year: 2024, month: 1, day: 10))!

        let result = start.days(until: end)

        XCTAssertEqual(result, 9, "Days from Jan 1 to Jan 10 should be 9")
    }

    func testDaysUntilPastDate() {
        let calendar = Calendar.current
        let start = calendar.date(from: DateComponents(year: 2024, month: 1, day: 10))!
        let end = calendar.date(from: DateComponents(year: 2024, month: 1, day: 1))!

        let result = start.days(until: end)

        XCTAssertEqual(result, -9, "Days from Jan 10 to Jan 1 should be -9")
    }

    func testDaysUntilSameDate() {
        let calendar = Calendar.current
        let date = calendar.date(from: DateComponents(year: 2024, month: 1, day: 15))!

        let result = date.days(until: date)

        XCTAssertEqual(result, 0, "Days from a date to itself should be 0")
    }

    func testDaysUntilCrossMonthBoundary() {
        let calendar = Calendar.current
        let jan31 = calendar.date(from: DateComponents(year: 2024, month: 1, day: 31))!
        let feb5 = calendar.date(from: DateComponents(year: 2024, month: 2, day: 5))!

        let result = jan31.days(until: feb5)

        XCTAssertEqual(result, 5, "Days from Jan 31 to Feb 5 should be 5")
    }

    func testDaysUntilCrossYearBoundary() {
        let calendar = Calendar.current
        let dec25 = calendar.date(from: DateComponents(year: 2024, month: 12, day: 25))!
        let jan5 = calendar.date(from: DateComponents(year: 2025, month: 1, day: 5))!

        let result = dec25.days(until: jan5)

        XCTAssertEqual(result, 11, "Days from Dec 25 to Jan 5 (next year) should be 11")
    }

    // MARK: - isToday Tests

    func testIsTodayTrue() {
        let now = Date()

        XCTAssertTrue(now.isToday, "Current date should be today")
    }

    func testIsTodayFalse() {
        let calendar = Calendar.current
        let yesterday = calendar.date(byAdding: .day, value: -1, to: Date())!

        XCTAssertFalse(yesterday.isToday, "Yesterday should not be today")
    }

    func testIsTodayTomorrow() {
        let calendar = Calendar.current
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: Date())!

        XCTAssertFalse(tomorrow.isToday, "Tomorrow should not be today")
    }

    func testIsTodaySameDayDifferentTime() {
        let calendar = Calendar.current
        // Use start of today + 5 hours to avoid crossing midnight
        let startOfToday = calendar.startOfDay(for: Date())
        let laterToday = calendar.date(byAdding: .hour, value: 5, to: startOfToday)!

        XCTAssertTrue(laterToday.isToday, "Later time on the same day should still be today")
    }
}
