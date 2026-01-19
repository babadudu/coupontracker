//
//  MultipleBenefitsTests.swift
//  CouponTrackerTests
//
//  Created by Junior Engineer 3 on 2026-01-19.
//

import XCTest
import SwiftData
@testable import CouponTracker

/// Unit tests for multiple benefits interaction scenarios.
/// Tests that mark/undo operations on multiple benefits are independent and correctly tracked.
@MainActor
final class MultipleBenefitsTests: XCTestCase {

    // MARK: - Properties

    var modelContainer: ModelContainer!
    var modelContext: ModelContext!
    var repository: BenefitRepository!
    var cardRepository: CardRepository!

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

    // MARK: TEST 4.1: Independent Tracking

    func testMarkUndoMultipleBenefits_IndependentTracking() throws {
        // Given: Create card with two benefits (A: $100, B: $50)
        let card = UserCard(nickname: "Test Card")
        modelContext.insert(card)

        let calendar = Calendar.current
        let today = Date()

        let benefitA = createBenefit(
            card: card,
            value: 100,
            status: .available,
            periodEnd: calendar.date(byAdding: .day, value: 30, to: today)!
        )
        let benefitB = createBenefit(
            card: card,
            value: 50,
            status: .available,
            periodEnd: calendar.date(byAdding: .day, value: 30, to: today)!
        )

        modelContext.insert(benefitA)
        modelContext.insert(benefitB)
        try modelContext.save()

        // When: Mark A used
        try repository.markBenefitUsed(benefitA)

        // Then: Redeemed = $100
        let redeemedAfterA = getTotalRedeemedValue(for: card)
        XCTAssertEqual(redeemedAfterA, 100, "Total redeemed should be $100 after marking A")
        XCTAssertEqual(benefitA.status, .used, "Benefit A should be marked as used")
        XCTAssertEqual(benefitB.status, .available, "Benefit B should still be available")

        // When: Mark B used
        try repository.markBenefitUsed(benefitB)

        // Then: Redeemed = $150
        let redeemedAfterB = getTotalRedeemedValue(for: card)
        XCTAssertEqual(redeemedAfterB, 150, "Total redeemed should be $150 after marking both")
        XCTAssertEqual(benefitA.status, .used, "Benefit A should still be used")
        XCTAssertEqual(benefitB.status, .used, "Benefit B should be marked as used")

        // When: Undo A
        try repository.undoMarkBenefitUsed(benefitA)

        // Then: Redeemed = $50 (only B remains)
        let redeemedAfterUndo = getTotalRedeemedValue(for: card)
        XCTAssertEqual(redeemedAfterUndo, 50, "Total redeemed should be $50 after undoing A")
        XCTAssertEqual(benefitA.status, .available, "Benefit A should be available after undo")
        XCTAssertEqual(benefitB.status, .used, "Benefit B should still be used")
    }

    // MARK: TEST 4.2: Undo Only Affects Target

    func testMarkUndoMultipleBenefits_UndoOnlyAffectsTarget() throws {
        // Given: Create card with two benefits
        let card = UserCard(nickname: "Test Card")
        modelContext.insert(card)

        let calendar = Calendar.current
        let today = Date()

        let benefitA = createBenefit(
            card: card,
            value: 100,
            status: .available,
            periodEnd: calendar.date(byAdding: .day, value: 30, to: today)!
        )
        let benefitB = createBenefit(
            card: card,
            value: 50,
            status: .available,
            periodEnd: calendar.date(byAdding: .day, value: 30, to: today)!
        )

        modelContext.insert(benefitA)
        modelContext.insert(benefitB)
        try modelContext.save()

        // When: Mark both as used
        try repository.markBenefitUsed(benefitA)
        try repository.markBenefitUsed(benefitB)

        // Then: Both should have usage records
        let usagesAfterMark = try modelContext.fetch(FetchDescriptor<BenefitUsage>())
        XCTAssertEqual(usagesAfterMark.count, 2, "Should have two usage records")

        let usageA = usagesAfterMark.first { $0.benefit?.id == benefitA.id }
        let usageB = usagesAfterMark.first { $0.benefit?.id == benefitB.id }
        XCTAssertNotNil(usageA, "Benefit A should have a usage record")
        XCTAssertNotNil(usageB, "Benefit B should have a usage record")

        // When: Undo A only
        try repository.undoMarkBenefitUsed(benefitA)

        // Then: A has no usage record, B still has usage record
        let usagesAfterUndo = try modelContext.fetch(FetchDescriptor<BenefitUsage>())
        XCTAssertEqual(usagesAfterUndo.count, 1, "Should have one usage record remaining")

        let remainingUsage = usagesAfterUndo[0]
        XCTAssertEqual(remainingUsage.benefit?.id, benefitB.id, "Remaining usage should be for benefit B")
        XCTAssertEqual(benefitA.status, .available, "Benefit A should be available")
        XCTAssertEqual(benefitB.status, .used, "Benefit B should still be used")
    }

