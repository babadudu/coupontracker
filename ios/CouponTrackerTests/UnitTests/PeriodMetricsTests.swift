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

    // MARK: - Historical Aggregation Tests

    /// Tests that getRedeemedValue queries BenefitUsage records for quarterly aggregation.
    /// Q1 (Jan + Feb + Mar) should sum actual redemptions across all 3 months.
    func testHistoricalAggregation_Q1_SumsThreeMonths() throws {
        // Given: BenefitUsage records for Jan, Feb, Mar
        let card = UserCard(nickname: "Test Card")
        modelContext.insert(card)

        let calendar = Calendar.current
        var components = DateComponents()
        components.year = 2026
        components.day = 15

        // Create benefit for context
        let benefit = createBenefit(
            card: card,
            value: 100,
            frequency: .monthly,
            status: .available,
            periodStart: Date(),
            periodEnd: Date()
        )
        modelContext.insert(benefit)

        // Create January usage ($50)
        components.month = 1
        let janStart = calendar.date(from: components)!
        let janUsage = BenefitUsage(
            benefit: benefit,
            usedDate: janStart,
            periodStart: janStart,
            periodEnd: calendar.date(byAdding: .month, value: 1, to: janStart)!,
            valueRedeemed: 50,
            wasAutoExpired: false,
            cardNameSnapshot: "Test",
            benefitNameSnapshot: "Benefit"
        )
        modelContext.insert(janUsage)

        // Create February usage ($30)
        components.month = 2
        let febStart = calendar.date(from: components)!
        let febUsage = BenefitUsage(
            benefit: benefit,
            usedDate: febStart,
            periodStart: febStart,
            periodEnd: calendar.date(byAdding: .month, value: 1, to: febStart)!,
            valueRedeemed: 30,
            wasAutoExpired: false,
            cardNameSnapshot: "Test",
            benefitNameSnapshot: "Benefit"
        )
        modelContext.insert(febUsage)

        // Create March usage ($20)
        components.month = 3
        let marStart = calendar.date(from: components)!
        let marUsage = BenefitUsage(
            benefit: benefit,
            usedDate: marStart,
            periodStart: marStart,
            periodEnd: calendar.date(byAdding: .month, value: 1, to: marStart)!,
            valueRedeemed: 20,
            wasAutoExpired: false,
            cardNameSnapshot: "Test",
            benefitNameSnapshot: "Benefit"
        )
        modelContext.insert(marUsage)

        try modelContext.save()

        // When: Query Q1 historical redeemed value
        components.month = 2 // Reference date in Q1
        let q1ReferenceDate = calendar.date(from: components)!
        let redeemedValue = try benefitRepository.getRedeemedValue(for: .quarterly, referenceDate: q1ReferenceDate)

        // Then: Should be $50 + $30 + $20 = $100
        XCTAssertEqual(redeemedValue, 100, "Q1 redeemed should be $100 (Jan $50 + Feb $30 + Mar $20)")
    }

    /// Tests that H2 only aggregates Q3 + Q4, excluding H1.
    func testHistoricalAggregation_H2_ExcludesH1() throws {
        // Given: BenefitUsage records across all quarters
        let card = UserCard(nickname: "Test Card")
        modelContext.insert(card)

        let calendar = Calendar.current
        var components = DateComponents()
        components.year = 2026
        components.day = 15

        let benefit = createBenefit(
            card: card,
            value: 100,
            frequency: .monthly,
            status: .available,
            periodStart: Date(),
            periodEnd: Date()
        )
        modelContext.insert(benefit)

        // H1 usages (should NOT be included in H2)
        components.month = 2 // Q1
        let q1Start = calendar.date(from: components)!
        let q1Usage = BenefitUsage(
            benefit: benefit,
            usedDate: q1Start,
            periodStart: q1Start,
            periodEnd: calendar.date(byAdding: .month, value: 1, to: q1Start)!,
            valueRedeemed: 100,
            wasAutoExpired: false,
            cardNameSnapshot: "Test",
            benefitNameSnapshot: "Benefit"
        )
        modelContext.insert(q1Usage)

        components.month = 5 // Q2
        let q2Start = calendar.date(from: components)!
        let q2Usage = BenefitUsage(
            benefit: benefit,
            usedDate: q2Start,
            periodStart: q2Start,
            periodEnd: calendar.date(byAdding: .month, value: 1, to: q2Start)!,
            valueRedeemed: 150,
            wasAutoExpired: false,
            cardNameSnapshot: "Test",
            benefitNameSnapshot: "Benefit"
        )
        modelContext.insert(q2Usage)

        // H2 usages (SHOULD be included)
        components.month = 8 // Q3
        let q3Start = calendar.date(from: components)!
        let q3Usage = BenefitUsage(
            benefit: benefit,
            usedDate: q3Start,
            periodStart: q3Start,
            periodEnd: calendar.date(byAdding: .month, value: 1, to: q3Start)!,
            valueRedeemed: 80,
            wasAutoExpired: false,
            cardNameSnapshot: "Test",
            benefitNameSnapshot: "Benefit"
        )
        modelContext.insert(q3Usage)

        components.month = 11 // Q4
        let q4Start = calendar.date(from: components)!
        let q4Usage = BenefitUsage(
            benefit: benefit,
            usedDate: q4Start,
            periodStart: q4Start,
            periodEnd: calendar.date(byAdding: .month, value: 1, to: q4Start)!,
            valueRedeemed: 70,
            wasAutoExpired: false,
            cardNameSnapshot: "Test",
            benefitNameSnapshot: "Benefit"
        )
        modelContext.insert(q4Usage)

        try modelContext.save()

        // When: Query H2 historical redeemed value
        components.month = 9 // Reference date in H2
        let h2ReferenceDate = calendar.date(from: components)!
        let redeemedValue = try benefitRepository.getRedeemedValue(for: .semiAnnual, referenceDate: h2ReferenceDate)

        // Then: Should be Q3($80) + Q4($70) = $150, NOT including H1
        XCTAssertEqual(redeemedValue, 150, "H2 redeemed should be $150 (Q3 $80 + Q4 $70), excluding H1")
    }

    /// Tests that annual aggregation sums all months.
    func testHistoricalAggregation_Annual_SumsAllMonths() throws {
        // Given: BenefitUsage records across the year
        let card = UserCard(nickname: "Test Card")
        modelContext.insert(card)

        let calendar = Calendar.current
        var components = DateComponents()
        components.year = 2026
        components.day = 15

        let benefit = createBenefit(
            card: card,
            value: 100,
            frequency: .monthly,
            status: .available,
            periodStart: Date(),
            periodEnd: Date()
        )
        modelContext.insert(benefit)

        // Create usages for H1 ($250 total)
        components.month = 2
        let h1Start = calendar.date(from: components)!
        let h1Usage = BenefitUsage(
            benefit: benefit,
            usedDate: h1Start,
            periodStart: h1Start,
            periodEnd: calendar.date(byAdding: .month, value: 1, to: h1Start)!,
            valueRedeemed: 250,
            wasAutoExpired: false,
            cardNameSnapshot: "Test",
            benefitNameSnapshot: "Benefit"
        )
        modelContext.insert(h1Usage)

        // Create usages for H2 ($150 total)
        components.month = 9
        let h2Start = calendar.date(from: components)!
        let h2Usage = BenefitUsage(
            benefit: benefit,
            usedDate: h2Start,
            periodStart: h2Start,
            periodEnd: calendar.date(byAdding: .month, value: 1, to: h2Start)!,
            valueRedeemed: 150,
            wasAutoExpired: false,
            cardNameSnapshot: "Test",
            benefitNameSnapshot: "Benefit"
        )
        modelContext.insert(h2Usage)

        try modelContext.save()

        // When: Query annual historical redeemed value
        components.month = 6 // Reference date in the year
        let annualReferenceDate = calendar.date(from: components)!
        let redeemedValue = try benefitRepository.getRedeemedValue(for: .annual, referenceDate: annualReferenceDate)

        // Then: Should be H1($250) + H2($150) = $400
        XCTAssertEqual(redeemedValue, 400, "Annual redeemed should be $400 (H1 $250 + H2 $150)")
    }

    /// Tests that auto-expired usages are excluded from historical aggregation.
    func testHistoricalAggregation_ExcludesAutoExpired() throws {
        // Given: Mix of real usages and auto-expired usages
        let card = UserCard(nickname: "Test Card")
        modelContext.insert(card)

        let calendar = Calendar.current
        var components = DateComponents()
        components.year = 2026
        components.month = 1
        components.day = 15

        let periodStart = calendar.date(from: components)!
        let periodEnd = calendar.date(byAdding: .month, value: 1, to: periodStart)!

        let benefit = createBenefit(
            card: card,
            value: 100,
            frequency: .monthly,
            status: .available,
            periodStart: periodStart,
            periodEnd: periodEnd
        )
        modelContext.insert(benefit)

        // Real usage ($50)
        let realUsage = BenefitUsage(
            benefit: benefit,
            usedDate: periodStart,
            periodStart: periodStart,
            periodEnd: periodEnd,
            valueRedeemed: 50,
            wasAutoExpired: false,
            cardNameSnapshot: "Test",
            benefitNameSnapshot: "Benefit"
        )
        modelContext.insert(realUsage)

        // Auto-expired usage ($100) - should be EXCLUDED
        let expiredUsage = BenefitUsage(
            benefit: benefit,
            usedDate: periodEnd,
            periodStart: periodStart,
            periodEnd: periodEnd,
            valueRedeemed: 100,
            wasAutoExpired: true,
            cardNameSnapshot: "Test",
            benefitNameSnapshot: "Benefit"
        )
        modelContext.insert(expiredUsage)

        try modelContext.save()

        // When: Query monthly historical redeemed value
        let redeemedValue = try benefitRepository.getRedeemedValue(for: .monthly, referenceDate: periodStart)

        // Then: Should be $50 only, excluding auto-expired
        XCTAssertEqual(redeemedValue, 50, "Redeemed should be $50, excluding auto-expired $100")
    }

    /// Tests calculateWithHistory uses provided historical value instead of status.
    func testCalculateWithHistory_UsesProvidedHistoricalValue() throws {
        // Given: Benefits with current status (all available)
        let card = UserCard(nickname: "Test Card")
        modelContext.insert(card)

        let calendar = Calendar.current
        let today = Date()
        let periodStart = calendar.date(byAdding: .day, value: -15, to: today)!
        let periodEnd = calendar.date(byAdding: .day, value: 15, to: today)!

        let benefit1 = createBenefit(
            card: card,
            value: 100,
            frequency: .monthly,
            status: .available,
            periodStart: periodStart,
            periodEnd: periodEnd
        )
        let benefit2 = createBenefit(
            card: card,
            value: 50,
            frequency: .monthly,
            status: .available,
            periodStart: periodStart,
            periodEnd: periodEnd
        )

        modelContext.insert(benefit1)
        modelContext.insert(benefit2)
        try modelContext.save()

        let benefits = [benefit1, benefit2]

        // When: Calculate with historical value of $75 (doesn't match status)
        let historicalRedeemed: Decimal = 75
        let metrics = PeriodMetrics.calculateWithHistory(
            for: benefits,
            historicalRedeemed: historicalRedeemed,
            period: .monthly
        )

        // Then: Redeemed should be $75 (from history), not $0 (from status)
        XCTAssertEqual(metrics.redeemedValue, 75, "Should use historical value $75")
        XCTAssertEqual(metrics.totalValue, 150, "Total should still be $150")
        XCTAssertEqual(metrics.availableValue, 150, "Available based on status should be $150")
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
