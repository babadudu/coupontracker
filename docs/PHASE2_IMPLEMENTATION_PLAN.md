# Phase 2: Dashboard Enhancement - Implementation Plan

**Created:** January 18, 2026
**Status:** Completed
**Completed:** January 18, 2026
**Session Reference:** Clear context and resume from this file

---

## Quick Start

To resume this plan in a new session:
```
Read /Volumes/990PRO/babadudu/Documents/projects/coupontracker/docs/PHASE2_IMPLEMENTATION_PLAN.md
Continue from the next unchecked item.
```

---

## Progress Tracking

Use `[x]` to mark completed items. Update this file as you work.

---

## STEP 1: Wire HomeTabView Callbacks (PARALLEL-SAFE: NO)

**Priority:** Critical (Blocker)
**Depends on:** Nothing
**File:** `ios/CouponTracker/Sources/App/ContentView.swift`

### Tasks:
- [x] Add navigation state properties to HomeTabView:
  ```swift
  @State private var showAddCard = false
  @State private var showExpiringList = false
  @State private var selectedCardId: UUID?
  @Binding var selectedTab: Tab
  ```
- [x] Update QuickActionsView instantiation (lines 203-208):
  - [x] `onAddCard: { showAddCard = true }`
  - [x] `onViewExpiring: { showExpiringList = true }`
  - [x] `onViewAllCards: { selectedTab = .wallet }`
  - [x] `onSettings: { selectedTab = .settings }`
- [x] Update ExpiringBenefitsSectionView (lines 229-233):
  - [x] `onBenefitTap: { benefit in selectedCardId = benefit.cardId }`
  - [x] `onSeeAll: { showExpiringList = true }`
- [x] Add sheet modifiers:
  ```swift
  .sheet(isPresented: $showAddCard) { AddCardView() }
  .sheet(isPresented: $showExpiringList) { ExpiringBenefitsListView(viewModel: viewModel!) }
  .navigationDestination(item: $selectedCardId) { id in CardDetailView(cardId: id) }
  ```
- [x] Pass `selectedTab` binding from ContentView parent
- [x] Build and test navigation flows

### Verification:
- [x] "Add Card" button opens AddCardView sheet
- [x] "View Expiring" opens ExpiringBenefitsListView
- [x] "View All Cards" switches to Wallet tab
- [x] "Settings" switches to Settings tab
- [x] Benefit tap navigates to card detail

---

## STEP 2: Create ExpiringBenefitsListView (PARALLEL-SAFE: YES)

**Priority:** Critical
**Depends on:** Nothing (can run parallel with Step 3)
**New File:** `ios/CouponTracker/Sources/Features/Home/ExpiringBenefitsListView.swift`

### Agent Delegation:
```
Task: Create ExpiringBenefitsListView component
File: ios/CouponTracker/Sources/Features/Home/ExpiringBenefitsListView.swift
Pattern: Follow ExpiringBenefitsSectionView structure
```

### Tasks:
- [x] Create new file with view structure
- [x] Accept `[BenefitDisplayable]` or HomeViewModel as dependency
- [x] Implement grouped List sections:
  - [x] "Expiring Today" section
  - [x] "This Week" section (1-7 days)
  - [x] "This Month" section (8-30 days)
- [x] Add swipe actions for mark-as-done
- [x] Add tap navigation to card detail
- [x] Add empty state ("All Clear!" message)
- [x] Add accessibility labels
- [x] Create SwiftUI previews (3+ states)

### Verification:
- [x] Previews render correctly
- [x] Groups sort by urgency
- [x] Swipe action triggers (visually)

---

## STEP 3: Add HomeViewModel Properties (PARALLEL-SAFE: YES)

**Priority:** High
**Depends on:** Nothing (can run parallel with Step 2)
**File:** `ios/CouponTracker/Sources/Features/Home/HomeViewModel.swift`

### Agent Delegation:
```
Task: Add computed properties to HomeViewModel
File: ios/CouponTracker/Sources/Features/Home/HomeViewModel.swift
Properties needed: see list below
```

