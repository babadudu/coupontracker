//
//  SubscriptionTemplateTests.swift
//  CouponTrackerTests
//
//  Created: January 2026
//  Purpose: Unit tests for SubscriptionTemplate frequency-specific pricing feature.
//

import XCTest
@testable import CouponTracker

/// Unit tests for SubscriptionTemplate.
/// Tests the price(for:) method and availableFrequencies computed property.
final class SubscriptionTemplateTests: XCTestCase {

    // MARK: - price(for:) Tests

    func test_priceFor_returnsFrequencySpecificPrice() {
        // Given: Template with frequencyPrices for monthly and annual
        let template = SubscriptionTemplate(
            id: UUID(),
            name: "Spotify",
            defaultPrice: 10.99,
            frequency: .monthly,
            category: .streaming,
            frequencyPrices: [
                "monthly": 10.99,
                "annual": 99.99
            ]
        )

        // When/Then: Requesting annual price returns frequency-specific price
        XCTAssertEqual(template.price(for: .annual), 99.99, "Should return annual price from frequencyPrices")
        XCTAssertEqual(template.price(for: .monthly), 10.99, "Should return monthly price from frequencyPrices")
    }

    func test_priceFor_returnsDefaultPrice_whenFrequencyMatchesDefault() {
        // Given: Template with no frequencyPrices, default frequency is monthly
        let template = SubscriptionTemplate(
            id: UUID(),
            name: "Netflix",
            defaultPrice: 15.99,
            frequency: .monthly,
            category: .streaming,
            frequencyPrices: nil
        )

        // When/Then: Requesting default frequency returns defaultPrice
        XCTAssertEqual(template.price(for: .monthly), 15.99, "Should return defaultPrice when frequency matches template default")
    }

    func test_priceFor_returnsNil_whenFrequencyNotSupported() {
        // Given: Template with only monthly pricing (no frequencyPrices, default is monthly)
        let template = SubscriptionTemplate(
            id: UUID(),
            name: "Netflix",
            defaultPrice: 15.99,
            frequency: .monthly,
            category: .streaming,
            frequencyPrices: nil
        )

        // When/Then: Requesting unsupported frequency returns nil
        XCTAssertNil(template.price(for: .annual), "Should return nil for unsupported frequency")
        XCTAssertNil(template.price(for: .quarterly), "Should return nil for unsupported frequency")
        XCTAssertNil(template.price(for: .weekly), "Should return nil for unsupported frequency")
    }

    func test_priceFor_prefersFrequencyPrices_overDefault() {
        // Given: Template where frequencyPrices has a different monthly price than defaultPrice
        let template = SubscriptionTemplate(
            id: UUID(),
            name: "Test Service",
            defaultPrice: 10.00,
            frequency: .monthly,
            category: .software,
            frequencyPrices: [
                "monthly": 12.99  // Different from defaultPrice
            ]
        )

        // When/Then: frequencyPrices takes precedence over defaultPrice
        XCTAssertEqual(template.price(for: .monthly), 12.99, "Should return price from frequencyPrices even when it matches default frequency")
    }

    func test_priceFor_returnsDefaultPrice_whenFrequencyMatchesButNotInPrices() {
        // Given: Template with frequencyPrices for annual only, default is monthly
        let template = SubscriptionTemplate(
            id: UUID(),
            name: "Test Service",
            defaultPrice: 9.99,
            frequency: .monthly,
            category: .software,
            frequencyPrices: [
                "annual": 99.99
            ]
        )

        // When/Then: Requesting default frequency falls back to defaultPrice
        XCTAssertEqual(template.price(for: .monthly), 9.99, "Should return defaultPrice when frequency matches default but not in frequencyPrices")
        XCTAssertEqual(template.price(for: .annual), 99.99, "Should still return frequencyPrices value for annual")
    }

    // MARK: - availableFrequencies Tests

    func test_availableFrequencies_includesDefaultAndFrequencyPrices() {
        // Given: Template with monthly default and annual in frequencyPrices
        let template = SubscriptionTemplate(
            id: UUID(),
            name: "Spotify",
            defaultPrice: 10.99,
            frequency: .monthly,
            category: .streaming,
            frequencyPrices: [
                "annual": 99.99,
                "quarterly": 29.99
            ]
        )

        // When
        let frequencies = template.availableFrequencies

        // Then: Should include default frequency and all frequencyPrices keys
        XCTAssertEqual(frequencies.count, 3, "Should have 3 frequencies: monthly (default) + annual + quarterly")
        XCTAssertTrue(frequencies.contains(.monthly), "Should include default frequency")
        XCTAssertTrue(frequencies.contains(.annual), "Should include annual from frequencyPrices")
        XCTAssertTrue(frequencies.contains(.quarterly), "Should include quarterly from frequencyPrices")
    }

