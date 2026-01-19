//
//  PeriodMetricsTests.swift
//  CouponTrackerTests
//
//  Created by Junior Engineer on 2026-01-19.
//  Tests for PeriodMetrics calculations to verify redeemed value tracking.
//

import XCTest
import SwiftData
@testable import CouponTracker

/// Unit tests for PeriodMetrics calculation logic.
/// Uses in-memory ModelContainer for isolated testing.
@MainActor
final class PeriodMetricsTests: XCTestCase {

    // MARK: - Properties

    var modelContainer: ModelContainer!
    var modelContext: ModelContext!
    var cardRepository: CardRepository!
    var benefitRepository: BenefitRepository!

    // MARK: - Setup & Teardown

    override func setUp() async throws {
        try await super.setUp()

        // Create in-memory model container for testing
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
        cardRepository = CardRepository(modelContext: modelContext)
        benefitRepository = BenefitRepository(modelContext: modelContext)
    }

    override func tearDown() async throws {
        modelContainer = nil
        modelContext = nil
        cardRepository = nil
        benefitRepository = nil
        try await super.tearDown()
    }

    // MARK: - Test Cases

    // TEST 5.1: testPeriodMetrics_AfterMarkUsed_RedeemedValueCorrect
    func testPeriodMetrics_AfterMarkUsed_RedeemedValueCorrect() throws {
        // Given: 3 benefits: $100, $50, $25 (all available)
        let card = UserCard(nickname: "Test Card")
        modelContext.insert(card)

        let calendar = Calendar.current
        let today = Date()
        let periodStart = calendar.date(byAdding: .day, value: -15, to: today)!
        let periodEnd = calendar.date(byAdding: .day, value: 15, to: today)!

        let benefit100 = createBenefit(
            card: card,
            value: 100,
            frequency: .monthly,
            status: .available,
            periodStart: periodStart,
            periodEnd: periodEnd
        )
        let benefit50 = createBenefit(
            card: card,
            value: 50,
            frequency: .monthly,
            status: .available,
            periodStart: periodStart,
            periodEnd: periodEnd
        )
        let benefit25 = createBenefit(
            card: card,
            value: 25,
            frequency: .monthly,
            status: .available,
            periodStart: periodStart,
            periodEnd: periodEnd
        )

        modelContext.insert(benefit100)
        modelContext.insert(benefit50)
        modelContext.insert(benefit25)
        try modelContext.save()

        // When: Mark $100 benefit used
        try benefitRepository.markBenefitUsed(benefit100)

        // Then: Calculate PeriodMetrics and verify
        let benefits = [benefit100, benefit50, benefit25]
        let metrics = PeriodMetrics.calculate(for: benefits, period: .monthly)

        XCTAssertEqual(metrics.redeemedValue, 100, "Redeemed value should be $100")
        XCTAssertEqual(metrics.availableValue, 75, "Available value should be $75 ($50 + $25)")
        XCTAssertEqual(metrics.usedCount, 1, "Used count should be 1")
        XCTAssertEqual(metrics.totalValue, 175, "Total value should be $175")
    }

