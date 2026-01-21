//
//  SwiftDataHelpersTests.swift
//  CouponTrackerTests
//
//  Tests for SwiftData lazy loading helpers
//

import XCTest
@testable import CouponTracker

final class SwiftDataHelpersTests: XCTestCase {

    // MARK: - Test Models

    /// Simple test model to verify property access
    private class TestModel {
        var propertyAccessCount = 0

        var lazyProperty: String {
            propertyAccessCount += 1
            return "loaded"
        }

        var simpleProperty: Int = 42
    }

    // MARK: - Empty Sequence Tests

    func testEagerLoad_EmptySequence_ReturnsEmpty() {
        // Arrange
        let emptyArray: [TestModel] = []

        // Act
        let result = emptyArray.eagerLoad(\.simpleProperty)

        // Assert
        XCTAssertTrue(result.isEmpty, "Empty sequence should return empty array")
    }

    // MARK: - Single Element Tests

    func testEagerLoad_SingleElement_LoadsProperty() {
        // Arrange
        let model = TestModel()
        let array = [model]

        // Act
        let result = array.eagerLoad(\.lazyProperty)

        // Assert
        XCTAssertEqual(result.count, 1, "Should return one element")
        XCTAssertEqual(model.propertyAccessCount, 1, "Property should be accessed once during eager loading")
        XCTAssertTrue(result[0] === model, "Should return the same instance")
    }

    func testEagerLoad_SingleElement_PreservesInstance() {
        // Arrange
        let model = TestModel()
        let array = [model]

        // Act
        let result = array.eagerLoad(\.simpleProperty)

        // Assert
        XCTAssertTrue(result[0] === model, "Should preserve the same object instance")
    }

    // MARK: - Multiple Elements Tests

    func testEagerLoad_MultipleElements_LoadsAllProperties() {
        // Arrange
        let models = [TestModel(), TestModel(), TestModel()]

        // Act
        let result = models.eagerLoad(\.lazyProperty)

        // Assert
        XCTAssertEqual(result.count, 3, "Should return all three elements")
        for (index, model) in models.enumerated() {
            XCTAssertEqual(model.propertyAccessCount, 1, "Model \(index) property should be accessed once")
            XCTAssertTrue(result[index] === model, "Should preserve instance at index \(index)")
        }
    }

    func testEagerLoad_MultipleElements_MaintainsOrder() {
        // Arrange
        let model1 = TestModel()
        model1.simpleProperty = 1
        let model2 = TestModel()
        model2.simpleProperty = 2
        let model3 = TestModel()
        model3.simpleProperty = 3
        let models = [model1, model2, model3]

        // Act
        let result = models.eagerLoad(\.simpleProperty)

        // Assert
        XCTAssertEqual(result[0].simpleProperty, 1, "First element should maintain order")
        XCTAssertEqual(result[1].simpleProperty, 2, "Second element should maintain order")
        XCTAssertEqual(result[2].simpleProperty, 3, "Third element should maintain order")
    }

    // MARK: - Chaining Tests

    func testEagerLoad_CanChainMultipleProperties() {
        // Arrange
        let model = TestModel()
        let array = [model]

        // Act - chain two different eager loads
        let result = array
            .eagerLoad(\.lazyProperty)
            .eagerLoad(\.lazyProperty)

        // Assert
        XCTAssertEqual(result.count, 1, "Should return one element after chaining")
        XCTAssertEqual(model.propertyAccessCount, 2, "Lazy property should be accessed twice (once per chain)")
        XCTAssertTrue(result[0] === model, "Should preserve the same instance after chaining")
    }

    func testEagerLoad_ChainedWithOtherSequenceOperations() {
        // Arrange
        let models = [TestModel(), TestModel(), TestModel()]
        models[0].simpleProperty = 10
        models[1].simpleProperty = 20
        models[2].simpleProperty = 30

        // Act
        let sum = models
            .eagerLoad(\.simpleProperty)
            .map { $0.simpleProperty }
            .reduce(0, +)

        // Assert
        XCTAssertEqual(sum, 60, "Should be able to chain with map and reduce")
    }

    // MARK: - Real-World Scenario Tests

    func testEagerLoad_AggregationScenario() {
        // Arrange: Simulate the pattern used in BenefitRepository
        let models = (1...5).map { _ in TestModel() }

        // Act: Eager load before aggregation
        let count = models
            .eagerLoad(\.lazyProperty)
            .count

        // Assert
        XCTAssertEqual(count, 5, "Should correctly count after eager loading")
        for model in models {
            XCTAssertEqual(model.propertyAccessCount, 1, "Each model's property should be accessed once")
        }
    }
}
