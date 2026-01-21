# Dashboard Enhancement Tasks

**Document Version:** 1.0
**Created:** January 17, 2026
**Author:** Senior Engineer
**Status:** Ready for Assignment

---

## Overview

This document contains detailed task specifications for enhancing the CouponTracker dashboard (HomeTabView). Each task is designed to be completed independently by junior engineers. Tasks are organized by priority and complexity.

### Current State

The dashboard currently displays:
- Total available value (large number)
- Card count stat card
- Expiring benefits count stat card
- List of expiring benefits (top 5)
- Empty state for new users

### Target State

An enhanced dashboard with:
- Visual charts showing benefit distribution
- Quick actions for common tasks
- Better benefit categorization and insights
- Navigation to expiring benefits
- Monthly tracking and progress visualization

---

## Architecture Reference

### Required Patterns

All implementations MUST follow these patterns:

1. **MVVM Architecture**
   - Views are stateless UI components
   - ViewModels use `@Observable` macro and `@MainActor`
   - Business logic lives in ViewModels, not Views

2. **Display Protocols (ADR-001)**
   - Use `CardDisplayable` and `BenefitDisplayable` protocols
   - Never expose SwiftData entities directly to views
   - Use `DisplayAdapters` for data transformation

3. **Design System**
   - All colors: `DesignSystem.Colors.*`
   - All typography: `DesignSystem.Typography.*`
   - All spacing: `DesignSystem.Spacing.*`
   - All sizing: `DesignSystem.Sizing.*`

### Key Files Reference

| Purpose | File Path |
|---------|-----------|
| Dashboard View | `Sources/App/ContentView.swift` (HomeTabView, lines 193-337) |
| Dashboard ViewModel | `Sources/Features/Home/HomeViewModel.swift` |
| Display Protocols | `Sources/Core/Protocols/DisplayProtocols.swift` |
| Display Adapters | `Sources/Core/Adapters/DisplayAdapters.swift` |
| Design System | `Sources/Core/Extensions/DesignSystem.swift` |
| Existing Summary Card | `Sources/Features/Common/Views/ValueSummaryCard.swift` |
| Benefit Row Component | `Sources/Features/Home/Components/BenefitRowView.swift` |

---

## Task 1: Benefit Category Chart Component

**Priority:** High
**Estimated Effort:** 4-6 hours
**Assignee:** _________________

### Description

Create a pie/donut chart component that visualizes benefits by category. Users should see at a glance how their available value is distributed across Travel, Dining, Streaming, etc.

### Acceptance Criteria

- [ ] Chart displays benefit categories with proportional segments
- [ ] Each segment is colored according to category
- [ ] Center of donut shows total available value
- [ ] Legend shows category names, colors, and values
- [ ] Empty state displays when no benefits exist
- [ ] Tapping a segment highlights it and shows category details
- [ ] Supports both light and dark mode
- [ ] Includes SwiftUI previews for all states
- [ ] Accessibility: VoiceOver reads chart summary and each segment

### Technical Specification

**New File:** `Sources/Features/Home/Components/CategoryChartView.swift`

**Data Source:** Add computed property to `HomeViewModel`:
```swift
var benefitsByCategory: [BenefitCategory: Decimal] {
    // Group available benefits by category
    // Sum values for each category
}
```

**Category Colors:** Use these from DesignSystem (add if needed):
- Travel: `DesignSystem.Colors.primaryFallback` (blue)
- Dining: `Color(hex: "#FF6B35")` (orange)
- Streaming: `Color(hex: "#9B59B6")` (purple)
- Shopping: `Color(hex: "#27AE60")` (green)
- Entertainment: `Color(hex: "#E74C3C")` (red)
- Other: `DesignSystem.Colors.neutral` (gray)

**View Structure:**
```swift
struct CategoryChartView: View {
    let categoryData: [BenefitCategory: Decimal]
    let totalValue: Decimal
    var onCategoryTap: ((BenefitCategory) -> Void)? = nil

    var body: some View {
        // Implementation
    }
}
```

### Reference Code

See `ValueProgressRing` in `ValueSummaryCard.swift` (lines 297-348) for circular chart drawing patterns.

### Testing Requirements

- Unit test: Verify category grouping logic in ViewModel
- Preview: Show chart with 2, 4, and 6 categories
- Preview: Empty state
- Preview: Dark mode variant

---

## Task 2: Quick Actions Section

**Priority:** High
**Estimated Effort:** 3-4 hours
**Assignee:** _________________

### Description

Add a horizontal scrollable row of quick action buttons below the summary card. These provide one-tap access to common actions.

### Acceptance Criteria

