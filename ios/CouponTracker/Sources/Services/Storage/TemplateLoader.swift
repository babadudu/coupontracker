// TemplateLoader.swift
// CouponTracker
//
// Service to load and parse CardTemplates.json from bundle resources.
//

import Foundation

/// Service responsible for loading card templates from bundled JSON resources
final class TemplateLoader: TemplateLoaderProtocol {

    // MARK: - Error Types

    enum TemplateLoaderError: LocalizedError {
        case resourceNotFound(String)
        case invalidData
        case decodingFailed(Error)
        case invalidSchemaVersion(Int)

        var errorDescription: String? {
            switch self {
            case .resourceNotFound(let filename):
                return "Template resource '\(filename)' not found in bundle"
            case .invalidData:
                return "Template data is invalid or corrupted"
            case .decodingFailed(let error):
                return "Failed to decode templates: \(error.localizedDescription)"
            case .invalidSchemaVersion(let version):
                return "Unsupported schema version: \(version)"
            }
        }
    }

    // MARK: - Properties

    private let bundle: Bundle
    private let resourceName: String
    private let resourceExtension: String

    // Cache for loaded database
    private var cachedDatabase: CardDatabase?

    // MARK: - Initialization

    /// Initialize the template loader
    /// - Parameters:
    ///   - bundle: Bundle to load resources from (default: main bundle)
    ///   - resourceName: Name of the JSON resource file (default: "CardTemplates")
    ///   - resourceExtension: File extension (default: "json")
    init(
        bundle: Bundle = .main,
        resourceName: String = "CardTemplates",
        resourceExtension: String = "json"
    ) {
        self.bundle = bundle
        self.resourceName = resourceName
        self.resourceExtension = resourceExtension
    }

    // MARK: - Public Methods

    /// Load all card templates from the bundled JSON file
    /// - Returns: CardDatabase containing all templates
    /// - Throws: TemplateLoaderError if loading or parsing fails
    func loadAllTemplates() throws -> CardDatabase {
        // Return cached database if available
        if let cached = cachedDatabase {
            return cached
        }

        // Try to locate the resource in the bundle
        if let url = bundle.url(forResource: resourceName, withExtension: resourceExtension) {
            // Read the data from the file
            do {
                let data = try Data(contentsOf: url)
                let decoder = JSONDecoder()
                decoder.dateDecodingStrategy = .iso8601
                let database = try decoder.decode(CardDatabase.self, from: data)
                
                // Validate schema version
                guard database.schemaVersion == 1 else {
                    throw TemplateLoaderError.invalidSchemaVersion(database.schemaVersion)
                }
                
                // Cache and return
                cachedDatabase = database
                return database
            } catch {
                print("⚠️ Failed to load CardTemplates.json: \(error). Using fallback templates.")
            }
        } else {
            print("⚠️ CardTemplates.json not found in bundle. Using fallback templates.")
        }
        
        // Return fallback templates if file not found or loading failed
        let fallback = createFallbackDatabase()
        cachedDatabase = fallback
        return fallback
    }
    