    // MARK: TEST 4.3: Sequential Operations

    func testMarkUndoMultipleBenefits_SequentialOperations() throws {
        // Given: Create card with three benefits (A: $100, B: $50, C: $25)
        let card = UserCard(nickname: "Test Card")
        modelContext.insert(card)

        let calendar = Calendar.current
        let today = Date()

        let benefitA = createBenefit(
            card: card,
            value: 100,
            status: .available,
            periodEnd: calendar.date(byAdding: .day, value: 30, to: today)!
        )
        let benefitB = createBenefit(
            card: card,
            value: 50,
            status: .available,
            periodEnd: calendar.date(byAdding: .day, value: 30, to: today)!
        )
        let benefitC = createBenefit(
            card: card,
            value: 25,
            status: .available,
            periodEnd: calendar.date(byAdding: .day, value: 30, to: today)!
        )

        modelContext.insert(benefitA)
        modelContext.insert(benefitB)
        modelContext.insert(benefitC)
        try modelContext.save()

        // Step 1: Mark A → redeemed = $100
        try repository.markBenefitUsed(benefitA)
        XCTAssertEqual(getTotalRedeemedValue(for: card), 100, "Step 1: Redeemed should be $100")

        // Step 2: Mark B → redeemed = $150
        try repository.markBenefitUsed(benefitB)
        XCTAssertEqual(getTotalRedeemedValue(for: card), 150, "Step 2: Redeemed should be $150")

        // Step 3: Undo A → redeemed = $50
        try repository.undoMarkBenefitUsed(benefitA)
        XCTAssertEqual(getTotalRedeemedValue(for: card), 50, "Step 3: Redeemed should be $50")

        // Step 4: Mark C → redeemed = $75
        try repository.markBenefitUsed(benefitC)
        XCTAssertEqual(getTotalRedeemedValue(for: card), 75, "Step 4: Redeemed should be $75")

        // Step 5: Undo B → redeemed = $25
        try repository.undoMarkBenefitUsed(benefitB)
        XCTAssertEqual(getTotalRedeemedValue(for: card), 25, "Step 5: Redeemed should be $25")

        // Step 6: Undo C → redeemed = $0
        try repository.undoMarkBenefitUsed(benefitC)
        XCTAssertEqual(getTotalRedeemedValue(for: card), 0, "Step 6: Redeemed should be $0")

        // Final state verification
        XCTAssertEqual(benefitA.status, .available, "Benefit A should be available")
        XCTAssertEqual(benefitB.status, .available, "Benefit B should be available")
        XCTAssertEqual(benefitC.status, .available, "Benefit C should be available")

        let finalUsages = try modelContext.fetch(FetchDescriptor<BenefitUsage>())
        XCTAssertEqual(finalUsages.count, 0, "All usage records should be removed")
    }

    // MARK: - Helper Methods

    /// Creates a benefit with specified properties for testing.
    /// - Parameters:
    ///   - card: The parent UserCard
    ///   - value: The custom value for the benefit
    ///   - status: Initial status of the benefit
    ///   - periodEnd: End date of the current period
    /// - Returns: A configured Benefit entity
    private func createBenefit(
        card: UserCard,
        value: Decimal,
        status: BenefitStatus,
        periodEnd: Date
    ) -> Benefit {
        let calendar = Calendar.current
        let periodStart = calendar.date(byAdding: .month, value: -1, to: periodEnd)!

        let benefit = Benefit(
            userCard: card,
            templateBenefitId: UUID(),
            status: status,
            currentPeriodStart: periodStart,
            currentPeriodEnd: periodEnd,
            nextResetDate: periodEnd
        )
        benefit.customValue = value
        benefit.customName = "Test Benefit"

        return benefit
    }

    /// Calculates the total redeemed value for all benefits of a card.
    /// - Parameter card: The UserCard to calculate redeemed value for
    /// - Returns: Total redeemed value across all benefits
    private func getTotalRedeemedValue(for card: UserCard) -> Decimal {
        // Fetch all usage records
        let allUsages = (try? modelContext.fetch(FetchDescriptor<BenefitUsage>())) ?? []

        // Filter to only usages for benefits of this card and sum their values
        let cardUsages = allUsages.filter { usage in
            usage.benefit?.userCard?.id == card.id
        }

        return cardUsages.reduce(Decimal(0)) { total, usage in
            total + usage.valueRedeemed
        }
    }
}