- [ ] Horizontal scroll view with 4+ quick action buttons
- [ ] Actions: "Add Card", "View Expiring", "Mark All Read", "Settings"
- [ ] Each button has an icon and label
- [ ] Buttons use consistent styling from DesignSystem
- [ ] Haptic feedback on tap (UIImpactFeedbackGenerator)
- [ ] Actions trigger appropriate navigation or sheets
- [ ] Accessible with VoiceOver
- [ ] Includes SwiftUI previews

### Technical Specification

**New File:** `Sources/Features/Home/Components/QuickActionsView.swift`

**View Structure:**
```swift
struct QuickActionsView: View {
    var onAddCard: () -> Void
    var onViewExpiring: () -> Void
    var onMarkAllRead: (() -> Void)? = nil
    var onOpenSettings: () -> Void

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: DesignSystem.Spacing.md) {
                QuickActionButton(icon: "plus.circle.fill", label: "Add Card", action: onAddCard)
                QuickActionButton(icon: "clock.badge.exclamationmark", label: "Expiring", action: onViewExpiring)
                // ... more buttons
            }
            .padding(.horizontal, DesignSystem.Spacing.lg)
        }
    }
}

struct QuickActionButton: View {
    let icon: String
    let label: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: DesignSystem.Spacing.xs) {
                Image(systemName: icon)
                    .font(.system(size: 24))
                Text(label)
                    .font(DesignSystem.Typography.caption)
            }
            .frame(width: 72, height: 72)
            .background(DesignSystem.Colors.backgroundSecondary)
            .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Sizing.buttonCornerRadius))
        }
        .buttonStyle(.plain)
    }
}
```

**Integration in HomeTabView:**
Add below `dashboardSummary` section:
```swift
QuickActionsView(
    onAddCard: { /* navigate to add card */ },
    onViewExpiring: { /* navigate to expiring list */ },
    onOpenSettings: { /* switch to settings tab */ }
)
```

### Reference Code

See `StatCard` in `ContentView.swift` (lines 340-366) for similar button styling.

---

## Task 3: Expiring Benefits Section Enhancement

**Priority:** High
**Estimated Effort:** 4-5 hours
**Assignee:** _________________

### Description

Enhance the "Expiring Soon" section with better grouping, a "See All" button, and navigation to a full expiring benefits list.

### Acceptance Criteria

- [ ] Section header shows count badge: "Expiring Soon (5)"
- [ ] "See All" button navigates to full list when >5 items
- [ ] Benefits grouped by urgency: "Today", "This Week", "This Month"
- [ ] Each group has collapsible header
- [ ] Tapping a benefit row navigates to card detail
- [ ] Swipe-to-mark-done works on each row
- [ ] Empty state: "No benefits expiring soon" with checkmark icon
- [ ] Includes SwiftUI previews for all states

### Technical Specification

**Modify Files:**
- `Sources/App/ContentView.swift` - Update `expiringSoonSection`
- `Sources/Features/Home/HomeViewModel.swift` - Add grouped benefits

**New File:** `Sources/Features/Home/ExpiringBenefitsListView.swift`

**ViewModel Additions:**
```swift
// Add to HomeViewModel
var benefitsExpiringToday: [ExpiringBenefitDisplayAdapter] {
    displayExpiringBenefits.filter { $0.benefit.daysRemaining == 0 }
}

var benefitsExpiringThisWeek: [ExpiringBenefitDisplayAdapter] {
    displayExpiringBenefits.filter { $0.benefit.daysRemaining > 0 && $0.benefit.daysRemaining <= 7 }
}

var benefitsExpiringThisMonth: [ExpiringBenefitDisplayAdapter] {
    displayExpiringBenefits.filter { $0.benefit.daysRemaining > 7 && $0.benefit.daysRemaining <= 30 }
}
```

**Section Header Pattern:**
```swift
HStack {
    Text("Expiring Soon")
        .font(DesignSystem.Typography.title3)

    Text("\(viewModel.displayExpiringBenefits.count)")
        .font(DesignSystem.Typography.badge)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(DesignSystem.Colors.warning)
        .foregroundStyle(.white)
        .clipShape(Capsule())

    Spacer()

    if viewModel.displayExpiringBenefits.count > 5 {
        NavigationLink("See All") {
            ExpiringBenefitsListView(viewModel: viewModel)
        }
        .font(DesignSystem.Typography.subhead)
    }
}
```

### Reference Code

See existing `expiringSoonSection` in `ContentView.swift` (lines 277-313) and `CompactBenefitRowView` in `BenefitRowView.swift` (lines 421-493).

---

## Task 4: Monthly Progress Card

