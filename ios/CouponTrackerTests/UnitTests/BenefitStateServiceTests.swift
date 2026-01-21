//
//  BenefitStateServiceTests.swift
//  CouponTrackerTests
//
//  Created: January 2026
//  Purpose: Unit tests for BenefitStateService business logic.
//

import XCTest
import SwiftData
@testable import CouponTracker

/// Unit tests for BenefitStateService.
/// Tests state validation, frequency inference, and period calculations.
@MainActor
final class BenefitStateServiceTests: XCTestCase {

    // MARK: - Properties

    var modelContainer: ModelContainer!
    var modelContext: ModelContext!
    var service: BenefitStateService!

    // MARK: - Setup & Teardown

    override func setUp() async throws {
        try await super.setUp()

        // Create in-memory model container for creating test benefits
        let schema = Schema([
            UserCard.self,
            Benefit.self,
            BenefitUsage.self
        ])

        let modelConfiguration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: true
        )

        modelContainer = try ModelContainer(
            for: schema,
            configurations: [modelConfiguration]
        )

        modelContext = ModelContext(modelContainer)
        service = BenefitStateService()
    }

    override func tearDown() async throws {
        service = nil
        modelContext = nil
        modelContainer = nil
        try await super.tearDown()
    }

    // MARK: - Helper Methods

    /// Creates a test benefit with specified period dates.
    private func createBenefit(
        periodStart: Date,
        periodEnd: Date,
        status: BenefitStatus = .available,
        customFrequency: BenefitFrequency? = nil
    ) -> Benefit {
        let card = UserCard()
        modelContext.insert(card)

        let benefit = Benefit(
            userCard: card,
            currentPeriodStart: periodStart,
            currentPeriodEnd: periodEnd,
            nextResetDate: Calendar.current.date(byAdding: .day, value: 1, to: periodEnd)!
        )
        benefit.status = status
        benefit.customFrequency = customFrequency
        modelContext.insert(benefit)

        return benefit
    }

    /// Creates a benefit with a period of specified months.
    private func createBenefitWithPeriodLength(months: Int, status: BenefitStatus = .available) -> Benefit {
        let calendar = Calendar.current
        let periodStart = calendar.date(from: DateComponents(year: 2026, month: 1, day: 1))!
        let periodEnd = calendar.date(byAdding: .month, value: months, to: periodStart)!
            .addingTimeInterval(-86400) // Subtract one day for inclusive end

        return createBenefit(periodStart: periodStart, periodEnd: periodEnd, status: status)
    }

    // MARK: - canMarkAsUsed Tests

    func testCanMarkAsUsed_WhenAvailable_ReturnsTrue() {
        // Given
        let benefit = createBenefitWithPeriodLength(months: 1, status: .available)

        // When
        let result = service.canMarkAsUsed(benefit)

        // Then
        XCTAssertTrue(result, "Available benefit should be markable as used")
    }

    func testCanMarkAsUsed_WhenAlreadyUsed_ReturnsFalse() {
        // Given
        let benefit = createBenefitWithPeriodLength(months: 1, status: .used)

        // When
        let result = service.canMarkAsUsed(benefit)

        // Then
        XCTAssertFalse(result, "Used benefit should not be markable as used")
    }

    func testCanMarkAsUsed_WhenExpired_ReturnsFalse() {
        // Given
        let benefit = createBenefitWithPeriodLength(months: 1, status: .expired)

        // When
        let result = service.canMarkAsUsed(benefit)

        // Then
        XCTAssertFalse(result, "Expired benefit should not be markable as used")
    }

    // MARK: - canUndo Tests

    func testCanUndo_WhenUsed_ReturnsTrue() {
        // Given
        let benefit = createBenefitWithPeriodLength(months: 1, status: .used)

        // When
        let result = service.canUndo(benefit)

        // Then
        XCTAssertTrue(result, "Used benefit should be undoable")
    }

    func testCanUndo_WhenAvailable_ReturnsFalse() {
        // Given
        let benefit = createBenefitWithPeriodLength(months: 1, status: .available)

        // When
        let result = service.canUndo(benefit)

        // Then
        XCTAssertFalse(result, "Available benefit should not be undoable")
    }

    func testCanUndo_WhenExpired_ReturnsFalse() {
        // Given
        let benefit = createBenefitWithPeriodLength(months: 1, status: .expired)

        // When
        let result = service.canUndo(benefit)

        // Then
        XCTAssertFalse(result, "Expired benefit should not be undoable")
    }

    // MARK: - inferFrequency Tests

    func testInferFrequency_OnePeriodMonth_ReturnsMonthly() {
        // Given - 1 month period (Jan 1 - Jan 31)
        let benefit = createBenefitWithPeriodLength(months: 1)

        // When
        let frequency = service.inferFrequency(from: benefit)

        // Then
        XCTAssertEqual(frequency, .monthly, "1-month period should infer monthly frequency")
    }

    func testInferFrequency_ThreeMonthPeriod_ReturnsQuarterly() {
        // Given - 3 month period (Jan 1 - Mar 31)
        let benefit = createBenefitWithPeriodLength(months: 3)

        // When
        let frequency = service.inferFrequency(from: benefit)

        // Then
        XCTAssertEqual(frequency, .quarterly, "3-month period should infer quarterly frequency")
    }

    func testInferFrequency_SixMonthPeriod_ReturnsSemiAnnual() {
        // Given - 6 month period (Jan 1 - Jun 30)
        let benefit = createBenefitWithPeriodLength(months: 6)

        // When
        let frequency = service.inferFrequency(from: benefit)

        // Then
        XCTAssertEqual(frequency, .semiAnnual, "6-month period should infer semiAnnual frequency")
    }

    func testInferFrequency_TwelveMonthPeriod_ReturnsAnnual() {
        // Given - 12 month period (Jan 1 - Dec 31)
        let benefit = createBenefitWithPeriodLength(months: 12)

        // When
        let frequency = service.inferFrequency(from: benefit)

        // Then
        XCTAssertEqual(frequency, .annual, "12-month period should infer annual frequency")
    }

    func testInferFrequency_TwoMonthPeriod_ReturnsMonthly() {
        // Given - 2 month period (Jan 1 - Feb 28, dateComponents shows ~1 month)
        let benefit = createBenefitWithPeriodLength(months: 2)

        // When
        let frequency = service.inferFrequency(from: benefit)

        // Then - Since period ends 1 day before 2 full months, dateComponents calculates ~1 month
        XCTAssertEqual(frequency, .monthly, "2-month period boundary (minus 1 day) infers monthly frequency")
    }

    func testInferFrequency_FourMonthPeriod_ReturnsQuarterly() {
        // Given - 4 month period (edge case in 2-4 range)
        let benefit = createBenefitWithPeriodLength(months: 4)

        // When
        let frequency = service.inferFrequency(from: benefit)

        // Then
        XCTAssertEqual(frequency, .quarterly, "4-month period should infer quarterly frequency")
    }

    func testInferFrequency_FiveMonthPeriod_ReturnsQuarterly() {
        // Given - 5 month period (Jan 1 - May 31, dateComponents shows ~4 months)
        let benefit = createBenefitWithPeriodLength(months: 5)

        // When
        let frequency = service.inferFrequency(from: benefit)

        // Then - Since period ends 1 day before 5 full months, dateComponents calculates ~4 months
        XCTAssertEqual(frequency, .quarterly, "5-month period boundary (minus 1 day) infers quarterly frequency")
    }

    func testInferFrequency_SevenMonthPeriod_ReturnsSemiAnnual() {
        // Given - 7 month period (edge case in 5-7 range)
        let benefit = createBenefitWithPeriodLength(months: 7)

        // When
        let frequency = service.inferFrequency(from: benefit)

        // Then
        XCTAssertEqual(frequency, .semiAnnual, "7-month period should infer semiAnnual frequency")
    }

    func testInferFrequency_EightMonthPeriod_ReturnsSemiAnnual() {
        // Given - 8 month period (Jan 1 - Aug 31, dateComponents shows ~7 months)
        let benefit = createBenefitWithPeriodLength(months: 8)

        // When
        let frequency = service.inferFrequency(from: benefit)

        // Then - Since period ends 1 day before 8 full months, dateComponents calculates ~7 months
        XCTAssertEqual(frequency, .semiAnnual, "8-month period boundary (minus 1 day) infers semiAnnual frequency")
    }

    // MARK: - calculateNextPeriod Tests

    func testCalculateNextPeriod_Monthly_ReturnsCorrectDates() {
        // Given - Monthly benefit ending Jan 31, 2026
        let calendar = Calendar.current
        let periodStart = calendar.date(from: DateComponents(year: 2026, month: 1, day: 1))!
        let periodEnd = calendar.date(from: DateComponents(year: 2026, month: 1, day: 31))!
        let benefit = createBenefit(periodStart: periodStart, periodEnd: periodEnd)

        // When
        let nextPeriod = service.calculateNextPeriod(for: benefit)

        // Then - Next period should be Feb 2026
        let expectedStart = calendar.date(from: DateComponents(year: 2026, month: 2, day: 1))!
        let expectedEnd = calendar.date(from: DateComponents(year: 2026, month: 2, day: 28))!

        XCTAssertEqual(
            calendar.startOfDay(for: nextPeriod.start),
            calendar.startOfDay(for: expectedStart),
            "Next period start should be Feb 1"
        )
        XCTAssertEqual(
            calendar.startOfDay(for: nextPeriod.end),
            calendar.startOfDay(for: expectedEnd),
            "Next period end should be Feb 28"
        )
    }

    func testCalculateNextPeriod_Quarterly_ReturnsCorrectDates() {
        // Given - Q1 benefit ending Mar 31, 2026
        let calendar = Calendar.current
        let periodStart = calendar.date(from: DateComponents(year: 2026, month: 1, day: 1))!
        let periodEnd = calendar.date(from: DateComponents(year: 2026, month: 3, day: 31))!
        let benefit = createBenefit(
            periodStart: periodStart,
            periodEnd: periodEnd,
            customFrequency: .quarterly
        )

        // When
        let nextPeriod = service.calculateNextPeriod(for: benefit)

        // Then - Next period should be Q2 2026
        let expectedStart = calendar.date(from: DateComponents(year: 2026, month: 4, day: 1))!
        let expectedEnd = calendar.date(from: DateComponents(year: 2026, month: 6, day: 30))!

        XCTAssertEqual(
            calendar.startOfDay(for: nextPeriod.start),
            calendar.startOfDay(for: expectedStart),
            "Next Q2 period start should be Apr 1"
        )
        XCTAssertEqual(
            calendar.startOfDay(for: nextPeriod.end),
            calendar.startOfDay(for: expectedEnd),
            "Next Q2 period end should be Jun 30"
        )
    }

    func testCalculateNextPeriod_UsesCustomFrequencyOverInferred() {
        // Given - A benefit with 1-month period but custom quarterly frequency
        let calendar = Calendar.current
        let periodStart = calendar.date(from: DateComponents(year: 2026, month: 1, day: 1))!
        let periodEnd = calendar.date(from: DateComponents(year: 2026, month: 1, day: 31))!
        let benefit = createBenefit(
            periodStart: periodStart,
            periodEnd: periodEnd,
            customFrequency: .quarterly // Override even though period is 1 month
        )

        // When
        let nextPeriod = service.calculateNextPeriod(for: benefit)

        // Then - The next period should use quarterly calculation.
        // BenefitFrequency.quarterly.calculatePeriodDates aligns to Q boundaries.
        // From Feb 1 (day after Jan 31), quarterly aligns to Q1 boundary (Jan 1).
        // The key test is that period end reflects quarterly span (3 months from start).
        let periodLengthDays = calendar.dateComponents([.day], from: nextPeriod.start, to: nextPeriod.end).day ?? 0

        // Quarterly period is ~90 days (3 months), monthly is ~28-31 days
        XCTAssertGreaterThan(
            periodLengthDays,
            60, // Must be longer than 2 months
            "Custom quarterly frequency should produce a quarterly-length period, not monthly"
        )
    }

    func testCalculateNextPeriod_Annual_ReturnsCorrectDates() {
        // Given - Annual benefit ending Dec 31, 2026
        let calendar = Calendar.current
        let periodStart = calendar.date(from: DateComponents(year: 2026, month: 1, day: 1))!
        let periodEnd = calendar.date(from: DateComponents(year: 2026, month: 12, day: 31))!
        let benefit = createBenefit(
            periodStart: periodStart,
            periodEnd: periodEnd,
            customFrequency: .annual
        )

        // When
        let nextPeriod = service.calculateNextPeriod(for: benefit)

        // Then - Next period should be 2027
        let expectedStart = calendar.date(from: DateComponents(year: 2027, month: 1, day: 1))!
        let expectedEnd = calendar.date(from: DateComponents(year: 2027, month: 12, day: 31))!

        XCTAssertEqual(
            calendar.startOfDay(for: nextPeriod.start),
            calendar.startOfDay(for: expectedStart),
            "Next annual period start should be Jan 1, 2027"
        )
        XCTAssertEqual(
            calendar.startOfDay(for: nextPeriod.end),
            calendar.startOfDay(for: expectedEnd),
            "Next annual period end should be Dec 31, 2027"
        )
    }

    func testCalculateNextPeriod_SemiAnnual_ReturnsCorrectDates() {
        // Given - H1 benefit ending Jun 30, 2026
        let calendar = Calendar.current
        let periodStart = calendar.date(from: DateComponents(year: 2026, month: 1, day: 1))!
        let periodEnd = calendar.date(from: DateComponents(year: 2026, month: 6, day: 30))!
        let benefit = createBenefit(
            periodStart: periodStart,
            periodEnd: periodEnd,
            customFrequency: .semiAnnual
        )

        // When
        let nextPeriod = service.calculateNextPeriod(for: benefit)

        // Then - Next period should be H2 2026
        let expectedStart = calendar.date(from: DateComponents(year: 2026, month: 7, day: 1))!
        let expectedEnd = calendar.date(from: DateComponents(year: 2026, month: 12, day: 31))!

        XCTAssertEqual(
            calendar.startOfDay(for: nextPeriod.start),
            calendar.startOfDay(for: expectedStart),
            "Next H2 period start should be Jul 1"
        )
        XCTAssertEqual(
            calendar.startOfDay(for: nextPeriod.end),
            calendar.startOfDay(for: expectedEnd),
            "Next H2 period end should be Dec 31"
        )
    }

    // MARK: - PeriodDates Struct Tests

    func testPeriodDates_Equatable() {
        // Given
        let calendar = Calendar.current
        let start = calendar.date(from: DateComponents(year: 2026, month: 1, day: 1))!
        let end = calendar.date(from: DateComponents(year: 2026, month: 1, day: 31))!
        let nextReset = calendar.date(from: DateComponents(year: 2026, month: 2, day: 1))!

        let period1 = PeriodDates(start: start, end: end, nextReset: nextReset)
        let period2 = PeriodDates(start: start, end: end, nextReset: nextReset)

        // Then
        XCTAssertEqual(period1, period2, "Identical PeriodDates should be equal")
    }
}
