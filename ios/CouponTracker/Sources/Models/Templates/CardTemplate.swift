// CardTemplate.swift
// CouponTracker
//
// Pre-populated card definition (read-only, bundled).
//

import Foundation

struct CardTemplate: Codable, Identifiable, Hashable {
    let id: UUID
    let name: String
    let issuer: String
    let artworkAsset: String
    let annualFee: Decimal?
    let primaryColorHex: String
    let secondaryColorHex: String
    let isActive: Bool
    let lastUpdated: Date
    let benefits: [BenefitTemplate]

    // MARK: - Computed Properties

    var totalAnnualValue: Decimal {
        benefits.reduce(Decimal.zero) { total, benefit in
            total + benefit.annualValue
        }
    }

    var hasBundledArtwork: Bool {
        !artworkAsset.isEmpty
    }

    // MARK: - Hashable
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: CardTemplate, rhs: CardTemplate) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - CodingKeys with defaults
extension CardTemplate {
    enum CodingKeys: String, CodingKey {
        case id, name, issuer, artworkAsset, annualFee
        case primaryColorHex = "primaryColor"
        case secondaryColorHex = "secondaryColor"
        case isActive, lastUpdated, benefits
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        id = try container.decode(UUID.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        issuer = try container.decode(String.self, forKey: .issuer)
        artworkAsset = try container.decodeIfPresent(String.self, forKey: .artworkAsset) ?? ""
        annualFee = try container.decodeIfPresent(Decimal.self, forKey: .annualFee)
        primaryColorHex = try container.decodeIfPresent(String.self, forKey: .primaryColorHex) ?? "#1a1a2e"
        secondaryColorHex = try container.decodeIfPresent(String.self, forKey: .secondaryColorHex) ?? "#4a4e69"
        isActive = try container.decodeIfPresent(Bool.self, forKey: .isActive) ?? true
        lastUpdated = try container.decodeIfPresent(Date.self, forKey: .lastUpdated) ?? Date()
        benefits = try container.decode([BenefitTemplate].self, forKey: .benefits)
    }
}
