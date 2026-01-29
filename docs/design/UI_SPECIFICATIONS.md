# CouponTracker UI/UX Specifications

**Version:** 2.0
**Last Updated:** January 29, 2026
**Status:** Active
**Author:** Product Team

---

## Purpose

This document provides detailed UI/UX specifications for the CouponTracker iOS app. It is intended to guide the ui-design-expert in creating high-fidelity mockups and interactive prototypes that align with product requirements and technical constraints.

---

## Table of Contents

1. [Design Brief](#design-brief)
2. [Wallet UI Specifications](#wallet-ui-specifications)
3. [Card Component Detailed Specs](#card-component-detailed-specs)
4. [Reward Status Visualization](#reward-status-visualization)
5. [Screen-by-Screen Specifications](#screen-by-screen-specifications)
6. [Interaction Design](#interaction-design)
7. [Prototype Requirements](#prototype-requirements)
8. [Design Deliverables Checklist](#design-deliverables-checklist)

---

## Design Brief

### Product Context

CouponTracker helps users track credit card rewards and benefits before they expire. The primary audience holds premium credit cards (Amex Platinum, Chase Sapphire, etc.) and wants to maximize the value of their annual fees.

### Design Challenge

Create a **wallet-style interface** that:
1. Displays credit cards in a visually appealing, recognizable format
2. Clearly communicates which rewards are available vs. used
3. Creates urgency for expiring benefits without causing anxiety
4. Makes the "mark as done" action satisfying and effortless

### Emotional Goals

| Goal | Expression |
|------|------------|
| **Confidence** | User feels in control of their benefits |
| **Delight** | Marking benefits as used feels rewarding |
| **Trust** | Premium aesthetic appropriate for financial content |
| **Calm** | Information presented clearly, not overwhelming |

### Key Constraints

- iOS 17+ native app (SwiftUI)
- iPhone portrait orientation only
- Must support Dark Mode
- Must follow iOS Human Interface Guidelines
- Accessibility: Dynamic Type, VoiceOver support

---

## Wallet UI Specifications

### Wallet Concept

The wallet is the primary view for browsing user's cards. It should evoke the feeling of a physical leather wallet with credit cards visible.

### Visual Metaphor Options

**Option A: Card Stack (Recommended)**
- Cards stacked vertically with slight offset
- Most valuable/urgent card on top
- Tap to expand and see full card
- Swipe through stack to browse

```
+------------------------------------------+
|     +---------------------------------+  |
|     |                                 |  |
|   +-|-------------------------------+ |  |
|   | |                               | |  |
| +-|-|-----------------------------+ | |  |
| | | |     [Amex Platinum]         | | |  |
| | | |     $127 Available          | | |  |
| | | |     2 expiring soon         | |-+  |
| | +-|-----------------------------+      |
| +---|---------------------------------+  |
|     +---------------------------------+  |
+------------------------------------------+
```

**Option B: Horizontal Carousel**
- Cards in horizontal scroll
- Current card centered and larger
- Previous/next cards peeking from edges
- Dots indicator for position

**Option C: Grid View**
- 2-column grid of mini card representations
- Tap to expand to full detail
- Better for users with many cards

**Recommendation:** Start with Option A (Card Stack) for MVP as it is most visually distinctive and works well for typical 3-5 cards. Consider grid view for users with 6+ cards.

### Wallet View Layout

```
+------------------------------------------+
| [< back]    My Wallet            [+ Add] |  <- Navigation
+------------------------------------------+
|                                          |
|  Total Available Value                   |  <- Summary Header
|  $847                                    |
|  Across 4 cards                          |
|                                          |
+------------------------------------------+
|                                          |
|     +--------------------------------+   |
|     |    [Card 1 - Top/Active]       |   |
|     |    Card Artwork                |   |
|     |    AMEX PLATINUM               |   |
|     |    $127 available | 2 expiring |   |
|     +--------------------------------+   |
|   +----------------------------------+   |  <- Card Stack
|   |    [Card 2 - Offset 8pt]         |   |
|   +----------------------------------+   |
| +------------------------------------+   |
| |    [Card 3 - Offset 16pt]          |   |
| +------------------------------------+   |
|                                          |
+------------------------------------------+
|  [Home]        [Wallet]       [Settings] |  <- Tab Bar
+------------------------------------------+
```

### Card Stack Behavior

| Interaction | Behavior |
|-------------|----------|
| Tap top card | Expand to card detail view |
| Drag top card down | Reveal cards underneath |
| Tap lower card | Bring to front (optional: expand directly) |
| Long press | Quick action menu |
| Pull down on stack | Refresh card data |

---

## Card Component Detailed Specs

### Credit Card Visual Design

The card component is the core visual element. It should look like a real credit card while remaining functional.

### Card Anatomy

```
+------------------------------------------+
|  [Issuer Logo]                      [Chip] |
|                                           |
|                                           |
|  [Card Artwork / Gradient Background]     |
|                                           |
|                                           |
|  CARD NAME                                |
|  "Personal" (nickname if set)             |
|                                           |
|  +----------------+  +------------------+ |
|  | $127 Available |  | 2 Expiring Soon  | |
|  +----------------+  +------------------+ |
+-------------------------------------------+
```

### Card Dimensions

| Property | Value | Notes |
|----------|-------|-------|
| Aspect Ratio | 1.586:1 | Standard credit card (85.6mm x 53.98mm) |
| Width | Screen width - 32pt | 16pt margin each side |
| Corner Radius | 12pt | Matches iOS card aesthetic |
| Shadow | See elevation system | Level 2 shadow |

### Card Visual Elements

**1. Card Artwork**
- High-res image for popular cards (bundled in app)
- Dimensions: 686pt x 432pt @2x (1029pt x 648pt @3x)
- Gradient fallback for custom cards

**2. Issuer Logo**
- Positioned top-left, 16pt from edges
- Maximum height: 24pt
- White or appropriate contrast color

**3. Chip Element (Decorative)**
- Standard credit card chip graphic
- Positioned top-right area
- Subtle, not distracting

**4. Card Name**
- Bottom-left, 16pt from edges
- SF Pro Display, Bold, 17pt
- White or high-contrast color
- Nickname on second line if set (14pt, regular)

**5. Status Pills**
- Bottom of card, above card name
- Two pills side by side
- "Available" pill (green tint when value > 0)
- "Expiring" pill (orange/red when items expiring)

### Card States

**Default State:**
```
+------------------------------------------+
|  [Standard card appearance]               |
|  Shadow: Level 2                          |
|  Opacity: 100%                            |
+------------------------------------------+
```

**Pressed State:**
```
+------------------------------------------+
|  Scale: 0.98                              |
|  Shadow: Level 1 (reduced)                |
|  Duration: 100ms                          |
+------------------------------------------+
```

**Urgent State (benefits expiring < 3 days):**
```
+------------------------------------------+
|  Subtle pulsing glow effect               |
|  Or: Animated border                      |
|  "Expiring" pill: Red background          |
+------------------------------------------+
```

**All Benefits Used State:**
```
+------------------------------------------+
|  Subtle checkmark overlay (corner)        |
|  "Available" pill: Gray, shows "$0"       |
|  Reduced visual prominence                |
+------------------------------------------+
```

### Custom Card Gradients

For cards not in the database, users select a color scheme:

| Name | Gradient Start | Gradient End |
|------|---------------|--------------|
| Midnight | #1a1a2e | #4a4e69 |
| Gold | #b8860b | #daa520 |
| Platinum | #a0a0a0 | #d0d0d0 |
| Sapphire | #0f4c75 | #3282b8 |
| Rose Gold | #b76e79 | #eacda3 |
| Obsidian | #1c1c1c | #434343 |
| Emerald | #1d4e4d | #43aa8b |
| Ruby | #9b2335 | #c41e3a |

---

## Reward Status Visualization

### Status Definition

| Status | Definition | Visual Treatment |
|--------|------------|------------------|
| **Available** | Benefit can be redeemed | Full color, prominent |
| **Used** | Benefit was redeemed this period | Muted, checkmark icon |
| **Expired** | Period ended without redemption | Strikethrough, gray |
| **Expiring Soon** | Available but expires within 7 days | Highlighted, urgency indicator |

### Benefit Row Design

```
+--------------------------------------------------+
|  [Status]  Benefit Name                   $Value |
|   Icon     Description text...                   |
|            Expires: Jan 31, 2026    [Action Btn] |
+--------------------------------------------------+
```

### Status Icons

| Status | Icon | Color | SF Symbol |
|--------|------|-------|-----------|
| Available | Empty circle | Green (#34C759) | circle |
| Used | Filled checkmark | Green (#34C759) | checkmark.circle.fill |
| Expired | X in circle | Gray (#8E8E93) | xmark.circle |
| Expiring Soon | Exclamation | Orange (#FF9500) | exclamationmark.circle.fill |
| Expiring Today | Exclamation | Red (#FF3B30) | exclamationmark.circle.fill |

### Urgency Visualization Scale

| Days Remaining | Visual Treatment |
|----------------|-----------------|
| 8+ days | Standard (green icon, no highlight) |
| 4-7 days | Warning (orange icon, subtle yellow background) |
| 1-3 days | Urgent (red icon, light red background) |
| Today (0 days) | Critical (red icon, prominent red background, badge) |

### Benefit Row Layout Specifications

```
+--------------------------------------------------+
|                                                  |
|  16pt  [24pt    16pt                      16pt   |
|        icon]    Benefit Name          $15.00     |
|                 Secondary text...                |
|                 [Expiry badge]      [56pt btn]   |
|                                                  |
+--------------------------------------------------+
   |                                           |
   +-- 16pt padding ---------------------------+
```

| Element | Specification |
|---------|--------------|
| Row height | 72pt minimum (expandable) |
| Horizontal padding | 16pt |
| Vertical padding | 12pt |
| Icon size | 24pt |
| Icon-to-text gap | 12pt |
| Primary text | SF Pro, 17pt, semibold |
| Secondary text | SF Pro, 15pt, regular, secondary color |
| Value text | SF Pro Rounded, 17pt, bold |
| Action button | 56pt width, 32pt height |

### "Mark as Done" Button Design

**Button States:**

| State | Background | Text | Icon |
|-------|------------|------|------|
| Default | Primary Blue (#007AFF) | White | checkmark |
| Pressed | Darker Blue (#0055CC) | White | checkmark |
| Loading | Primary Blue | Spinner | - |
| Disabled | Gray (#E5E5EA) | Gray (#8E8E93) | checkmark |

**Button Sizing:**
- Minimum tap target: 44pt x 44pt
- Visual size: 56pt x 32pt
- Corner radius: 8pt

### Success Animation

When user marks benefit as used:

1. **Button transforms** (100ms)
   - Button shrinks slightly
   - Spinner appears

2. **Checkmark draws** (300ms)
   - Animated checkmark stroke
   - Scale pop: 1.0 -> 1.1 -> 1.0

3. **Row updates** (200ms)
   - Row slides/morphs to "Used" state
   - Icon updates to filled checkmark
   - Color transitions to muted

4. **Haptic feedback**
   - Success haptic on completion

---

## Screen-by-Screen Specifications

### Screen 1: Dashboard (Home)

**Purpose:** Primary landing screen showing summary and urgent items

**Layout:**
```
+------------------------------------------+
| CouponTracker                      [Gear]|  <- Nav bar
+------------------------------------------+
|                                          |
| +--------------------------------------+ |
| |  Total Available                     | |
| |  $847                                | |  <- Value Card
| |  Across 4 cards                      | |
| |  [See breakdown ->]                  | |
| +--------------------------------------+ |
|                                          |
| Expiring Soon                            |  <- Section Header
|                                          |
| +--------------------------------------+ |
| | [Uber icon] $15 Uber Credit    3 days| |
| | Amex Platinum        [Mark as Done]  | |  <- Expiring Item
| +--------------------------------------+ |
|                                          |
| +--------------------------------------+ |
| | [Saks icon] $100 Saks Credit   7 days| |
| | Amex Platinum        [Mark as Done]  | |
| +--------------------------------------+ |
|                                          |
| Recently Used                            |  <- Section Header
|                                          |
| +--------------------------------------+ |
| | [Check] $10 Dining Credit   Used Jan 5| |
| | Amex Gold                            | |  <- Used Item
| +--------------------------------------+ |
|                                          |
+------------------------------------------+
|  [Home]        [Wallet]       [Settings] |  <- Tab Bar
+------------------------------------------+
```

**Specifications:**
- Scrollable content below value card
- Value card: fixed at top or scrolls with content (test both)
- "Expiring Soon" limited to 5 items, "See all" link if more
- "Recently Used" limited to 3 items

---

### Screen 2: Wallet (Card Stack)

See [Wallet UI Specifications](#wallet-ui-specifications) above.

---

### Screen 3: Card Detail

**Purpose:** Full view of a single card with all benefits

**Layout:**
```
+------------------------------------------+
| [< Wallet]                        [Edit] |  <- Nav bar
+------------------------------------------+
|                                          |
| +--------------------------------------+ |
| |                                      | |
| |    [Large Card Artwork]              | |  <- Card Header
| |    AMEX PLATINUM                     | |
| |    Personal (nickname)               | |
| |                                      | |
| +--------------------------------------+ |
|                                          |
| Available Benefits ($127)                |  <- Section
|                                          |
| [Benefit row 1 - expanded format]        |
| [Benefit row 2]                          |
| [Benefit row 3]                          |
|                                          |
| Used This Period                         |  <- Section
|                                          |
| [Used benefit row 1 - collapsed]         |
| [Used benefit row 2]                     |
|                                          |
| +--------------------------------------+ |
| | [Remove Card]                        | |  <- Danger Zone
| +--------------------------------------+ |
|                                          |
+------------------------------------------+
```

**Specifications:**
- Card header takes ~40% of screen
- Benefits list is scrollable
- Swipe actions on benefit rows
- "Remove Card" at bottom with confirmation

---

### Screen 4: Add Card - Browser

**Purpose:** Browse and select from pre-populated cards

**Layout:**
```
+------------------------------------------+
| [Cancel]    Add Card             [Custom]|  <- Nav bar
+------------------------------------------+
|                                          |
| +--------------------------------------+ |
| | [Search icon] Search cards...        | |  <- Search bar
| +--------------------------------------+ |
|                                          |
| American Express                         |  <- Issuer Section
|                                          |
| +----------+ +----------+ +----------+   |
| |[Platinum]| |  [Gold]  | | [Green]  |   |  <- Card Grid
| +----------+ +----------+ +----------+   |
|                                          |
| Chase                                    |
|                                          |
| +----------+ +----------+ +----------+   |
| |[Sapphire]| |[Sapphire]| |[Freedom] |   |
| |[Reserve] | |[Preferred]|           |   |
| +----------+ +----------+ +----------+   |
|                                          |
| Capital One                              |
|                                          |
| +----------+ +----------+                |
| |[Venture] | |[Savor]   |                |
| |   [X]    | |          |                |
| +----------+ +----------+                |
|                                          |
+------------------------------------------+
```

**Specifications:**
- Search filters results in real-time
- Issuer sections collapsible
- Grid: 3 columns, card mini previews
- Tap card to open detail sheet

---

### Screen 5: Card Preview Sheet

**Purpose:** Confirm card selection before adding

**Layout:**
```
+------------------------------------------+
|               [Drag Indicator]           |  <- Sheet Handle
+------------------------------------------+
|                                          |
| +--------------------------------------+ |
| |                                      | |
| |    [Full Card Artwork]               | |  <- Card Preview
| |                                      | |
| +--------------------------------------+ |
|                                          |
|  American Express Platinum Card          |  <- Card Name
|  Annual Fee: $695                        |
|                                          |
|  Included Benefits                       |  <- Benefits List
|                                          |
|  + $200 Uber Credits ($15/month)         |
|  + $200 Airline Credit (annual)          |
|  + $100 Saks Credit ($50 semi-annual)    |
|  + $240 Digital Entertainment ($20/mo)   |
|  + $189 CLEAR Credit (annual)            |
|                                          |
|  Total Annual Value: $929+               |  <- Value Summary
|                                          |
| +--------------------------------------+ |
| |         [Add to Wallet]              | |  <- Primary CTA
| +--------------------------------------+ |
|                                          |
+------------------------------------------+
```

**Specifications:**
- Medium sheet detent initially
- Expandable to full screen for scrolling
- Benefits shown as read-only list
- "Add to Wallet" button sticky at bottom

---

### Screen 6: Onboarding - Card Selection

**Purpose:** Quick setup by selecting owned cards

**Layout:**
```
+------------------------------------------+
|                                   [Skip] |  <- Nav bar
+------------------------------------------+
|                                          |
|  Select Your Cards                       |  <- Title
|  Choose the cards you have               |
|                                          |
| +--------------------------------------+ |
| | [Search icon] Search cards...        | |
| +--------------------------------------+ |
|                                          |
| +----------+ +----------+ +----------+   |
| |[Platinum]| |  [Gold]  | | [Green]  |   |
| |    [x]   | |          | |          |   |  <- Multi-select
| +----------+ +----------+ +----------+   |
|                                          |
| +----------+ +----------+ +----------+   |
| |[Sapphire]| |[Sapphire]| |[Venture] |   |
| |[Reserve] | |[Preferred]|   [X]     |   |
| |    [x]   | |          | |          |   |
| +----------+ +----------+ +----------+   |
|                                          |
|                 ...                      |
|                                          |
+------------------------------------------+
|                                          |
| +--------------------------------------+ |
| |    Continue (3 cards selected)       | |  <- Primary CTA
| +--------------------------------------+ |
|                                          |
+------------------------------------------+
```

**Specifications:**
- Multi-select mode (checkmarks on selected)
- Selected count shown in button
- Can continue with 0 cards (skip equivalent)
- Grid scrolls, button fixed at bottom

---

### Screen 7: Settings

**Purpose:** App configuration and preferences

**Layout:**
```
+------------------------------------------+
| Settings                                 |  <- Nav bar
+------------------------------------------+
|                                          |
| Notifications                            |  <- Section
|                                          |
| +--------------------------------------+ |
| | Enable Notifications          [Toggle]| |
| +--------------------------------------+ |
| | Reminder Time                   9:00 >| |
| +--------------------------------------+ |
| | Default Lead Time               7 days>| |
| +--------------------------------------+ |
|                                          |
| Quiet Hours                              |  <- Section
|                                          |
| +--------------------------------------+ |
| | Enable Quiet Hours           [Toggle] | |
| +--------------------------------------+ |
| | From                           10:00 >| |
| +--------------------------------------+ |
| | To                              8:00 >| |
| +--------------------------------------+ |
|                                          |
| Card Database                            |  <- Section
|                                          |
| +--------------------------------------+ |
| | Database Version                 1.0.0| |
| +--------------------------------------+ |
| | Last Updated              Jan 15, 2026| |
| +--------------------------------------+ |
|                                          |
| About                                    |  <- Section
|                                          |
| +--------------------------------------+ |
| | Version                          1.0.0| |
| +--------------------------------------+ |
| | Send Feedback                        >| |
| +--------------------------------------+ |
| | Privacy Policy                       >| |
| +--------------------------------------+ |
|                                          |
+------------------------------------------+
```

---

## Interaction Design

### Swipe Actions

**Right Swipe on Benefit (Mark as Done):**
```
+------------------------------------------+
| [GREEN BACKGROUND with checkmark icon]   |
|                       [Benefit Content]->|
+------------------------------------------+
Threshold: 80pt reveals action
Full swipe: Executes action
```

**Left Swipe on Benefit (Snooze):**
```
+------------------------------------------+
|<-[Benefit Content]                       |
|         [BLUE BACKGROUND with clock icon]|
+------------------------------------------+
Reveals snooze options (1 day, 1 week)
```

### Long Press Menus

**Long Press on Card:**
```
+------------------+
| View Details     |
| Edit Card        |
| Notification Settings |
| -----            |
| Remove Card      |  <- Destructive
+------------------+
```

**Long Press on Benefit:**
```
+------------------+
| Mark as Done     |
| Snooze           | >  (submenu: 1 day, 3 days, 1 week)
| Edit             |
| View History     |
+------------------+
```

### Pull to Refresh

Available on:
- Dashboard (refresh all benefit statuses)
- Wallet (refresh card data)
- Card Detail (refresh specific card)

Animation: Standard iOS pull-to-refresh spinner

### Tab Bar Behavior

| Tab | Icon | Label | Badge |
|-----|------|-------|-------|
| Home | house.fill | Home | Count of expiring items |
| Wallet | creditcard.fill | Wallet | - |
| Tracker | checklist | Tracker | Count of urgent items |
| Settings | gearshape.fill | Settings | - |

---

## Tracker Tab Specifications (Phase 4)

### Screen 8: Tracker Tab

**Purpose:** Manage subscriptions and coupons in a dedicated tab.

**Layout:**
```
+------------------------------------------+
| Tracker                            [+ Add]|  <- Nav bar
+------------------------------------------+
|                                          |
| [Subscriptions] [Coupons]                |  <- Segmented Control
|                                          |
+------------------------------------------+
|                                          |
| +--------------------------------------+ |
| | Monthly Total                        | |
| | $127.45                              | |  <- Summary Card
| | 8 active subscriptions               | |
| +--------------------------------------+ |
|                                          |
| Renewing Soon                            |  <- Section
|                                          |
| +--------------------------------------+ |
| | [Netflix] Netflix          $15.99/mo | |
| | Renews Tomorrow      [Sapphire Res.] | |  <- Subscription Row
| +--------------------------------------+ |
|                                          |
| +--------------------------------------+ |
| | [Spotify] Spotify          $10.99/mo | |
| | Renews in 5 days                     | |
| +--------------------------------------+ |
|                                          |
| All Subscriptions                        |  <- Section
|                                          |
| [More subscription rows...]              |
|                                          |
+------------------------------------------+
|  [Home]  [Wallet]  [Tracker]  [Settings] |
+------------------------------------------+
```

---

### Screen 9: Coupons View (Tracker Tab - Coupons Segment)

**Layout:**
```
+------------------------------------------+
| Tracker                            [+ Add]|
+------------------------------------------+
|                                          |
| [Subscriptions] [Coupons]                |  <- Selected: Coupons
|                                          |
+------------------------------------------+
|                                          |
| [!] Expiring Today (2)                   |  <- Urgency Section
|                                          |
| +--------------------------------------+ |
| | [McDonald's] BOGO Burger             | |
| | Expires 11:59 PM         [Mark Used] | |  <- Urgent Coupon
| +--------------------------------------+ |
|                                          |
| +--------------------------------------+ |
| | [Walgreens] $5 Off $25               | |
| | Expires 11:59 PM         [Mark Used] | |
| +--------------------------------------+ |
|                                          |
| [!] Expiring This Week (5)               |  <- Section
|                                          |
| +--------------------------------------+ |
| | [Uber Eats] 20% Off                  | |
| | 3 days left              [Mark Used] | |
| +--------------------------------------+ |
|                                          |
| Later (8)                                |
| [More coupon rows...]                    |
|                                          |
+------------------------------------------+
```

---

### Screen 10: Add Subscription

**Layout:**
```
+------------------------------------------+
| [Cancel]   Add Subscription       [Save] |
+------------------------------------------+
|                                          |
| +--------------------------------------+ |
| | [Search] Search services...          | |
| +--------------------------------------+ |
|                                          |
| Popular                                  |  <- Section
|                                          |
| +--------+ +--------+ +--------+         |
| |Netflix | |Spotify | |Disney+ |         |
| +--------+ +--------+ +--------+         |  <- Template Grid
| +--------+ +--------+ +--------+         |
| |Adobe   | |iCloud  | |Gym     |         |
| +--------+ +--------+ +--------+         |
|                                          |
| [+ Add Custom Subscription]              |  <- Manual Entry
|                                          |
+------------------------------------------+
```

**Configuration Sheet (after selecting template):**
```
+------------------------------------------+
|              [Drag Handle]               |
+------------------------------------------+
|                                          |
| [Netflix Logo]                           |
| Netflix                                  |
| Streaming service                        |
|                                          |
| +--------------------------------------+ |
| | Amount         |   $15.99           | |
| +--------------------------------------+ |
| | Frequency      |   Monthly       >  | |
| +--------------------------------------+ |
| | Next Renewal   |   Feb 1, 2026   >  | |
| +--------------------------------------+ |
| | Payment Card   |   (Optional)    >  | |
| +--------------------------------------+ |
|                                          |
| +--------------------------------------+ |
| |           [Add Subscription]         | |  <- Primary CTA
| +--------------------------------------+ |
|                                          |
+------------------------------------------+
```

---

### Screen 11: Add Coupon

**Layout:**
```
+------------------------------------------+
| [Cancel]      Add Coupon          [Save] |
+------------------------------------------+
|                                          |
| +--------------------------------------+ |
| | Name *                               | |
| | McDonald's BOGO                      | |
| +--------------------------------------+ |
|                                          |
| +--------------------------------------+ |
| | Description                          | |
| | Buy one Big Mac get one free         | |
| +--------------------------------------+ |
|                                          |
| +--------------------------------------+ |
| | Expiration Date *      Feb 15, 2026 >| |
| +--------------------------------------+ |
|                                          |
| +--------------------------------------+ |
| | Category              Dining       > | |
| +--------------------------------------+ |
|                                          |
| +--------------------------------------+ |
| | Value (optional)           $6.99     | |
| +--------------------------------------+ |
|                                          |
| +--------------------------------------+ |
| | Coupon Code (optional)               | |
| | BOGO2026                             | |
| +--------------------------------------+ |
|                                          |
+------------------------------------------+
```

---

### Screen 12: Annual Fee ROI Card (CardDetailView)

**Location:** CardDetailView, below card header, above benefits

**Layout:**
```
+------------------------------------------+
|                                          |
| +--------------------------------------+ |
| | Annual Fee ROI        Fee due: 45d   | |
| +--------------------------------------+ |
| |                                      | |
| |  $875          -    $550    =  $325  | |
| | Redeemed       Annual Fee    Net Gain| |
| |                                      | |
| | [====================----] 159%      | |
| |                                      | |
| | ✓ You've earned back your fee!       | |
| +--------------------------------------+ |
|                                          |
+------------------------------------------+
```

**States:**
- **Positive ROI:** Green background, checkmark, "Net Gain"
- **Negative ROI:** Red/orange background, arrow up, "Redeem $X more to break even"
- **Fee Due Soon (<30 days):** Warning badge with countdown

---

### Subscription Row Component

**Layout:**
```
+--------------------------------------------------+
|  [Icon]  Service Name              $XX.XX/freq   |
|          Renews [date]     [Optional: Card chip] |
+--------------------------------------------------+
```

**Visual Specifications:**
| Element | Spec |
|---------|------|
| Row height | 72pt |
| Icon size | 40pt (rounded rect) |
| Service name | SF Pro, 17pt, semibold |
| Renewal date | SF Pro, 15pt, regular, secondary |
| Price | SF Pro Rounded, 17pt, bold |
| Frequency label | SF Pro, 13pt, regular, tertiary |
| Card chip | 8pt height, card gradient background |

**Urgency States:**
| Days until renewal | Treatment |
|-------------------|-----------|
| 8+ | Standard (no highlight) |
| 4-7 | Orange icon, yellow tint background |
| 1-3 | Red icon, light red background |
| Today/Tomorrow | Red icon, prominent red background, "Renews Tomorrow" |

---

### Coupon Row Component

**Layout:**
```
+--------------------------------------------------+
|  [Icon]  Coupon Name                 [Mark Used] |
|          Expires [countdown]                     |
+--------------------------------------------------+
```

**Urgency States:**
| Time remaining | Treatment |
|----------------|-----------|
| 8+ days | Standard |
| 4-7 days | Orange, "X days left" |
| 1-3 days | Red, "X days left" |
| <24 hours | Red pulse, "Expires in Xh Xm" |
| Today | Red badge, "Expires Today" |

---

### Dashboard Integration (Phase 4)

**Add to Dashboard (HomeTabView):**

**Subscription Mini-Widget:**
```
+------------------------------------------+
| Subscriptions          $127.45/mo total  |
|                                          |
| [Netflix]  Netflix renews tomorrow       |
| [Spotify]  +2 more this week             |
|                                    [>]   |
+------------------------------------------+
```

**Coupons Mini-Widget:**
```
+------------------------------------------+
| Coupons Expiring                   [!]   |
|                                          |
| 2 expire today  |  5 expire this week    |
|                                    [>]   |
+------------------------------------------+
```

**New Insight Banner Types:**
| Insight | Trigger | Message |
|---------|---------|---------|
| subscriptionsDueSoon | 3+ renewals in 7 days | "3 subscriptions renew this week: $45" |
| couponsExpiringToday | 1+ coupons expire today | "2 coupons expire today!" |
| annualFeeDue | Fee in <30 days | "[Card] $550 annual fee due in 7 days" |

---

## Prototype Requirements

### Required Prototype Screens

For ui-design-expert to create:

| Priority | Screen | Interactions |
|----------|--------|--------------|
| P0 | Dashboard (Home) | Scroll, tap benefit |
| P0 | Wallet - Card Stack | Tap card to expand |
| P0 | Card Detail | Scroll, swipe benefit |
| P0 | Mark as Done | Full animation sequence |
| P1 | Add Card Browser | Search, tap card |
| P1 | Card Preview Sheet | Scroll, tap add |
| P1 | Onboarding - Card Selection | Multi-select, continue |
| P2 | Settings | Toggle, navigation |

### Prototype Flows

**Flow 1: View and Redeem Benefit**
```
Dashboard -> Tap expiring benefit -> Card Detail -> Swipe right on benefit -> Success animation -> Updated state
```

**Flow 2: Add New Card**
```
Wallet -> Tap + FAB -> Card Browser -> Tap card -> Preview Sheet -> Tap Add -> Success -> Wallet with new card
```

**Flow 3: First Launch**
```
Welcome 1 -> Welcome 2 -> Card Selection -> Notification Permission -> Dashboard
```

### Animation Specifications for Prototype

| Animation | Duration | Easing | Notes |
|-----------|----------|--------|-------|
| Card tap expand | 350ms | Spring (0.85, 0.4) | Scale + position |
| Sheet presentation | 300ms | Ease-out | Standard iOS sheet |
| Success checkmark | 400ms | Ease-out | Draw stroke + scale pop |
| Row status change | 200ms | Ease-in-out | Color + icon transition |
| Tab switch | 250ms | Ease-in-out | Crossfade |

---

## Design Deliverables Checklist

### For ui-design-expert to deliver:

**High-Fidelity Mockups:**
- [ ] Dashboard (Home) - default state
- [ ] Dashboard - with expiring items (urgency states)
- [ ] Dashboard - empty state (no cards)
- [ ] Wallet - Card Stack (3-4 cards)
- [ ] Wallet - Urgent card state
- [ ] Card Detail - with mixed benefit states
- [ ] Card Detail - all benefits used
- [ ] Benefit Detail Sheet
- [ ] Add Card - Browser with search
- [ ] Card Preview Sheet
- [ ] Custom Card Form
- [ ] Onboarding - Welcome screens (2-3)
- [ ] Onboarding - Card Selection
- [ ] Onboarding - Notification Permission
- [ ] Settings - Main
- [ ] Settings - Notification Preferences

**Component Library:**
- [ ] Card component (all states)
- [ ] Benefit row (all states)
- [ ] Status icons
- [ ] Action buttons
- [ ] Section headers
- [ ] Empty states
- [ ] Loading states

**Interactive Prototype:**
- [ ] Main flows connected (view, add, mark done)
- [ ] Key animations demonstrated
- [ ] Swipe gestures functional

**Design Specifications:**
- [ ] Redlines for key screens
- [ ] Color token documentation
- [ ] Typography specifications
- [ ] Spacing documentation
- [ ] Animation specifications

**Assets for Development:**
- [ ] SF Symbol mappings
- [ ] Custom icons (if any)
- [ ] Gradient definitions
- [ ] Card artwork requirements

---

## Open Questions for UI Design Expert

1. **Card Stack vs. Grid:** For the wallet, should we commit to card stack or explore grid view? What works better for 5+ cards?

2. **Urgency Visualization:** How aggressive should the "expiring" states be? Balance between visibility and creating anxiety.

3. **Custom Card Colors:** Are the proposed gradient presets sufficient? Should users have a full color picker?

4. **Empty States:** Need illustration concepts for:
   - No cards added
   - All benefits used
   - No expiring benefits

5. **Onboarding Illustrations:** Style direction for welcome screens - abstract, illustrative, or photographic?

6. **Dark Mode Card Artwork:** How do we handle card artwork in dark mode? Some cards are already dark. Options:
   - Leave as-is
   - Add subtle border in dark mode
   - Adjust brightness

---

## Document History

| Version | Date | Author | Changes |
|---------|------|--------|---------|
| 1.0 | 2026-01-16 | Product Team | Initial UI specifications |

---

## Review Sign-off

| Role | Name | Date | Status |
|------|------|------|--------|
| UI Design Expert | | | Pending Review |
| Product Manager | | | Approved |
| Engineering Lead | | | Pending Review |
