//
//  BenefitCategoryTests.swift
//  CouponTrackerTests
//
//  Created: January 2026
//  Purpose: Unit tests for BenefitCategory enum including migration support.
//

import XCTest
@testable import CouponTracker

/// Unit tests for BenefitCategory enum.
/// Tests category properties, migration from legacy values, and consolidation.
final class BenefitCategoryTests: XCTestCase {

    // MARK: - Category Count Tests

    func testCategoryCount_Is7() {
        // The consolidated category count should be exactly 7
        XCTAssertEqual(BenefitCategory.allCases.count, 7)
    }

    func testAllCategories_ArePresent() {
        let categories = BenefitCategory.allCases
        XCTAssertTrue(categories.contains(.travel))
        XCTAssertTrue(categories.contains(.dining))
        XCTAssertTrue(categories.contains(.transportation))
        XCTAssertTrue(categories.contains(.shopping))
        XCTAssertTrue(categories.contains(.entertainment))
        XCTAssertTrue(categories.contains(.business))
        XCTAssertTrue(categories.contains(.lifestyle))
    }

    // MARK: - Display Name Tests

    func testDisplayName_ReturnsCorrectValues() {
        XCTAssertEqual(BenefitCategory.travel.displayName, "Travel")
        XCTAssertEqual(BenefitCategory.dining.displayName, "Dining")
        XCTAssertEqual(BenefitCategory.transportation.displayName, "Transportation")
        XCTAssertEqual(BenefitCategory.shopping.displayName, "Shopping")
        XCTAssertEqual(BenefitCategory.entertainment.displayName, "Entertainment")
        XCTAssertEqual(BenefitCategory.business.displayName, "Business")
        XCTAssertEqual(BenefitCategory.lifestyle.displayName, "Lifestyle")
    }

    // MARK: - Icon Name Tests

    func testIconName_ReturnsValidSFSymbols() {
        XCTAssertEqual(BenefitCategory.travel.iconName, "airplane")
        XCTAssertEqual(BenefitCategory.dining.iconName, "fork.knife")
        XCTAssertEqual(BenefitCategory.transportation.iconName, "car.fill")
        XCTAssertEqual(BenefitCategory.shopping.iconName, "bag.fill")
        XCTAssertEqual(BenefitCategory.entertainment.iconName, "tv.fill")
        XCTAssertEqual(BenefitCategory.business.iconName, "briefcase.fill")
        XCTAssertEqual(BenefitCategory.lifestyle.iconName, "sparkles")
    }

    // MARK: - Category Description Tests

    func testCategoryDescription_IsNotEmpty() {
        for category in BenefitCategory.allCases {
            XCTAssertFalse(category.categoryDescription.isEmpty,
                          "\(category) should have a non-empty description")
        }
    }

    // MARK: - Raw Value Tests

    func testRawValue_MatchesCaseName() {
        XCTAssertEqual(BenefitCategory.travel.rawValue, "travel")
        XCTAssertEqual(BenefitCategory.dining.rawValue, "dining")
        XCTAssertEqual(BenefitCategory.transportation.rawValue, "transportation")
        XCTAssertEqual(BenefitCategory.shopping.rawValue, "shopping")
        XCTAssertEqual(BenefitCategory.entertainment.rawValue, "entertainment")
        XCTAssertEqual(BenefitCategory.business.rawValue, "business")
        XCTAssertEqual(BenefitCategory.lifestyle.rawValue, "lifestyle")
    }

    // MARK: - Migration Tests (Legacy Category Decoding)

    func testDecode_RideshareToTransportation() throws {
        let json = "\"rideshare\""
        let data = json.data(using: .utf8)!
        let category = try JSONDecoder().decode(BenefitCategory.self, from: data)
        XCTAssertEqual(category, .transportation)
    }

    func testDecode_StreamingToEntertainment() throws {
        let json = "\"streaming\""
        let data = json.data(using: .utf8)!
        let category = try JSONDecoder().decode(BenefitCategory.self, from: data)
        XCTAssertEqual(category, .entertainment)
    }

    func testDecode_HotelToTravel() throws {
        let json = "\"hotel\""
        let data = json.data(using: .utf8)!
        let category = try JSONDecoder().decode(BenefitCategory.self, from: data)
        XCTAssertEqual(category, .travel)
    }

    func testDecode_AirlineToTravel() throws {
        let json = "\"airline\""
        let data = json.data(using: .utf8)!
        let category = try JSONDecoder().decode(BenefitCategory.self, from: data)
        XCTAssertEqual(category, .travel)
    }

    func testDecode_WellnessToLifestyle() throws {
        let json = "\"wellness\""
        let data = json.data(using: .utf8)!
        let category = try JSONDecoder().decode(BenefitCategory.self, from: data)
        XCTAssertEqual(category, .lifestyle)
    }

    func testDecode_OtherToLifestyle() throws {
        let json = "\"other\""
        let data = json.data(using: .utf8)!
        let category = try JSONDecoder().decode(BenefitCategory.self, from: data)
        XCTAssertEqual(category, .lifestyle)
    }

    func testDecode_CurrentCategories_WorkCorrectly() throws {
        for category in BenefitCategory.allCases {
            let json = "\"\(category.rawValue)\""
            let data = json.data(using: .utf8)!
            let decoded = try JSONDecoder().decode(BenefitCategory.self, from: data)
            XCTAssertEqual(decoded, category)
        }
    }

    func testDecode_UnknownCategory_ThrowsError() {
        let json = "\"unknown_category\""
        let data = json.data(using: .utf8)!
        XCTAssertThrowsError(try JSONDecoder().decode(BenefitCategory.self, from: data))
    }

    // MARK: - Encoding Tests

    func testEncode_ProducesCorrectRawValue() throws {
        for category in BenefitCategory.allCases {
            let data = try JSONEncoder().encode(category)
            let string = String(data: data, encoding: .utf8)!
            XCTAssertEqual(string, "\"\(category.rawValue)\"")
        }
    }

    // MARK: - Identifiable Tests

    func testIdentifiable_IdMatchesRawValue() {
        for category in BenefitCategory.allCases {
            XCTAssertEqual(category.id, category.rawValue)
        }
    }

    // MARK: - Miller's Law Compliance

    func testCategoryCount_WithinMillersLaw() {
        // Miller's Law: humans can hold 7±2 items in working memory
        let count = BenefitCategory.allCases.count
        XCTAssertGreaterThanOrEqual(count, 5, "Should have at least 5 categories")
        XCTAssertLessThanOrEqual(count, 9, "Should have at most 9 categories")
    }
}
