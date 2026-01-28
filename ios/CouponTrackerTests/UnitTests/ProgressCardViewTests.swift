//
//  ProgressCardViewTests.swift
//  CouponTrackerTests
//
//  Created: January 20, 2026
//
//  Tests for ProgressCardView to verify multi-period display functionality.
//  These tests capture use cases before refactoring MonthlyProgressCardView.
//

import XCTest
import SwiftData
@testable import CouponTracker

/// Unit tests for ProgressCardView metrics calculation by period.
/// Uses PeriodMetrics.calculate to verify period-scoped values.
@MainActor
final class ProgressCardViewTests: XCTestCase {

    // MARK: - Properties

    var modelContainer: ModelContainer!
    var modelContext: ModelContext!

    // MARK: - Setup & Teardown

    override func setUp() async throws {
        try await super.setUp()

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
    }

    override func tearDown() async throws {
        modelContainer = nil
        modelContext = nil
        try await super.tearDown()
    }

    // MARK: - Helper Methods

    private func createBenefit(
        card: UserCard,
        value: Decimal,
        frequency: BenefitFrequency,
        status: BenefitStatus
    ) -> Benefit {
        // Calculate period dates based on frequency
        let (periodStart, periodEnd, _) = frequency.calculatePeriodDates(from: Date())

        let benefit = Benefit(
            userCard: card,
            templateBenefitId: UUID(),
            customValue: value,
            status: status,
            currentPeriodStart: periodStart,
            currentPeriodEnd: periodEnd,
            nextResetDate: periodEnd
        )
        benefit.customFrequency = frequency
        modelContext.insert(benefit)
        return benefit
    }

    private func fetchAllBenefits() throws -> [Benefit] {
        let descriptor = FetchDescriptor<Benefit>()
        return try modelContext.fetch(descriptor)
    }

    // MARK: - TEST 1: Period Switching Updates Displayed Values

    func testPeriodSwitch_Monthly_ShowsMonthlyMetrics() throws {
        // Given: Monthly benefit ($100 used) and Quarterly benefit ($200 available)
        let card = UserCard(nickname: "Test Card")
        modelContext.insert(card)

        _ = createBenefit(card: card, value: 100, frequency: .monthly, status: .used)
        _ = createBenefit(card: card, value: 200, frequency: .quarterly, status: .available)
        try modelContext.save()

        // When: Calculate metrics for monthly period
        let benefits = try fetchAllBenefits()
        let metrics = PeriodMetrics.calculate(for: benefits, period: .monthly)

        // Then: Monthly shows both benefits (quarterly overlaps with monthly)
        XCTAssertEqual(metrics.usedCount, 1, "Monthly should show 1 used benefit")
        XCTAssertEqual(metrics.redeemedValue, 100, "Monthly redeemed should be $100")
    }

    func testPeriodSwitch_Quarterly_ShowsQuarterlyMetrics() throws {
        // Given: Monthly benefit ($100 used) and Quarterly benefit ($200 available)
        let card = UserCard(nickname: "Test Card")
        modelContext.insert(card)

        _ = createBenefit(card: card, value: 100, frequency: .monthly, status: .used)
        _ = createBenefit(card: card, value: 200, frequency: .quarterly, status: .available)
        try modelContext.save()

        // When: Calculate metrics for quarterly period
        let benefits = try fetchAllBenefits()
        let metrics = PeriodMetrics.calculate(for: benefits, period: .quarterly)

        // Then: Quarterly includes both with multiplier for monthly
        XCTAssertEqual(metrics.totalCount, 2, "Quarterly should include both benefits")
        // Monthly benefit contributes 3x to quarterly total (3 months in quarter)
        XCTAssertEqual(metrics.totalValue, 500, "Total should be $100*3 + $200 = $500")
    }

    func testPeriodSwitch_Annual_ShowsAnnualMetrics() throws {
        // Given: Annual benefit ($500 used)
        let card = UserCard(nickname: "Test Card")
        modelContext.insert(card)

        _ = createBenefit(card: card, value: 500, frequency: .annual, status: .used)
        try modelContext.save()

        // When: Calculate metrics for annual period
        let benefits = try fetchAllBenefits()
        let metrics = PeriodMetrics.calculate(for: benefits, period: .annual)

        // Then: Annual shows the annual benefit
        XCTAssertEqual(metrics.usedCount, 1, "Annual should show 1 used benefit")
        XCTAssertEqual(metrics.redeemedValue, 500, "Annual redeemed should be $500")
        XCTAssertEqual(metrics.totalValue, 500, "Total should be $500 (no multiplier)")
    }

    // MARK: - TEST 2: Benefit Counts Match Period Filter