    /// Creates a fallback database with sample cards when JSON file is not available
    private func createFallbackDatabase() -> CardDatabase {
        let sapphireReserve = CardTemplate(
            id: UUID(uuidString: "550E8400-E29B-41D4-A716-446655440001")!,
            name: "Sapphire Reserve",
            issuer: "Chase",
            artworkAsset: "chase_sapphire_reserve",
            annualFee: 550,
            primaryColorHex: "#003C71",
            secondaryColorHex: "#0066B2",
            isActive: true,
            lastUpdated: Date(),
            benefits: [
                BenefitTemplate(
                    id: UUID(uuidString: "550E8400-E29B-41D4-A716-446655440101")!,
                    name: "Annual Travel Credit",
                    description: "$300 annual travel credit applied automatically",
                    value: 300,
                    frequency: .annual,
                    category: .travel,
                    merchant: nil,
                    resetDayOfMonth: nil
                ),
                BenefitTemplate(
                    id: UUID(uuidString: "550E8400-E29B-41D4-A716-446655440102")!,
                    name: "DoorDash Credit",
                    description: "$10 monthly DoorDash credit for DashPass members",
                    value: 10,
                    frequency: .monthly,
                    category: .dining,
                    merchant: "DoorDash",
                    resetDayOfMonth: 1
                )
            ]
        )
        
        let amexGold = CardTemplate(
            id: UUID(uuidString: "550E8400-E29B-41D4-A716-446655440002")!,
            name: "Gold Card",
            issuer: "American Express",
            artworkAsset: "amex_gold",
            annualFee: 250,
            primaryColorHex: "#D4AF37",
            secondaryColorHex: "#FFD700",
            isActive: true,
            lastUpdated: Date(),
            benefits: [
                BenefitTemplate(
                    id: UUID(uuidString: "550E8400-E29B-41D4-A716-446655440201")!,
                    name: "Uber Cash",
                    description: "$10 monthly Uber Cash for Uber Eats orders",
                    value: 10,
                    frequency: .monthly,
                    category: .dining,
                    merchant: "Uber",
                    resetDayOfMonth: nil
                ),
                BenefitTemplate(
                    id: UUID(uuidString: "550E8400-E29B-41D4-A716-446655440202")!,
                    name: "Dining Credit",
                    description: "$10 monthly dining credit at Grubhub, The Cheesecake Factory, etc.",
                    value: 10,
                    frequency: .monthly,
                    category: .dining,
                    merchant: nil,
                    resetDayOfMonth: 1
                )
            ]
        )
        
        let amexPlatinum = CardTemplate(
            id: UUID(uuidString: "550E8400-E29B-41D4-A716-446655440003")!,
            name: "Platinum Card",
            issuer: "American Express",
            artworkAsset: "amex_platinum",
            annualFee: 695,
            primaryColorHex: "#8B8B8B",
            secondaryColorHex: "#D4D4D4",
            isActive: true,
            lastUpdated: Date(),
            benefits: [
                BenefitTemplate(
                    id: UUID(uuidString: "550E8400-E29B-41D4-A716-446655440301")!,
                    name: "Uber Cash",
                    description: "$15 monthly Uber Cash ($20 in December)",
                    value: 15,
                    frequency: .monthly,
                    category: .transportation,
                    merchant: "Uber",
                    resetDayOfMonth: nil
                ),
                BenefitTemplate(
                    id: UUID(uuidString: "550E8400-E29B-41D4-A716-446655440302")!,
                    name: "Digital Entertainment Credit",
                    description: "$20 monthly credit for digital entertainment subscriptions",
                    value: 20,
                    frequency: .monthly,
                    category: .entertainment,
                    merchant: nil,
                    resetDayOfMonth: 1
                ),
                BenefitTemplate(
                    id: UUID(uuidString: "550E8400-E29B-41D4-A716-446655440303")!,
                    name: "Saks Credit",
                    description: "$50 semi-annual credit at Saks Fifth Avenue",
                    value: 50,
                    frequency: .semiAnnual,
                    category: .shopping,
                    merchant: "Saks Fifth Avenue",
                    resetDayOfMonth: nil
                )
            ]
        )
        
        return CardDatabase(
            schemaVersion: 1,
            dataVersion: "1.0.0-fallback",
            lastUpdated: Date(),
            cards: [sapphireReserve, amexGold, amexPlatinum]
        )
    }

    /// Get a specific card template by ID
    /// - Parameter id: UUID of the card template
    /// - Returns: CardTemplate if found, nil otherwise
    /// - Throws: TemplateLoaderError if loading fails
    func getTemplate(by id: UUID) throws -> CardTemplate? {
        let database = try loadAllTemplates()
        return database.card(for: id)
    }

    /// Get a specific benefit template by ID
    /// - Parameter id: UUID of the benefit template
    /// - Returns: BenefitTemplate if found, nil otherwise
    /// - Throws: TemplateLoaderError if loading fails
    func getBenefitTemplate(by id: UUID) throws -> BenefitTemplate? {
        let database = try loadAllTemplates()
        return database.benefit(for: id)
    }

    /// Search for card templates matching a query string
    /// - Parameter query: Search query (searches name and issuer)
    /// - Returns: Array of matching CardTemplates
    /// - Throws: TemplateLoaderError if loading fails
    func searchTemplates(query: String) throws -> [CardTemplate] {
        let database = try loadAllTemplates()

        // Return all active cards if query is empty
        guard !query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return database.activeCards
        }

        let lowercasedQuery = query.lowercased()

        return database.activeCards.filter { card in
            card.name.lowercased().contains(lowercasedQuery) ||
            card.issuer.lowercased().contains(lowercasedQuery)
        }
    }

    /// Get all active card templates
    /// - Returns: Array of active CardTemplates
    /// - Throws: TemplateLoaderError if loading fails
    func getActiveTemplates() throws -> [CardTemplate] {
        let database = try loadAllTemplates()
        return database.activeCards
    }

    /// Get templates grouped by issuer
    /// - Returns: Dictionary mapping issuer names to their card templates
    /// - Throws: TemplateLoaderError if loading fails
    func getTemplatesByIssuer() throws -> [String: [CardTemplate]] {
        let database = try loadAllTemplates()
        return database.cardsByIssuer
    }

    /// Clear the cached database (useful for testing or forced refresh)
    func clearCache() {
        cachedDatabase = nil
    }

    /// Get the data version of the loaded templates
    /// - Returns: Data version string
    /// - Throws: TemplateLoaderError if loading fails
    func getDataVersion() throws -> String {
        let database = try loadAllTemplates()
        return database.dataVersion
    }
}
