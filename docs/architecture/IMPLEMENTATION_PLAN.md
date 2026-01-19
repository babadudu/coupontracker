# CouponTracker Implementation Plan

**Version:** 1.0
**Last Updated:** January 16, 2026
**Status:** Approved
**Author:** Software Architect

---

## Table of Contents

1. [Architecture Decisions Summary](#architecture-decisions-summary)
2. [Technical Stack Confirmation](#technical-stack-confirmation)
3. [Project Structure](#project-structure)
4. [Phase 1 MVP Implementation](#phase-1-mvp-implementation)
5. [Integration Points](#integration-points)
6. [Testing Strategy](#testing-strategy)
7. [Risk Mitigation](#risk-mitigation)
8. [Gaps and Concerns](#gaps-and-concerns)
9. [Appendix](#appendix)

---

## Architecture Decisions Summary

### Decision 1: SwiftData vs Core Data

**Decision:** Use SwiftData with Core Data fallback strategy.

**Rationale:**
- SwiftData is production-ready for iOS 17+ as of January 2026
- Native integration with SwiftUI via `@Model` macro and `@Query` property wrapper
- Simpler API reduces boilerplate and development time
- Built on Core Data foundation provides stability
- Automatic CloudKit sync capability for future phases

**Fallback Strategy:**
- Abstract data layer behind `Repository` protocols
- If critical SwiftData bugs are encountered, swap implementation to Core Data
- Estimated fallback effort: 2-3 days (models and repositories only)

**Risk Level:** Low-Medium (SwiftData has matured significantly since iOS 17 launch)

---

### Decision 2: Benefit Period Calculation Strategy

**Decision:** Hybrid approach - Store next reset date, compute on-demand for display.

**Implementation:**
```
Benefit Entity stores:
- currentPeriodStart: Date
- currentPeriodEnd: Date (this is the expiration date for display)
- nextResetDate: Date (when to transition to new period)

On app launch / background refresh:
1. Query benefits where nextResetDate <= now
2. For each expired period:
   - Create BenefitUsage record if status was "available" (mark as expired)
   - Calculate new period dates based on frequency
   - Update benefit with new period
   - Reset status to "available"
   - Schedule new notifications
```

**Period Calculation Rules:**
| Frequency | Period Start | Period End | Reset Logic |
|-----------|--------------|------------|-------------|
| Monthly | 1st of month | Last day of month | Calendar month boundaries |
| Quarterly | Q start (Jan/Apr/Jul/Oct 1) | Q end (Mar/Jun/Sep/Dec last) | Calendar quarter boundaries |
| Semi-Annual | Jan 1 or Jul 1 | Jun 30 or Dec 31 | 6-month periods |
| Annual | Jan 1 (default) or card anniversary | Dec 31 or anniversary-1 | User-configurable |

**Edge Cases Handled:**
- User adds card mid-period: Prorate by calculating remaining time in current period
- Leap years: Use Calendar API for accurate date math
- Time zones: All dates stored in UTC, displayed in local time

---

### Decision 3: Background Refresh Strategy

**Decision:** Best-effort background refresh with robust foreground fallback.

**Implementation:**
1. **BGAppRefreshTask** for periodic maintenance (every 4-6 hours when possible)
2. **Foreground sync** on every app launch
3. **Notification-triggered refresh** when user interacts with notification

**Background Task Scope:**
```swift
func handleBackgroundRefresh() async {
    // 1. Check and reset expired benefit periods
    await benefitResetService.processExpiredPeriods()

    // 2. Reschedule notifications for upcoming expirations
    await notificationService.scheduleUpcomingReminders()

    // 3. Clean up old usage history (> 2 years)
    await storageService.pruneOldHistory()
}
```

**Reliability Mitigation:**
- Foreground launch always performs sync (user will see correct state)
- Benefit reset logic is idempotent (safe to run multiple times)
- Notification scheduling is conservative (schedule further ahead)

---

### Decision 4: Notification Limit Handling (64 Notification Limit)

**Decision:** Priority-based scheduling with dynamic rebalancing.

**Strategy:**
1. **Priority Scoring:**
   ```
   Priority = (value / 100) + (14 - daysUntilExpiration) * 2

   Examples:
   - $100 benefit, 7 days out: 1 + 14 = 15
   - $15 benefit, 3 days out: 0.15 + 22 = 22.15 (higher priority due to urgency)
   ```

2. **Scheduling Rules:**
   - Maximum 50 notifications scheduled (leave 14 buffer for snoozes/resets)
   - Only schedule for benefits expiring within 45 days
   - One notification per benefit (no follow-up chains in schedule)
   - Re-evaluate and reschedule on each app launch

3. **Notification Grouping:**
   - Group by card when 3+ benefits expire on same day
   - Individual notifications otherwise for clarity

**Implementation:**
```swift
func scheduleNotifications() async {
    let benefits = await getUpcomingBenefits(withinDays: 45)
    let prioritized = benefits.sorted { $0.priority > $1.priority }
    let toSchedule = Array(prioritized.prefix(50))

    await cancelAllPendingNotifications()
    for benefit in toSchedule {
        await scheduleReminder(for: benefit)
    }
}
```

---

### Decision 5: Card Artwork Storage Approach

**Decision:** Bundled assets for known cards, generated gradients for custom.

**Implementation:**
1. **Bundled Cards (20 initial):**
   - High-res PNG images in Assets.xcassets
   - Naming convention: `card_{issuer}_{cardname}` (e.g., `card_amex_platinum`)
   - Dimensions: 686x432 @2x, 1029x648 @3x
   - Estimated bundle impact: ~5MB

2. **Custom Cards:**
   - 8 predefined gradient presets (see UI spec)
   - User selects gradient during card creation
   - Gradient rendered via SwiftUI at runtime

3. **Future Enhancement (Post-MVP):**
   - On-demand download of additional card artwork
   - User photo capture for custom card images

**Lazy Loading:**
- Card artwork loaded on-demand as cards scroll into view
- Use SwiftUI `AsyncImage` pattern for smooth loading
- Memory-efficient: UIImages released when cards scroll off-screen

---

### Decision 6: Template Versioning Strategy

**Decision:** Bundled templates with version-aware merging.

**Template Database Structure:**
```json
{
  "schemaVersion": 1,
  "dataVersion": "2026.01.15",
  "cards": [...]
}
```

**Merge Rules on App Update:**
1. **New Cards:** Add to template catalog
2. **Updated Benefits:** Update template, but preserve user's existing benefit customizations
3. **Removed Cards:** Mark as `isActive: false`, don't delete user data
4. **User Customizations:** Always preserved (customName, customValue override template)

**No Remote Updates for MVP:** Templates only update via App Store releases.

---

## Technical Stack Confirmation

### Confirmed Stack

| Layer | Technology | Version |
|-------|------------|---------|
| **Platform** | iOS | 17.0+ |
| **Language** | Swift | 5.9+ |
| **UI Framework** | SwiftUI | iOS 17 |
| **Persistence** | SwiftData | iOS 17 |
| **Notifications** | UserNotifications | Standard |
| **Background Tasks** | BackgroundTasks | Standard |
| **Testing** | XCTest + Swift Testing | Latest |

### Architecture Pattern

**MVVM with Repository Pattern**

```
┌─────────────────────────────────────────────────────────────┐
│                    Presentation Layer                        │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────────────┐  │
│  │   Views     │  │ ViewModels  │  │  Navigation         │  │
│  │  (SwiftUI)  │◄─┤ (Observable)│  │  (NavigationStack)  │  │
│  └─────────────┘  └──────┬──────┘  └─────────────────────┘  │
└──────────────────────────┼──────────────────────────────────┘
                           │
┌──────────────────────────▼──────────────────────────────────┐
│                     Domain Layer                             │
│  ┌─────────────────┐  ┌─────────────────────────────────┐   │
│  │   Use Cases     │  │         Domain Models           │   │
│  │  (Interactors)  │  │  (Card, Benefit, BenefitUsage)  │   │
│  └────────┬────────┘  └─────────────────────────────────┘   │
└───────────┼─────────────────────────────────────────────────┘
            │
┌───────────▼─────────────────────────────────────────────────┐
│                      Data Layer                              │
│  ┌──────────────────┐  ┌──────────────────────────────────┐ │
│  │   Repositories   │  │       Data Sources               │ │
│  │  (Protocols)     │◄─┤  Local: SwiftData                │ │
│  └──────────────────┘  │  Templates: JSON Bundle          │ │
│                        │  Future: Remote API              │ │
│                        └──────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────┘
                           │
┌──────────────────────────▼──────────────────────────────────┐
│                  Infrastructure Layer                        │
│  ┌────────────────┐  ┌────────────────┐  ┌───────────────┐  │
│  │  SwiftData     │  │  Notification  │  │  Background   │  │
│  │  ModelContext  │  │  Center        │  │  Task Sched.  │  │
│  └────────────────┘  └────────────────┘  └───────────────┘  │
└─────────────────────────────────────────────────────────────┘
```

### Dependency Injection

Using SwiftUI's `@Environment` and custom `@EnvironmentObject` for service injection:

```swift
// App Entry Point
@main
struct CouponTrackerApp: App {
    let container = DependencyContainer()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.modelContext, container.modelContext)
                .environmentObject(container.cardRepository)
                .environmentObject(container.benefitRepository)
                .environmentObject(container.notificationService)
        }
    }
}
```

---

## Project Structure

### Directory Layout

```
ios/CouponTracker/
├── Sources/
│   ├── App/
│   │   ├── CouponTrackerApp.swift          # App entry point
│   │   ├── DependencyContainer.swift       # DI container
│   │   └── AppDelegate.swift               # Background tasks, notifications
│   │
│   ├── Models/
│   │   ├── Entities/                       # SwiftData models
│   │   │   ├── UserCard.swift
│   │   │   ├── Benefit.swift
│   │   │   └── BenefitUsage.swift
│   │   ├── Templates/                      # Codable templates
│   │   │   ├── CardTemplate.swift
│   │   │   └── BenefitTemplate.swift
│   │   ├── Enums/
│   │   │   ├── BenefitStatus.swift
│   │   │   ├── BenefitFrequency.swift
│   │   │   └── BenefitCategory.swift
│   │   └── ViewModels/                     # Presentation models
│   │       ├── CardViewModel.swift
│   │       └── BenefitViewModel.swift
│   │
│   ├── Features/
│   │   ├── Home/
│   │   │   ├── Views/
│   │   │   │   ├── DashboardView.swift
│   │   │   │   ├── ValueSummaryCard.swift
│   │   │   │   └── ExpiringBenefitRow.swift
│   │   │   └── HomeViewModel.swift
│   │   │
│   │   ├── Wallet/
│   │   │   ├── Views/
│   │   │   │   ├── WalletView.swift
│   │   │   │   ├── CardStackView.swift
│   │   │   │   ├── CreditCardView.swift
│   │   │   │   └── CardDetailView.swift
│   │   │   └── WalletViewModel.swift
│   │   │
│   │   ├── Benefits/
│   │   │   ├── Views/
│   │   │   │   ├── BenefitListView.swift
│   │   │   │   ├── BenefitRowView.swift
│   │   │   │   └── BenefitDetailSheet.swift
│   │   │   └── BenefitViewModel.swift
│   │   │
│   │   ├── AddCard/
│   │   │   ├── Views/
│   │   │   │   ├── AddCardView.swift
│   │   │   │   ├── CardBrowserView.swift
│   │   │   │   ├── CardPreviewSheet.swift
│   │   │   │   └── CustomCardFormView.swift
│   │   │   └── AddCardViewModel.swift
│   │   │
│   │   ├── Onboarding/
│   │   │   ├── Views/
│   │   │   │   ├── OnboardingContainerView.swift
│   │   │   │   ├── WelcomeView.swift
│   │   │   │   ├── CardSelectionView.swift
│   │   │   │   └── NotificationPermissionView.swift
│   │   │   └── OnboardingViewModel.swift
│   │   │
│   │   ├── Settings/
│   │   │   ├── Views/
│   │   │   │   ├── SettingsView.swift
│   │   │   │   └── NotificationSettingsView.swift
│   │   │   └── SettingsViewModel.swift
│   │   │
│   │   └── Common/
│   │       ├── Views/
│   │       │   ├── StatusBadge.swift
│   │       │   ├── EmptyStateView.swift
│   │       │   ├── LoadingView.swift
│   │       │   └── ConfirmationDialog.swift
│   │       └── ViewModifiers/
│   │           ├── CardShadow.swift
│   │           └── SwipeActions.swift
│   │
│   ├── Services/
│   │   ├── Storage/
│   │   │   ├── Repositories/
│   │   │   │   ├── CardRepository.swift
│   │   │   │   ├── BenefitRepository.swift
│   │   │   │   └── UsageRepository.swift
│   │   │   ├── CardTemplateRepository.swift
│   │   │   └── UserDefaultsService.swift
│   │   │
│   │   ├── Notifications/
│   │   │   ├── NotificationService.swift
│   │   │   ├── NotificationScheduler.swift
│   │   │   └── NotificationHandler.swift
│   │   │
│   │   ├── Background/
│   │   │   ├── BackgroundTaskService.swift
│   │   │   └── BenefitResetService.swift
│   │   │
│   │   └── Analytics/
│   │       └── AnalyticsService.swift       # Stub for future
│   │
│   ├── Core/
│   │   ├── Navigation/
│   │   │   ├── AppRouter.swift
│   │   │   └── NavigationPath+Extensions.swift
│   │   │
│   │   ├── Extensions/
│   │   │   ├── Date+Extensions.swift
│   │   │   ├── Decimal+Extensions.swift
│   │   │   └── Color+Extensions.swift
│   │   │
│   │   └── Protocols/
│   │       ├── Repository.swift
│   │       └── DataSource.swift
│   │
│   └── Utils/
│       ├── Constants.swift
│       ├── DateCalculator.swift
│       └── PriorityCalculator.swift
│
├── Resources/
│   ├── Assets.xcassets/
│   │   ├── AppIcon.appiconset/
│   │   ├── Colors/
│   │   │   ├── Primary.colorset/
│   │   │   ├── Success.colorset/
│   │   │   └── ...
│   │   ├── CardArtwork/
│   │   │   ├── card_amex_platinum.imageset/
│   │   │   ├── card_amex_gold.imageset/
│   │   │   └── ...
│   │   └── Illustrations/
│   │       ├── onboarding_welcome.imageset/
│   │       └── empty_wallet.imageset/
│   │
│   ├── Data/
│   │   └── CardTemplates.json
│   │
│   └── Localization/
│       └── Localizable.strings
│
├── SupportingFiles/
│   ├── Info.plist
│   └── CouponTracker.entitlements
│
└── Tests/
    ├── UnitTests/
    │   ├── Models/
    │   ├── Services/
    │   └── ViewModels/
    └── UITests/
        └── Flows/
```

---

## Phase 1 MVP Implementation

### Sprint Overview

| Sprint | Duration | Focus Area | Key Deliverables |
|--------|----------|------------|------------------|
| Sprint 1 | Week 1-2 | Foundation | Data models, repositories, template loading |
| Sprint 2 | Week 2-3 | Core Features | Card management, benefit tracking |
| Sprint 3 | Week 3-4 | Wallet UI | Card visualization, benefit display |
| Sprint 4 | Week 4-5 | Notifications | Scheduling, actions, background refresh |
| Sprint 5 | Week 5-6 | Polish & Launch | Onboarding, settings, testing, bug fixes |

---

### Sprint 1: Foundation (Days 1-10)

**Objective:** Establish data layer and core infrastructure.

#### Milestone 1.1: Project Setup (Days 1-2)

**Tasks:**
| Task | File(s) | Effort | Dependencies |
|------|---------|--------|--------------|
| Configure Xcode project settings | Project.xcodeproj | 2h | None |
| Set up SwiftData container | `App/CouponTrackerApp.swift` | 2h | None |
| Create dependency container | `App/DependencyContainer.swift` | 3h | SwiftData |
| Set up color assets | `Resources/Assets.xcassets/Colors/` | 2h | None |
| Configure app icons | `Resources/Assets.xcassets/AppIcon.appiconset/` | 1h | Design assets |

**Deliverables:**
- [ ] App builds and runs
- [ ] SwiftData ModelContainer initialized
- [ ] Basic color palette configured
- [ ] DI container structure in place

---

#### Milestone 1.2: Data Models (Days 3-5)

**Tasks:**
| Task | File(s) | Effort | Dependencies |
|------|---------|--------|--------------|
| Create UserCard entity | `Models/Entities/UserCard.swift` | 3h | SwiftData setup |
| Create Benefit entity | `Models/Entities/Benefit.swift` | 4h | UserCard |
| Create BenefitUsage entity | `Models/Entities/BenefitUsage.swift` | 2h | Benefit |
| Define enums | `Models/Enums/*.swift` | 2h | None |
| Create CardTemplate structs | `Models/Templates/CardTemplate.swift` | 2h | None |
| Create BenefitTemplate structs | `Models/Templates/BenefitTemplate.swift` | 2h | CardTemplate |
| Write unit tests for models | `Tests/UnitTests/Models/` | 4h | All models |

**Deliverables:**
- [ ] All SwiftData entities defined with relationships
- [ ] Template structs defined and Codable
- [ ] Model unit tests passing
- [ ] Documentation comments on all public interfaces

**Code Example - UserCard Entity:**
```swift
// Models/Entities/UserCard.swift
import SwiftData
import Foundation

@Model
final class UserCard {
    @Attribute(.unique) var id: UUID
    var cardTemplateId: UUID?
    var nickname: String?
    var addedDate: Date
    var isCustom: Bool
    var customName: String?
    var customIssuer: String?
    var customColorHex: String?
    var sortOrder: Int

    @Relationship(deleteRule: .cascade, inverse: \Benefit.userCard)
    var benefits: [Benefit] = []

    init(
        id: UUID = UUID(),
        cardTemplateId: UUID? = nil,
        nickname: String? = nil,
        isCustom: Bool = false,
        customName: String? = nil,
        customIssuer: String? = nil,
        customColorHex: String? = nil
    ) {
        self.id = id
        self.cardTemplateId = cardTemplateId
        self.nickname = nickname
        self.addedDate = Date()
        self.isCustom = isCustom
        self.customName = customName
        self.customIssuer = customIssuer
        self.customColorHex = customColorHex
        self.sortOrder = 0
    }
}
```

---

#### Milestone 1.3: Template Loading (Days 6-8)

**Tasks:**
| Task | File(s) | Effort | Dependencies |
|------|---------|--------|--------------|
| Create CardTemplates.json | `Resources/Data/CardTemplates.json` | 4h | Template structs |
| Implement CardTemplateRepository | `Services/Storage/CardTemplateRepository.swift` | 4h | JSON file |
| Add search functionality | `Services/Storage/CardTemplateRepository.swift` | 2h | Repository |
| Add grouping by issuer | `Services/Storage/CardTemplateRepository.swift` | 1h | Repository |
| Write repository tests | `Tests/UnitTests/Services/` | 3h | Repository |

**Deliverables:**
- [ ] CardTemplates.json with 10+ popular cards
- [ ] Template repository loads and parses JSON
- [ ] Search by name/issuer works
- [ ] Grouping by issuer works
- [ ] Repository tests passing

---

#### Milestone 1.4: Core Repositories (Days 9-10)

**Tasks:**
| Task | File(s) | Effort | Dependencies |
|------|---------|--------|--------------|
| Define Repository protocol | `Core/Protocols/Repository.swift` | 1h | None |
| Implement CardRepository | `Services/Storage/Repositories/CardRepository.swift` | 4h | UserCard model |
| Implement BenefitRepository | `Services/Storage/Repositories/BenefitRepository.swift` | 4h | Benefit model |
| Implement UsageRepository | `Services/Storage/Repositories/UsageRepository.swift` | 2h | BenefitUsage model |
| Integration tests | `Tests/UnitTests/Services/` | 4h | All repositories |

**Deliverables:**
- [ ] CRUD operations for all entities
- [ ] Query methods for common operations
- [ ] Repository integration tests passing

---

### Sprint 2: Core Features (Days 11-20)

**Objective:** Implement card and benefit management logic.

#### Milestone 2.1: Add Card Flow (Days 11-14)

**Tasks:**
| Task | File(s) | Effort | Dependencies |
|------|---------|--------|--------------|
| Create AddCardViewModel | `Features/AddCard/AddCardViewModel.swift` | 4h | Repositories |
| Implement card creation from template | AddCardViewModel | 4h | CardTemplateRepository |
| Calculate initial benefit periods | `Utils/DateCalculator.swift` | 6h | Benefit model |
| Create benefits from template | AddCardViewModel | 3h | DateCalculator |
| Custom card creation logic | AddCardViewModel | 3h | Repositories |
| Unit tests | `Tests/UnitTests/ViewModels/` | 4h | ViewModel |

**Deliverables:**
- [ ] Add card from template populates all benefits
- [ ] Initial period dates calculated correctly
- [ ] Custom card creation works
- [ ] All unit tests passing

**Critical Logic - Date Calculator:**
```swift
// Utils/DateCalculator.swift
struct DateCalculator {

    /// Calculate the current period boundaries for a given frequency
    static func currentPeriod(
        for frequency: BenefitFrequency,
        referenceDate: Date = Date()
    ) -> (start: Date, end: Date) {
        let calendar = Calendar.current

        switch frequency {
        case .monthly:
            let start = calendar.date(from: calendar.dateComponents([.year, .month], from: referenceDate))!
            let end = calendar.date(byAdding: DateComponents(month: 1, day: -1), to: start)!
            return (start, end)

        case .quarterly:
            let month = calendar.component(.month, from: referenceDate)
            let quarterStartMonth = ((month - 1) / 3) * 3 + 1
            var components = calendar.dateComponents([.year], from: referenceDate)
            components.month = quarterStartMonth
            components.day = 1
            let start = calendar.date(from: components)!
            let end = calendar.date(byAdding: DateComponents(month: 3, day: -1), to: start)!
            return (start, end)

        case .semiAnnual:
            let month = calendar.component(.month, from: referenceDate)
            let halfStartMonth = month <= 6 ? 1 : 7
            var components = calendar.dateComponents([.year], from: referenceDate)
            components.month = halfStartMonth
            components.day = 1
            let start = calendar.date(from: components)!
            let end = calendar.date(byAdding: DateComponents(month: 6, day: -1), to: start)!
            return (start, end)

        case .annual:
            var components = calendar.dateComponents([.year], from: referenceDate)
            components.month = 1
            components.day = 1
            let start = calendar.date(from: components)!
            components.month = 12
            components.day = 31
            let end = calendar.date(from: components)!
            return (start, end)
        }
    }
}
```

---

#### Milestone 2.2: Benefit Status Management (Days 15-17)

**Tasks:**
| Task | File(s) | Effort | Dependencies |
|------|---------|--------|--------------|
| Mark benefit as used | BenefitRepository | 3h | Benefit model |
| Undo mark as used | BenefitRepository | 2h | Benefit model |
| Create usage history record | UsageRepository | 2h | BenefitUsage model |
| Status transition validation | BenefitRepository | 2h | Status enum |
| Benefit reset logic | `Services/Background/BenefitResetService.swift` | 6h | DateCalculator |
| Unit tests | Tests | 4h | All above |

**Deliverables:**
- [ ] Mark as used creates usage record
- [ ] Undo within grace period works
- [ ] Status transitions are validated
- [ ] Period reset logic works correctly

---

#### Milestone 2.3: ViewModels Layer (Days 18-20)

**Tasks:**
| Task | File(s) | Effort | Dependencies |
|------|---------|--------|--------------|
| Create CardViewModel | `Models/ViewModels/CardViewModel.swift` | 3h | UserCard, templates |
| Create BenefitViewModel | `Models/ViewModels/BenefitViewModel.swift` | 3h | Benefit |
| HomeViewModel | `Features/Home/HomeViewModel.swift` | 4h | Repositories |
| WalletViewModel | `Features/Wallet/WalletViewModel.swift` | 4h | Repositories |
| Unit tests | Tests | 4h | ViewModels |

**Deliverables:**
- [ ] ViewModels compute display properties
- [ ] Observable state management works
- [ ] Expiration calculations correct
- [ ] Value summaries correct

---

### Sprint 3: Wallet UI (Days 21-30)

**Objective:** Build the visual wallet and card interfaces.

#### Milestone 3.1: Card Components (Days 21-24)

**Tasks:**
| Task | File(s) | Effort | Dependencies |
|------|---------|--------|--------------|
| Create CreditCardView | `Features/Wallet/Views/CreditCardView.swift` | 6h | CardViewModel |
| Card artwork integration | CreditCardView | 3h | Asset catalog |
| Custom card gradients | CreditCardView | 2h | Color extensions |
| Card states (default, urgent, used) | CreditCardView | 3h | BenefitViewModel |
| Status pills component | `Features/Common/Views/StatusBadge.swift` | 2h | None |
| CardShadow modifier | `Features/Common/ViewModifiers/CardShadow.swift` | 1h | None |
| Snapshot tests | Tests | 3h | Components |

**Deliverables:**
- [ ] Card renders with correct aspect ratio
- [ ] Bundled artwork displays
- [ ] Custom gradients render
- [ ] Urgency states visible
- [ ] Snapshot tests passing

---

#### Milestone 3.2: Wallet Stack View (Days 25-27)

**Tasks:**
| Task | File(s) | Effort | Dependencies |
|------|---------|--------|--------------|
| Create CardStackView | `Features/Wallet/Views/CardStackView.swift` | 6h | CreditCardView |
| Stack offset animation | CardStackView | 3h | None |
| Card tap to expand | CardStackView | 2h | Navigation |
| Pull to refresh | CardStackView | 1h | ViewModel |
| WalletView container | `Features/Wallet/Views/WalletView.swift` | 3h | CardStackView |
| Empty state | `Features/Common/Views/EmptyStateView.swift` | 2h | None |

**Deliverables:**
- [ ] Cards stack with correct offset
- [ ] Tap navigates to detail
- [ ] Smooth animations
- [ ] Empty state shows when no cards

---

#### Milestone 3.3: Card Detail & Benefits (Days 28-30)

**Tasks:**
| Task | File(s) | Effort | Dependencies |
|------|---------|--------|--------------|
| CardDetailView | `Features/Wallet/Views/CardDetailView.swift` | 4h | CreditCardView |
| BenefitRowView | `Features/Benefits/Views/BenefitRowView.swift` | 4h | BenefitViewModel |
| BenefitListView | `Features/Benefits/Views/BenefitListView.swift` | 3h | BenefitRowView |
| Swipe actions | `Features/Common/ViewModifiers/SwipeActions.swift` | 4h | None |
| Mark as done animation | BenefitRowView | 3h | None |
| BenefitDetailSheet | `Features/Benefits/Views/BenefitDetailSheet.swift` | 3h | BenefitViewModel |

**Deliverables:**
- [ ] Card detail shows all benefits
- [ ] Benefits grouped by status
- [ ] Swipe right marks as done
- [ ] Success animation plays
- [ ] Haptic feedback works

---

### Sprint 4: Notifications (Days 31-40)

**Objective:** Implement notification system and background refresh.

#### Milestone 4.1: Notification Infrastructure (Days 31-34)

**Tasks:**
| Task | File(s) | Effort | Dependencies |
|------|---------|--------|--------------|
| NotificationService setup | `Services/Notifications/NotificationService.swift` | 4h | None |
| Permission request flow | NotificationService | 2h | None |
| Notification categories | NotificationService | 3h | None |
| NotificationScheduler | `Services/Notifications/NotificationScheduler.swift` | 6h | PriorityCalculator |
| Priority calculation | `Utils/PriorityCalculator.swift` | 3h | Benefit model |
| Rich notification content | NotificationScheduler | 2h | Card artwork |

**Deliverables:**
- [ ] Permission request works
- [ ] Categories with actions registered
- [ ] Notifications schedule correctly
- [ ] Rich content with card image

---

#### Milestone 4.2: Notification Actions (Days 35-37)

**Tasks:**
| Task | File(s) | Effort | Dependencies |
|------|---------|--------|--------------|
| NotificationHandler delegate | `Services/Notifications/NotificationHandler.swift` | 4h | NotificationService |
| Mark as done from notification | NotificationHandler | 3h | BenefitRepository |
| Snooze functionality | NotificationHandler | 3h | NotificationScheduler |
| Deep link to benefit | NotificationHandler | 2h | Navigation |
| AppDelegate integration | `App/AppDelegate.swift` | 2h | NotificationHandler |

**Deliverables:**
- [ ] Mark as done works from notification
- [ ] Snooze reschedules correctly
- [ ] Tap opens relevant screen
- [ ] Background action works without full app launch

---

#### Milestone 4.3: Background Refresh (Days 38-40)

**Tasks:**
| Task | File(s) | Effort | Dependencies |
|------|---------|--------|--------------|
| BackgroundTaskService | `Services/Background/BackgroundTaskService.swift` | 4h | BackgroundTasks framework |
| Register BGAppRefreshTask | BackgroundTaskService | 2h | Info.plist |
| Foreground sync on launch | AppDelegate | 2h | BenefitResetService |
| Period reset processing | BenefitResetService | 4h (refinement) | Repositories |
| Notification rescheduling | BackgroundTaskService | 2h | NotificationScheduler |
| Integration testing | Manual + automated | 4h | All above |

**Deliverables:**
- [ ] Background refresh registered
- [ ] Foreground sync works reliably
- [ ] Expired periods reset correctly
- [ ] Notifications updated after reset

---

### Sprint 5: Polish & Launch (Days 41-50)

**Objective:** Complete onboarding, settings, and prepare for release.

#### Milestone 5.1: Onboarding Flow (Days 41-44)

**Tasks:**
| Task | File(s) | Effort | Dependencies |
|------|---------|--------|--------------|
| OnboardingContainerView | `Features/Onboarding/Views/OnboardingContainerView.swift` | 3h | None |
| WelcomeView (2 screens) | `Features/Onboarding/Views/WelcomeView.swift` | 3h | Illustrations |
| CardSelectionView | `Features/Onboarding/Views/CardSelectionView.swift` | 4h | CardTemplateRepository |
| NotificationPermissionView | `Features/Onboarding/Views/NotificationPermissionView.swift` | 2h | NotificationService |
| OnboardingViewModel | `Features/Onboarding/OnboardingViewModel.swift` | 4h | UserDefaults |
| Skip functionality | OnboardingViewModel | 1h | None |
| Onboarding completion persistence | UserDefaultsService | 1h | UserDefaults |

**Deliverables:**
- [ ] Onboarding shows on first launch only
- [ ] Card multi-select works
- [ ] Notification permission requested with context
- [ ] Can skip any step
- [ ] Completes under 2 minutes

---

#### Milestone 5.2: Settings & Dashboard (Days 45-47)

**Tasks:**
| Task | File(s) | Effort | Dependencies |
|------|---------|--------|--------------|
| SettingsView | `Features/Settings/Views/SettingsView.swift` | 3h | None |
| NotificationSettingsView | `Features/Settings/Views/NotificationSettingsView.swift` | 4h | NotificationService |
| SettingsViewModel | `Features/Settings/SettingsViewModel.swift` | 3h | UserDefaultsService |
| DashboardView | `Features/Home/Views/DashboardView.swift` | 4h | HomeViewModel |
| ValueSummaryCard | `Features/Home/Views/ValueSummaryCard.swift` | 2h | HomeViewModel |
| ExpiringBenefitRow | `Features/Home/Views/ExpiringBenefitRow.swift` | 2h | BenefitViewModel |
| Tab bar navigation | `App/ContentView.swift` | 2h | All views |

**Deliverables:**
- [ ] Settings toggles persist
- [ ] Notification preferences apply
- [ ] Dashboard shows correct summaries
- [ ] Expiring items sorted by urgency
- [ ] Tab navigation works

---

#### Milestone 5.3: Add Card Browser (Days 45-47, parallel)

**Tasks:**
| Task | File(s) | Effort | Dependencies |
|------|---------|--------|--------------|
| AddCardView | `Features/AddCard/Views/AddCardView.swift` | 2h | None |
| CardBrowserView | `Features/AddCard/Views/CardBrowserView.swift` | 4h | CardTemplateRepository |
| Search functionality | CardBrowserView | 2h | Repository |
| CardPreviewSheet | `Features/AddCard/Views/CardPreviewSheet.swift` | 3h | CardTemplate |
| CustomCardFormView | `Features/AddCard/Views/CustomCardFormView.swift` | 4h | AddCardViewModel |
| Color/gradient picker | CustomCardFormView | 2h | Color assets |

**Deliverables:**
- [ ] Card browser shows all cards by issuer
- [ ] Search filters in real-time
- [ ] Preview shows benefits
- [ ] Add creates card with benefits
- [ ] Custom card form works

---

#### Milestone 5.4: Testing & Bug Fixes (Days 48-50)

**Tasks:**
| Task | Files | Effort | Dependencies |
|------|-------|--------|--------------|
| UI test suite | `Tests/UITests/` | 8h | All features |
| Performance testing | Instruments | 4h | None |
| Memory leak analysis | Instruments | 2h | None |
| Accessibility audit | Manual testing | 4h | All views |
| Bug fixes | Various | 8h | Testing results |
| Final documentation | README, comments | 4h | None |

**Deliverables:**
- [ ] UI tests pass for critical flows
- [ ] No memory leaks
- [ ] Accessibility audit passed
- [ ] All P0 bugs fixed
- [ ] Documentation complete

---

## Integration Points

### Module Dependencies

```
┌─────────────────────────────────────────────────────────────────┐
│                        App Module                                │
│  CouponTrackerApp.swift, AppDelegate.swift, DependencyContainer │
└─────────────────────────────────────────────────────────────────┘
          │                    │                    │
          ▼                    ▼                    ▼
┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐
│  Home Feature   │  │ Wallet Feature  │  │ Settings Feature│
│                 │  │                 │  │                 │
│ HomeViewModel   │  │ WalletViewModel │  │ SettingsViewModel│
│ DashboardView   │  │ WalletView      │  │ SettingsView    │
└────────┬────────┘  └────────┬────────┘  └────────┬────────┘
         │                    │                    │
         └────────────────────┼────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                       Services Layer                             │
│  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐  │
│  │ CardRepository  │  │NotificationSvc  │  │BackgroundTaskSvc│  │
│  │ BenefitRepository│  │NotificationSched│  │BenefitResetSvc │  │
│  │ UsageRepository │  │NotificationHndlr│  │                 │  │
│  └────────┬────────┘  └────────┬────────┘  └────────┬────────┘  │
└───────────┼────────────────────┼────────────────────┼───────────┘
            │                    │                    │
            ▼                    ▼                    ▼
┌─────────────────────────────────────────────────────────────────┐
│                     Infrastructure Layer                         │
│                                                                   │
│  SwiftData ModelContext    UNUserNotificationCenter    BGScheduler│
└─────────────────────────────────────────────────────────────────┘
```

### Key Integration Contracts

**1. ViewModel to Repository:**
```swift
protocol CardRepositoryProtocol {
    func fetchAllCards() async throws -> [UserCard]
    func fetchCard(by id: UUID) async throws -> UserCard?
    func addCard(_ card: UserCard) async throws
    func deleteCard(_ card: UserCard) async throws
}
```

**2. NotificationService to Repository:**
```swift
// NotificationHandler needs to update benefit status
protocol BenefitRepositoryProtocol {
    func markAsUsed(benefitId: UUID) async throws
    func fetchBenefit(by id: UUID) async throws -> Benefit?
}
```

**3. BackgroundTask to Services:**
```swift
// Background task coordinates multiple services
protocol BackgroundRefreshable {
    func performBackgroundRefresh() async throws
}

// BenefitResetService and NotificationScheduler conform
```

---

## Testing Strategy

### Testing Pyramid

```
                    ┌───────────────┐
                    │   UI Tests    │  10%
                    │  (Critical    │
                    │   Flows)      │
                    └───────┬───────┘
                            │
                ┌───────────┴───────────┐
                │   Integration Tests   │  20%
                │  (Repository + DB)    │
                │  (Notification Flow)  │
                └───────────┬───────────┘
                            │
        ┌───────────────────┴───────────────────┐
        │            Unit Tests                  │  70%
        │  (ViewModels, DateCalculator,         │
        │   PriorityCalculator, Models)         │
        └───────────────────────────────────────┘
```

### Test Coverage Targets

| Layer | Coverage Target | Priority Areas |
|-------|-----------------|----------------|
| Models | 90% | Date calculations, status transitions |
| ViewModels | 80% | Computed properties, business logic |
| Services | 75% | Repository operations, notification scheduling |
| Views | 50% | Snapshot tests for key states |

### Testing by Sprint

| Sprint | Test Focus |
|--------|------------|
| Sprint 1 | Model unit tests, repository integration tests |
| Sprint 2 | ViewModel tests, DateCalculator edge cases |
| Sprint 3 | UI snapshot tests, interaction tests |
| Sprint 4 | Notification integration tests, background task tests |
| Sprint 5 | End-to-end UI tests, performance tests |

### Key Test Cases

**DateCalculator Tests:**
```swift
func testMonthlyPeriodBoundaries() {
    // January 15 -> Jan 1 to Jan 31
    let date = Date(year: 2026, month: 1, day: 15)
    let period = DateCalculator.currentPeriod(for: .monthly, referenceDate: date)
    XCTAssertEqual(period.start, Date(year: 2026, month: 1, day: 1))
    XCTAssertEqual(period.end, Date(year: 2026, month: 1, day: 31))
}

func testQuarterlyQ1() {
    // February 20 -> Jan 1 to Mar 31
    let date = Date(year: 2026, month: 2, day: 20)
    let period = DateCalculator.currentPeriod(for: .quarterly, referenceDate: date)
    XCTAssertEqual(period.start, Date(year: 2026, month: 1, day: 1))
    XCTAssertEqual(period.end, Date(year: 2026, month: 3, day: 31))
}

func testLeapYearFebruary() {
    let date = Date(year: 2028, month: 2, day: 15) // 2028 is a leap year
    let period = DateCalculator.currentPeriod(for: .monthly, referenceDate: date)
    XCTAssertEqual(period.end, Date(year: 2028, month: 2, day: 29))
}
```

**Notification Priority Tests:**
```swift
func testHighValueLowUrgencyPriority() {
    let benefit = makeBenefit(value: 200, daysUntilExpiration: 14)
    let priority = PriorityCalculator.calculate(for: benefit)
    XCTAssertEqual(priority, 2.0 + 0) // value/100 + (14-14)*2
}

func testLowValueHighUrgencyPriority() {
    let benefit = makeBenefit(value: 15, daysUntilExpiration: 1)
    let priority = PriorityCalculator.calculate(for: benefit)
    XCTAssertEqual(priority, 0.15 + 26) // value/100 + (14-1)*2
}
```

---

## Risk Mitigation

### Technical Risks

| Risk | Probability | Impact | Mitigation |
|------|-------------|--------|------------|
| SwiftData stability issues | Low | High | Repository abstraction allows Core Data swap |
| Background refresh unreliable | High | Medium | Foreground sync on every launch |
| Notification limit exceeded | Medium | Medium | Priority-based scheduling, dynamic rebalancing |
| Card artwork licensing | Low | Low | Generic gradients as fallback |
| Performance with many cards | Low | Medium | Lazy loading, pagination if needed |

### Contingency Plans

**If SwiftData has critical bugs:**
1. Implement CoreDataRepository conforming to same protocol
2. Swap implementation in DependencyContainer
3. Estimated effort: 2-3 days

**If 64 notification limit is problematic:**
1. Reduce to 30-day window (from 45 days)
2. Implement grouped notifications per card
3. Add in-app notification center as backup

**If background refresh is too unreliable:**
1. Accept best-effort for follow-up reminders
2. Ensure foreground sync is robust
3. Consider push notifications in Phase 2

---

## Gaps and Concerns

### Architectural Assessment Summary

After thorough review of the PRD, Design Document, Technical Specification, and UI Specifications, the documentation is **comprehensive and well-aligned**. The following gaps and concerns have been identified for resolution.

### Gap Analysis: PRD vs Technical Feasibility

| PRD Requirement | Technical Feasibility | Gap/Concern | Resolution |
|-----------------|----------------------|-------------|------------|
| F2.3: Benefit Reset Automation | Feasible | Background refresh not guaranteed | Foreground sync on launch provides reliable fallback |
| F3.3: Recurring Reminders | Partial | iOS cannot chain notifications automatically | Background refresh + foreground sync; accept best-effort for follow-ups |
| F3.2: Notification Snooze | Feasible | Snooze from notification requires app context | Use `UNNotificationAction` with background processing |
| F1.1: 20 Pre-populated Cards | Feasible | Card artwork bundle size (~5MB) | Acceptable; lazy loading mitigates memory impact |
| F2.3: Anniversary-based Reset | Complex | Requires user input for card open date | Defer to Phase 3; use calendar year for MVP |

### Identified Concerns

#### Concern 1: Anniversary-Based Annual Benefit Reset

**PRD Reference:** F2.3 states "Annual benefits reset on calendar year or cardmember anniversary (configurable)"

**Issue:** Determining cardmember anniversary requires either:
1. User manual input of card open date
2. API integration with card issuer (future)

**Architect Recommendation:**
- **MVP:** Use calendar year reset for all annual benefits
- **Phase 2/3:** Add optional "card anniversary date" field for users who want anniversary-based tracking
- **Impact:** Slight reduction in accuracy for users whose card anniversary differs from calendar year

#### Concern 2: Notification Follow-up Reliability

**PRD Reference:** F3.3 requires "follow-up reminders if not acknowledged"

**Issue:** iOS `BGAppRefreshTask` is not guaranteed to execute at specific times or frequencies. The system may delay or skip background tasks based on battery, usage patterns, and system conditions.

**Architect Recommendation:**
- Accept best-effort for automated follow-ups
- Implement robust foreground sync that catches up on any missed reminders
- Add in-app "pending reminders" section for visibility
- Document limitation in user-facing help content

#### Concern 3: Semi-Annual Benefit Period Alignment

**PRD Reference:** Table lists "semi-annual" benefits (e.g., Saks credit)

**Issue:** Semi-annual benefits may reset on:
1. Calendar half-years (Jan 1, Jul 1)
2. Cardmember anniversary half-years
3. Issuer-specific dates

**Architect Recommendation:**
- **MVP:** Use calendar half-year boundaries (Jan-Jun, Jul-Dec)
- Store `customResetMonth` in Benefit entity for future customization
- Document assumption in app help content

#### Concern 4: Card Artwork Licensing

**PRD Reference:** F4.1 requires "authentic-looking artwork"

**Issue:** Using actual credit card artwork may require licensing agreements with card issuers.

**Architect Recommendation:**
- Create stylized representations inspired by card designs
- Use issuer color schemes (publicly available brand colors)
- Include disclaimer in app about unofficial status
- Design fallback gradient system that looks premium

#### Concern 5: Partial Benefit Usage (Future)

**PRD Reference:** Not explicitly covered in MVP

**Issue:** Some benefits allow partial usage (e.g., $200 airline credit used in multiple transactions). Current model supports only binary used/available.

**Architect Recommendation:**
- Model already includes `partiallyUsed` status placeholder
- **MVP:** Binary status only (used/available)
- **Phase 2:** Add `amountUsed` field and partial tracking UI
- No architectural changes needed; data model is ready

### Documentation Gaps Identified

| Gap | Impact | Resolution |
|-----|--------|------------|
| Error handling patterns not specified | Medium | Added to testing strategy; follow Swift error handling best practices |
| Accessibility implementation details | Medium | Follow iOS HIG; add to Definition of Done checklist |
| Analytics requirements vague | Low | Stub service created; define events in Phase 2 |
| Localization strategy not detailed | Low | Use SwiftUI localization; English only for MVP |

### Recommendations for PRD Updates

1. **Clarify anniversary reset scope:** Add note that MVP uses calendar-based resets; anniversary support is Phase 3

2. **Set expectations for follow-up reminders:** Note that follow-up reliability depends on iOS background execution policies

3. **Define partial usage requirements:** Specify whether Phase 2 should support partial benefit redemption tracking

4. **Add card artwork disclaimer:** Acknowledge that artwork will be stylized representations, not official card images

### Questions Requiring Product Decision

1. **Q: Should users be able to manually trigger benefit period reset?**
   - Scenario: User knows they missed a benefit last period and wants to reset early
   - Recommendation: Not for MVP; adds complexity

2. **Q: What happens when a user deletes a card with unused benefits?**
   - Current behavior: Card and benefits deleted; usage history preserved
   - Alternative: Warn user about losing tracking data
   - Recommendation: Show confirmation dialog with "unused benefits" count

3. **Q: Should the app track benefits the user explicitly marks as "not using"?**
   - Scenario: User has Airline Credit but never uses it
   - Recommendation: Phase 2 feature; add "hide benefit" option

---

## Appendix

### A1: Card Template JSON Schema

```json
{
  "$schema": "http://json-schema.org/draft-07/schema#",
  "type": "object",
  "properties": {
    "schemaVersion": { "type": "integer" },
    "dataVersion": { "type": "string" },
    "cards": {
      "type": "array",
      "items": {
        "type": "object",
        "required": ["id", "name", "issuer", "benefits"],
        "properties": {
          "id": { "type": "string", "format": "uuid" },
          "name": { "type": "string" },
          "issuer": { "type": "string" },
          "artworkAsset": { "type": "string" },
          "annualFee": { "type": "number" },
          "primaryColor": { "type": "string" },
          "secondaryColor": { "type": "string" },
          "isActive": { "type": "boolean" },
          "benefits": {
            "type": "array",
            "items": {
              "type": "object",
              "required": ["id", "name", "value", "frequency"],
              "properties": {
                "id": { "type": "string", "format": "uuid" },
                "name": { "type": "string" },
                "description": { "type": "string" },
                "value": { "type": "number" },
                "frequency": { "enum": ["monthly", "quarterly", "semiAnnual", "annual"] },
                "category": { "type": "string" },
                "merchant": { "type": "string" },
                "resetDayOfMonth": { "type": "integer" }
              }
            }
          }
        }
      }
    }
  }
}
```

### A2: Info.plist Requirements

```xml
<!-- Background Modes -->
<key>UIBackgroundModes</key>
<array>
    <string>fetch</string>
    <string>processing</string>
</array>

<!-- Background Task Identifiers -->
<key>BGTaskSchedulerPermittedIdentifiers</key>
<array>
    <string>com.coupontracker.refresh</string>
    <string>com.coupontracker.reset</string>
</array>
```

### A3: Sprint Burndown Template

| Day | Planned | Completed | Notes |
|-----|---------|-----------|-------|
| 1 | X points | | |
| 2 | X points | | |
| ... | | | |

### A4: Definition of Done

A feature is considered "done" when:
- [ ] Code compiles without warnings
- [ ] Unit tests written and passing
- [ ] Code reviewed by peer
- [ ] Accessibility checked
- [ ] Dark mode tested
- [ ] Documentation updated
- [ ] Merged to main branch

---

## Document History

| Version | Date | Author | Changes |
|---------|------|--------|---------|
| 1.0 | 2026-01-16 | Software Architect | Initial implementation plan |

---

## Approval Sign-off

| Role | Name | Date | Signature |
|------|------|------|-----------|
| Software Architect | | 2026-01-16 | Approved |
| Engineering Lead | | | Pending |
| Product Manager | | | Pending |