    func test_availableFrequencies_onlyDefault_whenNoFrequencyPrices() {
        // Given: Template with no frequencyPrices
        let template = SubscriptionTemplate(
            id: UUID(),
            name: "Netflix",
            defaultPrice: 15.99,
            frequency: .monthly,
            category: .streaming,
            frequencyPrices: nil
        )

        // When
        let frequencies = template.availableFrequencies

        // Then: Should only include the default frequency
        XCTAssertEqual(frequencies.count, 1, "Should have only 1 frequency")
        XCTAssertEqual(frequencies.first, .monthly, "Should be the default frequency")
    }

    func test_availableFrequencies_deduplicates_whenDefaultInPrices() {
        // Given: Template where default frequency is also in frequencyPrices
        let template = SubscriptionTemplate(
            id: UUID(),
            name: "Test Service",
            defaultPrice: 10.00,
            frequency: .monthly,
            category: .software,
            frequencyPrices: [
                "monthly": 10.00,
                "annual": 99.99
            ]
        )

        // When
        let frequencies = template.availableFrequencies

        // Then: Should not duplicate the default frequency
        XCTAssertEqual(frequencies.count, 2, "Should have 2 unique frequencies")
        XCTAssertTrue(frequencies.contains(.monthly), "Should include monthly")
        XCTAssertTrue(frequencies.contains(.annual), "Should include annual")
    }

    func test_availableFrequencies_sortedByAnnualMultiplier() {
        // Given: Template with multiple frequencies
        let template = SubscriptionTemplate(
            id: UUID(),
            name: "Test Service",
            defaultPrice: 2.99,
            frequency: .weekly,
            category: .software,
            frequencyPrices: [
                "monthly": 9.99,
                "quarterly": 24.99,
                "annual": 79.99
            ]
        )

        // When
        let frequencies = template.availableFrequencies

        // Then: Should be sorted by annualMultiplier descending (weekly=52, monthly=12, quarterly=4, annual=1)
        XCTAssertEqual(frequencies.count, 4, "Should have all 4 frequencies")
        XCTAssertEqual(frequencies[0], .weekly, "Weekly should be first (highest multiplier)")
        XCTAssertEqual(frequencies[1], .monthly, "Monthly should be second")
        XCTAssertEqual(frequencies[2], .quarterly, "Quarterly should be third")
        XCTAssertEqual(frequencies[3], .annual, "Annual should be last (lowest multiplier)")
    }

    func test_availableFrequencies_ignoresInvalidKeys() {
        // Given: Template with an invalid frequency key in frequencyPrices
        let template = SubscriptionTemplate(
            id: UUID(),
            name: "Test Service",
            defaultPrice: 9.99,
            frequency: .monthly,
            category: .software,
            frequencyPrices: [
                "annual": 99.99,
                "invalid_frequency": 49.99  // This should be ignored
            ]
        )

        // When
        let frequencies = template.availableFrequencies

        // Then: Should only include valid frequencies
        XCTAssertEqual(frequencies.count, 2, "Should have 2 frequencies (monthly default + annual)")
        XCTAssertTrue(frequencies.contains(.monthly), "Should include default")
        XCTAssertTrue(frequencies.contains(.annual), "Should include valid annual")
        XCTAssertFalse(frequencies.contains(.quarterly), "Should not include invalid key")
    }

    func test_availableFrequencies_emptyFrequencyPrices() {
        // Given: Template with empty frequencyPrices dictionary (not nil)
        let template = SubscriptionTemplate(
            id: UUID(),
            name: "Test Service",
            defaultPrice: 9.99,
            frequency: .annual,
            category: .software,
            frequencyPrices: [:]
        )

        // When
        let frequencies = template.availableFrequencies

        // Then: Should only include the default frequency
        XCTAssertEqual(frequencies.count, 1, "Should have only default frequency")
        XCTAssertEqual(frequencies.first, .annual, "Should be the annual default")
    }
}