    func testBenefitCount_Monthly_CountsOnlyOverlappingBenefits() throws {
        // Given: 3 monthly benefits, 1 quarterly benefit
        let card = UserCard(nickname: "Test Card")
        modelContext.insert(card)

        _ = createBenefit(card: card, value: 50, frequency: .monthly, status: .available)
        _ = createBenefit(card: card, value: 50, frequency: .monthly, status: .used)
        _ = createBenefit(card: card, value: 50, frequency: .monthly, status: .available)
        _ = createBenefit(card: card, value: 100, frequency: .quarterly, status: .available)
        try modelContext.save()

        // When: Calculate monthly metrics
        let benefits = try fetchAllBenefits()
        let metrics = PeriodMetrics.calculate(for: benefits, period: .monthly)

        // Then: All 4 benefits should be counted (quarterly overlaps monthly)
        XCTAssertEqual(metrics.totalCount, 4, "Monthly should count all overlapping benefits")
        XCTAssertEqual(metrics.usedCount, 1, "Should have 1 used benefit")
        XCTAssertEqual(metrics.availableCount, 3, "Should have 3 available benefits")
    }

    func testBenefitCount_Quarterly_CountsWithCorrectMultiplier() throws {
        // Given: 2 monthly benefits
        let card = UserCard(nickname: "Test Card")
        modelContext.insert(card)

        _ = createBenefit(card: card, value: 100, frequency: .monthly, status: .used)
        _ = createBenefit(card: card, value: 100, frequency: .monthly, status: .available)
        try modelContext.save()

        // When: Calculate quarterly metrics
        let benefits = try fetchAllBenefits()
        let metrics = PeriodMetrics.calculate(for: benefits, period: .quarterly)

        // Then: Total value should include 3x multiplier for monthly
        XCTAssertEqual(metrics.totalCount, 2, "Quarterly should count 2 benefits")
        XCTAssertEqual(metrics.totalValue, 600, "Total should be 2 * $100 * 3 = $600")
    }

    // MARK: - TEST 3: Progress Calculation Edge Cases

    func testProgress_ZeroTotal_ReturnsZeroPercent() throws {
        // Given: No benefits
        let benefits: [Benefit] = []

        // When: Calculate metrics
        let metrics = PeriodMetrics.calculate(for: benefits, period: .monthly)

        // Then: Should return 0% without division error
        XCTAssertEqual(metrics.percentageUsed, 0, "Zero total should return 0%")
        XCTAssertTrue(metrics.isEmpty, "Should be marked as empty")
    }

    func testProgress_FullyRedeemed_Returns100Percent() throws {
        // Given: 1 benefit fully used
        let card = UserCard(nickname: "Test Card")
        modelContext.insert(card)

        _ = createBenefit(card: card, value: 100, frequency: .monthly, status: .used)
        try modelContext.save()

        // When: Calculate metrics
        let benefits = try fetchAllBenefits()
        let metrics = PeriodMetrics.calculate(for: benefits, period: .monthly)

        // Then: Should return 100%
        XCTAssertEqual(metrics.percentageUsed, 100, "Fully redeemed should return 100%")
    }

    func testProgress_PartiallyRedeemed_CalculatesCorrectly() throws {
        // Given: $50 used of $200 total
        let card = UserCard(nickname: "Test Card")
        modelContext.insert(card)

        _ = createBenefit(card: card, value: 50, frequency: .monthly, status: .used)
        _ = createBenefit(card: card, value: 150, frequency: .monthly, status: .available)
        try modelContext.save()

        // When: Calculate metrics
        let benefits = try fetchAllBenefits()
        let metrics = PeriodMetrics.calculate(for: benefits, period: .monthly)

        // Then: Should return 25%
        XCTAssertEqual(metrics.percentageUsed, 25, "Should be 50/200 = 25%")
    }

    // MARK: - TEST 4: Period Label Formatting

    func testPeriodLabel_Monthly_FormatsAsMonthYear() {
        // Given: Monthly period
        let period = BenefitPeriod.monthly
        let testDate = Calendar.current.date(from: DateComponents(year: 2026, month: 1, day: 15))!

        // When: Get period label
        let label = period.periodLabel(for: testDate)

        // Then: Should format as "Month Year"
        XCTAssertEqual(label, "January 2026", "Monthly should format as 'Month Year'")
    }

    func testPeriodLabel_Quarterly_FormatsAsQ1_Year() {
        // Given: Quarterly period
        let period = BenefitPeriod.quarterly
        let testDate = Calendar.current.date(from: DateComponents(year: 2026, month: 2, day: 15))!

        // When: Get period label
        let label = period.periodLabel(for: testDate)

        // Then: Should format as "Q# Year"
        XCTAssertEqual(label, "Q1 2026", "Quarterly should format as 'Q# Year'")
    }

    func testPeriodLabel_SemiAnnual_FormatsAsH1_Year() {
        // Given: Semi-annual period
        let period = BenefitPeriod.semiAnnual
        let testDate = Calendar.current.date(from: DateComponents(year: 2026, month: 4, day: 15))!

        // When: Get period label
        let label = period.periodLabel(for: testDate)

        // Then: Should format as "H# Year"
        XCTAssertEqual(label, "H1 2026", "Semi-annual should format as 'H# Year'")
    }

    func testPeriodLabel_Annual_FormatsAsYear() {
        // Given: Annual period
        let period = BenefitPeriod.annual
        let testDate = Calendar.current.date(from: DateComponents(year: 2026, month: 6, day: 15))!

        // When: Get period label
        let label = period.periodLabel(for: testDate)

        // Then: Should format as "Year"
        XCTAssertEqual(label, "2026", "Annual should format as 'Year'")
    }
}
