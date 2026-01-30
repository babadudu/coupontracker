//
//  AddSubscriptionViewModelTests.swift
//  CouponTrackerTests
//
//  Created: January 2026
//  Purpose: Unit tests for AddSubscriptionViewModel frequency-specific pricing feature.
//

import XCTest
@testable import CouponTracker

/// Unit tests for AddSubscriptionViewModel.
/// Tests the onFrequencyChanged(to:) method and template selection pricing behavior.
@MainActor
final class AddSubscriptionViewModelTests: XCTestCase {

    // MARK: - Properties

    var mockRepository: MockSubscriptionRepository!
    var notificationService: NotificationService!
    var viewModel: AddSubscriptionViewModel!

    // MARK: - Setup & Teardown

    override func setUp() async throws {
        try await super.setUp()
        mockRepository = MockSubscriptionRepository()
        notificationService = NotificationService()
        viewModel = AddSubscriptionViewModel(
            subscriptionRepository: mockRepository,
            notificationService: notificationService
        )
    }

    override func tearDown() async throws {
        viewModel = nil
        notificationService = nil
        mockRepository = nil
        try await super.tearDown()
    }

    // MARK: - onFrequencyChanged(to:) Tests

    func test_onFrequencyChanged_updatesPriceFromTemplate() {
        // Given: ViewModel with template selected that has frequency-specific prices
        let template = createTemplateWithMultiplePrices()
        viewModel.selectTemplate(template)
        XCTAssertEqual(viewModel.customPrice, "10.99", "Initial price should be monthly default")

        // When: Frequency changed to annual
        viewModel.customFrequency = .annual
        viewModel.onFrequencyChanged(to: .annual)

        // Then: Price should update to annual price
        XCTAssertEqual(viewModel.customPrice, "99.99", "Price should update to annual price from template")
    }

    func test_onFrequencyChanged_doesNothing_whenNoTemplateSelected() {
        // Given: ViewModel with no template selected, custom price set
        viewModel.customPrice = "25.00"
        viewModel.customFrequency = .monthly

        // When: Frequency changed without template
        viewModel.onFrequencyChanged(to: .annual)

        // Then: Price should remain unchanged
        XCTAssertEqual(viewModel.customPrice, "25.00", "Price should not change when no template selected")
    }

    func test_onFrequencyChanged_keepsPrice_whenFrequencyNotInTemplate() {
        // Given: Template with only monthly pricing
        let template = createTemplateWithSinglePrice()
        viewModel.selectTemplate(template)
        let originalPrice = viewModel.customPrice

        // When: Changing to frequency not supported by template
        viewModel.customFrequency = .annual
        viewModel.onFrequencyChanged(to: .annual)

        // Then: Price should remain the same (nil returned, no update)
        XCTAssertEqual(viewModel.customPrice, originalPrice, "Price should not change for unsupported frequency")
    }

    func test_onFrequencyChanged_updatesToQuarterlyPrice() {
        // Given: Template with quarterly pricing
        let template = createTemplateWithAllPrices()
        viewModel.selectTemplate(template)

        // When: Frequency changed to quarterly
        viewModel.customFrequency = .quarterly
        viewModel.onFrequencyChanged(to: .quarterly)

        // Then: Price should update to quarterly price
        XCTAssertEqual(viewModel.customPrice, "29.99", "Price should update to quarterly price")
    }

    func test_onFrequencyChanged_updatesToWeeklyPrice() {
        // Given: Template with weekly pricing
        let template = createTemplateWithAllPrices()
        viewModel.selectTemplate(template)

        // When: Frequency changed to weekly
        viewModel.customFrequency = .weekly
        viewModel.onFrequencyChanged(to: .weekly)

        // Then: Price should update to weekly price
        XCTAssertEqual(viewModel.customPrice, "2.99", "Price should update to weekly price")
    }

    // MARK: - selectTemplate Tests

