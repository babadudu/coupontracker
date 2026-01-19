# CouponTracker Technical Specification

**Version:** 1.0
**Last Updated:** January 16, 2026
**Status:** Draft - For Architect Review
**Author:** Product Team

---

## Purpose

This document provides technical specifications and requirements for the CouponTracker iOS application. It is intended to facilitate coordination with the software-architect to validate feasibility, refine the data model, and ensure the architecture supports both MVP needs and future extensibility.

---

## Table of Contents

1. [Technical Overview](#technical-overview)
2. [Data Model Design](#data-model-design)
3. [Notification Architecture](#notification-architecture)
4. [Storage Strategy](#storage-strategy)
5. [Card Database Management](#card-database-management)
6. [Future API Integration Considerations](#future-api-integration-considerations)
7. [Technical Risks and Questions](#technical-risks-and-questions)

---

## Technical Overview

### Platform Requirements

| Requirement | Value | Rationale |
|-------------|-------|-----------|
| Minimum iOS Version | 17.0 | SwiftData, modern SwiftUI features |
| Swift Version | 5.9+ | Modern concurrency, macros |
| Device Support | iPhone only (MVP) | Focus development effort |
| Orientation | Portrait only (MVP) | Wallet UI optimized for portrait |

### Proposed Technology Stack

| Layer | Technology | Notes |
|-------|------------|-------|
| UI Framework | SwiftUI | Modern, declarative UI |
| Data Persistence | SwiftData | Apple's new persistence framework |
| Local Notifications | UserNotifications | iOS native framework |
| Networking (Future) | URLSession + async/await | For API integration |
| Dependency Injection | Swift Property Wrappers | @Environment, custom DI |
| Testing | XCTest, Swift Testing | Unit and UI tests |

### Architecture Pattern

**Recommended:** MVVM with Clean Architecture principles

```
Presentation Layer (Views)
        |
        v
ViewModel Layer (ObservableObject)
        |
        v
Domain Layer (Use Cases / Interactors)
        |
        v
Data Layer (Repositories)
        |
        v
Infrastructure (SwiftData, UserNotifications)
```

**Rationale:**
- MVVM works naturally with SwiftUI's data binding
- Clean Architecture provides testability and separation
- Repository pattern enables swapping local for remote data sources

---

## Data Model Design

### Entity Relationship Diagram

```
+------------------+       +-------------------+       +------------------+
|   UserCard       |       |     Benefit       |       |   BenefitUsage   |
+------------------+       +-------------------+       +------------------+
| id: UUID (PK)    |       | id: UUID (PK)     |       | id: UUID (PK)    |
| cardTemplateId   |<------| userCardId (FK)   |<------| benefitId (FK)   |
| nickname: String?|  1:N  | templateBenefitId |  1:N  | usedDate: Date   |
| addedDate: Date  |       | customName: String?|      | periodStart: Date|
| isCustom: Bool   |       | customValue: Decimal?|   | periodEnd: Date  |
| customColor: Str?|       | status: Status    |       +------------------+
+------------------+       | currentDueDate    |
                          | reminderEnabled   |
                          +-------------------+
                                   |
                                   | References (optional)
                                   v
+------------------+       +-------------------+
| CardTemplate     |       | BenefitTemplate   |
+------------------+       +-------------------+
| id: UUID (PK)    |       | id: UUID (PK)     |
| name: String     |<------| cardTemplateId(FK)|
| issuer: String   |  1:N  | name: String      |
| artworkAsset     |       | description       |
| annualFee: Dec?  |       | value: Decimal    |
| lastUpdated      |       | frequency: Freq   |
| isActive: Bool   |       | category: Cat     |
+------------------+       | resetDayOfMonth   |
                          +-------------------+
```

### Core Entities

#### UserCard

Represents a card in the user's wallet.

```swift
@Model
final class UserCard {
    @Attribute(.unique) var id: UUID
    var cardTemplateId: UUID?  // nil for custom cards
    var nickname: String?
    var addedDate: Date
    var isCustom: Bool
    var customName: String?
    var customIssuer: String?
    var customColorHex: String?
    var sortOrder: Int

    @Relationship(deleteRule: .cascade, inverse: \Benefit.userCard)
    var benefits: [Benefit]

    // Computed
    var displayName: String {
        nickname ?? customName ?? cardTemplate?.name ?? "Unknown Card"
    }
}
```

#### Benefit

Represents an individual benefit/reward being tracked.

```swift
@Model
final class Benefit {
    @Attribute(.unique) var id: UUID
    var userCard: UserCard?
    var templateBenefitId: UUID?  // nil for custom benefits

    // Override values for customization
    var customName: String?
    var customValue: Decimal?
    var customDescription: String?

    // Tracking state
    var status: BenefitStatus
    var currentPeriodStart: Date
    var currentPeriodEnd: Date
    var reminderEnabled: Bool
    var reminderDaysBefore: Int
    var lastReminderDate: Date?

    @Relationship(deleteRule: .cascade, inverse: \BenefitUsage.benefit)
    var usageHistory: [BenefitUsage]

    // Computed
    var effectiveName: String {
        customName ?? templateBenefit?.name ?? "Unknown Benefit"
    }

    var effectiveValue: Decimal {
        customValue ?? templateBenefit?.value ?? 0
    }

    var daysUntilExpiration: Int {
        Calendar.current.dateComponents([.day], from: Date(), to: currentPeriodEnd).day ?? 0
    }
}

enum BenefitStatus: String, Codable {
    case available
    case used
    case expired
    case partiallyUsed  // For future: benefits with multiple uses per period
}
```

#### BenefitUsage

Historical record of benefit redemptions.

```swift
@Model
final class BenefitUsage {
    @Attribute(.unique) var id: UUID
    var benefit: Benefit?
    var usedDate: Date
    var periodStart: Date
    var periodEnd: Date
    var valueRedeemed: Decimal
    var notes: String?
}
```

#### CardTemplate (Read-only, bundled)

Pre-populated card definitions.

```swift
struct CardTemplate: Codable, Identifiable {
    let id: UUID
    let name: String
    let issuer: String
    let artworkAssetName: String
    let annualFee: Decimal?
    let benefits: [BenefitTemplate]
    let lastUpdated: Date
    let isActive: Bool

    // Issuer branding
    let primaryColorHex: String
    let secondaryColorHex: String
}

struct BenefitTemplate: Codable, Identifiable {
    let id: UUID
    let name: String
    let description: String
    let value: Decimal
    let frequency: BenefitFrequency
    let category: BenefitCategory
    let resetDayOfMonth: Int?  // nil = calendar start
    let merchant: String?  // e.g., "Uber", "Saks"
}

enum BenefitFrequency: String, Codable {
    case monthly
    case quarterly
    case semiAnnual
    case annual
}

enum BenefitCategory: String, Codable {
    case travel
    case dining
    case entertainment
    case shopping
    case transportation
    case wellness
    case other
}
```

### Data Model Questions for Architect

1. **SwiftData vs Core Data:** Should we use SwiftData given iOS 17 minimum, or is Core Data more mature/reliable for production?

2. **Template Versioning:** How should we handle updates to the card template database? Consider:
   - App updates with new templates
   - Users who have already added cards from old templates
   - Merging strategy for template changes

3. **Benefit Period Calculation:** The period calculation logic (when does a quarterly benefit reset?) is complex. Should this be:
   - Calculated on-demand (simpler but CPU cost)
   - Pre-computed and stored (complexity but performance)
   - Background job that updates periodically

4. **Cascade Deletes:** Current design cascades benefit deletion when card is removed. Should we preserve usage history independently?

---

## Notification Architecture

### Notification Requirements Summary

| Requirement | Description |
|-------------|-------------|
| Pre-expiration reminder | Notify X days before benefit expires |
| Follow-up reminders | If not acknowledged, re-notify daily or weekly |
| Quick actions | Mark as done / Snooze from notification |
| Reset notifications | Notify when benefits become available again |

### iOS Notification Framework Usage

**Framework:** `UserNotifications` (UNUserNotificationCenter)

**Notification Types:**
1. **Time-based alerts** - Scheduled for specific date/time
2. **Actionable notifications** - Include quick action buttons
3. **Rich notifications** - Include card artwork image

### Notification Scheduling Strategy

```swift
// Notification Category Definition
let benefitCategory = UNNotificationCategory(
    identifier: "BENEFIT_REMINDER",
    actions: [
        UNNotificationAction(identifier: "DONE", title: "Mark as Done"),
        UNNotificationAction(identifier: "SNOOZE_DAY", title: "Snooze 1 Day"),
        UNNotificationAction(identifier: "SNOOZE_WEEK", title: "Snooze 1 Week")
    ],
    intentIdentifiers: [],
    options: [.customDismissAction]
)
```

**Scheduling Approach:**

```swift
class NotificationScheduler {

    func scheduleExpirationReminder(for benefit: Benefit) async throws {
        let content = UNMutableNotificationContent()
        content.title = "Reward Expiring Soon"
        content.subtitle = benefit.userCard?.displayName ?? ""
        content.body = "Your \(benefit.effectiveName) (\(benefit.formattedValue)) expires in \(benefit.daysUntilExpiration) days"
        content.categoryIdentifier = "BENEFIT_REMINDER"
        content.userInfo = [
            "benefitId": benefit.id.uuidString,
            "type": "expiration"
        ]
        content.sound = .default

        // Attach card artwork if available
        if let attachment = try? await createAttachment(for: benefit) {
            content.attachments = [attachment]
        }

        // Calculate trigger date
        let reminderDate = Calendar.current.date(
            byAdding: .day,
            value: -benefit.reminderDaysBefore,
            to: benefit.currentPeriodEnd
        )!

        // Set preferred time (from user preferences)
        let triggerDate = setPreferredTime(reminderDate)
        let trigger = UNCalendarNotificationTrigger(
            dateMatching: Calendar.current.dateComponents(
                [.year, .month, .day, .hour, .minute],
                from: triggerDate
            ),
            repeats: false
        )

        let request = UNNotificationRequest(
            identifier: "benefit-\(benefit.id.uuidString)-reminder",
            content: content,
            trigger: trigger
        )

        try await UNUserNotificationCenter.current().add(request)
    }

    func handleNotificationAction(
        _ action: String,
        benefitId: UUID
    ) async throws {
        switch action {
        case "DONE":
            try await markBenefitAsUsed(benefitId)
        case "SNOOZE_DAY":
            try await rescheduleReminder(benefitId, addDays: 1)
        case "SNOOZE_WEEK":
            try await rescheduleReminder(benefitId, addDays: 7)
        default:
            break
        }
    }
}
```

### Follow-up Reminder Logic

**Challenge:** iOS does not support truly repeating notifications with custom logic. We need a strategy for follow-up reminders.

**Proposed Solution:**

1. **Initial Reminder:** Scheduled for X days before expiration
2. **On Snooze:** Cancel current, schedule new for snooze date
3. **On Ignore:** App uses background refresh to detect unacknowledged reminders and schedule follow-ups
4. **Background Refresh:** Use `BGAppRefreshTask` to check for benefits needing follow-up

```swift
// Background task registration
BGTaskScheduler.shared.register(
    forTaskWithIdentifier: "com.coupontracker.refresh",
    using: nil
) { task in
    self.handleAppRefresh(task: task as! BGAppRefreshTask)
}

func handleAppRefresh(task: BGAppRefreshTask) {
    // 1. Check for benefits expiring soon without reminders
    // 2. Check for ignored reminders needing follow-up
    // 3. Update benefit statuses (mark expired)
    // 4. Schedule new notifications as needed

    scheduleNextRefresh()
    task.setTaskCompleted(success: true)
}
```

### Notification Considerations for Architect

1. **Background Refresh Reliability:** BGAppRefreshTask is not guaranteed to run. How critical is the follow-up reminder feature? Should we:
   - Accept best-effort for MVP
   - Investigate alternative approaches (server-side push in future)
   - Use more aggressive local scheduling

2. **Notification Limits:** iOS limits pending notifications to 64 per app. With users having many benefits, we need a prioritization strategy:
   - Only schedule for benefits expiring within 30 days
   - Prioritize by value or urgency
   - Reschedule dynamically as dates approach

3. **Notification Grouping:** Should we group notifications by card or show individual benefit notifications? Trade-off between detail and notification fatigue.

4. **Action Handling:** When user taps "Mark as Done" from notification, the app may not be running. Need robust handling:
   - Use `userNotificationCenter(_:didReceive:)` delegate
   - Ensure data updates persist even if app not fully launched

---

## Storage Strategy

### Local Storage (MVP)

**Primary Storage:** SwiftData (or Core Data)
- User cards, benefits, usage history
- User preferences and settings
- Notification state

**Bundled Assets:**
- Card template database (JSON)
- Card artwork images

**UserDefaults:**
- Onboarding completion flag
- Last sync date (future)
- Simple app preferences

### Data Size Estimates

| Data Type | Estimated Size | Notes |
|-----------|---------------|-------|
| Card templates (JSON) | ~50 KB | 20 cards with benefits |
| Card artwork (all) | ~5 MB | 20 cards @ ~250KB each |
| User data (typical) | ~10 KB | 5 cards, 20 benefits |
| Usage history (1 year) | ~50 KB | ~200 entries |

**Total App Size Impact:** ~10-15 MB (acceptable)

### Migration Strategy

**Schema Versioning:**
- Use SwiftData's built-in migration support
- Plan for additive changes (new fields with defaults)
- Avoid destructive changes in minor versions

**Template Database Updates:**
- Templates bundled with each app version
- On app update, merge new templates:
  - Add new cards/benefits
  - Update existing template data
  - Preserve user customizations
  - Flag deprecated cards

---

## Card Database Management

### Template Database Format

```json
{
  "version": "1.0.0",
  "lastUpdated": "2026-01-15T00:00:00Z",
  "cards": [
    {
      "id": "uuid-here",
      "name": "Platinum Card",
      "issuer": "American Express",
      "artworkAsset": "amex_platinum",
      "annualFee": 695,
      "primaryColor": "#006FCF",
      "secondaryColor": "#FFFFFF",
      "benefits": [
        {
          "id": "uuid-here",
          "name": "Uber Credits",
          "description": "$15 monthly Uber credit for rides or Uber Eats",
          "value": 15,
          "frequency": "monthly",
          "category": "transportation",
          "merchant": "Uber",
          "resetDayOfMonth": 1
        }
      ]
    }
  ]
}
```

### Template Loading

```swift
class CardTemplateRepository {

    private var templates: [CardTemplate] = []

    func loadTemplates() throws {
        guard let url = Bundle.main.url(
            forResource: "CardTemplates",
            withExtension: "json"
        ) else {
            throw TemplateError.notFound
        }

        let data = try Data(contentsOf: url)
        let database = try JSONDecoder().decode(CardDatabase.self, from: data)
        self.templates = database.cards.filter { $0.isActive }
    }

    func getCard(by id: UUID) -> CardTemplate? {
        templates.first { $0.id == id }
    }

    func searchCards(query: String) -> [CardTemplate] {
        guard !query.isEmpty else { return templates }
        let lowercased = query.lowercased()
        return templates.filter {
            $0.name.lowercased().contains(lowercased) ||
            $0.issuer.lowercased().contains(lowercased)
        }
    }

    func cardsByIssuer() -> [String: [CardTemplate]] {
        Dictionary(grouping: templates, by: { $0.issuer })
    }
}
```

### Questions for Architect

1. **Remote Template Updates:** Should we support downloading template updates without app update?
   - Pro: Faster updates to benefit info
   - Con: Complexity, versioning, storage
   - Recommendation: Not for MVP, design for future

2. **Search Performance:** With 20+ cards and many benefits, is linear search acceptable or should we use a search index?

3. **Image Loading:** Should card artwork be lazy-loaded from Assets catalog or pre-loaded? Memory considerations for wallet view with many cards.

---

## Future API Integration Considerations

### Planned Integration Points

1. **Credit Card Provider APIs** (e.g., Amex, Chase)
   - OAuth authentication
   - Read benefit status
   - Real-time balance/credit info

2. **Plaid or Similar**
   - Aggregate access to multiple accounts
   - Benefit detection from transactions

3. **Custom Backend**
   - User accounts and cloud sync
   - Push notifications (server-side)
   - Template database updates

### Architecture Preparation

**Service Abstraction:**

```swift
protocol BenefitDataSource {
    func getBenefits(for cardId: UUID) async throws -> [Benefit]
    func markAsUsed(benefitId: UUID) async throws
    func getUsageHistory(for benefitId: UUID) async throws -> [BenefitUsage]
}

// MVP: Local implementation
class LocalBenefitDataSource: BenefitDataSource {
    private let modelContext: ModelContext
    // SwiftData operations
}

// Future: Remote implementation
class RemoteBenefitDataSource: BenefitDataSource {
    private let apiClient: APIClient
    // Network operations with local cache
}

// Coordinator that handles sync
class SyncingBenefitDataSource: BenefitDataSource {
    private let local: LocalBenefitDataSource
    private let remote: RemoteBenefitDataSource
    // Sync logic
}
```

**Data Sync Strategy (Future):**
- Optimistic updates with local-first approach
- Conflict resolution: Last write wins with timestamp
- Background sync on app launch and periodically
- Manual sync trigger available

---

## Technical Risks and Questions

### Open Questions for Architect

| # | Question | Context | Priority |
|---|----------|---------|----------|
| 1 | SwiftData maturity | Is SwiftData production-ready, or should we use Core Data? | High |
| 2 | Benefit period calculation | Should reset dates be computed or stored? Edge cases? | High |
| 3 | Background refresh reliability | Can we rely on BGAppRefreshTask for follow-up notifications? | Medium |
| 4 | Notification limits | Strategy for 64-notification iOS limit with many benefits? | Medium |
| 5 | Template versioning | How to handle template updates without data loss? | Medium |
| 6 | Test data strategy | How to seed test data for development and testing? | Low |
| 7 | Analytics integration | What analytics should we capture? Privacy considerations? | Low |

### Identified Technical Risks

| Risk | Impact | Likelihood | Mitigation |
|------|--------|------------|------------|
| SwiftData bugs/limitations | High | Medium | Have Core Data fallback plan |
| Background refresh unreliable | Medium | High | Accept best-effort for MVP |
| Notification action edge cases | Medium | Medium | Thorough testing, graceful fallbacks |
| Card artwork licensing | Low | Low | Use generic gradients as fallback |
| App size with all artwork | Low | Low | Optimize images, lazy loading |

### Performance Targets

| Metric | Target | Measurement |
|--------|--------|-------------|
| App launch (cold) | < 1 second | Time to first meaningful paint |
| Card database search | < 100ms | Time to display search results |
| Mark as done action | < 500ms | User action to UI update |
| Wallet scroll | 60 fps | No frame drops with 10 cards |
| Memory footprint | < 100 MB | Typical usage with 5 cards |

---

## Appendix

### A1: Sequence Diagrams

**Mark Benefit as Used (from notification):**

```
User              Notification         NotificationDelegate      BenefitService       SwiftData
 |                     |                      |                       |                  |
 |---(long press)----->|                      |                       |                  |
 |                     |---(action: DONE)---->|                       |                  |
 |                     |                      |---markAsUsed(id)----->|                  |
 |                     |                      |                       |---update-------->|
 |                     |                      |                       |<--success--------|
 |                     |                      |<------success---------|                  |
 |                     |----(dismiss)-------->|                       |                  |
 |<----(banner)--------|                      |                       |                  |
```

**Benefit Auto-Reset (background):**

```
BGScheduler          RefreshTask          BenefitService          SwiftData        NotificationScheduler
    |                     |                     |                     |                     |
    |----(trigger)------->|                     |                     |                     |
    |                     |---getExpiredBenefits-->|                  |                     |
    |                     |                     |---query------------>|                     |
    |                     |                     |<--[benefits]--------|                     |
    |                     |<--[benefits]--------|                     |                     |
    |                     |                     |                     |                     |
    |                     |--(for each benefit)-|                     |                     |
    |                     |---resetBenefit----->|                     |                     |
    |                     |                     |---update----------->|                     |
    |                     |                     |<--success-----------|                     |
    |                     |---scheduleResetNotification-------------->|                     |
    |                     |                     |                     |<--schedule----------|
    |                     |<--complete----------|                     |                     |
    |<----(complete)------|                     |                     |                     |
```

### A2: Dependencies

**Required Frameworks:**
- SwiftUI
- SwiftData (or CoreData)
- UserNotifications
- BackgroundTasks

**Potential Third-Party:**
- None for MVP (minimize dependencies)

**Future Considerations:**
- KeychainAccess (for secure token storage)
- Plaid SDK (for bank integration)

---

## Document History

| Version | Date | Author | Changes |
|---------|------|--------|---------|
| 1.0 | 2026-01-16 | Product Team | Initial technical specification |

---

## Review Sign-off

| Role | Name | Date | Status |
|------|------|------|--------|
| Software Architect | | | Pending Review |
| Engineering Lead | | | Pending Review |
| Product Manager | | | Approved |
