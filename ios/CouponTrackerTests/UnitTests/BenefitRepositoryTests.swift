//
//  BenefitRepositoryTests.swift
//  CouponTrackerTests
//
//  Created by Junior Engineer 3 on 2026-01-17.
//

import XCTest
import SwiftData
@testable import CouponTracker

/// Unit tests for BenefitRepository operations.
/// Uses in-memory ModelContainer for isolated testing.
@MainActor
final class BenefitRepositoryTests: XCTestCase {

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

    // MARK: getBenefits(for:) Tests

    func testGetBenefits_WithValidCard_ReturnsBenefits() throws {
        // Given
        let template = createMockCardTemplate()
        let card = try cardRepository.addCard(from: template, nickname: "Test Card")

        // When
        let benefits = try repository.getBenefits(for: card)

        // Then
        XCTAssertEqual(benefits.count, template.benefits.count, "Should return all benefits for card")
        XCTAssertTrue(benefits.allSatisfy { $0.userCard?.id == card.id }, "All benefits should belong to the card")
    }

    func testGetBenefits_WithEmptyCard_ReturnsEmpty() throws {
        // Given
        let card = UserCard(nickname: "Empty Card")
        modelContext.insert(card)
        try modelContext.save()

        // When
        let benefits = try repository.getBenefits(for: card)

        // Then
        XCTAssertTrue(benefits.isEmpty, "Should return empty array for card with no benefits")
    }

    func testGetBenefits_SortsByExpiration() throws {
        // Given
        let card = UserCard(nickname: "Test Card")
        modelContext.insert(card)

        let calendar = Calendar.current
        let today = Date()

        // Create benefits with different expiration dates
        let benefit1 = createBenefit(
            card: card,
            status: .available,
            periodEnd: calendar.date(byAdding: .day, value: 10, to: today)!
        )
        let benefit2 = createBenefit(
            card: card,
            status: .available,
            periodEnd: calendar.date(byAdding: .day, value: 2, to: today)!
        )
        let benefit3 = createBenefit(
            card: card,
            status: .available,
            periodEnd: calendar.date(byAdding: .day, value: 5, to: today)!
        )

        modelContext.insert(benefit1)
        modelContext.insert(benefit2)
        modelContext.insert(benefit3)
        try modelContext.save()

        // When
        let benefits = try repository.getBenefits(for: card)

        // Then
        XCTAssertEqual(benefits.count, 3, "Should return all benefits")
        // Benefits should be sorted by expiration date (soonest first)
        XCTAssertLessThan(benefits[0].currentPeriodEnd, benefits[1].currentPeriodEnd, "First should expire soonest")
        XCTAssertLessThan(benefits[1].currentPeriodEnd, benefits[2].currentPeriodEnd, "Should be sorted by expiration")
    }

    // MARK: getAllBenefits Tests

    func testGetAllBenefits_WithMultipleCards_ReturnsAll() throws {
        // Given
        let template1 = createMockCardTemplate()
        let template2 = createMockCardTemplate()

        let card1 = try cardRepository.addCard(from: template1, nickname: "Card 1")
        let card2 = try cardRepository.addCard(from: template2, nickname: "Card 2")

        let expectedCount = template1.benefits.count + template2.benefits.count

        // When
        let benefits = try repository.getAllBenefits()

        // Then
        XCTAssertEqual(benefits.count, expectedCount, "Should return all benefits from all cards")
    }

    func testGetAllBenefits_WhenEmpty_ReturnsEmptyArray() throws {
        // When
        let benefits = try repository.getAllBenefits()

        // Then
        XCTAssertTrue(benefits.isEmpty, "Should return empty array when no benefits exist")
    }

    // MARK: getAvailableBenefits Tests

    func testGetAvailableBenefits_ReturnsOnlyAvailable() throws {
        // Given
        let card = UserCard(nickname: "Test Card")
        modelContext.insert(card)

        let calendar = Calendar.current
        let today = Date()

        let availableBenefit = createBenefit(
            card: card,
            status: .available,
            periodEnd: calendar.date(byAdding: .day, value: 10, to: today)!
        )
        let usedBenefit = createBenefit(
            card: card,
            status: .used,
            periodEnd: calendar.date(byAdding: .day, value: 10, to: today)!
        )
        let expiredBenefit = createBenefit(
            card: card,
            status: .expired,
            periodEnd: calendar.date(byAdding: .day, value: -5, to: today)!
        )

        modelContext.insert(availableBenefit)
        modelContext.insert(usedBenefit)
        modelContext.insert(expiredBenefit)
        try modelContext.save()

        // When
        let benefits = try repository.getAvailableBenefits()

        // Then
        XCTAssertEqual(benefits.count, 1, "Should return only available benefits")
        XCTAssertEqual(benefits[0].status, .available, "Returned benefit should be available")
    }

