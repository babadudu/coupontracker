//
//  BenefitRowConfigurationTests.swift
//  CouponTrackerTests
//
//  Created: January 2026
//  Purpose: Unit tests for BenefitRowConfiguration and BenefitRowStyle.
//

import XCTest
@testable import CouponTracker

/// Unit tests for BenefitRowConfiguration factory methods and properties.
final class BenefitRowConfigurationTests: XCTestCase {

    // MARK: - BenefitRowStyle Tests

    func testBenefitRowStyle_HasAllCases() {
        // Verify all expected cases exist
        let styles: [BenefitRowStyle] = [.standard, .compact, .swipeable]
        XCTAssertEqual(styles.count, 3, "Should have 3 style cases")
    }

    // MARK: - Standard Configuration Tests

    func testStandardConfiguration_HasCorrectDefaults() {
        // When
        let config = BenefitRowConfiguration.standard

        // Then
        XCTAssertEqual(config.style, .standard, "Style should be standard")
        XCTAssertFalse(config.showCard, "Should not show card by default")
        XCTAssertNil(config.cardGradient, "Card gradient should be nil")
        XCTAssertNil(config.cardName, "Card name should be nil")
        XCTAssertNil(config.onMarkAsDone, "onMarkAsDone should be nil")
        XCTAssertNil(config.onSnooze, "onSnooze should be nil")
        XCTAssertNil(config.onUndo, "onUndo should be nil")
        XCTAssertNil(config.onTap, "onTap should be nil")
    }

    // MARK: - Compact Configuration Tests

    func testCompactConfiguration_RequiresCardName() {
        // When
        let config = BenefitRowConfiguration.compact(cardName: "Amex Platinum")

        // Then
        XCTAssertEqual(config.style, .compact, "Style should be compact")
        XCTAssertTrue(config.showCard, "Should show card in compact mode")
        XCTAssertEqual(config.cardName, "Amex Platinum", "Card name should be set")
    }

    func testCompactConfiguration_WithAllParameters() {
        // Given
        var markAsDoneCalled = false
        var tapCalled = false

        // When
        let config = BenefitRowConfiguration.compact(
            cardName: "Chase Sapphire",
            cardGradient: .sapphire,
            onMarkAsDone: { markAsDoneCalled = true },
            onTap: { tapCalled = true }
        )

        // Then
        XCTAssertEqual(config.style, .compact, "Style should be compact")
        XCTAssertTrue(config.showCard, "Should show card")
        XCTAssertEqual(config.cardName, "Chase Sapphire", "Card name should match")
        XCTAssertEqual(config.cardGradient, .sapphire, "Card gradient should match")

        // Verify callbacks are set
        XCTAssertNotNil(config.onMarkAsDone, "onMarkAsDone should be set")
        XCTAssertNotNil(config.onTap, "onTap should be set")

        // Verify callbacks work
        config.onMarkAsDone?()
        config.onTap?()
        XCTAssertTrue(markAsDoneCalled, "onMarkAsDone callback should execute")
        XCTAssertTrue(tapCalled, "onTap callback should execute")
    }

    func testCompactConfiguration_DisablesSnoozeAndUndo() {
        // When
        let config = BenefitRowConfiguration.compact(cardName: "Test Card")

        // Then
        XCTAssertNil(config.onSnooze, "Compact mode should not have snooze")
        XCTAssertNil(config.onUndo, "Compact mode should not have undo")
    }

    func testCompactConfiguration_WithNilGradient() {
        // When
        let config = BenefitRowConfiguration.compact(
            cardName: "Generic Card",
            cardGradient: nil
        )

        // Then
        XCTAssertNil(config.cardGradient, "Card gradient should be nil when not provided")
        XCTAssertTrue(config.showCard, "Should still show card even without gradient")
    }

    // MARK: - Custom Configuration Tests

    func testCustomConfiguration_WithAllCallbacks() {
        // Given
        var markAsDoneCalled = false
        var snoozeDays: Int?
        var undoCalled = false
        var tapCalled = false

        // When
        let config = BenefitRowConfiguration(
            style: .standard,
            showCard: true,
            cardGradient: .platinum,
            cardName: "Amex Platinum",
            onMarkAsDone: { markAsDoneCalled = true },
            onSnooze: { days in snoozeDays = days },
            onUndo: { undoCalled = true },
            onTap: { tapCalled = true }
        )

        // Execute callbacks
        config.onMarkAsDone?()
        config.onSnooze?(7)
        config.onUndo?()
        config.onTap?()

        // Then
        XCTAssertTrue(markAsDoneCalled, "onMarkAsDone should execute")
        XCTAssertEqual(snoozeDays, 7, "onSnooze should receive correct days")
        XCTAssertTrue(undoCalled, "onUndo should execute")
        XCTAssertTrue(tapCalled, "onTap should execute")
    }

    func testCustomConfiguration_WithSwipeableStyle() {
        // When
        let config = BenefitRowConfiguration(
            style: .swipeable,
            showCard: false,
            cardGradient: nil,
            cardName: nil,
            onMarkAsDone: { },
            onSnooze: { _ in },
            onUndo: nil,
            onTap: nil
        )

        // Then
        XCTAssertEqual(config.style, .swipeable, "Style should be swipeable")
        XCTAssertNotNil(config.onMarkAsDone, "Swipeable should have onMarkAsDone")
        XCTAssertNotNil(config.onSnooze, "Swipeable should have onSnooze")
    }

    // MARK: - Card Display Tests

    func testConfiguration_ShowCardWithCardInfo() {
        // When
        let config = BenefitRowConfiguration(
            style: .standard,
            showCard: true,
            cardGradient: .gold,
            cardName: "Amex Gold",
            onMarkAsDone: nil,
            onSnooze: nil,
            onUndo: nil,
            onTap: nil
        )

        // Then
        XCTAssertTrue(config.showCard, "Should show card")
        XCTAssertEqual(config.cardGradient, .gold, "Should have gold gradient")
        XCTAssertEqual(config.cardName, "Amex Gold", "Should have correct name")
    }

    func testConfiguration_HideCardByDefault() {
        // When
        let config = BenefitRowConfiguration.standard

        // Then
        XCTAssertFalse(config.showCard, "Standard config should hide card by default")
    }

    // MARK: - Snooze Callback Tests

    func testSnoozeCallback_ReceivesCorrectDays() {
        // Given
        var receivedDays: [Int] = []

        let config = BenefitRowConfiguration(
            style: .standard,
            showCard: false,
            cardGradient: nil,
            cardName: nil,
            onMarkAsDone: nil,
            onSnooze: { days in receivedDays.append(days) },
            onUndo: nil,
            onTap: nil
        )

        // When
        config.onSnooze?(1)
        config.onSnooze?(3)
        config.onSnooze?(7)

        // Then
        XCTAssertEqual(receivedDays, [1, 3, 7], "Should receive all snooze day values")
    }

    // MARK: - Edge Cases

    func testConfiguration_EmptyCardName() {
        // When
        let config = BenefitRowConfiguration.compact(cardName: "")

        // Then
        XCTAssertEqual(config.cardName, "", "Should allow empty card name")
        XCTAssertTrue(config.showCard, "Should still show card")
    }

    func testConfiguration_LongCardName() {
        // When
        let longName = "Chase Sapphire Preferred Rewards Platinum Elite Card"
        let config = BenefitRowConfiguration.compact(cardName: longName)

        // Then
        XCTAssertEqual(config.cardName, longName, "Should handle long card names")
    }
}