    func test_selectTemplate_setsFrequencySpecificPrice() {
        // Given: Template with default frequency = monthly and frequency prices
        let template = createTemplateWithMultiplePrices()

        // When: Template selected
        viewModel.selectTemplate(template)

        // Then: Should set price for template's default frequency
        XCTAssertEqual(viewModel.customPrice, "10.99", "Should set monthly price as that's the default frequency")
        XCTAssertEqual(viewModel.customFrequency, .monthly, "Should set frequency to template default")
    }

    func test_selectTemplate_usesDefaultPriceWhenNoFrequencyPrices() {
        // Given: Template with no frequency prices
        let template = createTemplateWithSinglePrice()

        // When: Template selected
        viewModel.selectTemplate(template)

        // Then: Should fall back to defaultPrice
        XCTAssertEqual(viewModel.customPrice, "15.99", "Should use defaultPrice when no frequencyPrices")
    }

    func test_selectTemplate_setsAnnualPriceForAnnualDefault() {
        // Given: Template with annual default frequency
        let template = createAnnualTemplate()

        // When: Template selected
        viewModel.selectTemplate(template)

        // Then: Should set annual price
        XCTAssertEqual(viewModel.customPrice, "79.99", "Should set annual price for annual default")
        XCTAssertEqual(viewModel.customFrequency, .annual, "Should set frequency to annual")
    }

    // MARK: - Integration Tests

    func test_fullFlow_selectTemplateChangeFrquencyChangeBack() {
        // Given: Template with multiple prices
        let template = createTemplateWithMultiplePrices()

        // When: Select template (monthly default)
        viewModel.selectTemplate(template)
        XCTAssertEqual(viewModel.customPrice, "10.99")

        // When: Change to annual
        viewModel.customFrequency = .annual
        viewModel.onFrequencyChanged(to: .annual)
        XCTAssertEqual(viewModel.customPrice, "99.99")

        // When: Change back to monthly
        viewModel.customFrequency = .monthly
        viewModel.onFrequencyChanged(to: .monthly)
        XCTAssertEqual(viewModel.customPrice, "10.99", "Should restore monthly price")
    }

    func test_clearSelection_allowsCustomPricing() {
        // Given: Template selected
        let template = createTemplateWithMultiplePrices()
        viewModel.selectTemplate(template)

        // When: Clear selection and set custom price
        viewModel.clearSelection()
        viewModel.customPrice = "50.00"
        viewModel.customFrequency = .monthly

        // Then: Frequency change should not affect custom price
        viewModel.onFrequencyChanged(to: .annual)
        XCTAssertEqual(viewModel.customPrice, "50.00", "Custom price should remain after frequency change with no template")
    }

    // MARK: - Helper Methods

    private func createTemplateWithMultiplePrices() -> SubscriptionTemplate {
        SubscriptionTemplate(
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
    }

    private func createTemplateWithSinglePrice() -> SubscriptionTemplate {
        SubscriptionTemplate(
            id: UUID(),
            name: "Netflix",
            defaultPrice: 15.99,
            frequency: .monthly,
            category: .streaming,
            frequencyPrices: nil
        )
    }

    private func createTemplateWithAllPrices() -> SubscriptionTemplate {
        SubscriptionTemplate(
            id: UUID(),
            name: "Test Service",
            defaultPrice: 10.99,
            frequency: .monthly,
            category: .software,
            frequencyPrices: [
                "weekly": 2.99,
                "monthly": 10.99,
                "quarterly": 29.99,
                "annual": 99.99
            ]
        )
    }

    private func createAnnualTemplate() -> SubscriptionTemplate {
        SubscriptionTemplate(
            id: UUID(),
            name: "Annual Service",
            defaultPrice: 79.99,
            frequency: .annual,
            category: .software,
            frequencyPrices: [
                "annual": 79.99,
                "monthly": 9.99
            ]
        )
    }
}
