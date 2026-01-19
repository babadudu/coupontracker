// CardDatabase.swift
// CouponTracker
//
// Container for the full template database.
//

import Foundation

struct CardDatabase: Codable {
    let schemaVersion: Int
    let dataVersion: String
    let lastUpdated: Date
    let cards: [CardTemplate]

    // MARK: - Convenience

    func card(for id: UUID) -> CardTemplate? {
        cards.first { $0.id == id }
    }

    func benefit(for id: UUID) -> BenefitTemplate? {
        for card in cards {
            if let benefit = card.benefits.first(where: { $0.id == id }) {
                return benefit
            }
        }
        return nil
    }

    var activeCards: [CardTemplate] {
        cards.filter { $0.isActive }
    }

    var cardsByIssuer: [String: [CardTemplate]] {
        Dictionary(grouping: activeCards, by: { $0.issuer })
    }
}
