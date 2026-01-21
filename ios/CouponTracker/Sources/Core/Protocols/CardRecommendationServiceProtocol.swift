// CardRecommendationServiceProtocol.swift
// CouponTracker
//
// Protocol for card recommendation operations

import Foundation

/// A recommended card with scoring information
struct RecommendedCard: Identifiable, Equatable {
    let id: UUID
    let cardTemplateId: UUID
    let cardName: String
    let issuer: String
    let score: Double
    let reason: String

    init(
        id: UUID = UUID(),
        cardTemplateId: UUID,
        cardName: String,
        issuer: String,
        score: Double,
        reason: String
    ) {
        self.id = id
        self.cardTemplateId = cardTemplateId
        self.cardName = cardName
        self.issuer = issuer
        self.score = score
        self.reason = reason
    }
}

/// Protocol defining card recommendation operations
protocol CardRecommendationServiceProtocol {
    /// Get best card recommendations by category
    func getRecommendationsByCategory() -> [BenefitCategory: RecommendedCard]

    /// Find best cards for all categories (throws on error)
    func findBestCardsForAllCategories() throws -> [BenefitCategory: RecommendedCard]

    /// Get top recommended cards overall
    func getTopRecommendations(limit: Int) -> [RecommendedCard]

    /// Search for cards matching a query
    func searchCards(query: String) -> [RecommendedCard]
}
