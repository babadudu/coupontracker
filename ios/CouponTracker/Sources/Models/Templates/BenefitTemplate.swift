// BenefitTemplate.swift
// CouponTracker
//
// Pre-populated benefit definition for card templates.
//

import Foundation

struct BenefitTemplate: Codable, Identifiable, Hashable {
    let id: UUID
    let name: String
    let description: String
    let value: Decimal
    let frequency: BenefitFrequency
    let category: BenefitCategory
    let merchant: String?
    let resetDayOfMonth: Int?  // nil means calendar period start
    let bonusValue: Decimal?   // Additional value in bonus months (e.g., December)
    let bonusMonths: [Int]?    // Months when bonus applies (1-12, e.g., [12] for December)

    // MARK: - Computed Properties

    /// Current month's value (uses bonusValue in bonus months, otherwise base value)
    var effectiveValue: Decimal {
        let currentMonth = Calendar.current.component(.month, from: Date())
        if let bonus = bonusValue, let months = bonusMonths, months.contains(currentMonth) {
            return bonus  // Replacement value, not additive
        }
        return value
    }

    /// Whether this benefit has a different value in the current month
    var hasBonusThisMonth: Bool {
        guard let months = bonusMonths else { return false }
        let currentMonth = Calendar.current.component(.month, from: Date())
        return months.contains(currentMonth)
    }

    /// Annual value of this benefit (accounts for bonus month replacements)
    var annualValue: Decimal {
        let bonusMonthCount = bonusMonths?.count ?? 0
        let regularMonthCount: Int

        switch frequency {
        case .monthly:
            regularMonthCount = 12 - bonusMonthCount
        case .quarterly:
            regularMonthCount = 4 - bonusMonthCount
        case .semiAnnual:
            regularMonthCount = 2 - bonusMonthCount
        case .annual:
            regularMonthCount = 1 - bonusMonthCount
        }

        let regularTotal = value * Decimal(max(0, regularMonthCount))
        let bonusTotal = (bonusValue ?? value) * Decimal(bonusMonthCount)
        return regularTotal + bonusTotal
    }

    /// Human-readable frequency string
    var frequencyDescription: String {
        switch frequency {
        case .monthly:
            return "Monthly"
        case .quarterly:
            return "Quarterly"
        case .semiAnnual:
            return "Semi-Annual"
        case .annual:
            return "Annual"
        }
    }

    // MARK: - Hashable
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: BenefitTemplate, rhs: BenefitTemplate) -> Bool {
        lhs.id == rhs.id
    }

    // MARK: - Convenience Init (with defaults for optional fields)

    init(
        id: UUID,
        name: String,
        description: String,
        value: Decimal,
        frequency: BenefitFrequency,
        category: BenefitCategory,
        merchant: String?,
        resetDayOfMonth: Int?,
        bonusValue: Decimal? = nil,
        bonusMonths: [Int]? = nil
    ) {
        self.id = id
        self.name = name
        self.description = description
        self.value = value
        self.frequency = frequency
        self.category = category
        self.merchant = merchant
        self.resetDayOfMonth = resetDayOfMonth
        self.bonusValue = bonusValue
        self.bonusMonths = bonusMonths
    }
}

// MARK: - Codable

extension BenefitTemplate {
    enum CodingKeys: String, CodingKey {
        case id, name, description, value, frequency, category
        case merchant, resetDayOfMonth, bonusValue, bonusMonths
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        id = try container.decode(UUID.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        description = try container.decode(String.self, forKey: .description)
        value = try container.decode(Decimal.self, forKey: .value)
        frequency = try container.decode(BenefitFrequency.self, forKey: .frequency)
        category = try container.decode(BenefitCategory.self, forKey: .category)
        merchant = try container.decodeIfPresent(String.self, forKey: .merchant)
        resetDayOfMonth = try container.decodeIfPresent(Int.self, forKey: .resetDayOfMonth)
        bonusValue = try container.decodeIfPresent(Decimal.self, forKey: .bonusValue)
        bonusMonths = try container.decodeIfPresent([Int].self, forKey: .bonusMonths)
    }
}

// Note: BenefitFrequency and BenefitCategory enums are defined in
// Models/Enums/BenefitEnums.swift to avoid duplication and provide
// shared functionality across templates and entities.