**Priority:** Medium
**Estimated Effort:** 3-4 hours
**Assignee:** _________________

### Description

Add a card showing this month's benefit redemption progress. Shows how much has been used vs. available with a progress bar.

### Acceptance Criteria

- [ ] Card shows current month name
- [ ] Horizontal progress bar: Used (green) | Available (blue) | Expired (gray)
- [ ] Legend with values for each segment
- [ ] Percentage text: "67% redeemed this month"
- [ ] Tapping card shows monthly breakdown modal
- [ ] Graceful handling when no benefits exist
- [ ] Supports light and dark mode
- [ ] Includes SwiftUI previews

### Technical Specification

**Integration:** Use existing `MonthlySummaryCard` from `ValueSummaryCard.swift` (lines 353-418) as the base component.

**ViewModel Additions to `HomeViewModel`:**
```swift
var currentMonthName: String {
    let formatter = DateFormatter()
    formatter.dateFormat = "MMMM yyyy"
    return formatter.string(from: Date())
}

var usedValueThisMonth: Decimal {
    // Sum of benefits marked as used where usedDate is in current month
}

var expiredValueThisMonth: Decimal {
    // Sum of benefits that expired this month without being used
}

var availableValueThisMonth: Decimal {
    // Sum of currently available benefits expiring this month
}

var redemptionPercentage: Double {
    let total = usedValueThisMonth + expiredValueThisMonth + availableValueThisMonth
    guard total > 0 else { return 0 }
    return Double(truncating: (usedValueThisMonth / total * 100) as NSDecimalNumber)
}
```

**Add to HomeTabView body, after quickStats:**
```swift
if !viewModel.isEmpty {
    MonthlySummaryCard(
        monthName: viewModel.currentMonthName,
        availableValue: viewModel.availableValueThisMonth,
        usedValue: viewModel.usedValueThisMonth,
        expiredValue: viewModel.expiredValueThisMonth
    )
}
```

### Reference Code

See `MonthlySummaryCard` in `ValueSummaryCard.swift` (lines 353-418) for the existing implementation.

---

## Task 5: Dashboard Insights Banner

**Priority:** Medium
**Estimated Effort:** 2-3 hours
**Assignee:** _________________

### Description

Add contextual insight banners that highlight actionable information based on the user's data.

### Acceptance Criteria

- [ ] Shows relevant insight based on current state
- [ ] Insight types:
  - "You have $X expiring today!" (urgent, red)
  - "Great job! You've redeemed $X this month" (success, green)
  - "$X in benefits available" (neutral, blue)
  - "Add your first card to get started" (onboarding)
- [ ] Dismissible with X button (stores in UserPreferences)
- [ ] Maximum one insight shown at a time (priority order)
- [ ] Smooth appear/disappear animation
- [ ] Accessible with VoiceOver

### Technical Specification

**New File:** `Sources/Features/Home/Components/InsightBannerView.swift`

**Insight Model:**
```swift
enum DashboardInsight: Identifiable {
    case urgentExpiring(value: Decimal)
    case monthlySuccess(value: Decimal)
    case availableValue(value: Decimal)
    case onboarding

    var id: String {
        switch self {
        case .urgentExpiring: return "urgent"
        case .monthlySuccess: return "success"
        case .availableValue: return "available"
        case .onboarding: return "onboarding"
        }
    }

    var icon: String { /* SF Symbol name */ }
    var backgroundColor: Color { /* appropriate color */ }
    var message: String { /* formatted message */ }
}
```

**ViewModel Addition:**
```swift
var currentInsight: DashboardInsight? {
    // Return highest priority insight based on current data
    if let expiringToday = benefitsExpiringToday.first {
        let totalToday = benefitsExpiringToday.reduce(0) { $0 + $1.benefit.value }
        return .urgentExpiring(value: totalToday)
    }
    // ... more priority checks
}
```

**View Structure:**
```swift
struct InsightBannerView: View {
    let insight: DashboardInsight
    var onDismiss: (() -> Void)? = nil

    var body: some View {
        HStack {
            Image(systemName: insight.icon)
            Text(insight.message)
                .font(DesignSystem.Typography.subhead)
            Spacer()
            if onDismiss != nil {
                Button(action: { onDismiss?() }) {
                    Image(systemName: "xmark")
                }
            }
        }
        .padding(DesignSystem.Spacing.md)
        .background(insight.backgroundColor.opacity(0.15))
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Sizing.buttonCornerRadius))
    }
}
```

---

## Task 6: Value Breakdown Modal

**Priority:** Medium
**Estimated Effort:** 3-4 hours
**Assignee:** _________________

### Description

