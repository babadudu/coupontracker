// CardRecommendationService.swift
// CouponTracker
//
// Service for recommending cards based on benefits and usage patterns

import Foundation

/// CardRecommendationService
///
/// Responsibilities:
/// - Recommend best card for each benefit category based on annual value
/// - Provide top-scoring cards across all categories
/// - Search card templates by name and issuer
///
/// Dependencies:
/// - CardRepositoryProtocol for accessing user's existing cards
/// - TemplateLoaderProtocol for loading available card templates
///
/// Thread Safety: MainActor
@MainActor
final class CardRecommendationService: CardRecommendationServiceProtocol {

    // MARK: - Dependencies

    private let cardRepository: CardRepositoryProtocol
    private let templateLoader: TemplateLoaderProtocol

    // MARK: - Initialization

    init(cardRepository: CardRepositoryProtocol, templateLoader: TemplateLoaderProtocol) {
        self.cardRepository = cardRepository
        self.templateLoader = templateLoader
    }

    // MARK: - CardRecommendationServiceProtocol

    /// Returns the best card recommendation for each benefit category.
    /// - Returns: Dictionary mapping each BenefitCategory to its top RecommendedCard, empty dict on error
    func getRecommendationsByCategory() -> [BenefitCategory: RecommendedCard] {
        do {
            return try findBestCardsForAllCategories()
        } catch {
            return [:]
        }
    }

    func findBestCardsForAllCategories() throws -> [BenefitCategory: RecommendedCard] {
        let templates = try templateLoader.getActiveTemplates()
        var recommendations: [BenefitCategory: RecommendedCard] = [:]

        // Group benefits by category and find best card for each
        for category in BenefitCategory.allCases {
            if let bestCard = findBestCardForCategory(category, templates: templates) {
                recommendations[category] = bestCard
            }
        }

        return recommendations
    }

    /// Returns the top-scoring card recommendations across all categories.
    /// - Parameter limit: Maximum number of recommendations to return
    /// - Returns: Array of RecommendedCard sorted by score, empty array on error
    func getTopRecommendations(limit: Int) -> [RecommendedCard] {
        do {
            let templates = try templateLoader.getActiveTemplates()
            return templates.prefix(limit).map { template in
                RecommendedCard(
                    cardTemplateId: template.id,
                    cardName: template.name,
                    issuer: template.issuer,
                    score: calculateCardScore(template),
                    reason: "Good overall value"
                )
            }
        } catch {
            return []
        }
    }

    /// Searches card templates matching the query string.
    /// - Parameter query: Search term to match against card name and issuer
    /// - Returns: Array of RecommendedCard matching query, empty array on error
    func searchCards(query: String) -> [RecommendedCard] {
        do {
            let templates = try templateLoader.searchTemplates(query: query)
            return templates.map { template in
                RecommendedCard(
                    cardTemplateId: template.id,
                    cardName: template.name,
                    issuer: template.issuer,
                    score: calculateCardScore(template),
                    reason: "Matches search: \(query)"
                )
            }
        } catch {
            return []
        }
    }

    // MARK: - Private Helpers

    private func findBestCardForCategory(
        _ category: BenefitCategory,
        templates: [CardTemplate]
    ) -> RecommendedCard? {
        var bestCard: CardTemplate?
        var bestValue: Decimal = 0

        for template in templates {
            let categoryValue = template.benefits
                .filter { $0.category == category }
                .reduce(Decimal.zero) { $0 + $1.annualValue }

            if categoryValue > bestValue {
                bestValue = categoryValue
                bestCard = template
            }
        }

        guard let card = bestCard, bestValue > 0 else { return nil }

        return RecommendedCard(
            cardTemplateId: card.id,
            cardName: card.name,
            issuer: card.issuer,
            score: Double(truncating: bestValue as NSNumber),
            reason: "Best for \(category.displayName)"
        )
    }

    private func calculateCardScore(_ template: CardTemplate) -> Double {
        Double(truncating: template.totalAnnualValue as NSNumber)
    }
}