### Tasks:
- [x] Add `benefitsByCategory: [BenefitCategory: Decimal]`:
  ```swift
  var benefitsByCategory: [BenefitCategory: Decimal] {
      Dictionary(grouping: allDisplayBenefits, by: { $0.category })
          .mapValues { benefits in
              benefits.reduce(Decimal.zero) { $0 + $1.value }
          }
  }
  ```
- [x] Add expiring benefit filters:
  ```swift
  var benefitsExpiringToday: [any BenefitDisplayable] {
      allDisplayBenefits.filter { $0.daysRemaining == 0 }
  }
  var benefitsExpiringThisWeek: [any BenefitDisplayable] {
      allDisplayBenefits.filter { $0.daysRemaining > 0 && $0.daysRemaining <= 7 }
  }
  var benefitsExpiringThisMonth: [any BenefitDisplayable] {
      allDisplayBenefits.filter { $0.daysRemaining > 7 && $0.daysRemaining <= 30 }
  }
  ```
- [x] Add monthly tracking:
  ```swift
  var expiredValueThisMonth: Decimal { /* sum expired benefits this month */ }
  var availableValueThisMonth: Decimal { /* sum available benefits expiring this month */ }
  ```
- [x] Add refresh tracking:
  ```swift
  private(set) var lastRefreshed: Date?
  var lastRefreshedText: String? {
      guard let date = lastRefreshed else { return nil }
      let formatter = RelativeDateTimeFormatter()
      formatter.unitsStyle = .abbreviated
      return "Updated \(formatter.localizedString(for: date, relativeTo: Date()))"
  }
  ```
- [x] Update `loadData()` to set `lastRefreshed = Date()`

### Verification:
- [x] Build succeeds
- [x] Write unit tests for new properties

---

## STEP 4: Task 5 - InsightBannerView (PARALLEL-SAFE: YES)

**Priority:** Medium
**Depends on:** Step 3 (needs ViewModel properties)
**New File:** `ios/CouponTracker/Sources/Features/Home/Components/InsightBannerView.swift`

### Agent Delegation:
```
Task: Create InsightBannerView component for dashboard
Reference: dashboard-tasks.md Task 5 specification
Pattern: Follow BenefitCategoryChartView structure
```

### Tasks:
- [x] Create `DashboardInsight` enum in file:
  ```swift
  enum DashboardInsight: Identifiable {
      case urgentExpiring(value: Decimal, count: Int)
      case monthlySuccess(value: Decimal)
      case availableValue(value: Decimal)
      case onboarding

      var id: String { /* unique id */ }
      var icon: String { /* SF Symbol */ }
      var backgroundColor: Color { /* themed color */ }
      var message: String { /* formatted message */ }
  }
  ```
- [x] Create `InsightBannerView`:
  - [x] HStack: icon + message + optional dismiss button
  - [x] Background with color opacity
  - [x] Rounded corners (DesignSystem.Sizing)
  - [x] Animation on appear/disappear
- [x] Add `currentInsight` computed property to HomeViewModel
- [x] Integrate into HomeTabView (above QuickActionsView)
- [x] Create SwiftUI previews for all insight types
- [x] Add VoiceOver accessibility

### Verification:
- [x] Previews show all 4 insight types
- [x] Banner appears with animation
- [x] Dismiss button works (if implemented)

---

## STEP 5: Task 6 - ValueBreakdownView (PARALLEL-SAFE: YES)

**Priority:** Medium
**Depends on:** Step 3 (needs ViewModel properties)
**New File:** `ios/CouponTracker/Sources/Features/Home/ValueBreakdownView.swift`

### Agent Delegation:
```
Task: Create ValueBreakdownView modal sheet
Reference: dashboard-tasks.md Task 6 specification
```

### Tasks:
- [x] Create modal view with NavigationStack
- [x] Add Section "By Card":
  - [x] ForEach displayCards
  - [x] Mini gradient icon + name + value
  - [x] Tap to navigate
- [x] Add Section "By Category":
  - [x] Use benefitsByCategory from ViewModel
  - [x] Color dot + category name + value