    func testGetAvailableBenefits_SortsByExpiration() throws {
        // Given
        let card = UserCard(nickname: "Test Card")
        modelContext.insert(card)

        let calendar = Calendar.current
        let today = Date()

        let benefit1 = createBenefit(
            card: card,
            status: .available,
            periodEnd: calendar.date(byAdding: .day, value: 30, to: today)!
        )
        let benefit2 = createBenefit(
            card: card,
            status: .available,
            periodEnd: calendar.date(byAdding: .day, value: 5, to: today)!
        )
        let benefit3 = createBenefit(
            card: card,
            status: .available,
            periodEnd: calendar.date(byAdding: .day, value: 15, to: today)!
        )

        modelContext.insert(benefit1)
        modelContext.insert(benefit2)
        modelContext.insert(benefit3)
        try modelContext.save()

        // When
        let benefits = try repository.getAvailableBenefits()

        // Then
        XCTAssertEqual(benefits.count, 3, "Should return all available benefits")
        XCTAssertLessThan(benefits[0].currentPeriodEnd, benefits[1].currentPeriodEnd, "First should expire soonest")
        XCTAssertLessThan(benefits[1].currentPeriodEnd, benefits[2].currentPeriodEnd, "Should be sorted by expiration")
    }

    // MARK: getExpiringBenefits Tests

    func testGetExpiringBenefits_WithinDays_ReturnsCorrectBenefits() throws {
        // Given
        let card = UserCard(nickname: "Test Card")
        modelContext.insert(card)

        let calendar = Calendar.current
        let today = Date()

        let expiringSoon = createBenefit(
            card: card,
            status: .available,
            periodEnd: calendar.date(byAdding: .day, value: 3, to: today)!
        )
        let expiringLater = createBenefit(
            card: card,
            status: .available,
            periodEnd: calendar.date(byAdding: .day, value: 10, to: today)!
        )
        let alreadyExpired = createBenefit(
            card: card,
            status: .available,
            periodEnd: calendar.date(byAdding: .day, value: -1, to: today)!
        )

        modelContext.insert(expiringSoon)
        modelContext.insert(expiringLater)
        modelContext.insert(alreadyExpired)
        try modelContext.save()

        // When
        let benefits = try repository.getExpiringBenefits(within: 7)

        // Then
        XCTAssertEqual(benefits.count, 2, "Should return benefits expiring within 7 days (including expired)")
        XCTAssertTrue(benefits.allSatisfy { $0.status == .available }, "Should only return available benefits")
    }

    func testGetExpiringBenefits_OnlyReturnsAvailable() throws {
        // Given
        let card = UserCard(nickname: "Test Card")
        modelContext.insert(card)

        let calendar = Calendar.current
        let today = Date()

        let availableExpiring = createBenefit(
            card: card,
            status: .available,
            periodEnd: calendar.date(byAdding: .day, value: 3, to: today)!
        )
        let usedExpiring = createBenefit(
            card: card,
            status: .used,
            periodEnd: calendar.date(byAdding: .day, value: 3, to: today)!
        )

        modelContext.insert(availableExpiring)
        modelContext.insert(usedExpiring)
        try modelContext.save()

        // When
        let benefits = try repository.getExpiringBenefits(within: 7)

        // Then
        XCTAssertEqual(benefits.count, 1, "Should only return available benefits")
        XCTAssertEqual(benefits[0].status, .available, "Returned benefit should be available")
    }

    // MARK: markBenefitUsed Tests

    func testMarkBenefitUsed_ChangesStatusToUsed() throws {
        // Given
        let card = UserCard(nickname: "Test Card")
        modelContext.insert(card)

        let calendar = Calendar.current
        let today = Date()

        let benefit = createBenefit(
            card: card,
            status: .available,
            periodEnd: calendar.date(byAdding: .day, value: 10, to: today)!
        )
        modelContext.insert(benefit)
        try modelContext.save()

        // When
        try repository.markBenefitUsed(benefit)

        // Then
        XCTAssertEqual(benefit.status, .used, "Benefit status should be updated to used")
    }

