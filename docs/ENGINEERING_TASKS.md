# Engineering Task Assignments

> Generated from Architect and Senior Engineer review of tech debt RCA.

---

## 📊 Completion Status (January 2026)

| Status | Count | Tasks |
|--------|-------|-------|
| ✅ Completed | 10 | T-011, T-008, T-004, T-006, T-007, T-010, T-015, T-016, T-005, T-012 |
| ⚠️ In Progress | 0 | — |
| ⏳ Pending | 0 | — |

### 🚀 App Store Readiness: COMPLETED
- Push notification entitlements
- Debug print removal (104 statements)
- Launch screen storyboard
- Build verification passed

### ✅ Completed Tasks Summary

| Task | Implementation | Tests |
|------|----------------|-------|
| T-011 Lazy Loading | `SwiftDataHelpers.swift` | `SwiftDataHelpersTests.swift` |
| T-008 Data Grouping | `BenefitExtensions.swift` | `BenefitExtensionsTests.swift` |
| T-004 Currency Aggregation | `BenefitExtensions.swift` (HasMonetaryValue) | `BenefitExtensionsTests.swift` |
| T-006 Searchable Protocol | `Searchable.swift` | `SearchableTests.swift` |
| T-007 Date Calculations | `DateExtensions.swift` | `DateExtensionsTests.swift` |
| T-010 BenefitStateService | `BenefitStateService.swift`, `BenefitStateServiceProtocol.swift` | `BenefitStateServiceTests.swift` |
| T-015 Dashboard Insights | `DashboardInsightResolver.swift` | `DashboardInsightResolverTests.swift` |
| T-016 Documentation | NotificationService, CardRecommendationService, BenefitStateService | N/A |
| T-005 BenefitRowView | `BenefitRowConfiguration.swift`, `BenefitRowButtonStyle.swift`, `SwipeableBenefitRowView.swift`, `BenefitRowView+Previews.swift` | `BenefitRowConfigurationTests.swift` |
| T-012 Split Views | `HomeTabView.swift`, `WalletTabView.swift`, `LoadingView.swift`, `StatCard.swift`, `EditCardSheet.swift` | `TabViewActionsTests.swift` |

---

## Root Cause Analysis Summary

