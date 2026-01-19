# CouponTracker Data Model Specification

**Version:** 1.0
**Last Updated:** January 16, 2026
**Status:** Approved
**Author:** Software Architect

---

## Table of Contents

1. [Overview](#overview)
2. [Entity Relationship Diagram](#entity-relationship-diagram)
3. [SwiftData Entity Definitions](#swiftdata-entity-definitions)
4. [Template Structures](#template-structures)
5. [Enumerations](#enumerations)
6. [Relationships and Constraints](#relationships-and-constraints)
7. [Migration Strategy](#migration-strategy)
8. [Sample Data](#sample-data)
9. [Query Patterns](#query-patterns)

---

## Overview

### Data Architecture

CouponTracker uses a **hybrid data architecture**:

1. **SwiftData Persistence** - User data (cards, benefits, usage history)
2. **Bundled JSON Templates** - Pre-populated card database (read-only)
3. **UserDefaults** - App preferences and simple flags

### Design Principles

1. **Template-Instance Separation:** Templates are immutable references; user instances can override/customize
2. **Soft References:** User entities reference template IDs rather than embedding template data
3. **Historical Integrity:** Usage history preserved even when cards/benefits are deleted
4. **Future-Ready:** Model supports cloud sync with UUID primary keys and timestamps

---

## Entity Relationship Diagram

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                           SWIFTDATA ENTITIES                                 │
│                        (User Data - Persistent)                              │
└─────────────────────────────────────────────────────────────────────────────┘

┌─────────────────────┐         ┌─────────────────────┐         ┌─────────────────────┐
│      UserCard       │         │      Benefit        │         │    BenefitUsage     │
├─────────────────────┤         ├─────────────────────┤         ├─────────────────────┤
│ id: UUID (PK)       │         │ id: UUID (PK)       │         │ id: UUID (PK)       │
│ cardTemplateId: UUID│◄────────│ userCardId: UUID(FK)│◄────────│ benefitId: UUID(FK) │
│ nickname: String?   │   1:N   │ templateBenefitId   │   1:N   │ usedDate: Date      │
│ addedDate: Date     │         │ customName: String? │         │ periodStart: Date   │
│ isCustom: Bool      │         │ customValue: Decimal│         │ periodEnd: Date     │
│ customName: String? │         │ status: BenefitStat │         │ valueRedeemed: Dec  │
│ customIssuer: String│         │ currentPeriodStart  │         │ notes: String?      │
│ customColorHex: Str?│         │ currentPeriodEnd    │         │ createdAt: Date     │
│ sortOrder: Int      │         │ reminderEnabled:Bool│         └─────────────────────┘
│ createdAt: Date     │         │ reminderDaysBefore  │
│ updatedAt: Date     │         │ lastReminderDate    │
└─────────────────────┘         │ createdAt: Date     │
                                │ updatedAt: Date     │
                                └─────────────────────┘
                                          │
                                          │ References (Lookup)
                                          ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                           TEMPLATE STRUCTURES                                │
│                     (Read-Only - Bundled in App)                            │
└─────────────────────────────────────────────────────────────────────────────┘

┌─────────────────────┐         ┌─────────────────────┐
│    CardTemplate     │         │   BenefitTemplate   │
├─────────────────────┤         ├─────────────────────┤
│ id: UUID (PK)       │◄────────│ id: UUID (PK)       │
│ name: String        │   1:N   │ cardTemplateId: UUID│
│ issuer: String      │         │ name: String        │
│ artworkAsset: String│         │ description: String │
│ annualFee: Decimal? │         │ value: Decimal      │
│ primaryColor: String│         │ frequency: Frequency│
│ secondaryColor: Str │         │ category: Category  │
│ isActive: Bool      │         │ merchant: String?   │
│ lastUpdated: Date   │         │ resetDayOfMonth: Int│
└─────────────────────┘         └─────────────────────┘
```

---

## SwiftData Entity Definitions

### UserCard

Represents a credit card in the user's wallet.

```swift
// Sources/Models/Entities/UserCard.swift

import SwiftData
import Foundation

@Model
final class UserCard {
    // MARK: - Primary Key
    @Attribute(.unique)
    var id: UUID

    // MARK: - Template Reference
    /// Reference to CardTemplate.id for pre-populated cards.
    /// nil for custom cards.
    var cardTemplateId: UUID?

    // MARK: - User Customization
    /// User-defined nickname (e.g., "Personal", "Business")
    var nickname: String?

    // MARK: - Custom Card Properties
    /// True if this is a user-created custom card
    var isCustom: Bool

    /// Name for custom cards (ignored if isCustom = false)
    var customName: String?

    /// Issuer for custom cards
    var customIssuer: String?

    /// Hex color for custom card gradient (e.g., "#1a1a2e")
    var customColorHex: String?

    // MARK: - Metadata
    /// Date card was added to wallet
    var addedDate: Date

    /// Sort order in wallet view (lower = first)
    var sortOrder: Int

    /// Record creation timestamp
    var createdAt: Date

    /// Last modification timestamp
    var updatedAt: Date

    // MARK: - Relationships
    @Relationship(deleteRule: .cascade, inverse: \Benefit.userCard)
    var benefits: [Benefit] = []

    // MARK: - Initialization
    init(
        id: UUID = UUID(),
        cardTemplateId: UUID? = nil,
        nickname: String? = nil,
        isCustom: Bool = false,
        customName: String? = nil,
        customIssuer: String? = nil,
        customColorHex: String? = nil,
        sortOrder: Int = 0
    ) {
        self.id = id
        self.cardTemplateId = cardTemplateId
        self.nickname = nickname
        self.isCustom = isCustom
        self.customName = customName
        self.customIssuer = customIssuer
        self.customColorHex = customColorHex
        self.sortOrder = sortOrder
        self.addedDate = Date()
        self.createdAt = Date()
        self.updatedAt = Date()
    }

    // MARK: - Computed Properties

    /// Returns the display name for this card.
    /// Priority: nickname > customName > template name
    func displayName(template: CardTemplate?) -> String {
        if let nickname = nickname, !nickname.isEmpty {
            return nickname
        }
        if isCustom, let customName = customName {
            return customName
        }
        return template?.name ?? "Unknown Card"
    }

    /// Returns the issuer name.
    func issuerName(template: CardTemplate?) -> String {
        if isCustom {
            return customIssuer ?? ""
        }
        return template?.issuer ?? ""
    }

    /// Total available value across all benefits
    var totalAvailableValue: Decimal {
        benefits
            .filter { $0.status == .available }
            .reduce(Decimal.zero) { $0 + $1.effectiveValue }
    }

    /// Count of benefits expiring within specified days
    func expiringCount(withinDays days: Int) -> Int {
        let threshold = Calendar.current.date(
            byAdding: .day,
            value: days,
            to: Date()
        ) ?? Date()

        return benefits.filter { benefit in
            benefit.status == .available &&
            benefit.currentPeriodEnd <= threshold
        }.count
    }
}
```

---

### Benefit

Represents an individual trackable benefit/reward.

```swift
// Sources/Models/Entities/Benefit.swift

import SwiftData
import Foundation

@Model
final class Benefit {
    // MARK: - Primary Key
    @Attribute(.unique)
    var id: UUID

    // MARK: - Relationships
    var userCard: UserCard?

    // MARK: - Template Reference
    /// Reference to BenefitTemplate.id for template-based benefits.
    /// nil for custom benefits.
    var templateBenefitId: UUID?

    // MARK: - Custom/Override Values
    /// Overrides template name
    var customName: String?

    /// Overrides template value
    var customValue: Decimal?

    /// Overrides template description
    var customDescription: String?

    /// Overrides template frequency
    var customFrequency: BenefitFrequency?

    // MARK: - Tracking State
    /// Current status of the benefit
    var status: BenefitStatus

    /// Start of current benefit period
    var currentPeriodStart: Date

    /// End of current benefit period (expiration date)
    var currentPeriodEnd: Date

    /// When the benefit will reset to a new period
    var nextResetDate: Date

    // MARK: - Notification Settings
    /// Whether reminders are enabled for this benefit
    var reminderEnabled: Bool

    /// Days before expiration to send reminder (default: 7)
    var reminderDaysBefore: Int

    /// Last time a reminder was sent (for follow-up logic)
    var lastReminderDate: Date?

    /// Scheduled notification identifier
    var scheduledNotificationId: String?

    // MARK: - Metadata
    var createdAt: Date
    var updatedAt: Date

    // MARK: - Relationships
    @Relationship(deleteRule: .cascade, inverse: \BenefitUsage.benefit)
    var usageHistory: [BenefitUsage] = []

    // MARK: - Initialization
    init(
        id: UUID = UUID(),
        userCard: UserCard? = nil,
        templateBenefitId: UUID? = nil,
        status: BenefitStatus = .available,
        currentPeriodStart: Date,
        currentPeriodEnd: Date,
        nextResetDate: Date? = nil,
        reminderEnabled: Bool = true,
        reminderDaysBefore: Int = 7
    ) {
        self.id = id
        self.userCard = userCard
        self.templateBenefitId = templateBenefitId
        self.status = status
        self.currentPeriodStart = currentPeriodStart
        self.currentPeriodEnd = currentPeriodEnd
        self.nextResetDate = nextResetDate ?? currentPeriodEnd
        self.reminderEnabled = reminderEnabled
        self.reminderDaysBefore = reminderDaysBefore
        self.createdAt = Date()
        self.updatedAt = Date()
    }

    // MARK: - Computed Properties

    /// Effective name (custom override or template)
    var effectiveName: String {
        customName ?? ""  // Resolved via repository with template lookup
    }

    /// Effective value (custom override or template)
    var effectiveValue: Decimal {
        customValue ?? Decimal.zero  // Resolved via repository with template lookup
    }

    /// Days until benefit expires
    var daysUntilExpiration: Int {
        let calendar = Calendar.current
        let components = calendar.dateComponents(
            [.day],
            from: calendar.startOfDay(for: Date()),
            to: calendar.startOfDay(for: currentPeriodEnd)
        )
        return max(0, components.day ?? 0)
    }

    /// Whether benefit is expiring soon (within 7 days)
    var isExpiringSoon: Bool {
        daysUntilExpiration <= 7 && status == .available
    }

    /// Whether benefit is urgent (expiring within 3 days)
    var isUrgent: Bool {
        daysUntilExpiration <= 3 && status == .available
    }

    /// Whether benefit period has expired
    var isPeriodExpired: Bool {
        Date() > currentPeriodEnd
    }

    /// Whether benefit needs to be reset to new period
    var needsReset: Bool {
        Date() >= nextResetDate
    }

    // MARK: - Methods

    /// Mark the benefit as used
    mutating func markAsUsed() {
        guard status == .available else { return }
        status = .used
        updatedAt = Date()
    }

    /// Mark the benefit as expired
    mutating func markAsExpired() {
        guard status == .available else { return }
        status = .expired
        updatedAt = Date()
    }

    /// Reset benefit to a new period
    mutating func resetToNewPeriod(
        periodStart: Date,
        periodEnd: Date,
        nextReset: Date
    ) {
        status = .available
        currentPeriodStart = periodStart
        currentPeriodEnd = periodEnd
        nextResetDate = nextReset
        lastReminderDate = nil
        scheduledNotificationId = nil
        updatedAt = Date()
    }
}
```

---

### BenefitUsage

Historical record of benefit redemptions.

```swift
// Sources/Models/Entities/BenefitUsage.swift

import SwiftData
import Foundation

@Model
final class BenefitUsage {
    // MARK: - Primary Key
    @Attribute(.unique)
    var id: UUID

    // MARK: - Relationships
    var benefit: Benefit?

    // MARK: - Usage Details
    /// When the benefit was marked as used
    var usedDate: Date

    /// Period start for which this usage applies
    var periodStart: Date

    /// Period end for which this usage applies
    var periodEnd: Date

    /// Value that was redeemed
    var valueRedeemed: Decimal

    /// Optional user notes
    var notes: String?

    /// Was this an auto-expiration (vs manual mark as used)
    var wasAutoExpired: Bool

    // MARK: - Denormalized Data (for history display)
    /// Card name at time of usage (in case card is later deleted)
    var cardNameSnapshot: String?

    /// Benefit name at time of usage
    var benefitNameSnapshot: String?

    // MARK: - Metadata
    var createdAt: Date

    // MARK: - Initialization
    init(
        id: UUID = UUID(),
        benefit: Benefit? = nil,
        usedDate: Date = Date(),
        periodStart: Date,
        periodEnd: Date,
        valueRedeemed: Decimal,
        notes: String? = nil,
        wasAutoExpired: Bool = false,
        cardNameSnapshot: String? = nil,
        benefitNameSnapshot: String? = nil
    ) {
        self.id = id
        self.benefit = benefit
        self.usedDate = usedDate
        self.periodStart = periodStart
        self.periodEnd = periodEnd
        self.valueRedeemed = valueRedeemed
        self.notes = notes
        self.wasAutoExpired = wasAutoExpired
        self.cardNameSnapshot = cardNameSnapshot
        self.benefitNameSnapshot = benefitNameSnapshot
        self.createdAt = Date()
    }
}
```

---

### UserPreferences

User settings stored in SwiftData (alternative to UserDefaults for sync).

```swift
// Sources/Models/Entities/UserPreferences.swift

import SwiftData
import Foundation

@Model
final class UserPreferences {
    // MARK: - Singleton Key
    @Attribute(.unique)
    var id: String = "user_preferences"

    // MARK: - Notification Preferences
    /// Master toggle for all notifications
    var notificationsEnabled: Bool

    /// Preferred time for notifications (hour, minute)
    var preferredReminderHour: Int
    var preferredReminderMinute: Int

    /// Default reminder lead time in days
    var defaultReminderDays: Int

    // MARK: - Quiet Hours
    var quietHoursEnabled: Bool
    var quietHoursStart: Int  // Hour (0-23)
    var quietHoursEnd: Int    // Hour (0-23)

    // MARK: - App State
    var hasCompletedOnboarding: Bool
    var lastSyncDate: Date?

    // MARK: - Metadata
    var updatedAt: Date

    // MARK: - Initialization
    init() {
        self.notificationsEnabled = true
        self.preferredReminderHour = 9
        self.preferredReminderMinute = 0
        self.defaultReminderDays = 7
        self.quietHoursEnabled = false
        self.quietHoursStart = 22
        self.quietHoursEnd = 8
        self.hasCompletedOnboarding = false
        self.updatedAt = Date()
    }
}
```

---

## Template Structures

### CardTemplate

Pre-populated card definition (read-only, bundled).

```swift
// Sources/Models/Templates/CardTemplate.swift

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
```

---

### BenefitTemplate

Pre-populated benefit definition.

```swift
// Sources/Models/Templates/BenefitTemplate.swift

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

    // MARK: - Computed Properties

    /// Annual value of this benefit
    var annualValue: Decimal {
        switch frequency {
        case .monthly:
            return value * 12
        case .quarterly:
            return value * 4
        case .semiAnnual:
            return value * 2
        case .annual:
            return value
        }
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
}
```

---

### CardDatabase

Container for the full template database.

```swift
// Sources/Models/Templates/CardDatabase.swift

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
```

---

## Enumerations

```swift
// Sources/Models/Enums/BenefitStatus.swift

import Foundation

enum BenefitStatus: String, Codable, CaseIterable {
    case available
    case used
    case expired

    var displayName: String {
        switch self {
        case .available: return "Available"
        case .used: return "Used"
        case .expired: return "Expired"
        }
    }

    var iconName: String {
        switch self {
        case .available: return "circle"
        case .used: return "checkmark.circle.fill"
        case .expired: return "xmark.circle"
        }
    }
}
```

```swift
// Sources/Models/Enums/BenefitFrequency.swift

import Foundation

enum BenefitFrequency: String, Codable, CaseIterable {
    case monthly
    case quarterly
    case semiAnnual
    case annual

    var displayName: String {
        switch self {
        case .monthly: return "Monthly"
        case .quarterly: return "Quarterly"
        case .semiAnnual: return "Semi-Annual"
        case .annual: return "Annual"
        }
    }

    /// Number of periods per year
    var periodsPerYear: Int {
        switch self {
        case .monthly: return 12
        case .quarterly: return 4
        case .semiAnnual: return 2
        case .annual: return 1
        }
    }
}
```

```swift
// Sources/Models/Enums/BenefitCategory.swift

import Foundation

enum BenefitCategory: String, Codable, CaseIterable {
    case travel
    case dining
    case entertainment
    case shopping
    case transportation
    case wellness
    case hotel
    case airline
    case other

    var displayName: String {
        switch self {
        case .travel: return "Travel"
        case .dining: return "Dining"
        case .entertainment: return "Entertainment"
        case .shopping: return "Shopping"
        case .transportation: return "Transportation"
        case .wellness: return "Wellness"
        case .hotel: return "Hotel"
        case .airline: return "Airline"
        case .other: return "Other"
        }
    }

    var iconName: String {
        switch self {
        case .travel: return "airplane"
        case .dining: return "fork.knife"
        case .entertainment: return "tv"
        case .shopping: return "bag"
        case .transportation: return "car"
        case .wellness: return "heart"
        case .hotel: return "building.2"
        case .airline: return "airplane.departure"
        case .other: return "star"
        }
    }
}
```

---

## Relationships and Constraints

### Relationship Summary

| Parent | Child | Cardinality | Delete Rule | Inverse |
|--------|-------|-------------|-------------|---------|
| UserCard | Benefit | 1:N | Cascade | userCard |
| Benefit | BenefitUsage | 1:N | Cascade | benefit |

### Constraints

| Entity | Field | Constraint | Rationale |
|--------|-------|------------|-----------|
| UserCard | id | Unique | Primary key |
| Benefit | id | Unique | Primary key |
| BenefitUsage | id | Unique | Primary key |
| UserPreferences | id | Unique | Singleton pattern |

### Indexes (Recommended)

```swift
// These would be configured in the ModelContainer setup
// or via @Attribute macros

// UserCard
// - Index on cardTemplateId for template lookups
// - Index on sortOrder for ordered queries

// Benefit
// - Index on status for filtering
// - Index on currentPeriodEnd for expiration queries
// - Index on userCard for relationship traversal

// BenefitUsage
// - Index on usedDate for history queries
// - Index on periodStart, periodEnd for period lookups
```

### Validation Rules

```swift
extension UserCard {
    func validate() throws {
        if isCustom && (customName?.isEmpty ?? true) {
            throw ValidationError.customCardRequiresName
        }
    }
}

extension Benefit {
    func validate() throws {
        if currentPeriodEnd < currentPeriodStart {
            throw ValidationError.invalidPeriodRange
        }
        if reminderDaysBefore < 0 || reminderDaysBefore > 30 {
            throw ValidationError.invalidReminderDays
        }
    }
}

enum ValidationError: Error {
    case customCardRequiresName
    case invalidPeriodRange
    case invalidReminderDays
}
```

---

## Migration Strategy

### Schema Version Management

```swift
// Sources/App/DataMigration.swift

import SwiftData

enum SchemaVersion: Int {
    case v1 = 1  // Initial release
    case v2 = 2  // Future: add new fields
}

// SwiftData handles lightweight migrations automatically for:
// - Adding new optional fields
// - Adding new entities
// - Adding new relationships

// For complex migrations:
struct MigrationPlan: SchemaMigrationPlan {
    static var schemas: [any VersionedSchema.Type] {
        [SchemaV1.self]
    }

    static var stages: [MigrationStage] {
        []  // No migrations yet
    }
}

// Version 1 Schema
enum SchemaV1: VersionedSchema {
    static var versionIdentifier: Schema.Version = .init(1, 0, 0)

    static var models: [any PersistentModel.Type] {
        [UserCard.self, Benefit.self, BenefitUsage.self, UserPreferences.self]
    }
}
```

### Template Database Versioning

```swift
// Template database update strategy

struct TemplateVersionManager {

    /// Compare bundled templates with last synced version
    func checkForUpdates(
        bundled: CardDatabase,
        lastSynced: String?
    ) -> TemplateUpdateResult {

        guard let lastSynced = lastSynced else {
            return .initialLoad(bundled.cards)
        }

        if bundled.dataVersion == lastSynced {
            return .noUpdates
        }

        // In future: compute delta between versions
        return .updatesAvailable(bundled.dataVersion)
    }

    /// Merge new templates without losing user customizations
    func mergeTemplates(
        existingCards: [UserCard],
        newTemplates: [CardTemplate],
        context: ModelContext
    ) {
        // 1. User customizations (nickname, custom values) are preserved
        // 2. Template-derived defaults update if user hasn't customized
        // 3. New cards added to catalog (not to user wallet)
        // 4. Deprecated cards marked inactive

        for card in existingCards where card.cardTemplateId != nil {
            // Card exists - preserve user customizations
            // Template data is looked up fresh each time
        }
    }
}

enum TemplateUpdateResult {
    case initialLoad([CardTemplate])
    case noUpdates
    case updatesAvailable(String)
}
```

### Data Backup/Export (Future)

```swift
// For future cloud sync or export functionality

struct ExportableData: Codable {
    let exportVersion: Int
    let exportDate: Date
    let cards: [ExportableCard]
    let preferences: ExportablePreferences
}

struct ExportableCard: Codable {
    let id: UUID
    let templateId: UUID?
    let nickname: String?
    let isCustom: Bool
    let customName: String?
    let customIssuer: String?
    let customColorHex: String?
    let benefits: [ExportableBenefit]
    let usageHistory: [ExportableUsage]
}
```

---

## Sample Data

### CardTemplates.json

```json
{
  "schemaVersion": 1,
  "dataVersion": "2026.01.16",
  "lastUpdated": "2026-01-16T00:00:00Z",
  "cards": [
    {
      "id": "550e8400-e29b-41d4-a716-446655440001",
      "name": "Platinum Card",
      "issuer": "American Express",
      "artworkAsset": "card_amex_platinum",
      "annualFee": 695,
      "primaryColor": "#E5E4E2",
      "secondaryColor": "#A9A9A9",
      "isActive": true,
      "lastUpdated": "2026-01-15T00:00:00Z",
      "benefits": [
        {
          "id": "550e8400-e29b-41d4-a716-446655440101",
          "name": "Uber Credits",
          "description": "$15 monthly Uber credit for rides or Uber Eats",
          "value": 15,
          "frequency": "monthly",
          "category": "transportation",
          "merchant": "Uber",
          "resetDayOfMonth": 1
        },
        {
          "id": "550e8400-e29b-41d4-a716-446655440102",
          "name": "Airline Incidental Credit",
          "description": "Up to $200 per calendar year in incidental fees",
          "value": 200,
          "frequency": "annual",
          "category": "airline",
          "merchant": null,
          "resetDayOfMonth": null
        },
        {
          "id": "550e8400-e29b-41d4-a716-446655440103",
          "name": "Saks Fifth Avenue Credit",
          "description": "$50 semi-annual Saks credit",
          "value": 50,
          "frequency": "semiAnnual",
          "category": "shopping",
          "merchant": "Saks Fifth Avenue",
          "resetDayOfMonth": null
        },
        {
          "id": "550e8400-e29b-41d4-a716-446655440104",
          "name": "Digital Entertainment Credit",
          "description": "$20 monthly statement credit for select streaming",
          "value": 20,
          "frequency": "monthly",
          "category": "entertainment",
          "merchant": null,
          "resetDayOfMonth": 1
        },
        {
          "id": "550e8400-e29b-41d4-a716-446655440105",
          "name": "CLEAR Credit",
          "description": "Up to $189 annual statement credit for CLEAR membership",
          "value": 189,
          "frequency": "annual",
          "category": "travel",
          "merchant": "CLEAR",
          "resetDayOfMonth": null
        },
        {
          "id": "550e8400-e29b-41d4-a716-446655440106",
          "name": "Hotel Credit",
          "description": "$200 annual hotel credit when booking through Amex Travel",
          "value": 200,
          "frequency": "annual",
          "category": "hotel",
          "merchant": null,
          "resetDayOfMonth": null
        }
      ]
    },
    {
      "id": "550e8400-e29b-41d4-a716-446655440002",
      "name": "Gold Card",
      "issuer": "American Express",
      "artworkAsset": "card_amex_gold",
      "annualFee": 250,
      "primaryColor": "#CFB53B",
      "secondaryColor": "#8B7500",
      "isActive": true,
      "lastUpdated": "2026-01-15T00:00:00Z",
      "benefits": [
        {
          "id": "550e8400-e29b-41d4-a716-446655440201",
          "name": "Uber Cash",
          "description": "$10 monthly Uber Cash credit",
          "value": 10,
          "frequency": "monthly",
          "category": "transportation",
          "merchant": "Uber",
          "resetDayOfMonth": 1
        },
        {
          "id": "550e8400-e29b-41d4-a716-446655440202",
          "name": "Dining Credit",
          "description": "$10 monthly dining credit at participating partners",
          "value": 10,
          "frequency": "monthly",
          "category": "dining",
          "merchant": null,
          "resetDayOfMonth": 1
        }
      ]
    },
    {
      "id": "550e8400-e29b-41d4-a716-446655440003",
      "name": "Sapphire Reserve",
      "issuer": "Chase",
      "artworkAsset": "card_chase_sapphire_reserve",
      "annualFee": 550,
      "primaryColor": "#0f4c75",
      "secondaryColor": "#1a1a2e",
      "isActive": true,
      "lastUpdated": "2026-01-15T00:00:00Z",
      "benefits": [
        {
          "id": "550e8400-e29b-41d4-a716-446655440301",
          "name": "Travel Credit",
          "description": "$300 annual travel credit automatically applied",
          "value": 300,
          "frequency": "annual",
          "category": "travel",
          "merchant": null,
          "resetDayOfMonth": null
        },
        {
          "id": "550e8400-e29b-41d4-a716-446655440302",
          "name": "DoorDash DashPass",
          "description": "Complimentary DashPass membership ($9.99/mo value)",
          "value": 9.99,
          "frequency": "monthly",
          "category": "dining",
          "merchant": "DoorDash",
          "resetDayOfMonth": 1
        },
        {
          "id": "550e8400-e29b-41d4-a716-446655440303",
          "name": "Lyft Pink Credit",
          "description": "$5 monthly Lyft credit with Lyft Pink",
          "value": 5,
          "frequency": "monthly",
          "category": "transportation",
          "merchant": "Lyft",
          "resetDayOfMonth": 1
        }
      ]
    },
    {
      "id": "550e8400-e29b-41d4-a716-446655440004",
      "name": "Sapphire Preferred",
      "issuer": "Chase",
      "artworkAsset": "card_chase_sapphire_preferred",
      "annualFee": 95,
      "primaryColor": "#117ACA",
      "secondaryColor": "#0055AA",
      "isActive": true,
      "lastUpdated": "2026-01-15T00:00:00Z",
      "benefits": [
        {
          "id": "550e8400-e29b-41d4-a716-446655440401",
          "name": "Hotel Credit",
          "description": "$50 annual hotel credit when booking through Chase",
          "value": 50,
          "frequency": "annual",
          "category": "hotel",
          "merchant": null,
          "resetDayOfMonth": null
        }
      ]
    },
    {
      "id": "550e8400-e29b-41d4-a716-446655440005",
      "name": "Venture X",
      "issuer": "Capital One",
      "artworkAsset": "card_capital_one_venture_x",
      "annualFee": 395,
      "primaryColor": "#1a1a2e",
      "secondaryColor": "#4a4e69",
      "isActive": true,
      "lastUpdated": "2026-01-15T00:00:00Z",
      "benefits": [
        {
          "id": "550e8400-e29b-41d4-a716-446655440501",
          "name": "Travel Credit",
          "description": "$300 annual credit for bookings through Capital One Travel",
          "value": 300,
          "frequency": "annual",
          "category": "travel",
          "merchant": null,
          "resetDayOfMonth": null
        },
        {
          "id": "550e8400-e29b-41d4-a716-446655440502",
          "name": "Experience Credit",
          "description": "$100 credit for Capital One Entertainment purchases",
          "value": 100,
          "frequency": "annual",
          "category": "entertainment",
          "merchant": null,
          "resetDayOfMonth": null
        }
      ]
    },
    {
      "id": "550e8400-e29b-41d4-a716-446655440006",
      "name": "Hilton Honors Aspire",
      "issuer": "American Express",
      "artworkAsset": "card_amex_hilton_aspire",
      "annualFee": 450,
      "primaryColor": "#002C5F",
      "secondaryColor": "#00508C",
      "isActive": true,
      "lastUpdated": "2026-01-15T00:00:00Z",
      "benefits": [
        {
          "id": "550e8400-e29b-41d4-a716-446655440601",
          "name": "Airline Credit",
          "description": "Up to $250 per year in airline incidentals",
          "value": 250,
          "frequency": "annual",
          "category": "airline",
          "merchant": null,
          "resetDayOfMonth": null
        },
        {
          "id": "550e8400-e29b-41d4-a716-446655440602",
          "name": "Hilton Resort Credit",
          "description": "$250 semi-annual Hilton resort credit",
          "value": 250,
          "frequency": "semiAnnual",
          "category": "hotel",
          "merchant": "Hilton",
          "resetDayOfMonth": null
        },
        {
          "id": "550e8400-e29b-41d4-a716-446655440603",
          "name": "Free Night Award",
          "description": "Annual free night at Hilton properties",
          "value": 200,
          "frequency": "annual",
          "category": "hotel",
          "merchant": "Hilton",
          "resetDayOfMonth": null
        }
      ]
    },
    {
      "id": "550e8400-e29b-41d4-a716-446655440007",
      "name": "Marriott Bonvoy Brilliant",
      "issuer": "American Express",
      "artworkAsset": "card_amex_marriott_brilliant",
      "annualFee": 650,
      "primaryColor": "#8B0000",
      "secondaryColor": "#4B0000",
      "isActive": true,
      "lastUpdated": "2026-01-15T00:00:00Z",
      "benefits": [
        {
          "id": "550e8400-e29b-41d4-a716-446655440701",
          "name": "Dining Credit",
          "description": "$25 monthly dining credit at participating restaurants",
          "value": 25,
          "frequency": "monthly",
          "category": "dining",
          "merchant": null,
          "resetDayOfMonth": 1
        },
        {
          "id": "550e8400-e29b-41d4-a716-446655440702",
          "name": "Free Night Award",
          "description": "Annual 85,000 point free night award",
          "value": 250,
          "frequency": "annual",
          "category": "hotel",
          "merchant": "Marriott",
          "resetDayOfMonth": null
        }
      ]
    },
    {
      "id": "550e8400-e29b-41d4-a716-446655440008",
      "name": "Delta SkyMiles Reserve",
      "issuer": "American Express",
      "artworkAsset": "card_amex_delta_reserve",
      "annualFee": 650,
      "primaryColor": "#003366",
      "secondaryColor": "#C8102E",
      "isActive": true,
      "lastUpdated": "2026-01-15T00:00:00Z",
      "benefits": [
        {
          "id": "550e8400-e29b-41d4-a716-446655440801",
          "name": "Resy Credit",
          "description": "$10 monthly credit for Resy restaurant reservations",
          "value": 10,
          "frequency": "monthly",
          "category": "dining",
          "merchant": "Resy",
          "resetDayOfMonth": 1
        }
      ]
    },
    {
      "id": "550e8400-e29b-41d4-a716-446655440009",
      "name": "Citi Prestige",
      "issuer": "Citi",
      "artworkAsset": "card_citi_prestige",
      "annualFee": 495,
      "primaryColor": "#003B70",
      "secondaryColor": "#1E5090",
      "isActive": true,
      "lastUpdated": "2026-01-15T00:00:00Z",
      "benefits": [
        {
          "id": "550e8400-e29b-41d4-a716-446655440901",
          "name": "Travel Credit",
          "description": "$250 annual travel credit",
          "value": 250,
          "frequency": "annual",
          "category": "travel",
          "merchant": null,
          "resetDayOfMonth": null
        }
      ]
    },
    {
      "id": "550e8400-e29b-41d4-a716-446655440010",
      "name": "Altitude Reserve",
      "issuer": "US Bank",
      "artworkAsset": "card_usbank_altitude_reserve",
      "annualFee": 400,
      "primaryColor": "#D71920",
      "secondaryColor": "#003DA5",
      "isActive": true,
      "lastUpdated": "2026-01-15T00:00:00Z",
      "benefits": [
        {
          "id": "550e8400-e29b-41d4-a716-446655441001",
          "name": "Travel Credit",
          "description": "$325 annual travel and dining credit",
          "value": 325,
          "frequency": "annual",
          "category": "travel",
          "merchant": null,
          "resetDayOfMonth": null
        }
      ]
    }
  ]
}
```

---

## Query Patterns

### Common Queries

```swift
// Sources/Services/Storage/Repositories/BenefitRepository.swift

import SwiftData
import Foundation

@MainActor
class BenefitRepository {
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    // MARK: - Available Benefits Queries

    /// Fetch all available benefits sorted by expiration
    func fetchAvailableBenefits() throws -> [Benefit] {
        let descriptor = FetchDescriptor<Benefit>(
            predicate: #Predicate { $0.status == .available },
            sortBy: [SortDescriptor(\.currentPeriodEnd, order: .forward)]
        )
        return try modelContext.fetch(descriptor)
    }

    /// Fetch benefits expiring within specified days
    func fetchExpiringBenefits(withinDays days: Int) throws -> [Benefit] {
        let threshold = Calendar.current.date(
            byAdding: .day,
            value: days,
            to: Date()
        )!

        let descriptor = FetchDescriptor<Benefit>(
            predicate: #Predicate { benefit in
                benefit.status == .available &&
                benefit.currentPeriodEnd <= threshold
            },
            sortBy: [SortDescriptor(\.currentPeriodEnd, order: .forward)]
        )
        return try modelContext.fetch(descriptor)
    }

    /// Fetch benefits that need period reset
    func fetchBenefitsNeedingReset() throws -> [Benefit] {
        let now = Date()
        let descriptor = FetchDescriptor<Benefit>(
            predicate: #Predicate { $0.nextResetDate <= now }
        )
        return try modelContext.fetch(descriptor)
    }

    // MARK: - Aggregation Queries

    /// Calculate total available value across all benefits
    func totalAvailableValue() throws -> Decimal {
        let benefits = try fetchAvailableBenefits()
        return benefits.reduce(Decimal.zero) { $0 + $1.effectiveValue }
    }

    /// Count of benefits by status
    func benefitCountsByStatus() throws -> [BenefitStatus: Int] {
        var counts: [BenefitStatus: Int] = [:]

        for status in BenefitStatus.allCases {
            let descriptor = FetchDescriptor<Benefit>(
                predicate: #Predicate { $0.status == status }
            )
            counts[status] = try modelContext.fetchCount(descriptor)
        }

        return counts
    }

    // MARK: - Card-Specific Queries

    /// Fetch benefits for a specific card
    func fetchBenefits(for cardId: UUID) throws -> [Benefit] {
        let descriptor = FetchDescriptor<Benefit>(
            predicate: #Predicate { $0.userCard?.id == cardId },
            sortBy: [
                SortDescriptor(\.status.rawValue),
                SortDescriptor(\.currentPeriodEnd, order: .forward)
            ]
        )
        return try modelContext.fetch(descriptor)
    }

    // MARK: - Notification Queries

    /// Fetch benefits needing notification scheduling
    func fetchBenefitsForNotificationScheduling(
        maxCount: Int = 50,
        withinDays: Int = 45
    ) throws -> [Benefit] {
        let threshold = Calendar.current.date(
            byAdding: .day,
            value: withinDays,
            to: Date()
        )!

        let descriptor = FetchDescriptor<Benefit>(
            predicate: #Predicate { benefit in
                benefit.status == .available &&
                benefit.reminderEnabled &&
                benefit.currentPeriodEnd <= threshold
            },
            sortBy: [SortDescriptor(\.currentPeriodEnd, order: .forward)]
        )
        descriptor.fetchLimit = maxCount

        return try modelContext.fetch(descriptor)
    }
}
```

### Usage History Queries

```swift
// Sources/Services/Storage/Repositories/UsageRepository.swift

@MainActor
class UsageRepository {
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    /// Fetch usage history for a benefit
    func fetchHistory(for benefitId: UUID) throws -> [BenefitUsage] {
        let descriptor = FetchDescriptor<BenefitUsage>(
            predicate: #Predicate { $0.benefit?.id == benefitId },
            sortBy: [SortDescriptor(\.usedDate, order: .reverse)]
        )
        return try modelContext.fetch(descriptor)
    }

    /// Fetch recent usage across all benefits
    func fetchRecentUsage(limit: Int = 10) throws -> [BenefitUsage] {
        var descriptor = FetchDescriptor<BenefitUsage>(
            predicate: #Predicate { !$0.wasAutoExpired },
            sortBy: [SortDescriptor(\.usedDate, order: .reverse)]
        )
        descriptor.fetchLimit = limit
        return try modelContext.fetch(descriptor)
    }

    /// Calculate total value redeemed in date range
    func totalValueRedeemed(from startDate: Date, to endDate: Date) throws -> Decimal {
        let descriptor = FetchDescriptor<BenefitUsage>(
            predicate: #Predicate { usage in
                !usage.wasAutoExpired &&
                usage.usedDate >= startDate &&
                usage.usedDate <= endDate
            }
        )
        let usages = try modelContext.fetch(descriptor)
        return usages.reduce(Decimal.zero) { $0 + $1.valueRedeemed }
    }

    /// Prune old history (cleanup)
    func pruneHistory(olderThan date: Date) throws {
        let descriptor = FetchDescriptor<BenefitUsage>(
            predicate: #Predicate { $0.usedDate < date }
        )
        let oldRecords = try modelContext.fetch(descriptor)
        for record in oldRecords {
            modelContext.delete(record)
        }
        try modelContext.save()
    }
}
```

---

## Document History

| Version | Date | Author | Changes |
|---------|------|--------|---------|
| 1.0 | 2026-01-16 | Software Architect | Initial data model specification |

---

## Approval Sign-off

| Role | Name | Date | Signature |
|------|------|------|-----------|
| Software Architect | | 2026-01-16 | Approved |
| Engineering Lead | | | Pending |
| Product Manager | | | Pending |