    func testMarkBenefitUsed_CreatesUsageHistory() throws {
        // Given
        let card = UserCard(nickname: "Test Card")
        modelContext.insert(card)

        let calendar = Calendar.current
        let today = Date()

        let benefit = createBenefit(
            card: card,
            status: .available,
            periodEnd: calendar.date(byAdding: .day, value: 10, to: today)!
        )
        benefit.customValue = 50 // Set a value for testing
        modelContext.insert(benefit)
        try modelContext.save()

        // When
        try repository.markBenefitUsed(benefit)

        // Then
        let allUsages = try modelContext.fetch(FetchDescriptor<BenefitUsage>())
        XCTAssertEqual(allUsages.count, 1, "Should create one usage record")

        let usage = allUsages[0]
        XCTAssertEqual(usage.benefit?.id, benefit.id, "Usage should be linked to benefit")
        XCTAssertEqual(usage.valueRedeemed, benefit.effectiveValue, "Should record correct value")
        XCTAssertFalse(usage.wasAutoExpired, "Should not be auto-expired")
    }

    func testMarkBenefitUsed_WithInvalidStatus_ThrowsError() throws {
        // Given
        let card = UserCard(nickname: "Test Card")
        modelContext.insert(card)

        let calendar = Calendar.current
        let today = Date()

        let benefit = createBenefit(
            card: card,
            status: .used, // Already used
            periodEnd: calendar.date(byAdding: .day, value: 10, to: today)!
        )
        modelContext.insert(benefit)
        try modelContext.save()

        // When/Then
        XCTAssertThrowsError(try repository.markBenefitUsed(benefit)) { error in
            XCTAssertTrue(error is BenefitRepositoryError, "Should throw BenefitRepositoryError")
        }
    }

    // MARK: resetBenefitForNewPeriod Tests

    func testResetBenefitForNewPeriod_UpdatesStatusToAvailable() throws {
        // Given
        let card = UserCard(nickname: "Test Card")
        modelContext.insert(card)

        let calendar = Calendar.current
        let today = Date()

        let benefit = createBenefit(
            card: card,
            status: .expired,
            periodEnd: calendar.date(byAdding: .day, value: -1, to: today)!
        )
        benefit.customFrequency = .monthly
        modelContext.insert(benefit)
        try modelContext.save()

        // When
        try repository.resetBenefitForNewPeriod(benefit)

        // Then
        XCTAssertEqual(benefit.status, .available, "Benefit should be reset to available")
    }

    func testResetBenefitForNewPeriod_CalculatesNewDates() throws {
        // Given
        let card = UserCard(nickname: "Test Card")
        modelContext.insert(card)

        let calendar = Calendar.current

        // Set period to end in the past (last month)
        var components = calendar.dateComponents([.year, .month], from: Date())
        components.month! -= 1
        components.day = 28
        let oldPeriodEnd = calendar.date(from: components)!

        let benefit = createBenefit(
            card: card,
            status: .expired,
            periodEnd: oldPeriodEnd
        )
        benefit.customFrequency = .monthly
        modelContext.insert(benefit)
        try modelContext.save()

        let oldStart = benefit.currentPeriodStart

        // When
        try repository.resetBenefitForNewPeriod(benefit)

        // Then - New period dates should be set (either calendar-based or after old period)
        XCTAssertNotEqual(benefit.currentPeriodStart, oldStart, "Period start should change")
        XCTAssertGreaterThan(benefit.currentPeriodEnd, benefit.currentPeriodStart, "Period end should be after period start")
        XCTAssertEqual(benefit.status, .available, "Status should be available after reset")
    }

    func testResetBenefitForNewPeriod_ClearsNotificationState() throws {
        // Given
        let card = UserCard(nickname: "Test Card")
        modelContext.insert(card)

        let calendar = Calendar.current
        let today = Date()

        let benefit = createBenefit(
            card: card,
            status: .expired,
            periodEnd: calendar.date(byAdding: .day, value: -1, to: today)!
        )
        benefit.customFrequency = .monthly
        benefit.lastReminderDate = today
        benefit.scheduledNotificationId = "test-notification-id"
        modelContext.insert(benefit)
        try modelContext.save()

        // When
        try repository.resetBenefitForNewPeriod(benefit)

        // Then
        XCTAssertNil(benefit.lastReminderDate, "Last reminder date should be cleared")
        XCTAssertNil(benefit.scheduledNotificationId, "Scheduled notification ID should be cleared")
    }

    // MARK: snoozeBenefit Tests

    func testSnoozeBenefit_UpdatesLastReminderDate() throws {
        // Given
        let card = UserCard(nickname: "Test Card")
        modelContext.insert(card)

        let calendar = Calendar.current
        let today = Date()

        let benefit = createBenefit(
            card: card,
            status: .available,
            periodEnd: calendar.date(byAdding: .day, value: 10, to: today)!
        )
        modelContext.insert(benefit)
        try modelContext.save()

        let snoozeUntil = calendar.date(byAdding: .day, value: 3, to: today)!

        // When
        try repository.snoozeBenefit(benefit, until: snoozeUntil)

        // Then
        XCTAssertEqual(benefit.lastReminderDate, snoozeUntil, "Last reminder date should be set to snooze date")
    }