- [x] Add Section "By Time Period":
  - [x] "This Week" + value
  - [x] "This Month" + value
  - [x] "Future" + remaining value
- [x] Add "Done" toolbar button to dismiss
- [x] Create SwiftUI previews
- [x] Wire to HomeTabView (tap on dashboardSummary)

### Verification:
- [x] Modal opens from dashboard tap
- [x] All sections populated with data
- [x] Done button dismisses modal

---

## STEP 6: Task 7 & 8 - Pull-to-Refresh & Empty State (PARALLEL-SAFE: YES)

**Priority:** Low
**Depends on:** Step 3 (lastRefreshed property)
**Files:** `ContentView.swift`

### Tasks for Pull-to-Refresh:
- [x] Add toolbar subtitle showing lastRefreshedText
- [x] Add haptic feedback (UINotificationFeedbackGenerator) on refresh complete

### Tasks for Empty State Enhancement:
- [x] Update quickStats function in ContentView
- [x] Add `.symbolEffect(.pulse)` to icon
- [x] Update headline: "Start Tracking Your Benefits"
- [x] Add descriptive subtext
- [x] Create styled CTA button
- [x] Wire button to trigger AddCardView

### Verification:
- [x] Timestamp updates on pull-to-refresh
- [x] Empty state shows animation
- [x] CTA button works

---

## STEP 7: Polish Existing Components (PARALLEL-SAFE: YES - Each file separate)

### 7A: QuickActionsView Haptic Feedback
**File:** `ios/CouponTracker/Sources/Features/Home/Components/QuickActionsView.swift`
- [x] Add `UIImpactFeedbackGenerator(style: .light).impactOccurred()` on tap

### 7B: ExpiringBenefitsSectionView Collapsible Headers
**File:** `ios/CouponTracker/Sources/Features/Home/Components/ExpiringBenefitsSectionView.swift`
- [x] Add @State for section expansion
- [x] Wrap sections in DisclosureGroup or custom collapsible
- [x] Add swipe-to-mark-done on rows

### 7C: MonthlyProgressCardView Segmented Bar
**File:** `ios/CouponTracker/Sources/Features/Home/Components/MonthlyProgressCardView.swift`
- [x] Refactor to show 3-segment progress (used/available/expired)
- [x] Add legend with breakdown values
- [x] Add onTap callback for modal trigger

---

## Parallel Execution Guide

### Can Run Together:
- Step 2 + Step 3 (no dependencies)
- Step 4 + Step 5 (both need Step 3, but don't conflict)
- All Step 7 subtasks (different files)

### Must Run Sequential:
- Step 1 → then Step 2's integration
- Step 3 → then Steps 4, 5, 6

### Agent Delegation Example:
```
Launch parallel agents for:
1. Agent A: Step 2 (ExpiringBenefitsListView)
2. Agent B: Step 3 (HomeViewModel properties)

Wait for completion, then:
3. Agent C: Step 4 (InsightBannerView)
4. Agent D: Step 5 (ValueBreakdownView)
```

---

## Files Modified Summary

| Step | File | Action |
|------|------|--------|
| 1 | ContentView.swift | Edit |
| 2 | ExpiringBenefitsListView.swift | Create |
| 3 | HomeViewModel.swift | Edit |
| 4 | InsightBannerView.swift | Create |
| 5 | ValueBreakdownView.swift | Create |
| 6 | ContentView.swift | Edit |
| 7A | QuickActionsView.swift | Edit |
| 7B | ExpiringBenefitsSectionView.swift | Edit |
| 7C | MonthlyProgressCardView.swift | Edit |

---

## Verification Checklist (Final)

- [x] Build succeeds with no errors
- [x] All SwiftUI previews render
- [x] Navigation: QuickActions all work
- [x] Navigation: Expiring benefit tap → card detail
- [x] Navigation: See All → expiring list
- [x] Empty state shows animation + CTA works
- [x] Pull-to-refresh shows timestamp
- [x] Insight banner appears when conditions met
- [x] Value breakdown modal opens from dashboard
- [x] Run unit tests: HomeViewModelTests pass