    // TEST 5.2: testPeriodMetrics_AfterUndo_RedeemedValueDecreases
    func testPeriodMetrics_AfterUndo_RedeemedValueDecreases() throws {
        // Given: Benefit A: $100 used, Benefit B: $50 available
        let card = UserCard(nickname: "Test Card")
        modelContext.insert(card)

        let calendar = Calendar.current
        let today = Date()
        let periodStart = calendar.date(byAdding: .day, value: -15, to: today)!
        let periodEnd = calendar.date(byAdding: .day, value: 15, to: today)!

        let benefitA = createBenefit(
            card: card,
            value: 100,
            frequency: .monthly,
            status: .available,
            periodStart: periodStart,
            periodEnd: periodEnd
        )
        let benefitB = createBenefit(
            card: card,
            value: 50,
            frequency: .monthly,
            status: .available,
            periodStart: periodStart,
            periodEnd: periodEnd
        )

        modelContext.insert(benefitA)
        modelContext.insert(benefitB)
        try modelContext.save()

        // Mark A as used
        try benefitRepository.markBenefitUsed(benefitA)

        let benefits = [benefitA, benefitB]

        // Initial redeemed = $100
        let metricsBeforeUndo = PeriodMetrics.calculate(for: benefits, period: .monthly)
        XCTAssertEqual(metricsBeforeUndo.redeemedValue, 100, "Initial redeemed value should be $100")

        // When: Undo A
        try benefitRepository.undoMarkBenefitUsed(benefitA)

        // Then: Redeemed should be $0
        let metricsAfterUndo = PeriodMetrics.calculate(for: benefits, period: .monthly)
        XCTAssertEqual(metricsAfterUndo.redeemedValue, 0, "Redeemed value should be $0 after undo")
        XCTAssertEqual(metricsAfterUndo.availableValue, 150, "Available value should be $150 ($100 + $50)")
    }

    // TEST 5.3: testPeriodMetrics_RedeemedNeverExceedsTotal [CRITICAL BUG VERIFICATION]
    func testPeriodMetrics_RedeemedNeverExceedsTotal() throws {
        // Given: Benefits totaling $500
        let card = UserCard(nickname: "Test Card")
        modelContext.insert(card)

        let calendar = Calendar.current
        let today = Date()
        let periodStart = calendar.date(byAdding: .day, value: -15, to: today)!
        let periodEnd = calendar.date(byAdding: .day, value: 15, to: today)!

        // Create 5 benefits of $100 each
        var benefits: [Benefit] = []
        for i in 1...5 {
            let benefit = createBenefit(
                card: card,
                value: 100,
                frequency: .monthly,
                status: .available,
                periodStart: periodStart,
                periodEnd: periodEnd
            )
            benefit.customName = "Benefit \(i)"
            modelContext.insert(benefit)
            benefits.append(benefit)
        }
        try modelContext.save()

        // When: Mark all used, undo all, repeat 3 times
        for iteration in 1...3 {
            // Mark all as used
            for benefit in benefits {
                if benefit.status == .available {
                    try benefitRepository.markBenefitUsed(benefit)
                }
            }

            // INVARIANT: Assert redeemedValue <= totalValue ALWAYS
            let metricsAfterMark = PeriodMetrics.calculate(for: benefits, period: .monthly)
            XCTAssertLessThanOrEqual(
                metricsAfterMark.redeemedValue,
                metricsAfterMark.totalValue,
                "CRITICAL BUG: Redeemed value ($\(metricsAfterMark.redeemedValue)) exceeds total value ($\(metricsAfterMark.totalValue)) on iteration \(iteration)"
            )
            XCTAssertEqual(
                metricsAfterMark.redeemedValue,
                500,
                "Redeemed should be $500 after marking all used on iteration \(iteration)"
            )

            // Undo all
            for benefit in benefits {
                if benefit.status == .used {
                    try benefitRepository.undoMarkBenefitUsed(benefit)
                }
            }

            // INVARIANT: Assert redeemedValue <= totalValue ALWAYS
            let metricsAfterUndo = PeriodMetrics.calculate(for: benefits, period: .monthly)
            XCTAssertLessThanOrEqual(
                metricsAfterUndo.redeemedValue,
                metricsAfterUndo.totalValue,
                "CRITICAL BUG: Redeemed value ($\(metricsAfterUndo.redeemedValue)) exceeds total value ($\(metricsAfterUndo.totalValue)) after undo on iteration \(iteration)"
            )
            XCTAssertEqual(
                metricsAfterUndo.redeemedValue,
                0,
                "Redeemed should be $0 after undoing all on iteration \(iteration)"
            )
        }

        // Final verification
        let finalMetrics = PeriodMetrics.calculate(for: benefits, period: .monthly)
        XCTAssertEqual(finalMetrics.totalValue, 500, "Total value should remain $500")
        XCTAssertEqual(finalMetrics.redeemedValue, 0, "Final redeemed value should be $0")
        XCTAssertEqual(finalMetrics.availableValue, 500, "Final available value should be $500")
    }

