//
//  SearchableTests.swift
//  CouponTrackerTests
//
//  Created on 2026-01-20.
//

import XCTest
@testable import CouponTracker

final class SearchableTests: XCTestCase {

    // MARK: - Test Data

    private var templates: [CardTemplate]!

    override func setUp() {
        super.setUp()
        templates = [
            CardTemplate(
                id: UUID(),
                name: "Gold Card",
                issuer: "American Express",
                artworkAsset: "amex-gold",
                annualFee: 250,
                primaryColorHex: "#1a1a2e",
                secondaryColorHex: "#4a4e69",
                isActive: true,
                lastUpdated: Date(),
                benefits: []
            ),
            CardTemplate(
                id: UUID(),
                name: "Sapphire Preferred",
                issuer: "Chase",
                artworkAsset: "chase-sapphire",
                annualFee: 95,
                primaryColorHex: "#1a1a2e",
                secondaryColorHex: "#4a4e69",
                isActive: true,
                lastUpdated: Date(),
                benefits: []
            ),
            CardTemplate(
                id: UUID(),
                name: "Costco Anywhere Visa",
                issuer: "Citi",
                artworkAsset: "citi-costco",
                annualFee: 0,
                primaryColorHex: "#1a1a2e",
                secondaryColorHex: "#4a4e69",
                isActive: true,
                lastUpdated: Date(),
                benefits: []
            ),
            CardTemplate(
                id: UUID(),
                name: "Discover It",
                issuer: "Discover",
                artworkAsset: "discover-it",
                annualFee: 0,
                primaryColorHex: "#1a1a2e",
                secondaryColorHex: "#4a4e69",
                isActive: true,
                lastUpdated: Date(),
                benefits: []
            )
        ]
    }

    override func tearDown() {
        templates = nil
        super.tearDown()
    }

    // MARK: - Case Insensitive Matching Tests

    func testCaseInsensitiveMatching_Lowercase() {
        let result = templates.filtered(by: "gold")

        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result.first?.name, "Gold Card")
    }

    func testCaseInsensitiveMatching_Uppercase() {
        let result = templates.filtered(by: "GOLD")

        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result.first?.name, "Gold Card")
    }

    func testCaseInsensitiveMatching_MixedCase() {
        let result = templates.filtered(by: "GoLd")

        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result.first?.name, "Gold Card")
    }

    // MARK: - Whitespace Trimming Tests

    func testWhitespaceTrimming_LeadingSpaces() {
        let result = templates.filtered(by: "   gold")

        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result.first?.name, "Gold Card")
    }

    func testWhitespaceTrimming_TrailingSpaces() {
        let result = templates.filtered(by: "gold   ")

        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result.first?.name, "Gold Card")
    }

    func testWhitespaceTrimming_BothSides() {
        let result = templates.filtered(by: "   gold   ")

        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result.first?.name, "Gold Card")
    }

    // MARK: - Empty Query Tests

    func testEmptyQuery_ReturnsAll() {
        let result = templates.filtered(by: "")

        XCTAssertEqual(result.count, templates.count)
        XCTAssertEqual(Set(result.map { $0.id }), Set(templates.map { $0.id }))
    }

    func testWhitespaceOnlyQuery_ReturnsAll() {
        let result = templates.filtered(by: "   ")

        XCTAssertEqual(result.count, templates.count)
        XCTAssertEqual(Set(result.map { $0.id }), Set(templates.map { $0.id }))
    }

    func testTabsAndSpacesQuery_ReturnsAll() {
        let result = templates.filtered(by: " \t \n ")

        XCTAssertEqual(result.count, templates.count)
        XCTAssertEqual(Set(result.map { $0.id }), Set(templates.map { $0.id }))
    }

    // MARK: - Partial Match Tests

    func testPartialMatch_ByName() {
        let result = templates.filtered(by: "sapp")

        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result.first?.name, "Sapphire Preferred")
    }

    func testPartialMatch_ByIssuer() {
        let result = templates.filtered(by: "amer")

        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result.first?.name, "Gold Card")
    }

    func testPartialMatch_MultipleResults() {
        let result = templates.filtered(by: "discover")

        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result.first?.name, "Discover It")
    }

    func testPartialMatch_NameOrIssuer() {
        // "citi" matches both issuer "Citi" and name "Costco Anywhere Visa" contains "Ci"
        let result = templates.filtered(by: "citi")

        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result.first?.name, "Costco Anywhere Visa")
    }

    // MARK: - No False Positives Tests

    func testNoFalsePositives_NoMatch() {
        let result = templates.filtered(by: "xyz")

        XCTAssertEqual(result.count, 0)
    }

    func testNoFalsePositives_PartialNoMatch() {
        let result = templates.filtered(by: "zyx")

        XCTAssertEqual(result.count, 0)
    }

    func testNoFalsePositives_CategoryNotSearchable() {
        // Category should not be searchable based on the protocol implementation
        let result = templates.filtered(by: "dining")

        XCTAssertEqual(result.count, 0, "Category should not be searchable")
    }

    // MARK: - Edge Cases

    func testSingleCharacterSearch() {
        let result = templates.filtered(by: "c")

        // Should match: "Chase", "Citi", "Costco", "Discover"
        XCTAssertGreaterThan(result.count, 0)
    }

    func testSpecialCharactersInQuery() {
        let result = templates.filtered(by: "@#$")

        XCTAssertEqual(result.count, 0)
    }

    func testNumbersInQuery() {
        let result = templates.filtered(by: "123")

        XCTAssertEqual(result.count, 0)
    }

    // MARK: - Multiple Matches Tests

    func testMultipleMatches_ByCommonIssuerPart() {
        // Add more templates with "Chase"
        let moreTemplates = templates + [
            CardTemplate(
                id: UUID(),
                name: "Freedom Unlimited",
                issuer: "Chase",
                artworkAsset: "chase-freedom",
                annualFee: 0,
                primaryColorHex: "#1a1a2e",
                secondaryColorHex: "#4a4e69",
                isActive: true,
                lastUpdated: Date(),
                benefits: []
            )
        ]

        let result = moreTemplates.filtered(by: "chase")

        XCTAssertEqual(result.count, 2)
        XCTAssertTrue(result.contains { $0.name == "Sapphire Preferred" })
        XCTAssertTrue(result.contains { $0.name == "Freedom Unlimited" })
    }

    // MARK: - Performance Tests

    func testPerformance_LargeDataset() {
        // Create a large dataset
        var largeDataset: [CardTemplate] = []
        for i in 0..<1000 {
            largeDataset.append(CardTemplate(
                id: UUID(),
                name: "Card \(i)",
                issuer: "Issuer \(i % 10)",
                artworkAsset: "card-\(i)",
                annualFee: 0,
                primaryColorHex: "#1a1a2e",
                secondaryColorHex: "#4a4e69",
                isActive: true,
                lastUpdated: Date(),
                benefits: []
            ))
        }

        measure {
            _ = largeDataset.filtered(by: "Card 5")
        }
    }
}
