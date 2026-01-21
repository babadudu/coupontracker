//
//  BenefitExtensionsTests.swift
//  CouponTrackerTests
//
//  Created: January 2026
//  Purpose: Unit tests for BenefitExtensions including grouping helpers.
//

import XCTest
@testable import CouponTracker

/// Unit tests for Benefit array extensions and data grouping helpers.
final class BenefitExtensionsTests: XCTestCase {

    // MARK: - Test Data

    struct TestItem {
        let id: Int
        let category: String
        let value: Int
    }

    struct TestMonetaryItem: HasMonetaryValue {
        let id: Int
        let monetaryValue: Decimal
    }

    // MARK: - Grouping Tests

    func testGrouped_EmptySequence_ReturnsEmptyDictionary() {
        let items: [TestItem] = []
        let grouped = items.grouped(by: \.category)

        XCTAssertTrue(grouped.isEmpty)
    }

    func testGrouped_SingleGroup_WorksCorrectly() {
        let items = [
            TestItem(id: 1, category: "A", value: 10),
            TestItem(id: 2, category: "A", value: 20),
            TestItem(id: 3, category: "A", value: 30)
        ]

        let grouped = items.grouped(by: \.category)

        XCTAssertEqual(grouped.keys.count, 1)
        XCTAssertEqual(grouped["A"]?.count, 3)
        XCTAssertEqual(grouped["A"]?.map { $0.id }, [1, 2, 3])
    }

    func testGrouped_MultipleGroups_WorksCorrectly() {
        let items = [
            TestItem(id: 1, category: "A", value: 10),
            TestItem(id: 2, category: "B", value: 20),
            TestItem(id: 3, category: "A", value: 30),
            TestItem(id: 4, category: "C", value: 40),
            TestItem(id: 5, category: "B", value: 50)
        ]

        let grouped = items.grouped(by: \.category)

        XCTAssertEqual(grouped.keys.count, 3)
        XCTAssertEqual(grouped["A"]?.count, 2)
        XCTAssertEqual(grouped["B"]?.count, 2)
        XCTAssertEqual(grouped["C"]?.count, 1)

        // Verify correct items in each group
        XCTAssertEqual(Set(grouped["A"]?.map { $0.id } ?? []), Set([1, 3]))
        XCTAssertEqual(Set(grouped["B"]?.map { $0.id } ?? []), Set([2, 5]))
        XCTAssertEqual(grouped["C"]?.map { $0.id }, [4])
    }

    func testGrouped_ByDifferentKeyPath_WorksCorrectly() {
        let items = [
            TestItem(id: 1, category: "A", value: 10),
            TestItem(id: 2, category: "B", value: 10),
            TestItem(id: 3, category: "A", value: 20),
            TestItem(id: 4, category: "C", value: 10)
        ]

        let groupedByValue = items.grouped(by: \.value)

        XCTAssertEqual(groupedByValue.keys.count, 2)
        XCTAssertEqual(groupedByValue[10]?.count, 3)
        XCTAssertEqual(groupedByValue[20]?.count, 1)

        // Verify correct items in each group
        XCTAssertEqual(Set(groupedByValue[10]?.map { $0.id } ?? []), Set([1, 2, 4]))
        XCTAssertEqual(groupedByValue[20]?.map { $0.id }, [3])
    }

    // MARK: - Monetary Value Tests

    func testTotalMonetaryValue_EmptySequence_ReturnsZero() {
        let items: [TestMonetaryItem] = []
        XCTAssertEqual(items.totalMonetaryValue, .zero)
    }

    func testTotalMonetaryValue_SingleItem_ReturnsValue() {
        let items = [TestMonetaryItem(id: 1, monetaryValue: 100.50)]
        XCTAssertEqual(items.totalMonetaryValue, 100.50)
    }

    func testTotalMonetaryValue_MultipleItems_ReturnsSum() {
        let items = [
            TestMonetaryItem(id: 1, monetaryValue: 100.50),
            TestMonetaryItem(id: 2, monetaryValue: 200.25),
            TestMonetaryItem(id: 3, monetaryValue: 50.00)
        ]
        XCTAssertEqual(items.totalMonetaryValue, 350.75)
    }

    func testTotalMonetaryValue_WithPredicate_ReturnsFilteredSum() {
        let items = [
            TestMonetaryItem(id: 1, monetaryValue: 100.50),
            TestMonetaryItem(id: 2, monetaryValue: 200.25),
            TestMonetaryItem(id: 3, monetaryValue: 50.00)
        ]
        let total = items.totalMonetaryValue { $0.id != 2 }
        XCTAssertEqual(total, 150.50)
    }

    func testTotalMonetaryValue_WithPredicate_NoMatches_ReturnsZero() {
        let items = [
            TestMonetaryItem(id: 1, monetaryValue: 100.50),
            TestMonetaryItem(id: 2, monetaryValue: 200.25)
        ]
        let total = items.totalMonetaryValue { $0.id == 999 }
        XCTAssertEqual(total, .zero)
    }
}
