// Repository.swift
// CouponTracker
//
// Created: January 2026
// Purpose: Base repository protocol defining standard CRUD operations
//          for data access abstraction. Enables swapping implementations
//          (e.g., SwiftData to Core Data or remote API) without affecting
//          the rest of the application.

import Foundation
import SwiftData

// MARK: - Repository Protocol

/// Base protocol for all repository implementations.
/// Provides standard CRUD operations with async/await support.
///
/// This abstraction allows:
/// - Unit testing with mock implementations
/// - Swapping persistence layers (SwiftData, Core Data, API)
/// - Consistent error handling across data operations
///
/// Usage:
/// ```swift
/// @MainActor
/// class CardRepository: Repository {
///     typealias Entity = UserCard
///     // ... implementation
/// }
/// ```
@MainActor
protocol Repository {
    /// The entity type this repository manages
    associatedtype Entity: PersistentModel

    /// The model context for SwiftData operations
    var modelContext: ModelContext { get }

    // MARK: - Create

    /// Inserts a new entity into the store.
    /// - Parameter entity: The entity to insert
    /// - Throws: RepositoryError if the operation fails
    func insert(_ entity: Entity) throws

    // MARK: - Read

    /// Fetches all entities of this type.
    /// - Returns: Array of all entities
    /// - Throws: RepositoryError if the fetch fails
    func fetchAll() throws -> [Entity]

    /// Fetches a single entity by its identifier.
    /// - Parameter id: The unique identifier of the entity
    /// - Returns: The entity if found, nil otherwise
    /// - Throws: RepositoryError if the fetch fails
    func fetch(by id: UUID) throws -> Entity?

    /// Fetches entities matching the given predicate.
    /// - Parameters:
    ///   - predicate: The predicate to filter entities
    ///   - sortDescriptors: Optional sort descriptors
    /// - Returns: Array of matching entities
    /// - Throws: RepositoryError if the fetch fails
    func fetch(
        predicate: Predicate<Entity>?,
        sortDescriptors: [SortDescriptor<Entity>]
    ) throws -> [Entity]

    // MARK: - Update

    /// Saves any pending changes to the store.
    /// - Throws: RepositoryError if the save fails
    func save() throws

    // MARK: - Delete

    /// Deletes an entity from the store.
    /// - Parameter entity: The entity to delete
    /// - Throws: RepositoryError if the deletion fails
    func delete(_ entity: Entity) throws

    /// Deletes all entities of this type from the store.
    /// - Throws: RepositoryError if the deletion fails
    func deleteAll() throws
}

// MARK: - Default Implementations

extension Repository {

    /// Default implementation for inserting an entity
    func insert(_ entity: Entity) throws {
        modelContext.insert(entity)
        try save()
    }

    /// Default implementation for fetching all entities
    func fetchAll() throws -> [Entity] {
        let descriptor = FetchDescriptor<Entity>()
        return try modelContext.fetch(descriptor)
    }

    /// Default implementation for fetching with predicate
    func fetch(
        predicate: Predicate<Entity>? = nil,
        sortDescriptors: [SortDescriptor<Entity>] = []
    ) throws -> [Entity] {
        let descriptor = FetchDescriptor<Entity>(
            predicate: predicate,
            sortBy: sortDescriptors
        )
        return try modelContext.fetch(descriptor)
    }

    /// Default implementation for saving changes
    func save() throws {
        guard modelContext.hasChanges else { return }
        try modelContext.save()
    }

    /// Default implementation for deleting an entity
    func delete(_ entity: Entity) throws {
        modelContext.delete(entity)
        try save()
    }

    /// Default implementation for deleting all entities
    func deleteAll() throws {
        let entities = try fetchAll()
        for entity in entities {
            modelContext.delete(entity)
        }
        try save()
    }
}

// MARK: - Repository Error

/// Errors that can occur during repository operations
enum RepositoryError: LocalizedError {
    case fetchFailed(underlying: Error)
    case saveFailed(underlying: Error)
    case deleteFailed(underlying: Error)
    case entityNotFound(id: UUID)
    case invalidEntity(reason: String)
    case contextUnavailable

    var errorDescription: String? {
        switch self {
        case .fetchFailed(let error):
            return "Failed to fetch data: \(error.localizedDescription)"
        case .saveFailed(let error):
            return "Failed to save data: \(error.localizedDescription)"
        case .deleteFailed(let error):
            return "Failed to delete data: \(error.localizedDescription)"
        case .entityNotFound(let id):
            return "Entity with id \(id) not found"
        case .invalidEntity(let reason):
            return "Invalid entity: \(reason)"
        case .contextUnavailable:
            return "Model context is not available"
        }
    }
}

// MARK: - Identifiable Entity Protocol

/// Protocol for entities that have a UUID identifier
/// This enables the generic fetch(by:) implementation
protocol IdentifiableEntity: PersistentModel {
    var id: UUID { get }
}

// MARK: - Observable Repository

/// Base class for observable repositories that can be used with SwiftUI
/// Provides @Published properties for reactive updates
@MainActor
class ObservableRepository<Entity: PersistentModel>: ObservableObject {

    /// The model context for SwiftData operations
    let modelContext: ModelContext

    /// Published array of entities for reactive UI updates
    @Published private(set) var entities: [Entity] = []

    /// Published loading state
    @Published private(set) var isLoading: Bool = false

    /// Published error state
    @Published private(set) var error: RepositoryError?

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    /// Refreshes the entities array by fetching from the store
    func refresh() {
        isLoading = true
        error = nil

        do {
            let descriptor = FetchDescriptor<Entity>()
            entities = try modelContext.fetch(descriptor)
        } catch {
            self.error = .fetchFailed(underlying: error)
        }

        isLoading = false
    }

    /// Inserts a new entity and refreshes the list
    func insert(_ entity: Entity) {
        do {
            modelContext.insert(entity)
            try modelContext.save()
            refresh()
        } catch {
            self.error = .saveFailed(underlying: error)
        }
    }

    /// Deletes an entity and refreshes the list
    func delete(_ entity: Entity) {
        do {
            modelContext.delete(entity)
            try modelContext.save()
            refresh()
        } catch {
            self.error = .deleteFailed(underlying: error)
        }
    }
}

// MARK: - Async Repository Protocol

/// Extended repository protocol with async/await support for
/// operations that may involve background processing or network calls
@MainActor
protocol AsyncRepository: Repository {

    /// Asynchronously fetches all entities
    func fetchAllAsync() async throws -> [Entity]

    /// Asynchronously fetches entity by ID
    func fetchAsync(by id: UUID) async throws -> Entity?

    /// Asynchronously saves changes
    func saveAsync() async throws
}

extension AsyncRepository {

    /// Default async implementation wraps synchronous call
    func fetchAllAsync() async throws -> [Entity] {
        try fetchAll()
    }

    /// Default async implementation wraps synchronous call
    func saveAsync() async throws {
        try save()
    }
}