Create a modal sheet that shows detailed breakdown of total value by card, category, and time period.

### Acceptance Criteria

- [ ] Triggered by tapping "See breakdown" on summary card
- [ ] Shows three sections: By Card, By Category, By Period
- [ ] By Card: List of cards with their available values
- [ ] By Category: Same data as category chart in list form
- [ ] By Period: This week, This month, Future
- [ ] Tapping a card navigates to card detail
- [ ] Close button in navigation bar
- [ ] Includes SwiftUI previews

### Technical Specification

**New File:** `Sources/Features/Home/ValueBreakdownView.swift`

**View Structure:**
```swift
struct ValueBreakdownView: View {
    @Environment(\.dismiss) private var dismiss
    let viewModel: HomeViewModel

    var body: some View {
        NavigationStack {
            List {
                Section("By Card") {
                    ForEach(viewModel.displayCards, id: \.id) { card in
                        HStack {
                            // Card mini icon
                            RoundedRectangle(cornerRadius: 4)
                                .fill(card.gradient.gradient)
                                .frame(width: 32, height: 20)

                            Text(card.displayName)
                            Spacer()
                            Text(card.formattedTotalValue)
                                .font(DesignSystem.Typography.headline)
                        }
                    }
                }

                Section("By Category") {
                    // Category breakdown rows
                }

                Section("By Time Period") {
                    // This week / This month / Future rows
                }
            }
            .navigationTitle("Value Breakdown")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}
```

**Integration in HomeTabView:**
```swift
@State private var showBreakdown = false

// In dashboardSummary, pass callback:
ValueSummaryCard(
    // ... existing params
    onTapBreakdown: { showBreakdown = true }
)
.sheet(isPresented: $showBreakdown) {
    ValueBreakdownView(viewModel: viewModel)
}
```

---

## Task 7: Pull-to-Refresh Enhancement

**Priority:** Low
**Estimated Effort:** 1-2 hours
**Assignee:** _________________

### Description

Enhance the existing pull-to-refresh with better visual feedback and a "Last updated" timestamp.

### Acceptance Criteria

- [ ] Custom refresh indicator with app icon or custom animation
- [ ] Shows "Last updated: 2 min ago" below navigation title
- [ ] Timestamp updates automatically
- [ ] Success haptic feedback when refresh completes
- [ ] Loading state shows on summary card during refresh

### Technical Specification

**Modify:** `Sources/Features/Home/HomeViewModel.swift`

**Add to ViewModel:**
```swift
private(set) var lastRefreshed: Date?

var lastRefreshedText: String? {
    guard let date = lastRefreshed else { return nil }
    let formatter = RelativeDateTimeFormatter()
    formatter.unitsStyle = .abbreviated
    return "Updated \(formatter.localizedString(for: date, relativeTo: Date()))"
}

func loadData() async {
    // ... existing code
    lastRefreshed = Date()
}
```

**Add to HomeTabView:**
```swift
.toolbar {
    ToolbarItem(placement: .principal) {
        VStack(spacing: 0) {
            Text("Dashboard")
                .font(DesignSystem.Typography.headline)
            if let lastUpdated = viewModel?.lastRefreshedText {
                Text(lastUpdated)
                    .font(DesignSystem.Typography.caption)
                    .foregroundStyle(DesignSystem.Colors.textTertiary)
            }
        }
    }
}
```

---

## Task 8: Empty State Enhancement

**Priority:** Low
**Estimated Effort:** 2-3 hours
**Assignee:** _________________

### Description

Improve the empty state UI when the user has no cards, making it more engaging and actionable.

### Acceptance Criteria

- [ ] Animated illustration (or SF Symbol animation)
- [ ] Clear headline: "Start tracking your benefits"
- [ ] Subtext explaining value proposition
- [ ] Prominent "Add Your First Card" button
- [ ] Optional: "Explore Features" secondary action
- [ ] Accessible with VoiceOver

### Technical Specification

**Modify:** `Sources/App/ContentView.swift` - `quickStats` function (lines 317-336)

