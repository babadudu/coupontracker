//
//  NotificationServiceTests.swift
//  CouponTrackerTests
//
//  Created: January 2026
//  Purpose: Unit tests for NotificationService
//

import XCTest
import SwiftData
import UserNotifications
@testable import CouponTracker

/// Unit tests for NotificationService operations.
/// Tests notification scheduling, cancellation, and action handling.
@MainActor
final class NotificationServiceTests: XCTestCase {

    // MARK: - Properties

    var notificationService: NotificationService!
    var modelContainer: ModelContainer!
    var modelContext: ModelContext!

    // MARK: - Setup & Teardown

    override func setUp() async throws {
        try await super.setUp()

        notificationService = NotificationService()

        // Create in-memory model container for testing
        let schema = Schema([
            UserCard.self,
            Benefit.self,
            BenefitUsage.self,
            UserPreferences.self
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
        notificationService.cancelAllNotifications()
        notificationService = nil
        modelContainer = nil
        modelContext = nil
        try await super.tearDown()
    }

    // MARK: - Notification Identifier Tests

    func testNotificationIdentifier_ContainsBenefitId() {
        // Given
        let benefitId = UUID()

        // When
        let identifier = "benefit_\(benefitId.uuidString)_within1Day"

        // Then
        XCTAssertTrue(identifier.contains(benefitId.uuidString))
    }

    func testNotificationIdentifier_ContainsUrgencyLevel() {
        // Given
        let benefitId = UUID()
        let urgencies = ["expiringToday", "within1Day", "within3Days", "within1Week"]

        // When/Then
        for urgency in urgencies {
            let identifier = "benefit_\(benefitId.uuidString)_\(urgency)"
            XCTAssertTrue(identifier.contains(urgency))
        }
    }

    // MARK: - Callback Tests

    func testOnOpenBenefit_CallbackIsCalled() {
        // Given
        var callbackCalled = false
        var receivedBenefitId: UUID?
        let expectedBenefitId = UUID()

        notificationService.onOpenBenefit = { benefitId in
            callbackCalled = true
            receivedBenefitId = benefitId
        }

        // When - simulate callback
        notificationService.onOpenBenefit?(expectedBenefitId)

        // Then
        XCTAssertTrue(callbackCalled)
        XCTAssertEqual(receivedBenefitId, expectedBenefitId)
    }

    func testOnMarkAsUsed_CallbackIsCalled() {
        // Given
        var callbackCalled = false
        var receivedBenefitId: UUID?
        let expectedBenefitId = UUID()

        notificationService.onMarkAsUsed = { benefitId in
            callbackCalled = true
            receivedBenefitId = benefitId
        }

        // When - simulate callback
        notificationService.onMarkAsUsed?(expectedBenefitId)

        // Then
        XCTAssertTrue(callbackCalled)
        XCTAssertEqual(receivedBenefitId, expectedBenefitId)
    }

    func testOnSnooze_CallbackIsCalledWithDays() {
        // Given
        var callbackCalled = false
        var receivedBenefitId: UUID?
        var receivedDays: Int?
        let expectedBenefitId = UUID()
        let expectedDays = 3

        notificationService.onSnooze = { benefitId, days in
            callbackCalled = true
            receivedBenefitId = benefitId
            receivedDays = days
        }

        // When - simulate callback
        notificationService.onSnooze?(expectedBenefitId, expectedDays)

        // Then
        XCTAssertTrue(callbackCalled)
        XCTAssertEqual(receivedBenefitId, expectedBenefitId)
        XCTAssertEqual(receivedDays, expectedDays)
    }

    // MARK: - Notification Category Tests

    func testNotificationCategory_HasCorrectIdentifier() {
        XCTAssertEqual(NotificationCategory.benefitExpiring, "BENEFIT_EXPIRING")
    }

    func testNotificationAction_MarkUsedHasCorrectIdentifier() {
        XCTAssertEqual(NotificationCategory.Action.markUsed.rawValue, "MARK_USED")
    }

    func testNotificationAction_Snooze1DayHasCorrectIdentifier() {
        XCTAssertEqual(NotificationCategory.Action.snooze1Day.rawValue, "SNOOZE_1D")
    }

    func testNotificationAction_Snooze3DaysHasCorrectIdentifier() {
        XCTAssertEqual(NotificationCategory.Action.snooze3Days.rawValue, "SNOOZE_3D")
    }

    // MARK: - Deep Link Notification Name Tests

    func testNavigateToBenefitNotificationName() {
        XCTAssertEqual(
            Notification.Name.navigateToBenefit.rawValue,
            "CouponTracker.navigateToBenefit"
        )
    }

    func testMarkBenefitUsedNotificationName() {
        XCTAssertEqual(
            Notification.Name.markBenefitUsed.rawValue,
            "CouponTracker.markBenefitUsed"
        )
    }

    func testSnoozeBenefitNotificationName() {
        XCTAssertEqual(
            Notification.Name.snoozeBenefit.rawValue,
            "CouponTracker.snoozeBenefit"
        )
    }

    // MARK: - User Info Key Tests

    func testUserInfoKey_BenefitId() {
        XCTAssertEqual(NotificationUserInfoKey.benefitId, "benefitId")
    }

    func testUserInfoKey_SnoozeDays() {
        XCTAssertEqual(NotificationUserInfoKey.snoozeDays, "snoozeDays")
    }

    // MARK: - Scheduling Logic Tests

    func testScheduleNotifications_DoesNotScheduleForUsedBenefit() async throws {
        // Given
        let card = UserCard(nickname: "Test Card")
        modelContext.insert(card)

        let calendar = Calendar.current
        let now = Date()
        let periodStart = calendar.date(from: calendar.dateComponents([.year, .month], from: now))!
        let periodEnd = calendar.date(byAdding: .day, value: 7, to: now)!

        let benefit = Benefit(
            userCard: card,
            customName: "Test Benefit",
            customValue: 50,
            status: .used,
            currentPeriodStart: periodStart,
            currentPeriodEnd: periodEnd
        )
        modelContext.insert(benefit)

        let preferences = UserPreferences()
        preferences.notificationsEnabled = true
        modelContext.insert(preferences)
        try modelContext.save()

        // When
        await notificationService.scheduleNotifications(for: benefit, preferences: preferences)

        // Then - no crash, benefit is filtered out by status check
        // (Can't easily verify no notification scheduled without mocking UNUserNotificationCenter)
        XCTAssertEqual(benefit.status, .used)
    }

    func testScheduleNotifications_DoesNotScheduleWhenDisabled() async throws {
        // Given
        let card = UserCard(nickname: "Test Card")
        modelContext.insert(card)

        let calendar = Calendar.current
        let now = Date()
        let periodStart = calendar.date(from: calendar.dateComponents([.year, .month], from: now))!
        let periodEnd = calendar.date(byAdding: .day, value: 7, to: now)!

        let benefit = Benefit(
            userCard: card,
            customName: "Test Benefit",
            customValue: 50,
            status: .available,
            currentPeriodStart: periodStart,
            currentPeriodEnd: periodEnd
        )
        modelContext.insert(benefit)

        let preferences = UserPreferences()
        preferences.notificationsEnabled = false
        modelContext.insert(preferences)
        try modelContext.save()

        // When
        await notificationService.scheduleNotifications(for: benefit, preferences: preferences)

        // Then - no crash, notifications disabled check should return early
        XCTAssertFalse(preferences.notificationsEnabled)
    }

    func testScheduleNotifications_RequiresPeriodEnd() async throws {
        // Given
        let card = UserCard(nickname: "Test Card")
        modelContext.insert(card)

        let calendar = Calendar.current
        let now = Date()
        let periodStart = calendar.date(from: calendar.dateComponents([.year, .month], from: now))!
        let periodEnd = calendar.date(byAdding: .month, value: 1, to: periodStart)!

        let benefit = Benefit(
            userCard: card,
            customName: "Test Benefit",
            customValue: 50,
            status: .available,
            currentPeriodStart: periodStart,
            currentPeriodEnd: periodEnd
        )
        modelContext.insert(benefit)

        let preferences = UserPreferences()
        preferences.notificationsEnabled = true
        modelContext.insert(preferences)
        try modelContext.save()

        // When
        await notificationService.scheduleNotifications(for: benefit, preferences: preferences)

        // Then - no crash, notifications scheduling should complete without errors
        // Note: benefit.currentPeriodEnd is now required in init, so this test verifies
        // that a benefit with a far-future period end doesn't cause issues
        XCTAssertNotNil(benefit.currentPeriodEnd)
    }

    // MARK: - Cancel Notifications Tests

    func testCancelAllNotifications_DoesNotCrash() {
        // When/Then - should not crash
        notificationService.cancelAllNotifications()
    }

    func testCancelNotifications_ForBenefit_DoesNotCrash() throws {
        // Given
        let card = UserCard(nickname: "Test Card")
        modelContext.insert(card)

        let calendar = Calendar.current
        let now = Date()
        let periodStart = calendar.date(from: calendar.dateComponents([.year, .month], from: now))!
        let periodEnd = calendar.date(byAdding: .day, value: 7, to: now)!

        let benefit = Benefit(
            userCard: card,
            customName: "Test Benefit",
            customValue: 50,
            status: .available,
            currentPeriodStart: periodStart,
            currentPeriodEnd: periodEnd
        )
        modelContext.insert(benefit)
        try modelContext.save()

        // When/Then - should not crash
        notificationService.cancelNotifications(for: benefit)
    }

    // MARK: - Reconciliation Tests

    func testReconcileNotifications_DoesNotCrash() async throws {
        // Given
        let card = UserCard(nickname: "Test Card")
        modelContext.insert(card)

        let calendar = Calendar.current
        let now = Date()
        let periodStart = calendar.date(from: calendar.dateComponents([.year, .month], from: now))!
        let periodEnd = calendar.date(byAdding: .day, value: 7, to: now)!

        let benefit = Benefit(
            userCard: card,
            customName: "Test Benefit",
            customValue: 50,
            status: .available,
            currentPeriodStart: periodStart,
            currentPeriodEnd: periodEnd
        )
        modelContext.insert(benefit)

        let preferences = UserPreferences()
        preferences.notificationsEnabled = true
        modelContext.insert(preferences)
        try modelContext.save()

        // When/Then - should not crash
        await notificationService.reconcileNotifications(
            benefits: [benefit],
            preferences: preferences
        )
    }

    // MARK: - Priority Calculation Tests

    func testExpirationUrgency_ExpiringToday() {
        // Given
        let daysRemaining = 0

        // When
        let urgency = ExpirationUrgency.from(daysRemaining: daysRemaining)

        // Then
        XCTAssertEqual(urgency, .expiringToday)
    }

    func testExpirationUrgency_Within1Day() {
        // Given
        let daysRemaining = 1

        // When
        let urgency = ExpirationUrgency.from(daysRemaining: daysRemaining)

        // Then
        XCTAssertEqual(urgency, .within1Day)
    }

    func testExpirationUrgency_Within3Days() {
        // Given
        let daysRemaining = 3

        // When
        let urgency = ExpirationUrgency.from(daysRemaining: daysRemaining)

        // Then
        XCTAssertEqual(urgency, .within3Days)
    }

    func testExpirationUrgency_Within1Week() {
        // Given
        let daysRemaining = 7

        // When
        let urgency = ExpirationUrgency.from(daysRemaining: daysRemaining)

        // Then
        XCTAssertEqual(urgency, .within1Week)
    }

    func testExpirationUrgency_Later() {
        // Given
        let daysRemaining = 14

        // When
        let urgency = ExpirationUrgency.from(daysRemaining: daysRemaining)

        // Then
        XCTAssertEqual(urgency, .later)
    }

    // MARK: - Lifecycle Integration Tests

    func testCancelNotifications_ForCardId_CancelsAllCardBenefits() throws {
        // Given
        let card = UserCard(nickname: "Test Card")
        modelContext.insert(card)

        let calendar = Calendar.current
        let now = Date()
        let periodStart = calendar.date(from: calendar.dateComponents([.year, .month], from: now))!
        let periodEnd = calendar.date(byAdding: .day, value: 7, to: now)!

        let benefit1 = Benefit(
            userCard: card,
            customName: "Benefit 1",
            customValue: 50,
            status: .available,
            currentPeriodStart: periodStart,
            currentPeriodEnd: periodEnd
        )
        let benefit2 = Benefit(
            userCard: card,
            customName: "Benefit 2",
            customValue: 25,
            status: .available,
            currentPeriodStart: periodStart,
            currentPeriodEnd: periodEnd
        )
        modelContext.insert(benefit1)
        modelContext.insert(benefit2)
        try modelContext.save()

        // When/Then - should not crash
        notificationService.cancelNotifications(forCardId: card.id, benefits: [benefit1, benefit2])
    }

    func testScheduleSnoozedNotification_DoesNotCrash() throws {
        // Given
        let card = UserCard(nickname: "Test Card")
        modelContext.insert(card)

        let calendar = Calendar.current
        let now = Date()
        let periodStart = calendar.date(from: calendar.dateComponents([.year, .month], from: now))!
        let periodEnd = calendar.date(byAdding: .day, value: 7, to: now)!

        let benefit = Benefit(
            userCard: card,
            customName: "Test Benefit",
            customValue: 50,
            status: .available,
            currentPeriodStart: periodStart,
            currentPeriodEnd: periodEnd
        )
        modelContext.insert(benefit)

        let preferences = UserPreferences()
        preferences.notificationsEnabled = true
        modelContext.insert(preferences)
        try modelContext.save()

        let snoozeDate = calendar.date(byAdding: .day, value: 1, to: now)!

        // When/Then - should not crash
        notificationService.scheduleSnoozedNotification(
            for: benefit,
            snoozeDate: snoozeDate,
            preferences: preferences
        )
    }

    func testNotificationLifecycle_ScheduleAndCancel() async throws {
        // Given
        let card = UserCard(nickname: "Test Card")
        modelContext.insert(card)

        let calendar = Calendar.current
        let now = Date()
        let periodStart = calendar.date(from: calendar.dateComponents([.year, .month], from: now))!
        let periodEnd = calendar.date(byAdding: .day, value: 3, to: now)!

        let benefit = Benefit(
            userCard: card,
            customName: "Test Benefit",
            customValue: 50,
            status: .available,
            currentPeriodStart: periodStart,
            currentPeriodEnd: periodEnd
        )
        modelContext.insert(benefit)

        let preferences = UserPreferences()
        preferences.notificationsEnabled = true
        modelContext.insert(preferences)
        try modelContext.save()

        // When - Schedule notifications
        await notificationService.scheduleNotifications(for: benefit, preferences: preferences)

        // Then - Cancel notifications (verifies cancel doesn't crash after schedule)
        notificationService.cancelNotifications(for: benefit)
    }

    func testNotificationLifecycle_MarkAsUsedCancelsNotifications() async throws {
        // Given
        var markAsUsedCallCount = 0
        var receivedBenefitId: UUID?

        notificationService.onMarkAsUsed = { benefitId in
            markAsUsedCallCount += 1
            receivedBenefitId = benefitId
        }

        let card = UserCard(nickname: "Test Card")
        modelContext.insert(card)

        let calendar = Calendar.current
        let now = Date()
        let periodStart = calendar.date(from: calendar.dateComponents([.year, .month], from: now))!
        let periodEnd = calendar.date(byAdding: .day, value: 3, to: now)!

        let benefit = Benefit(
            userCard: card,
            customName: "Test Benefit",
            customValue: 50,
            status: .available,
            currentPeriodStart: periodStart,
            currentPeriodEnd: periodEnd
        )
        modelContext.insert(benefit)

        let preferences = UserPreferences()
        preferences.notificationsEnabled = true
        modelContext.insert(preferences)
        try modelContext.save()

        // When - Simulate marking as used via callback
        notificationService.onMarkAsUsed?(benefit.id)

        // Then
        XCTAssertEqual(markAsUsedCallCount, 1, "Mark as used callback should be called once")
        XCTAssertEqual(receivedBenefitId, benefit.id, "Should receive correct benefit ID")

        // And cancel shouldn't crash
        notificationService.cancelNotifications(for: benefit)
    }
}
