// TemplateLoaderProtocol.swift
// CouponTracker
//
// Protocol for template loading operations

import Foundation

/// Protocol defining template loading operations
protocol TemplateLoaderProtocol {
    /// Load all templates from the database
    func loadAllTemplates() throws -> CardDatabase

    /// Get a specific template by ID
    func getTemplate(by id: UUID) throws -> CardTemplate?

    /// Get a specific benefit template by ID
    func getBenefitTemplate(by id: UUID) throws -> BenefitTemplate?

    /// Search templates by query string
    func searchTemplates(query: String) throws -> [CardTemplate]

    /// Get all active templates
    func getActiveTemplates() throws -> [CardTemplate]

    /// Get templates grouped by issuer
    func getTemplatesByIssuer() throws -> [String: [CardTemplate]]
}
