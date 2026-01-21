import XCTest
@testable import CouponTracker

@MainActor
final class DashboardInsightResolverTests: XCTestCase {

    // MARK: - Priority 1: Urgent Expiring

    func testUrgentExpiringTakesPrecedence() {
        let resolver = DashboardInsightResolver()

        let expiringBenefits = [
            PreviewBenefit.mock(value: 50),
            PreviewBenefit.mock(value: 75)
        ]

        let insight = resolver.resolve(
            benefitsExpiringToday: expiringBenefits,
            totalAvailableValue: 200,  // Would trigger Priority 2
            usedCount: 10,
            totalCount: 15,  // Would trigger Priority 3 (10/15 > 50%)
            redeemedThisMonth: 150
        )

        guard case .urgentExpiring(let value, let count) = insight else {
            XCTFail("Expected urgentExpiring, got \(String(describing: insight))")
            return
        }
        XCTAssertEqual(value, 125)
        XCTAssertEqual(count, 2)
    }

    func testUrgentExpiringCalculatesValue() {
        let resolver = DashboardInsightResolver()

        let expiringBenefits = [
            PreviewBenefit.mock(value: 25.50),
            PreviewBenefit.mock(value: 30.75),
            PreviewBenefit.mock(value: 15.25)
        ]

        let insight = resolver.resolve(
            benefitsExpiringToday: expiringBenefits,
            totalAvailableValue: 0,
            usedCount: 0,
            totalCount: 1,
            redeemedThisMonth: 0
        )

        guard case .urgentExpiring(let value, let count) = insight else {
            XCTFail("Expected urgentExpiring")
            return
        }
        XCTAssertEqual(value, 71.50)
        XCTAssertEqual(count, 3)
    }

    // MARK: - Priority 2: High Available Value

    func testHighAvailableValueShown() {
        let resolver = DashboardInsightResolver()

        let insight = resolver.resolve(
            benefitsExpiringToday: [],
            totalAvailableValue: 150,
            usedCount: 10,
            totalCount: 15,  // Would trigger Priority 3
            redeemedThisMonth: 100
        )

        guard case .availableValue(let value) = insight else {
            XCTFail("Expected availableValue, got \(String(describing: insight))")
            return
        }
        XCTAssertEqual(value, 150)
    }

    func testExactlyHundredDoesNotShow() {
        let resolver = DashboardInsightResolver()

        let insight = resolver.resolve(
            benefitsExpiringToday: [],
            totalAvailableValue: 100,
            usedCount: 10,
            totalCount: 15,  // Should show Priority 3 instead
            redeemedThisMonth: 100
        )

        guard case .monthlySuccess = insight else {
            XCTFail("Expected monthlySuccess at exactly $100, got \(String(describing: insight))")
            return
        }
    }

    func testJustOverHundredShows() {
        let resolver = DashboardInsightResolver()

        let insight = resolver.resolve(
            benefitsExpiringToday: [],
            totalAvailableValue: 100.01,
            usedCount: 0,
            totalCount: 1,
            redeemedThisMonth: 0
        )

        guard case .availableValue(let value) = insight else {
            XCTFail("Expected availableValue")
            return
        }
        XCTAssertEqual(value, 100.01)
    }

    // MARK: - Priority 3: Monthly Success

    func testMonthlySuccessShown() {
        let resolver = DashboardInsightResolver()

        let insight = resolver.resolve(
            benefitsExpiringToday: [],
            totalAvailableValue: 50,
            usedCount: 8,
            totalCount: 15,  // 8/15 = 53.3% > 50%
            redeemedThisMonth: 120
        )

        guard case .monthlySuccess(let value) = insight else {
            XCTFail("Expected monthlySuccess, got \(String(describing: insight))")
            return
        }
        XCTAssertEqual(value, 120)
    }

    func testExactlyFiftyPercentDoesNotShow() {
        let resolver = DashboardInsightResolver()

        let insight = resolver.resolve(
            benefitsExpiringToday: [],
            totalAvailableValue: 50,
            usedCount: 10,
            totalCount: 20,  // 10/20 = exactly 50%
            redeemedThisMonth: 100
        )

        XCTAssertNil(insight, "Exactly 50% should not trigger monthly success")
    }

    func testJustOverFiftyPercentShows() {
        let resolver = DashboardInsightResolver()

        let insight = resolver.resolve(
            benefitsExpiringToday: [],
            totalAvailableValue: 50,
            usedCount: 11,
            totalCount: 20,  // 11/20 = 55% > 50%
            redeemedThisMonth: 150
        )

        guard case .monthlySuccess(let value) = insight else {
            XCTFail("Expected monthlySuccess")
            return
        }
        XCTAssertEqual(value, 150)
    }

    func testMonthlySuccessNotShownWhenEmpty() {
        let resolver = DashboardInsightResolver()

        let insight = resolver.resolve(
            benefitsExpiringToday: [],
            totalAvailableValue: 0,
            usedCount: 0,
            totalCount: 0,
            redeemedThisMonth: 0
        )

        guard case .onboarding = insight else {
            XCTFail("Expected onboarding for empty state, got \(String(describing: insight))")
            return
        }
    }

    // MARK: - Priority 4: Onboarding

    func testOnboardingShownWhenEmpty() {
        let resolver = DashboardInsightResolver()

        let insight = resolver.resolve(
            benefitsExpiringToday: [],
            totalAvailableValue: 0,
            usedCount: 0,
            totalCount: 0,
            redeemedThisMonth: 0
        )

        guard case .onboarding = insight else {
            XCTFail("Expected onboarding, got \(String(describing: insight))")
            return
        }
    }

    // MARK: - No Insight Cases

    func testNilWhenNoConditionsMet() {
        let resolver = DashboardInsightResolver()

        let insight = resolver.resolve(
            benefitsExpiringToday: [],
            totalAvailableValue: 50,   // < 100
            usedCount: 2,
            totalCount: 10,  // 2/10 = 20% < 50%
            redeemedThisMonth: 20
        )

        XCTAssertNil(insight)
    }

    func testNilWithDataBelowThresholds() {
        let resolver = DashboardInsightResolver()

        let insight = resolver.resolve(
            benefitsExpiringToday: [],
            totalAvailableValue: 99.99,  // Just under 100
            usedCount: 5,
            totalCount: 10,  // Exactly 50%
            redeemedThisMonth: 50
        )

        XCTAssertNil(insight)
    }
}

// MARK: - Mock Helper

extension PreviewBenefit {
    static func mock(value: Decimal) -> PreviewBenefit {
        PreviewBenefit(
            name: "Mock Benefit",
            value: value,
            frequency: .monthly,
            category: .dining,
            expirationDate: Date()
        )
    }
}