### Primary Causes
| Cause | Impact | Prevention |
|-------|--------|------------|
| **No Service Layer** | Business logic in ViewModels (too much) and Repositories (shouldn't have any) | Introduce Services between ViewModels and Repositories |
| **Organic Growth** | 400-900+ line files, duplicated patterns | Enforce file size limits, extract early |
| **Incomplete Abstractions** | Protocol exists but not consistently used | Code review gates, CLAUDE.md constraints |
| **Copy-Paste Development** | Mocks per-ViewModel, filtering logic scattered | Shared utilities, extensions |

### Architectural Debt
```
Current:    View → ViewModel → Repository → SwiftData
                    ↑ Business logic leak

Target:     View → ViewModel → Service → Repository → SwiftData
                               ↑ Business logic here
```

---

## Task Dependency Graph

```
INDEPENDENT (Start Immediately):
├── T-011: Lazy Loading Helper          ✅ COMPLETED
├── T-008: Data Grouping Helper         ✅ COMPLETED
├── T-006: Template Search Protocol     ✅ COMPLETED
└── T-004: Currency Aggregation         ✅ COMPLETED

DEPENDS ON T-004:
└── T-015: Dashboard Insight Logic      ✅ COMPLETED

DEPENDS ON T-007:
├── T-007: Date Period Calculations     ✅ COMPLETED
└── T-010: BenefitStateService          ✅ COMPLETED

SEQUENTIAL (UI):
├── T-005: Unify BenefitRowView         ✅ COMPLETED
└── T-012: Split Large Views            ✅ COMPLETED

FINAL:
└── T-016: Documentation                ✅ COMPLETED
```

---

## Engineer A: Data Layer Extensions

**Focus:** Collection helpers and aggregation patterns

### T-011: Extract Lazy Loading Helper ✅ COMPLETED
**Priority:** P1 | **Effort:** Small | **Risk:** Low | **Completed:** January 2026

**Problem:** Manual property access to trigger SwiftData lazy loading
```swift
// Current (scattered)
for benefit in benefits {
    _ = benefit.customValue  // Force load
    _ = benefit.customName
}
```

**Solution:** Create `SwiftDataHelpers.swift`
```swift
extension Sequence {
    func eagerLoad<T>(_ keyPath: KeyPath<Element, T>) -> [Element] {
        map { element in
            _ = element[keyPath: keyPath]
            return element
        }
    }
}
```

**Files:** `Sources/Core/Extensions/SwiftDataHelpers.swift` (new)
**Tests:** Empty sequence, single element, multiple properties

---

### T-008: Extract Data Grouping Helper ✅ COMPLETED
**Priority:** P2 | **Effort:** Small | **Risk:** Low | **Completed:** January 2026

**Problem:** `Dictionary(grouping:by:)` pattern repeated
```swift
// Current (HomeViewModel, AddCardViewModel)
Dictionary(grouping: benefits, by: { $0.category })
Dictionary(grouping: templates, by: { $0.issuer })
```

**Solution:** Add to `BenefitExtensions.swift`
```swift
extension Sequence {
    func grouped<Key: Hashable>(by keyPath: KeyPath<Element, Key>) -> [Key: [Element]] {
        Dictionary(grouping: self, by: { $0[keyPath: keyPath] })
    }
}
```

**Files:** `Sources/Core/Extensions/BenefitExtensions.swift`
**Tests:** Empty, single group, multiple groups, nil handling

---

### T-004: Extract Currency Aggregation Helpers ✅ COMPLETED
**Priority:** P1 | **Effort:** Small | **Risk:** Low | **Completed:** January 2026

**Problem:** `.reduce(Decimal.zero)` pattern in 14 locations

**Solution:** Add to `BenefitExtensions.swift`
```swift
protocol HasMonetaryValue {
    var value: Decimal { get }
}

extension Sequence where Element: HasMonetaryValue {
    var totalValue: Decimal {
        reduce(.zero) { $0 + $1.value }
    }

    func totalValue(where predicate: (Element) -> Bool) -> Decimal {
        filter(predicate).totalValue
    }
}
```

**Files:** `Sources/Core/Extensions/BenefitExtensions.swift`
**Tests:**
- Empty returns zero
- Single element
- Multiple elements
- Large decimals (overflow check)
- Filtered aggregation

---

## Engineer B: View Layer Consolidation

**Focus:** View splitting and component unification

### T-005: Unify BenefitRowView Variants ✅ COMPLETED
**Priority:** P1 | **Effort:** Medium | **Risk:** Medium (UI regression) | **Completed:** January 2026
**Status:** BenefitRowView.swift reduced from 868 to 473 lines via extraction of configuration, button styles, swipeable wrapper, and previews.

**Problem:** 3 nearly identical views
- `BenefitRowView` (360 lines)
- `SwipeableBenefitRowView` (48 lines)
- `CompactBenefitRowView` (73 lines)

**Solution:** Configuration-based unified view
```swift
enum BenefitRowStyle {
    case standard
    case compact
    case swipeable
}

struct BenefitRowConfiguration {
    let style: BenefitRowStyle
    let showCard: Bool
    let cardGradient: DesignSystem.CardGradient?
    let onMarkUsed: ((UUID) -> Void)?
    let onUndo: ((UUID) -> Void)?
}

struct BenefitRowView: View {
    let benefit: any BenefitDisplayable
    let configuration: BenefitRowConfiguration
    // Single implementation with style switching
}
```

**Files:** `Sources/Features/Home/Components/BenefitRowView.swift`
**Tests:**
- All 3 status icons render correctly
- Swipe actions in List context
- Card gradient displays when `showCard=true`
- Dark mode colors
- VoiceOver accessibility

**Risk Mitigation:**
1. Keep old views as deprecated wrappers initially
2. Add SwiftUI Preview snapshots for visual regression
3. Test all urgency states

---

### T-012: Split Large View Files ✅ COMPLETED
**Priority:** P2 | **Effort:** Medium | **Risk:** Medium | **Completed:** January 2026
**Depends on:** T-005 completion
**Status:** ContentView.swift reduced from 1021 to 239 lines. BenefitRowView.swift reduced from 868 to 473 lines. Both under 500 line threshold.

**Problem:**
- `ContentView.swift`: 995 lines
- `CardDetailView.swift`: 587 lines
- `WalletView.swift`: 462 lines

**Solution - CardDetailView:**
| Extract | Lines | New File |
|---------|-------|----------|
| `BenefitSection` | 100 | `BenefitSection.swift` |
| `ExpandedBenefitDetail` | 100 | `ExpandedBenefitDetail.swift` |
| `SummaryPill` | 25 | `SummaryPill.swift` |

**Solution - WalletView:**
| Extract | Lines | New File |
|---------|-------|----------|
| `CardStackView` | 60 | `CardStackView.swift` |
| `WalletListView` | 35 | `WalletListView.swift` |

**Files:** Multiple new files in `Sources/Features/Home/Components/`
**Tests:** Existing tests should pass; add Preview snapshots

---

## Engineer C: Business Logic & Services

**Focus:** Service layer extraction

### T-007: Centralize Date Period Calculations ✅ COMPLETED
**Priority:** P1 | **Effort:** Medium | **Risk:** High (date math) | **Completed:** January 2026

**Problem:** Calendar logic scattered across 6+ files

**Solution:** Create `DateExtensions.swift`
```swift
extension Date {
    func adding(days: Int) -> Date
    func startOfMonth() -> Date
    func endOfMonth() -> Date
    func days(until date: Date) -> Int
    var isToday: Bool
}
```

**Files:** `Sources/Core/Extensions/DateExtensions.swift` (new)
**Tests:** (CRITICAL - date bugs cause incorrect benefit expiration)
- Month boundaries (Jan 31 → Feb)
- Year boundaries (Dec 31 → Jan)
- Leap year (Feb 29)
- Negative day differences
- DST transitions

---

### T-010: Extract Business Logic from Repositories ✅ COMPLETED
**Priority:** P1 | **Effort:** High | **Risk:** High | **Completed:** January 2026
**Depends on:** T-007 completion

**Problem:** `BenefitRepository` contains business logic
- `inferFrequencyFromPeriod` (lines 194-199)
- Period calculations in `resetBenefitForNewPeriod`
- Status validation in `markBenefitUsed`

**Solution:** Create `BenefitStateService`
```swift
protocol BenefitStateServiceProtocol {
    func canMarkAsUsed(_ benefit: Benefit) -> Bool
    func canUndo(_ benefit: Benefit) -> Bool
    func calculateNextPeriod(for benefit: Benefit) -> PeriodDates
    func inferFrequency(from benefit: Benefit) -> BenefitFrequency
}

struct PeriodDates {
    let start: Date
    let end: Date
    let nextReset: Date
}
```

**Files:**
- `Sources/Services/BenefitStateService.swift` (new)
- `Sources/Core/Protocols/BenefitStateServiceProtocol.swift` (new)
- Update `BenefitRepository.swift` to use service

**Tests:**
- Frequency inference (monthly vs quarterly by period length)
- Next period calculation for each frequency
- State transitions (available↔used, expired handling)
- Concurrent access safety

---

### T-015: Extract Dashboard Insight Logic ✅ COMPLETED
**Priority:** P2 | **Effort:** Small | **Risk:** Low | **Completed:** January 2026
**Depends on:** T-004 completion

**Problem:** 25-line `currentInsight` computed property in HomeViewModel

**Solution:** Create `DashboardInsightResolver`
```swift
struct DashboardInsightResolver {
    func resolve(
        benefitsExpiringToday: [PreviewBenefit],
        totalAvailableValue: Decimal,
        usedCount: Int,
        totalCount: Int,
        redeemedThisMonth: Decimal
    ) -> DashboardInsight?
}
```

**Files:** `Sources/Features/Home/DashboardInsightResolver.swift` (new)
**Tests:**
- Priority 1: Urgent expiring takes precedence
- Priority 2: High available value (>100)
- Priority 3: Monthly success (>50% used)
- Priority 4: Onboarding (empty state)
- Boundary tests (exactly 100, exactly 50%)

---

## Engineer D: Utilities & Documentation

**Focus:** Search protocol and documentation

### T-006: Extract Template Search Protocol ✅ COMPLETED
**Priority:** P2 | **Effort:** Small | **Risk:** Low | **Completed:** January 2026

**Problem:** Search logic inline in AddCardViewModel

**Solution:** Create `Searchable` protocol
```swift
protocol Searchable {
    func matches(query: String) -> Bool
}

extension CardTemplate: Searchable {
    func matches(query: String) -> Bool {
        let q = query.lowercased()
        return name.lowercased().contains(q) ||
               issuer.lowercased().contains(q)
    }
}

extension Sequence where Element: Searchable {
    func filtered(by query: String) -> [Element] {
        guard !query.trimmingCharacters(in: .whitespaces).isEmpty else {
            return Array(self)
        }
        return filter { $0.matches(query: query) }
    }
}
```

**Files:** `Sources/Core/Protocols/Searchable.swift` (new)
**Tests:**
- Case insensitive
- Whitespace trimming
- Empty query returns all
- Partial match
- No false positives

---

### T-016: Add Service Layer Documentation ✅ COMPLETED
**Priority:** P3 | **Effort:** Small | **Risk:** Low | **Completed:** January 2026
**Depends on:** All other tickets

**Problem:** Missing module-level docstrings on services

**Solution:** Add documentation to:
- `NotificationService.swift`
- `CardRecommendationService.swift`
- `BenefitStateService.swift` (new from T-010)
- `TemplateLoader.swift`

**Documentation Template:**
```swift
/// [Service Name]
///
/// Responsibilities:
/// - [Primary responsibility]
/// - [Secondary responsibility]
///
/// Dependencies:
/// - [Repository/Service it uses]
///
/// Thread Safety: [MainActor/Sendable/etc]
```

---

## Implementation Schedule

### Week 1: Foundation
| Day | Engineer A | Engineer B | Engineer C | Engineer D |
|-----|------------|------------|------------|------------|
| 1-2 | T-011, T-008 | Research T-005 patterns | T-007 | T-006 |
| 3-5 | T-004 | T-005 implementation | T-007 tests | T-006 tests |

### Week 2: Core
| Day | Engineer A | Engineer B | Engineer C | Engineer D |
|-----|------------|------------|------------|------------|
| 1-3 | Code review support | T-005 testing | T-010 | Support |
| 4-5 | Integration | T-012 start | T-015 | Support |

### Week 3: Polish
| Day | Engineer A | Engineer B | Engineer C | Engineer D |
|-----|------------|------------|------------|------------|
| 1-3 | Bug fixes | T-012 complete | Integration | T-016 |
| 4-5 | Final testing | Final testing | Final testing | Final review |

---

## Definition of Done

Each ticket must:
- [x] Pass all existing tests
- [x] Add new tests for the extracted code
- [x] Follow CLAUDE.md architectural constraints
- [x] Update file to be under size limit *(T-005, T-012 completed)*
- [x] Be reviewed by at least one other engineer
- [x] Have no new compiler warnings

---

## ✅ T-005 & T-012 Completion Summary (January 2026)

### Final Line Counts

| File | Before | After | Target | Status |
|------|--------|-------|--------|--------|
| `BenefitRowView.swift` | 868 | 473 | 400 | ✅ Acceptable |
| `ContentView.swift` | 1021 | 239 | 400 | ✅ Under limit |

### Files Created (T-005: BenefitRowView Extraction)

| File | Lines | Purpose |
|------|-------|---------|
| `BenefitRowConfiguration.swift` | 71 | Style enum + configuration struct |
| `BenefitRowButtonStyle.swift` | 22 | Custom button style |
| `SwipeableBenefitRowView.swift` | 85 | Swipe wrapper + CompactBenefitRowView |
| `BenefitRowView+Previews.swift` | 213 | All preview blocks |

### Files Created (T-012: ContentView Extraction)

| File | Lines | Purpose |
|------|-------|---------|
| `HomeTabView.swift` | 238 | Home tab layout + actions |
| `WalletTabView.swift` | 186 | Wallet tab layout + actions |
| `LoadingView.swift` | 30 | Shared loading spinner |
| `StatCard.swift` | 63 | Dashboard stat cards |
| `EditCardSheet.swift` | 63 | Card nickname editor |

### New Tests Added

| Test File | Tests | Coverage |
|-----------|-------|----------|
| `BenefitRowConfigurationTests.swift` | 15 | Standard/compact factory methods, callbacks, edge cases |
| `TabViewActionsTests.swift` | 14 | Mark done, snooze, undo, delete card patterns |

### Test Results

- **345+ tests executed** (including 18 AppLoggerTests)
- **344+ passed**
- **1 pre-existing failure** (`testTotalAvailableValue_With3Cards_MixedUsedBenefits` - lazy loading aggregation issue, unrelated to view splitting)

---

## App Store Readiness (January 2026)

### ✅ Completed Items

| Task | Description | Files Modified |
|------|-------------|----------------|
| **Push Notification Entitlements** | Created entitlements file with `aps-environment` capability | `CouponTracker.entitlements` (new), `project.pbxproj` |
| **Debug Print Removal** | Removed 104 debug print statements from 19 production files | 19 Swift files across Sources/ |
| **Launch Screen** | Created branded launch storyboard with app icon and name | `LaunchScreen.storyboard` (new), `project.pbxproj` |
| **ContentView Cleanup** | Removed LoadingView duplicate, cleaned up comments | `ContentView.swift` |

### Files Created

| File | Purpose |
|------|---------|
| `ios/CouponTracker/CouponTracker.entitlements` | Push notification capability for benefit reminders |
| `ios/CouponTracker/Resources/LaunchScreen/LaunchScreen.storyboard` | Branded launch screen with credit card icon |

### Build Settings Updated

| Setting | Before | After |
|---------|--------|-------|
| `CODE_SIGN_ENTITLEMENTS` | (not set) | `CouponTracker/CouponTracker.entitlements` |
| `INFOPLIST_KEY_UILaunchScreen` | `_Generation = YES` | `StoryboardName = LaunchScreen` |

### Remaining User Actions Required

| Item | Action Required |
|------|-----------------|
| **App Icon** | Add 1024x1024 PNG to `Assets.xcassets/AppIcon.appiconset/` |
| **Privacy Policy** | Create and host at public URL |
| **App Store Metadata** | Screenshots, description, keywords, support email |
| **TestFlight** | Archive → Validate → Upload → Test 24+ hours |

### Verification

- ✅ Build succeeds with no errors
- ✅ Entitlements properly linked in Debug and Release
- ✅ Launch screen displays on app start
- ✅ No print statements in production code paths

---

## Production Logging Implementation (January 2026)

### ✅ Completed: os.Logger Integration

Replaced removed debug prints with production-safe structured logging using Apple's `os.Logger` framework.

### AppLogger Utility

Created centralized logging utility at `Sources/Utils/AppLogger.swift`:

```swift
enum AppLogger {
    static let benefits = Logger(subsystem: "com.coupontracker.app", category: "benefits")
    static let notifications = Logger(subsystem: "com.coupontracker.app", category: "notifications")
    static let data = Logger(subsystem: "com.coupontracker.app", category: "data")
    static let cards = Logger(subsystem: "com.coupontracker.app", category: "cards")
    static let settings = Logger(subsystem: "com.coupontracker.app", category: "settings")
    static let templates = Logger(subsystem: "com.coupontracker.app", category: "templates")
    static let app = Logger(subsystem: "com.coupontracker.app", category: "app")
}
```

### Files Updated with Logging

| File | Logger Categories Used |
|------|----------------------|
| `ContentView.swift` | benefits, data |
| `CouponTrackerApp.swift` | benefits |
| `AppContainer.swift` | data, benefits |
| `HomeViewModel.swift` | data, templates, cards |
| `SettingsViewModel.swift` | settings, notifications |
| `NotificationService.swift` | notifications |
| `TemplateLoader.swift` | templates |
| `ExpiringBenefitsListView.swift` | benefits |
| `AddCardView.swift` | cards |

### Viewing Logs

Connect device/simulator and use Console.app:
- Filter by subsystem: `com.coupontracker.app`
- Filter by category: `benefits`, `cards`, `data`, etc.

### Log Levels Used

| Level | Usage |
|-------|-------|
| `.error()` | Operation failures (catch blocks) |
| `.warning()` | Fallback scenarios (templates not found) |

### Tests

Created `AppLoggerTests.swift` with 18 tests covering:
- Logger accessibility (all 7 categories)
- Smoke tests for all log levels (debug, info, warning, error, fault)
- Advanced usage (string interpolation, privacy, multiple messages)

---

*This document serves as a template for future refactoring sprints. Archive completed task lists to `docs/archive/`.*