    func testSnoozeBenefit_ClearsScheduledNotificationId() throws {
        // Given
        let card = UserCard(nickname: "Test Card")
        modelContext.insert(card)

        let calendar = Calendar.current
        let today = Date()

        let benefit = createBenefit(
            card: card,
            status: .available,
            periodEnd: calendar.date(byAdding: .day, value: 10, to: today)!
        )
        benefit.scheduledNotificationId = "existing-notification-id"
        modelContext.insert(benefit)
        try modelContext.save()

        let snoozeUntil = calendar.date(byAdding: .day, value: 3, to: today)!

        // When
        try repository.snoozeBenefit(benefit, until: snoozeUntil)

        // Then
        XCTAssertNil(benefit.scheduledNotificationId, "Scheduled notification ID should be cleared")
    }

    func testSnoozeBenefit_UpdatesTimestamp() throws {
        // Given
        let card = UserCard(nickname: "Test Card")
        modelContext.insert(card)

        let calendar = Calendar.current
        let today = Date()

        let benefit = createBenefit(
            card: card,
            status: .available,
            periodEnd: calendar.date(byAdding: .day, value: 10, to: today)!
        )
        modelContext.insert(benefit)
        try modelContext.save()

        let originalUpdateTime = benefit.updatedAt
        Thread.sleep(forTimeInterval: 0.01) // Small delay to ensure timestamp difference

        let snoozeUntil = calendar.date(byAdding: .day, value: 3, to: today)!

        // When
        try repository.snoozeBenefit(benefit, until: snoozeUntil)

        // Then
        XCTAssertGreaterThan(benefit.updatedAt, originalUpdateTime, "Updated timestamp should be newer")
    }

    // MARK: undoMarkBenefitUsed Tests

    func testUndoMarkBenefitUsed_RevertsStatusToAvailable() throws {
        // Given
        let card = UserCard(nickname: "Test Card")
        modelContext.insert(card)

        let calendar = Calendar.current
        let today = Date()

        let benefit = createBenefit(
            card: card,
            status: .available,
            periodEnd: calendar.date(byAdding: .day, value: 10, to: today)!
        )
        benefit.customValue = 50
        modelContext.insert(benefit)
        try modelContext.save()

        // Mark as used first
        try repository.markBenefitUsed(benefit)
        XCTAssertEqual(benefit.status, .used, "Benefit should be marked as used")

        // When
        try repository.undoMarkBenefitUsed(benefit)

        // Then
        XCTAssertEqual(benefit.status, .available, "Benefit status should be reverted to available")
    }

    func testUndoMarkBenefitUsed_RemovesUsageHistory() throws {
        // Given
        let card = UserCard(nickname: "Test Card")
        modelContext.insert(card)

        let calendar = Calendar.current
        let today = Date()

        let benefit = createBenefit(
            card: card,
            status: .available,
            periodEnd: calendar.date(byAdding: .day, value: 10, to: today)!
        )
        benefit.customValue = 50
        modelContext.insert(benefit)
        try modelContext.save()

        // Mark as used to create usage history
        try repository.markBenefitUsed(benefit)

        let usagesAfterMark = try modelContext.fetch(FetchDescriptor<BenefitUsage>())
        XCTAssertEqual(usagesAfterMark.count, 1, "Should have one usage record after marking as used")

        // When
        try repository.undoMarkBenefitUsed(benefit)

        // Then
        let usagesAfterUndo = try modelContext.fetch(FetchDescriptor<BenefitUsage>())
        XCTAssertEqual(usagesAfterUndo.count, 0, "Usage record should be removed after undo")
    }

    func testUndoMarkBenefitUsed_WithAvailableBenefit_ThrowsError() throws {
        // Given
        let card = UserCard(nickname: "Test Card")
        modelContext.insert(card)

        let calendar = Calendar.current
        let today = Date()

        let benefit = createBenefit(
            card: card,
            status: .available, // Not used
            periodEnd: calendar.date(byAdding: .day, value: 10, to: today)!
        )
        modelContext.insert(benefit)
        try modelContext.save()

        // When/Then
        XCTAssertThrowsError(try repository.undoMarkBenefitUsed(benefit)) { error in
            XCTAssertTrue(error is BenefitRepositoryError, "Should throw BenefitRepositoryError")
        }
    }

