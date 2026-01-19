# CouponTracker Design Document

**Version:** 1.0
**Last Updated:** January 16, 2026
**Status:** Draft
**Design Owner:** [TBD]

---

## Table of Contents

1. [Design Vision](#design-vision)
2. [Information Architecture](#information-architecture)
3. [Core User Flows](#core-user-flows)
4. [Screen Inventory](#screen-inventory)
5. [Component Specifications](#component-specifications)
6. [Visual Design System](#visual-design-system)
7. [Interaction Patterns](#interaction-patterns)
8. [Accessibility Requirements](#accessibility-requirements)
9. [Technical Design Considerations](#technical-design-considerations)
10. [Appendix](#appendix)

---

## Design Vision

### Design Principles

1. **Clarity First**
   - Information hierarchy prioritizes urgency and actionability
   - Status is always immediately apparent (available/used/expired)
   - No hidden functionality - common actions are always visible

2. **Delight Through Visuals**
   - Card artwork creates emotional connection
   - Wallet metaphor feels natural and intuitive
   - Smooth animations reinforce actions and state changes

3. **Minimal Friction**
   - One-tap actions for common tasks
   - Inline editing where possible
   - Smart defaults reduce setup burden

4. **Trustworthy and Premium**
   - Design reflects the premium nature of the cards being tracked
   - Professional aesthetic appropriate for financial content
   - Consistent, polished interactions build confidence

### Design Goals

- **Immediate Value Recognition:** Users understand available rewards within 3 seconds of opening the app
- **Effortless Maintenance:** Marking benefits as used takes under 2 seconds
- **Proactive Guidance:** The app surfaces what needs attention without requiring exploration
- **Visual Satisfaction:** Marking benefits as used feels rewarding

---

## Information Architecture

### IA Overview

```
CouponTracker
|
+-- Dashboard (Home)
|   +-- Value Summary Card
|   +-- Expiring Soon Section
|   +-- Recently Used Section
|   +-- Quick Actions
|
+-- Wallet
|   +-- Card Stack View
|   +-- Card Detail View
|       +-- Card Header
|       +-- Benefits List
|           +-- Available Benefits
|           +-- Used Benefits
|           +-- Expired Benefits
|       +-- Card Actions
|
+-- Add Card
|   +-- Popular Cards Browser
|       +-- Card Search
|       +-- Card Categories (by Issuer)
|       +-- Card Detail/Preview
|   +-- Custom Card Form
|       +-- Card Info Step
|       +-- Benefits Setup Step
|
+-- Notifications Center
|   +-- Pending Reminders
|   +-- Notification History
|
+-- Settings
    +-- Notification Preferences
    +-- Card Database Info
    +-- App Preferences
    +-- About/Help
```

### Content Prioritization

| Priority | Content Type | Rationale |
|----------|--------------|-----------|
| 1 | Expiring Benefits (< 7 days) | Highest urgency, requires immediate action |
| 2 | Available Benefits Summary | Core value proposition visibility |
| 3 | Individual Card Status | Secondary detail for browsing |
| 4 | Used/Expired Benefits | Historical reference, lower priority |
| 5 | Settings/Configuration | Infrequent access needs |

### Navigation Model

**Primary Navigation:** Tab bar with 3 main destinations
1. **Home** - Dashboard with summary and urgent items
2. **Wallet** - Card collection and management
3. **Settings** - App configuration

**Secondary Navigation:**
- Modal presentations for Add Card flows
- Push navigation for Card Detail from Wallet
- Sheet presentations for quick actions

---

## Core User Flows

### Flow 1: First-Time Onboarding

```
[App Launch]
    |
    v
[Welcome Screen 1: Value Proposition]
    | "Never miss a credit card reward again"
    v
[Welcome Screen 2: How It Works]
    | "Track your cards, get timely reminders"
    v
[Card Selection Screen]
    | Display popular cards grid
    | User selects their cards (multi-select)
    v
[Notification Permission Request]
    | Explain why notifications matter
    | Request permission
    v
[Setup Complete Screen]
    | Show summary of added cards
    | "You're tracking $X in monthly rewards"
    v
[Dashboard (Home)]
```

**Key Decision Points:**
- Skip button available on all screens
- Can proceed without selecting cards
- Can deny notifications and continue
- Onboarding state persisted; never shown again

---

### Flow 2: Mark Benefit as Used

```
[Dashboard or Card Detail]
    | View benefit card
    v
[Tap "Mark as Done" button]
    |
    v
[Confirmation Sheet]
    | "Mark $15 Uber credit as used?"
    | [Cancel] [Confirm]
    v (on Confirm)
[Success Animation]
    | Checkmark animation
    | Benefit slides to "Used" section
    v
[Updated UI State]
    | Available value decreases
    | Benefit shows usage date
```

**Alternate Path - Quick Undo:**
```
[After Success Animation]
    | "Undo" button appears (10 seconds)
    v (on Undo tap)
[Benefit Restored]
    | Returns to Available state
    | No permanent change made
```

---

### Flow 3: Add Card from Database

```
[Tap "+" FAB or Add Card]
    |
    v
[Add Card Screen]
    | Two options: "Popular Cards" / "Custom Card"
    v (select Popular Cards)
[Card Browser]
    | Search bar at top
    | Cards grouped by issuer
    | Grid or list view toggle
    v (tap card)
[Card Preview Sheet]
    | Full card artwork
    | List of included benefits
    | Annual fee info
    | [Add to Wallet] button
    v (tap Add to Wallet)
[Success State]
    | "Amex Platinum added!"
    | "Tracking 6 benefits worth $849/year"
    | [View Card] [Add Another]
    v
[Wallet View or Add More]
```

---

### Flow 4: Respond to Notification

```
[Push Notification Received]
    | "Your $15 Uber credit expires in 3 days"
    |
    +-- (Tap notification) -------> [App opens to Benefit Detail]
    |
    +-- (Long press) -----> [Action Options]
                               | [Mark as Done]
                               | [Snooze 1 Day]
                               | [Snooze 1 Week]
                               | [View Details]
                               |
                               +-- (Mark as Done) --> [Background update + confirmation banner]
                               |
                               +-- (Snooze) --> [Reminder rescheduled + confirmation]
```

---

### Flow 5: Add Custom Card

```
[Add Card Screen]
    | Select "Custom Card"
    v
[Card Info Form]
    | Card Name (required)
    | Issuer (optional)
    | Card Color picker
    | [Continue]
    v
[Add Benefits Form]
    | Empty state: "Add your first benefit"
    | [+ Add Benefit] button
    v (tap Add Benefit)
[Benefit Form Sheet]
    | Benefit Name
    | Value ($)
    | Frequency dropdown (Monthly/Quarterly/Annual)
    | Next Due Date picker
    | [Save Benefit]
    v (on Save)
[Benefits List Updated]
    | Shows added benefit
    | Can add more or continue
    | [Save Card] button
    v
[Card Added Success]
```

---

### Flow 6: View and Manage Card

```
[Wallet View]
    | Tap on card in stack
    v
[Card Detail View]
    | Card artwork header
    | Benefit sections (Available/Used)
    | Swipe actions on benefits
    |
    +-- (Tap benefit) --> [Benefit Detail Sheet]
    |                      | Full details
    |                      | Edit option
    |                      | Reminder settings
    |
    +-- (Swipe benefit) --> [Quick Actions]
    |                        | Swipe right: Mark as Done
    |                        | Swipe left: Snooze
    |
    +-- (Tap overflow menu) --> [Card Actions]
                                 | Edit Card
                                 | Notification Settings
                                 | Remove Card
```

---

## Screen Inventory

### Phase 1 MVP Screens

| Screen | Purpose | Priority |
|--------|---------|----------|
| **Onboarding - Welcome** | Introduce app value proposition | P0 |
| **Onboarding - Card Selection** | Quick card setup | P0 |
| **Onboarding - Notifications** | Request notification permission | P0 |
| **Dashboard (Home)** | Summary view with urgent benefits | P0 |
| **Wallet - Card Stack** | Visual display of all cards | P0 |
| **Card Detail** | Full card info with benefits list | P0 |
| **Benefit Detail Sheet** | Individual benefit management | P0 |
| **Add Card - Browser** | Browse pre-populated cards | P0 |
| **Card Preview Sheet** | Preview card before adding | P0 |
| **Add Card - Custom Form** | Manual card entry | P1 |
| **Settings - Main** | App configuration hub | P1 |
| **Settings - Notifications** | Notification preferences | P1 |

### Phase 2 Additional Screens

| Screen | Purpose | Priority |
|--------|---------|----------|
| **Coupon List** | View all tracked coupons | P2 |
| **Add Coupon** | Manual coupon entry with camera | P2 |
| **Coupon Detail** | Individual coupon management | P2 |
| **Search/Filter** | Find specific cards/benefits | P2 |
| **History/Analytics** | Value captured over time | P2 |

---

## Component Specifications

### C1: Card Component (Wallet Card)

The primary visual representation of a credit card in the wallet.

**Anatomy:**
```
+------------------------------------------+
|  [Card Artwork/Gradient Background]      |
|                                          |
|  ISSUER LOGO                             |
|                                          |
|                                          |
|  CARD NAME                               |
|  Nickname (if set)                       |
|                                          |
|  +-----------------+  +----------------+ |
|  | $XX Available   |  | X Expiring     | |
|  +-----------------+  +----------------+ |
+------------------------------------------+
```

**States:**
- **Default:** Standard display with summary chips
- **Urgent:** Pulsing indicator when benefits expire within 3 days
- **All Used:** Subtle "check" overlay indicating all benefits used this period
- **Pressed:** Slight scale reduction (0.98) on tap

**Specifications:**
| Property | Value |
|----------|-------|
| Aspect Ratio | 1.586:1 (standard credit card ratio) |
| Corner Radius | 12pt |
| Shadow | 0 4pt 12pt rgba(0,0,0,0.15) |
| Min Width | 280pt |
| Max Width | Screen width - 32pt |
| Card Stack Offset | 8pt vertical overlap |

**Interactions:**
- Tap: Navigate to Card Detail
- Long press: Quick action menu
- Swipe left: Reveal delete action (with confirmation)

---

### C2: Benefit Row Component

Displays an individual benefit within a card.

**Anatomy:**
```
+--------------------------------------------------+
|  [Status Icon]  Benefit Name              $Value |
|                 Expires: Jan 31, 2026            |
|                                       [Action]   |
+--------------------------------------------------+
```

**Status Icon Variants:**
- Available: Green circle with checkmark outline
- Used: Filled green circle with checkmark
- Expired: Gray circle with X
- Expiring Soon: Orange/red circle with exclamation

**States:**
- **Available:** Full opacity, action button visible
- **Used:** Reduced opacity (0.7), shows usage date
- **Expired:** Reduced opacity (0.5), strikethrough on value
- **Expiring (< 7 days):** Highlighted background, days remaining badge

**Specifications:**
| Property | Value |
|----------|-------|
| Row Height | 72pt (expandable) |
| Padding | 16pt horizontal, 12pt vertical |
| Icon Size | 24pt |
| Swipe Threshold | 80pt |

**Interactions:**
- Tap: Expand to show full details
- Swipe right: Mark as done (green action)
- Swipe left: Snooze options (blue action)

---

### C3: Value Summary Card

Dashboard component showing total available value.

**Anatomy:**
```
+------------------------------------------+
|  Total Available                         |
|  $847                                    |
|  Across 4 cards                          |
|                                          |
|  [Progress ring or illustration]         |
|                                          |
|  This month: $320 redeemed               |
+------------------------------------------+
```

**Specifications:**
| Property | Value |
|----------|-------|
| Card Height | Auto (content-based) |
| Corner Radius | 16pt |
| Background | Gradient or solid accent |
| Value Font | SF Pro Display Bold, 48pt |

---

### C4: Expiring Soon Item

Compact display of an expiring benefit for dashboard.

**Anatomy:**
```
+------------------------------------------+
|  [Card Mini Icon]  Benefit Name    $Value|
|  Card Name         Expires in X days     |
|                           [Mark as Done] |
+------------------------------------------+
```

**Urgency Indicators:**
- 7+ days: Gray text
- 4-7 days: Yellow/orange accent
- 1-3 days: Red accent
- Today: Red background highlight

---

### C5: Add Card FAB (Floating Action Button)

Primary action for adding new cards.

**Specifications:**
| Property | Value |
|----------|-------|
| Size | 56pt diameter |
| Position | Bottom right, 16pt margin |
| Icon | Plus (+) symbol |
| Background | Primary accent color |
| Shadow | 0 4pt 8pt rgba(0,0,0,0.2) |

**Behavior:**
- Visible on Dashboard and Wallet screens
- Hides on scroll down, shows on scroll up
- Tapping presents Add Card modal

---

### C6: Card Artwork Component

Visual representation of credit card artwork.

**Supported Formats:**
1. **Pre-loaded images:** High-res card images for popular cards (bundled in app)
2. **Gradient fallback:** Generated gradient for custom cards
3. **Issuer logo overlay:** Logo positioned per issuer standards

**Custom Card Gradients:**
Users can select from preset color schemes:
- Midnight Blue → Purple
- Gold → Bronze
- Silver → Gray
- Forest Green → Teal
- Ruby Red → Pink
- Classic Black

**Specifications:**
| Property | Value |
|----------|-------|
| Resolution | 3x for Retina |
| Format | PNG with transparency for logos |
| Gradient Angle | 135 degrees (top-left to bottom-right) |

---

## Visual Design System

### Color Palette

**Primary Colors:**
| Name | Hex | Usage |
|------|-----|-------|
| Primary | #007AFF | CTAs, links, primary actions |
| Primary Dark | #0055CC | Pressed states |
| Success | #34C759 | Positive states, "used" indicators |
| Warning | #FF9500 | Expiring soon (4-7 days) |
| Danger | #FF3B30 | Urgent, expiring today |
| Neutral | #8E8E93 | Secondary text, disabled states |

**Background Colors:**
| Name | Hex | Usage |
|------|-----|-------|
| Background Primary | #FFFFFF / #000000 | Main background (light/dark) |
| Background Secondary | #F2F2F7 / #1C1C1E | Cards, grouped content |
| Background Tertiary | #FFFFFF / #2C2C2E | Elevated surfaces |

**Card Issuer Colors:**
| Issuer | Primary | Secondary |
|--------|---------|-----------|
| American Express | #006FCF | #FFFFFF |
| Chase | #117ACA | #FFFFFF |
| Capital One | #D03027 | #004977 |
| Citi | #003B70 | #FFFFFF |
| US Bank | #D71920 | #003DA5 |

### Typography

**Font Family:** SF Pro (system font)

**Type Scale:**
| Style | Font | Size | Weight | Line Height |
|-------|------|------|--------|-------------|
| Large Title | SF Pro Display | 34pt | Bold | 41pt |
| Title 1 | SF Pro Display | 28pt | Bold | 34pt |
| Title 2 | SF Pro Display | 22pt | Bold | 28pt |
| Title 3 | SF Pro Text | 20pt | Semibold | 25pt |
| Headline | SF Pro Text | 17pt | Semibold | 22pt |
| Body | SF Pro Text | 17pt | Regular | 22pt |
| Callout | SF Pro Text | 16pt | Regular | 21pt |
| Subhead | SF Pro Text | 15pt | Regular | 20pt |
| Footnote | SF Pro Text | 13pt | Regular | 18pt |
| Caption | SF Pro Text | 12pt | Regular | 16pt |

**Value Display:**
- Currency values: SF Pro Rounded, Bold
- Large values (summary): 48pt
- Row values: 17pt

### Iconography

**Icon Style:** SF Symbols (Apple's system icons)

**Key Icons:**
| Purpose | SF Symbol Name |
|---------|----------------|
| Add | plus |
| Done/Used | checkmark.circle.fill |
| Available | circle |
| Expiring | exclamationmark.circle |
| Expired | xmark.circle |
| Snooze | clock.arrow.circlepath |
| Notification | bell.fill |
| Settings | gearshape.fill |
| Wallet | creditcard.fill |
| Home | house.fill |
| Search | magnifyingglass |
| Edit | pencil |
| Delete | trash |

### Spacing System

**Base Unit:** 4pt

**Spacing Scale:**
| Token | Value | Usage |
|-------|-------|-------|
| xs | 4pt | Minimal spacing, icon padding |
| sm | 8pt | Related element spacing |
| md | 16pt | Standard content padding |
| lg | 24pt | Section spacing |
| xl | 32pt | Major section separation |
| 2xl | 48pt | Screen-level padding |

### Elevation/Shadow System

| Level | Shadow | Usage |
|-------|--------|-------|
| 0 | None | Flat elements |
| 1 | 0 1pt 3pt rgba(0,0,0,0.12) | Cards, list items |
| 2 | 0 4pt 12pt rgba(0,0,0,0.15) | Floating cards, FAB |
| 3 | 0 8pt 24pt rgba(0,0,0,0.2) | Modals, sheets |

---

## Interaction Patterns

### Haptic Feedback

| Action | Haptic Type |
|--------|-------------|
| Mark as Done | Success (notificationSuccess) |
| Add Card | Success (notificationSuccess) |
| Snooze | Light impact |
| Delete | Warning (notificationWarning) |
| Error | Error (notificationError) |
| Button tap | Light impact |
| Swipe action trigger | Medium impact |

### Animation Specifications

**Card Transitions:**
- Duration: 350ms
- Easing: iOS spring (damping: 0.85, response: 0.4)

**Success Checkmark:**
- Draw-on animation: 400ms
- Scale pop: 1.0 -> 1.2 -> 1.0 (200ms)

**List Item Changes:**
- Insert/remove: 250ms ease-in-out
- Reorder: 300ms spring

**Sheet Presentation:**
- Standard iOS sheet behavior
- Medium detent for benefit details
- Large detent for add card flow

### Gesture Support

| Gesture | Location | Action |
|---------|----------|--------|
| Swipe right | Benefit row | Mark as done |
| Swipe left | Benefit row | Snooze options |
| Pull down | Any scrollable list | Refresh |
| Long press | Card | Quick action menu |
| Pinch | Wallet view (future) | Expand/collapse stack |

### Loading States

**Skeleton Screens:**
- Card shapes with shimmer animation
- Used when loading card data

**Inline Spinners:**
- For discrete actions (marking as done)
- Positioned where result will appear

**Progress Indicators:**
- Determinate progress for multi-step flows
- Shown in onboarding and batch operations

### Empty States

**No Cards Added:**
```
[Illustration: Empty wallet]
"Your wallet is empty"
"Add your first card to start tracking rewards"
[+ Add Card button]
```

**No Expiring Benefits:**
```
[Illustration: Celebration]
"You're all caught up!"
"No benefits expiring soon"
```

**All Benefits Used:**
```
[Illustration: Checkmarks]
"Great job!"
"You've used all available benefits this period"
```

---

## Accessibility Requirements

### VoiceOver Support

**All interactive elements must have:**
- Accessibility label (what it is)
- Accessibility hint (what happens on activation)
- Accessibility value (current state)

**Example - Benefit Row:**
```swift
accessibilityLabel = "$15 Uber credit from Amex Platinum"
accessibilityHint = "Double tap to mark as used"
accessibilityValue = "Available, expires in 5 days"
accessibilityTraits = [.button]
```

### Dynamic Type

- All text must scale with Dynamic Type settings
- Minimum supported size: xSmall
- Maximum supported size: AX5 (Accessibility sizes)
- Layout must adapt without truncation or overlap

### Color Contrast

- Minimum contrast ratio: 4.5:1 for normal text
- Minimum contrast ratio: 3:1 for large text (18pt+)
- Status must not rely on color alone (use icons + labels)

### Motion Sensitivity

- Respect "Reduce Motion" system setting
- Provide alternative transitions (crossfade vs. spring)
- No auto-playing animations that can't be paused

### Touch Targets

- Minimum touch target: 44pt x 44pt
- Spacing between targets: minimum 8pt

---

## Technical Design Considerations

### SwiftUI Implementation Notes

**Recommended Architecture:**
- NavigationStack for primary navigation
- TabView with 3 tabs (Home, Wallet, Settings)
- Sheet presentations for detail/add flows
- Observable objects for state management

**Key SwiftUI Components:**
```swift
// Card component using custom shape
struct CreditCardView: View {
    let card: Card
    // Aspect ratio enforced via .aspectRatio(1.586, contentMode: .fit)
}

// Benefit row with swipe actions
struct BenefitRow: View {
    let benefit: Benefit
    // Use .swipeActions for built-in swipe behavior
}

// Wallet stack using ZStack with offsets
struct CardStackView: View {
    let cards: [Card]
    // Cards offset by index * 8pt
}
```

**Animation Considerations:**
- Use `withAnimation(.spring())` for card interactions
- Implement `matchedGeometryEffect` for card expansion
- Use `sensoryFeedback` modifier for haptics (iOS 17+)

### Image Asset Requirements

**Card Artwork:**
- Provide @1x, @2x, @3x versions
- Dimensions: 343pt x 216pt (logical)
- Format: PNG for transparency, HEIC for photos
- Total initial bundle: ~15 popular card images

**App Icons:**
- Full icon set per Apple guidelines
- 1024x1024 App Store icon

**Onboarding Illustrations:**
- 3-4 illustrations for welcome screens
- Dimensions: 280pt x 280pt (logical)
- Style: Modern, inclusive, professional

### Notification Design

**Notification Content:**
```
Title: "Reward Expiring Soon"
Subtitle: "Amex Platinum"
Body: "Your $15 Uber credit expires in 3 days"
```

**Notification Actions (Category: "BENEFIT_REMINDER"):**
```swift
let doneAction = UNNotificationAction(
    identifier: "DONE",
    title: "Mark as Done",
    options: []
)
let snoozeAction = UNNotificationAction(
    identifier: "SNOOZE",
    title: "Snooze 1 Day",
    options: []
)
```

**Rich Notification:**
- Include card artwork as attachment
- Show benefit value prominently

### Local Data Visualization

**Dashboard Charts (Future):**
- Value redeemed over time (line chart)
- Benefits by category (pie chart)
- Use Swift Charts framework (iOS 16+)

---

## Appendix

### A1: Screen Wireframes Reference

Detailed wireframes should be created in design tool (Figma/Sketch) based on these specifications. Key screens requiring wireframes:

1. Dashboard (Home)
2. Wallet - Card Stack
3. Card Detail with Benefits
4. Add Card - Browser
5. Onboarding - Card Selection
6. Settings - Notifications
7. Benefit Detail Sheet

### A2: Card Database Visual Requirements

Each card in the database needs:
- High-resolution card artwork image
- Issuer logo (for fallback display)
- Primary and secondary brand colors
- Card type indicator (Platinum, Gold, etc.)

### A3: Prototype Checklist

For ui-design-expert coordination:

**High-Fidelity Prototype Should Demonstrate:**
- [ ] Onboarding flow (3-4 screens)
- [ ] Dashboard with sample data
- [ ] Wallet view with 3-4 cards
- [ ] Card detail expansion animation
- [ ] Mark as done interaction with success animation
- [ ] Swipe actions on benefit rows
- [ ] Add card flow (browse and select)
- [ ] Notification preview (static)

**Interactions to Prototype:**
- [ ] Card stack tap to expand
- [ ] Benefit swipe right (mark done)
- [ ] Success checkmark animation
- [ ] Sheet presentation and dismissal
- [ ] Tab bar navigation

### A4: Design Handoff Checklist

**For Engineering Implementation:**
- [ ] All color values documented with tokens
- [ ] Typography scale with exact specifications
- [ ] Spacing values documented
- [ ] Component states (default, pressed, disabled, loading)
- [ ] Animation timing and easing curves
- [ ] Gesture specifications
- [ ] Accessibility annotations
- [ ] Asset exports (icons, images)
- [ ] Redline specifications for key screens

### A5: Platform Considerations

**iOS Design Guidelines Compliance:**
- Follow Human Interface Guidelines for iOS 17
- Use standard iOS navigation patterns
- Support Dynamic Island for relevant notifications (future)
- Support Stage Manager on iPad (future)
- Use standard system controls where appropriate

**Dark Mode:**
- Full dark mode support required
- Use semantic colors (label, secondaryLabel, etc.)
- Card artwork should work in both modes
- Test all screens in dark mode before release

---

## Document History

| Version | Date | Author | Changes |
|---------|------|--------|---------|
| 1.0 | 2026-01-16 | Design Team | Initial design document creation |

---

## Approval Sign-off

| Role | Name | Date | Signature |
|------|------|------|-----------|
| Design Lead | | | |
| Product Manager | | | |
| Engineering Lead | | | |
