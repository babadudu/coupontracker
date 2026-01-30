// SubscriptionTemplate.swift
// CouponTracker
//
// Pre-populated subscription service template (read-only, bundled).

import Foundation

/// Represents a pre-defined subscription service template.
/// Used to quickly add common subscriptions with pre-filled information.
struct SubscriptionTemplate: Codable, Identifiable, Hashable {
    let id: UUID
    let name: String
    let defaultPrice: Decimal
    let frequency: SubscriptionFrequency
    let category: SubscriptionCategory
    let iconName: String?
    let websiteUrl: String?
    let description: String?

    /// Optional prices for different frequencies (key = frequency rawValue)
    let frequencyPrices: [String: Decimal]?

    // MARK: - Computed Properties

    /// Annualized cost based on frequency and default price
    var annualizedCost: Decimal {
        frequency.annualizedCost(price: defaultPrice)
    }

    /// Monthly cost for comparison
    var monthlyCost: Decimal {
        annualizedCost / 12
    }

    /// Display icon (custom or category default)
    var displayIconName: String {
        iconName ?? category.iconName
    }

    /// Returns the price for a specific frequency, or nil if not offered
    /// - Parameter frequency: The frequency to get the price for
    /// - Returns: The price for that frequency, or nil if not available
    func price(for frequency: SubscriptionFrequency) -> Decimal? {
        if let prices = frequencyPrices, let price = prices[frequency.rawValue] {
            return price
        }
        if frequency == self.frequency {
            return defaultPrice
        }
        return nil
    }

    /// Returns all frequencies this template supports
    var availableFrequencies: [SubscriptionFrequency] {
        var frequencies: Set<SubscriptionFrequency> = [self.frequency]
        if let prices = frequencyPrices {
            for key in prices.keys {
                if let freq = SubscriptionFrequency(rawValue: key) {
                    frequencies.insert(freq)
                }
            }
        }
        return frequencies.sorted { $0.annualMultiplier > $1.annualMultiplier }
    }

    // MARK: - Memberwise Init

    init(
        id: UUID,
        name: String,
        defaultPrice: Decimal,
        frequency: SubscriptionFrequency,
        category: SubscriptionCategory,
        iconName: String? = nil,
        websiteUrl: String? = nil,
        description: String? = nil,
        frequencyPrices: [String: Decimal]? = nil
    ) {
        self.id = id
        self.name = name
        self.defaultPrice = defaultPrice
        self.frequency = frequency
        self.category = category
        self.iconName = iconName
        self.websiteUrl = websiteUrl
        self.description = description
        self.frequencyPrices = frequencyPrices
    }

    // MARK: - Hashable

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: SubscriptionTemplate, rhs: SubscriptionTemplate) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - CodingKeys with defaults

extension SubscriptionTemplate {
    enum CodingKeys: String, CodingKey {
        case id, name, defaultPrice, frequency, category
        case iconName, websiteUrl, description, frequencyPrices
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        id = try container.decode(UUID.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        defaultPrice = try container.decode(Decimal.self, forKey: .defaultPrice)
        frequency = try container.decode(SubscriptionFrequency.self, forKey: .frequency)
        category = try container.decode(SubscriptionCategory.self, forKey: .category)
        iconName = try container.decodeIfPresent(String.self, forKey: .iconName)
        websiteUrl = try container.decodeIfPresent(String.self, forKey: .websiteUrl)
        description = try container.decodeIfPresent(String.self, forKey: .description)
        frequencyPrices = try container.decodeIfPresent([String: Decimal].self, forKey: .frequencyPrices)
    }
}

// MARK: - SubscriptionTemplateDatabase

/// Container for subscription templates loaded from JSON.
struct SubscriptionTemplateDatabase: Codable {
    let schemaVersion: Int
    let dataVersion: String
    let lastUpdated: Date
    let subscriptions: [SubscriptionTemplate]

    /// All templates sorted by name
    var sortedByName: [SubscriptionTemplate] {
        subscriptions.sorted { $0.name < $1.name }
    }

    /// Templates grouped by category
    var byCategory: [SubscriptionCategory: [SubscriptionTemplate]] {
        Dictionary(grouping: subscriptions, by: { $0.category })
    }

    /// Find a template by ID
    func template(for id: UUID) -> SubscriptionTemplate? {
        subscriptions.first { $0.id == id }
    }

    /// Search templates by name
    func search(query: String) -> [SubscriptionTemplate] {
        guard !query.isEmpty else { return sortedByName }
        let lowercased = query.lowercased()
        return subscriptions.filter {
            $0.name.lowercased().contains(lowercased)
        }
    }
}
