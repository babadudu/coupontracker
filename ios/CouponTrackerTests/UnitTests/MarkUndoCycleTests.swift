//
//  MarkUndoCycleTests.swift
//  CouponTrackerTests
//
//  Created by Junior Engineer on 2026-01-19.
//  Bug reproduction tests for mark/undo cycles
//

import XCTest
import SwiftData
@testable import CouponTracker

/// Tests for multiple mark/undo cycles to detect value accumulation bugs.
/// These tests reproduce the bug where repeatedly marking and undoing
/// a benefit causes the redeemed value to accumulate instead of returning to zero.
@MainActor
final class MarkUndoCycleTests: XCTestCase {

    // MARK: - Properties

    var modelContainer: ModelContainer!
    var modelContext: ModelContext!
    var repository: BenefitRepository!
    var cardRepository: CardRepository!

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
        repository = BenefitRepository(modelContext: modelContext)
        cardRepository = CardRepository(modelContext: modelContext)
    }

    override func tearDown() async throws {
        modelContainer = nil
        modelContext = nil
        repository = nil
        cardRepository = nil
        try await super.tearDown()
    }

    // MARK: - Test Cases

    // MARK: TEST 3.1: Single Mark/Undo Cycle

    func testMarkUndo_SingleCycle_ValuesReturnToOriginal() throws {
        // Given - Create benefit with $100 value
        let card = UserCard(nickname: "Test Card")
        modelContext.insert(card)

        let benefit = createBenefit(card: card, value: 100)
        modelContext.insert(benefit)
        try modelContext.save()

        // Force hydration to trigger lazy loading
        _ = benefit.effectiveValue
        _ = benefit.status

        // Record initial metrics
        let initialMetrics = PeriodMetrics.calculate(
            for: [benefit],
            period: .monthly
        )

        // When - Mark used
        try repository.markBenefitUsed(benefit)

        // Force hydration after mark
        _ = benefit.effectiveValue
        _ = benefit.status

        // Record metrics after mark
        let afterMarkMetrics = PeriodMetrics.calculate(
            for: [benefit],
            period: .monthly
        )

        // Then - Verify marked state
        XCTAssertEqual(benefit.status, .used, "Benefit should be marked as used")
        XCTAssertEqual(afterMarkMetrics.redeemedValue, Decimal(100), "Redeemed value should be $100")

        // When - Undo
        try repository.undoMarkBenefitUsed(benefit)

        // Force hydration after undo
        _ = benefit.effectiveValue
        _ = benefit.status

        // Record final metrics
        let finalMetrics = PeriodMetrics.calculate(
            for: [benefit],
            period: .monthly
        )

        // Then - Verify values returned to original
        XCTAssertEqual(benefit.status, .available, "Status should return to available")
        XCTAssertEqual(finalMetrics.redeemedValue, initialMetrics.redeemedValue, "Redeemed value should return to original")
        XCTAssertEqual(finalMetrics.availableValue, initialMetrics.availableValue, "Available value should return to original")
        XCTAssertEqual(finalMetrics.totalValue, initialMetrics.totalValue, "Total value should remain unchanged")
        XCTAssertEqual(finalMetrics.redeemedValue, Decimal(0), "Redeemed value should be $0 after undo")
    }

    // MARK: TEST 3.2: Two Mark/Undo Cycles

    func testMarkUndo_TwoCycles_ValuesRemainConsistent() throws {
        // Given - Create benefit with $50 value
        let card = UserCard(nickname: "Test Card")
        modelContext.insert(card)

        let benefit = createBenefit(card: card, value: 50)
        modelContext.insert(benefit)
        try modelContext.save()

        // Cycle 1: Mark -> Undo
        try repository.markBenefitUsed(benefit)
        XCTAssertEqual(benefit.status, .used, "Should be marked as used")
        try repository.undoMarkBenefitUsed(benefit)
        XCTAssertEqual(benefit.status, .available, "Should be available after undo")

        // Force hydration
        _ = benefit.effectiveValue

        let afterCycle1 = PeriodMetrics.calculate(for: [benefit], period: .monthly)
        XCTAssertEqual(afterCycle1.redeemedValue, Decimal(0), "Redeemed should be $0 after cycle 1")

        // Cycle 2: Mark -> Undo
        try repository.markBenefitUsed(benefit)
        XCTAssertEqual(benefit.status, .used, "Should be marked as used again")
        try repository.undoMarkBenefitUsed(benefit)
        XCTAssertEqual(benefit.status, .available, "Should be available after second undo")

        // Force hydration
        _ = benefit.effectiveValue

        let afterCycle2 = PeriodMetrics.calculate(for: [benefit], period: .monthly)

        // Then - Verify final state after 2 cycles
        XCTAssertEqual(benefit.status, .available, "Status should be available")
        XCTAssertEqual(afterCycle2.redeemedValue, Decimal(0), "Redeemed should remain $0")

        // Verify no orphaned usage records
        let allUsages = try modelContext.fetch(FetchDescriptor<BenefitUsage>())
        XCTAssertEqual(allUsages.count, 0, "No usage records should remain after complete undo")
    }

    // MARK: TEST 3.3: Five Mark/Undo Cycles - CRITICAL BUG REPRODUCTION

    func testMarkUndo_FiveCycles_NoValueAccumulation() throws {
        // Given - Create benefit with $100 value
        let card = UserCard(nickname: "Test Card")
        modelContext.insert(card)

        let benefit = createBenefit(card: card, value: 100)
        modelContext.insert(benefit)
        try modelContext.save()

        // When - Perform 5 mark/undo cycles
        for cycle in 1...5 {
            // Mark used
            try repository.markBenefitUsed(benefit)
            XCTAssertEqual(benefit.status, .used, "Cycle \(cycle): Should be marked as used")

            // Undo
            try repository.undoMarkBenefitUsed(benefit)
            XCTAssertEqual(benefit.status, .available, "Cycle \(cycle): Should be available after undo")

            // Force hydration after each cycle
            _ = benefit.effectiveValue
            _ = benefit.status

            // Verify metrics after each cycle
            let metrics = PeriodMetrics.calculate(for: [benefit], period: .monthly)
            XCTAssertEqual(
                metrics.redeemedValue,
                Decimal(0),
                "Cycle \(cycle): Redeemed value should be $0, not accumulated"
            )

            // CRITICAL: Verify redeemed never exceeds total
            XCTAssertLessThanOrEqual(
                metrics.redeemedValue,
                metrics.totalValue,
                "Cycle \(cycle): CRITICAL - Redeemed (\(metrics.redeemedValue)) should NEVER exceed total (\(metrics.totalValue))"
            )
        }

        // Then - Final verification
        let finalMetrics = PeriodMetrics.calculate(for: [benefit], period: .monthly)

        XCTAssertEqual(benefit.status, .available, "Final status should be available")
        XCTAssertEqual(finalMetrics.redeemedValue, Decimal(0), "Final redeemed should be $0")
        XCTAssertEqual(finalMetrics.availableValue, Decimal(100), "Final available should be $100")
        XCTAssertEqual(finalMetrics.totalValue, Decimal(100), "Final total should be $100")

        // Verify percentage calculation doesn't overflow
        XCTAssertEqual(finalMetrics.percentageUsed, 0, "Percentage used should be 0%")
    }

    // MARK: TEST 3.4: Multiple Cycles - No Orphaned Usage Records

    func testMarkUndo_MultipleCycles_NoOrphanedUsageRecords() throws {
        // Given - Create benefit
        let card = UserCard(nickname: "Test Card")
        modelContext.insert(card)

        let benefit = createBenefit(card: card, value: 75)
        modelContext.insert(benefit)
        try modelContext.save()

        // When - Perform 3 mark/undo cycles
        for _ in 1...3 {
            try repository.markBenefitUsed(benefit)

            // Verify usage was created
            let usagesAfterMark = try modelContext.fetch(FetchDescriptor<BenefitUsage>())
            XCTAssertEqual(usagesAfterMark.count, 1, "Should have 1 usage record after mark")

            try repository.undoMarkBenefitUsed(benefit)

            // Verify usage was deleted
            let usagesAfterUndo = try modelContext.fetch(FetchDescriptor<BenefitUsage>())
            XCTAssertEqual(usagesAfterUndo.count, 0, "Should have 0 usage records after undo")
        }

        // Then - Final verification
        let finalUsages = try modelContext.fetch(FetchDescriptor<BenefitUsage>())
        XCTAssertEqual(
            finalUsages.count,
            0,
            "No orphaned BenefitUsage records should remain after all cycles"
        )
        XCTAssertEqual(benefit.status, .available, "Benefit should be available")
    }

    // MARK: - Helper Methods

    /// Creates a benefit with specified value for testing.
    private func createBenefit(card: UserCard, value: Decimal) -> Benefit {
        let calendar = Calendar.current
        let today = Date()
        let periodStart = calendar.startOfDay(for: today)
        let periodEnd = calendar.date(byAdding: .day, value: 30, to: periodStart)!

        let benefit = Benefit(
            userCard: card,
            templateBenefitId: UUID(),
            status: .available,
            currentPeriodStart: periodStart,
            currentPeriodEnd: periodEnd,
            nextResetDate: periodEnd
        )

        // Set custom value for testing
        benefit.customValue = value

        return benefit
    }
}