    // TEST 5.4: testPeriodMetrics_WithMixedFrequencies_CorrectAggregation
    func testPeriodMetrics_WithMixedFrequencies_CorrectAggregation() throws {
        // Given: Monthly benefit $100, Quarterly benefit $300
        let card = UserCard(nickname: "Test Card")
        modelContext.insert(card)

        let calendar = Calendar.current
        let today = Date()

        // Calculate proper periods based on BenefitPeriod
        let (monthlyStart, monthlyEnd) = BenefitPeriod.monthly.periodDates(for: today)
        let (quarterlyStart, quarterlyEnd) = BenefitPeriod.quarterly.periodDates(for: today)

        let monthlyBenefit = createBenefit(
            card: card,
            value: 100,
            frequency: .monthly,
            status: .available,
            periodStart: monthlyStart,
            periodEnd: monthlyEnd
        )
        monthlyBenefit.customName = "Monthly Benefit"

        let quarterlyBenefit = createBenefit(
            card: card,
            value: 300,
            frequency: .quarterly,
            status: .available,
            periodStart: quarterlyStart,
            periodEnd: quarterlyEnd
        )
        quarterlyBenefit.customName = "Quarterly Benefit"

        modelContext.insert(monthlyBenefit)
        modelContext.insert(quarterlyBenefit)
        try modelContext.save()

        let benefits = [monthlyBenefit, quarterlyBenefit]

        // When: Calculate PeriodMetrics for monthly view
        let monthlyMetrics = PeriodMetrics.calculate(for: benefits, period: .monthly)

        // Then: Monthly benefit contributes 1x, Quarterly contributes 1x
        // (both periods overlap with current monthly view)
        XCTAssertEqual(monthlyMetrics.totalCount, 2, "Should have 2 overlapping benefits")
        XCTAssertEqual(monthlyMetrics.availableValue, 400, "Available value should be $400 ($100 monthly + $300 quarterly)")

        // When: Calculate PeriodMetrics for quarterly view
        let quarterlyMetrics = PeriodMetrics.calculate(for: benefits, period: .quarterly)

        // Then: Verify aggregation multiplier effect
        // Monthly benefit contributes 3x to quarterly (appears 3 times in a quarter)
        // Quarterly benefit contributes 1x
        XCTAssertEqual(quarterlyMetrics.totalCount, 2, "Should have 2 overlapping benefits")

        // Verify the aggregation multiplier logic:
        // Monthly: $100 * 3 (3 months per quarter) = $300
        // Quarterly: $300 * 1 = $300
        // Total: $600
        XCTAssertEqual(
            quarterlyMetrics.totalValue,
            600,
            "Total value should be $600 for quarterly view (monthly $100 * 3 + quarterly $300)"
        )

        // Mark monthly benefit as used
        try benefitRepository.markBenefitUsed(monthlyBenefit)

        let quarterlyMetricsAfterUse = PeriodMetrics.calculate(for: benefits, period: .quarterly)

        // Redeemed should only count actual usage (not multiplied)
        XCTAssertEqual(
            quarterlyMetricsAfterUse.redeemedValue,
            100,
            "Redeemed value should be $100 (actual monthly benefit used once)"
        )
        XCTAssertEqual(
            quarterlyMetricsAfterUse.availableValue,
            300,
            "Available value should be $300 (quarterly benefit still available)"
        )
    }

    // MARK: - Helper Methods

    /// Creates a benefit with specified properties for testing.
    private func createBenefit(
        card: UserCard,
        value: Decimal,
        frequency: BenefitFrequency,
        status: BenefitStatus,
        periodStart: Date,
        periodEnd: Date
    ) -> Benefit {
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
        return benefit
    }
}