    func testUndoMarkBenefitUsed_UpdatesTimestamp() throws {
        // Given
        let card = UserCard(nickname: "Test Card")
        modelContext.insert(card)

        let calendar = Calendar.current
        let today = Date()

        let benefit = createBenefit(
            card: card,
            status: .available,
            periodEnd: calendar.date(byAdding: .day, value: 10, to: today)!
        )
        benefit.customValue = 50
        modelContext.insert(benefit)
        try modelContext.save()

        // Mark as used first
        try repository.markBenefitUsed(benefit)

        let timestampBeforeUndo = benefit.updatedAt
        Thread.sleep(forTimeInterval: 0.01) // Small delay to ensure timestamp difference

        // When
        try repository.undoMarkBenefitUsed(benefit)

        // Then
        XCTAssertGreaterThan(benefit.updatedAt, timestampBeforeUndo, "Updated timestamp should be newer after undo")
    }

    // MARK: Integration Tests

    func testIntegration_AddCardAndQueryBenefits() throws {
        // Given
        let template = createMockCardTemplate()

        // When
        let card = try cardRepository.addCard(from: template, nickname: "Test Card")
        let benefits = try repository.getBenefits(for: card)

        // Then
        XCTAssertEqual(benefits.count, template.benefits.count, "Should create all benefits from template")
        XCTAssertTrue(benefits.allSatisfy { $0.status == .available }, "All new benefits should be available")
    }

    func testIntegration_MarkUsedAndReset() throws {
        // Given
        let template = createMockCardTemplate()
        let card = try cardRepository.addCard(from: template, nickname: "Test Card")
        let benefit = card.benefits.first!
        benefit.customFrequency = .monthly

        // When - Mark as used
        try repository.markBenefitUsed(benefit)

        // Then
        XCTAssertEqual(benefit.status, .used, "Should be marked as used")

        // When - Reset
        try repository.resetBenefitForNewPeriod(benefit)

        // Then
        XCTAssertEqual(benefit.status, .available, "Should be available after reset")
    }

    // MARK: Edge Cases

    func testGetExpiringBenefits_WithZeroDays_ReturnsAlreadyExpired() throws {
        // Given
        let card = UserCard(nickname: "Test Card")
        modelContext.insert(card)

        let calendar = Calendar.current
        let today = Date()

        let expiredYesterday = createBenefit(
            card: card,
            status: .available,
            periodEnd: calendar.date(byAdding: .day, value: -1, to: today)!
        )
        let expiresToday = createBenefit(
            card: card,
            status: .available,
            periodEnd: today
        )
        let expiresTomorrow = createBenefit(
            card: card,
            status: .available,
            periodEnd: calendar.date(byAdding: .day, value: 1, to: today)!
        )

        modelContext.insert(expiredYesterday)
        modelContext.insert(expiresToday)
        modelContext.insert(expiresTomorrow)
        try modelContext.save()

        // When
        let benefits = try repository.getExpiringBenefits(within: 0)

        // Then
        // Should return benefits expiring on or before today
        XCTAssertGreaterThanOrEqual(benefits.count, 2, "Should include expired and expiring today")
    }

    // MARK: Helper Methods

    /// Creates a benefit with specified properties for testing.
    private func createBenefit(
        card: UserCard,
        status: BenefitStatus,
        periodEnd: Date
    ) -> Benefit {
        let calendar = Calendar.current
        let periodStart = calendar.date(byAdding: .month, value: -1, to: periodEnd)!

        return Benefit(
            userCard: card,
            templateBenefitId: UUID(),
            status: status,
            currentPeriodStart: periodStart,
            currentPeriodEnd: periodEnd,
            nextResetDate: periodEnd
        )
    }

    /// Creates a mock card template for testing.
    private func createMockCardTemplate() -> CardTemplate {
        return CardTemplate(
            id: UUID(),
            name: "Test Card",
            issuer: "Test Bank",
            artworkAsset: "test_card",
            annualFee: 100,
            primaryColorHex: "#000000",
            secondaryColorHex: "#FFFFFF",
            isActive: true,
            lastUpdated: Date(),
            benefits: [
                BenefitTemplate(
                    id: UUID(),
                    name: "Monthly Credit",
                    description: "Monthly benefit",
                    value: 15,
                    frequency: .monthly,
                    category: .transportation,
                    merchant: "Test Merchant",
                    resetDayOfMonth: 1
                ),
                BenefitTemplate(
                    id: UUID(),
                    name: "Annual Credit",
                    description: "Annual benefit",
                    value: 200,
                    frequency: .annual,
                    category: .travel,
                    merchant: nil,
                    resetDayOfMonth: nil
                )
            ]
        )
    }
}
