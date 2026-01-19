//
//  CardRepositoryProtocol.swift
//  CouponTracker
//
//  Created by Junior Engineer 3 on 2026-01-17.
//

import Foundation

/// Protocol defining card repository operations for managing user cards.
/// This protocol abstracts the data layer to allow for different implementations
/// (e.g., SwiftData, Core Data fallback) and facilitates testing with mock repositories.
@MainActor
protocol CardRepositoryProtocol {

    // MARK: - Read Operations

    /// Retrieves all user cards from storage, sorted by sort order.
    /// - Returns: Array of all user cards
    /// - Throws: Repository error if fetch fails
    func getAllCards() throws -> [UserCard]

    /// Retrieves a specific card by its unique identifier.
    /// - Parameter id: The UUID of the card to retrieve
    /// - Returns: The user card if found, nil otherwise
    /// - Throws: Repository error if fetch fails
    func getCard(by id: UUID) throws -> UserCard?

    // MARK: - Write Operations

    /// Creates a new user card from a card template with optional nickname.
    /// This method will:
    /// 1. Create a new UserCard entity linked to the template
    /// 2. Create associated Benefit entities for each benefit in the template
    /// 3. Calculate initial period dates for each benefit
    /// 4. Persist everything to storage
    ///
    /// - Parameters:
    ///   - template: The card template to create the card from
    ///   - nickname: Optional user-defined nickname for the card
    /// - Returns: The newly created user card with all benefits
    /// - Throws: Repository error if creation fails
    func addCard(from template: CardTemplate, nickname: String?) throws -> UserCard

    /// Deletes a user card from storage.
    /// This will cascade delete all associated benefits and usage history.
    ///
    /// - Parameter card: The card to delete
    /// - Throws: Repository error if deletion fails
    func deleteCard(_ card: UserCard) throws

    /// Updates an existing user card in storage.
    /// This method persists changes made to a card's properties.
    ///
    /// - Parameter card: The card with updated properties
    /// - Throws: Repository error if update fails
    func updateCard(_ card: UserCard) throws
}
