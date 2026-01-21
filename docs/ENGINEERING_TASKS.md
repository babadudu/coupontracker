# Engineering Task Assignments

> Generated from Architect and Senior Engineer review of tech debt RCA.

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
├── T-011: Lazy Loading Helper          [Engineer A]
├── T-008: Data Grouping Helper         [Engineer A]
├── T-006: Template Search Protocol     [Engineer D]
└── T-004: Currency Aggregation         [Engineer A]

DEPENDS ON T-004:
└── T-015: Dashboard Insight Logic      [Engineer C]

DEPENDS ON T-007:
└── T-010: BenefitStateService          [Engineer C]

SEQUENTIAL (UI):
├── T-005: Unify BenefitRowView         [Engineer B]
└── T-012: Split Large Views            [Engineer B] (after T-005)

FINAL:
└── T-016: Documentation                [Engineer D] (after all)
```

---

## Engineer A: Data Layer Extensions

**Focus:** Collection helpers and aggregation patterns

### T-011: Extract Lazy Loading Helper
**Priority:** P1 | **Effort:** Small | **Risk:** Low

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

### T-008: Extract Data Grouping Helper
**Priority:** P2 | **Effort:** Small | **Risk:** Low

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

### T-004: Extract Currency Aggregation Helpers
**Priority:** P1 | **Effort:** Small | **Risk:** Low

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

### T-005: Unify BenefitRowView Variants
**Priority:** P1 | **Effort:** Medium | **Risk:** Medium (UI regression)

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

### T-012: Split Large View Files
**Priority:** P2 | **Effort:** Medium | **Risk:** Medium
**Depends on:** T-005 completion

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

### T-007: Centralize Date Period Calculations
**Priority:** P1 | **Effort:** Medium | **Risk:** High (date math)

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

### T-010: Extract Business Logic from Repositories
**Priority:** P1 | **Effort:** High | **Risk:** High
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

### T-015: Extract Dashboard Insight Logic
**Priority:** P2 | **Effort:** Small | **Risk:** Low
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

### T-006: Extract Template Search Protocol
**Priority:** P2 | **Effort:** Small | **Risk:** Low

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

### T-016: Add Service Layer Documentation
**Priority:** P3 | **Effort:** Small | **Risk:** Low
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
- [ ] Pass all existing tests
- [ ] Add new tests for the extracted code
- [ ] Follow CLAUDE.md architectural constraints
- [ ] Update file to be under size limit
- [ ] Be reviewed by at least one other engineer
- [ ] Have no new compiler warnings

---

*This document serves as a template for future refactoring sprints. Archive completed task lists to `docs/archive/`.*