**Enhanced Empty State:**
```swift
@ViewBuilder
private func emptyStateView() -> some View {
    VStack(spacing: DesignSystem.Spacing.xl) {
        // Animated icon
        Image(systemName: "creditcard.fill")
            .font(.system(size: 80))
            .foregroundStyle(DesignSystem.Colors.primaryFallback)
            .symbolEffect(.pulse)

        VStack(spacing: DesignSystem.Spacing.sm) {
            Text("Start Tracking Your Benefits")
                .font(DesignSystem.Typography.title2)
                .foregroundStyle(DesignSystem.Colors.textPrimary)

            Text("Add your credit cards and never miss a reward again. We'll remind you before benefits expire.")
                .font(DesignSystem.Typography.body)
                .foregroundStyle(DesignSystem.Colors.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, DesignSystem.Spacing.xl)
        }

        Button(action: { /* trigger add card */ }) {
            HStack {
                Image(systemName: "plus.circle.fill")
                Text("Add Your First Card")
            }
            .font(DesignSystem.Typography.headline)
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, DesignSystem.Spacing.md)
            .background(DesignSystem.Colors.primaryFallback)
            .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Sizing.buttonCornerRadius))
        }
        .padding(.horizontal, DesignSystem.Spacing.xl)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .padding(.vertical, DesignSystem.Spacing.xxl)
}
```

---

## Testing Guidelines

### Unit Testing

All ViewModel computed properties must have unit tests:

```swift
// Example test structure
final class HomeViewModelTests: XCTestCase {
    var viewModel: HomeViewModel!
    var mockCardRepo: MockCardRepository!
    var mockBenefitRepo: MockBenefitRepository!

    override func setUp() {
        super.setUp()
        mockCardRepo = MockCardRepository()
        mockBenefitRepo = MockBenefitRepository()
        viewModel = HomeViewModel(
            cardRepository: mockCardRepo,
            benefitRepository: mockBenefitRepo,
            templateLoader: MockTemplateLoader()
        )
    }

    func testBenefitsByCategory_groupsCorrectly() async {
        // Given: benefits with different categories
        // When: accessing benefitsByCategory
        // Then: values are grouped and summed correctly
    }
}
```

### Preview Testing

Every new view must include previews for:
1. Normal state with realistic data
2. Empty/no data state
3. Edge cases (single item, many items)
4. Dark mode
5. Dynamic type (accessibility sizes)

### Integration Testing

Before marking complete:
- [ ] Navigate through all new UI paths
- [ ] Test all tap/swipe interactions
- [ ] Verify data updates correctly after actions
- [ ] Test pull-to-refresh updates new components
- [ ] Verify VoiceOver navigation

---

## Code Review Checklist

Before submitting PR, ensure:

- [ ] All files have proper header comments with purpose
- [ ] No force unwrapping (`!`) without justification
- [ ] All strings are user-facing (consider localization later)
- [ ] No hardcoded colors - use DesignSystem
- [ ] No hardcoded spacing - use DesignSystem.Spacing
- [ ] All public interfaces documented
- [ ] SwiftUI previews included and working
- [ ] Accessibility labels added for VoiceOver
- [ ] No SwiftData entities exposed to views directly
- [ ] Unit tests written for new ViewModel logic

---

## Questions / Clarifications

If you have questions about:
- **Architecture**: Consult ADR-001 or ask Senior Engineer
- **Design**: Check DesignSystem.swift or Figma mockups
- **Data Flow**: Review HomeViewModel.swift patterns
- **Existing Components**: Check Features/Common/Views and Features/Home/Components

---

## Task Assignment Tracking

| Task | Assignee | Status | Completed | Notes |
|------|----------|--------|-----------|-------|
| Task 1: Category Chart | - | Complete | Jan 18, 2026 | BenefitCategoryChartView.swift |
| Task 2: Quick Actions | - | Complete | Jan 18, 2026 | Integrated in CardDetailView |
| Task 3: Expiring Section | - | Complete | Jan 18, 2026 | ExpiringBenefitsListView.swift |
| Task 4: Monthly Progress | - | Complete | Jan 18, 2026 | MonthlyProgressCardView.swift |
| Task 5: Insight Banner | - | Complete | Jan 18, 2026 | InsightBannerView.swift |
| Task 6: Value Breakdown | - | Complete | Jan 18, 2026 | ValueBreakdownView.swift |
| Task 7: Pull-to-Refresh | - | Complete | Jan 18, 2026 | Added to HomeTabView |
| Task 8: Empty State | - | Complete | Jan 18, 2026 | In HomeTabView.quickStats |

---

## Phase 3 Status (January 19, 2026)

### Completed Today:
- A1: Notification deep linking (wired up callbacks to UI navigation)
- A2: Multi-page onboarding flow with card selection
- A3: Enhanced settings view with support/data sections
- B1: NotificationService unit tests
- C1: Card nickname editing (EditCardSheet)
- C2: Accomplishment rings (AchievementRing, AccomplishmentRingsView)

### Architecture Notes:
- Deep linking uses NotificationCenter to post navigation events
- Onboarding uses TabView with custom page indicators
- Settings now includes data reset with confirmation dialogs

---

*Document maintained by Senior Engineer. Last updated: January 19, 2026*
