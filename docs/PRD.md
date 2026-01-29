# CouponTracker Product Requirements Document (PRD)

**Version:** 2.0
**Last Updated:** January 29, 2026
**Status:** Active
**Product Owner:** [TBD]

---

## Table of Contents

1. [Executive Summary](#executive-summary)
2. [Product Vision](#product-vision)
3. [Problem Statement](#problem-statement)
4. [User Personas](#user-personas)
5. [MVP Scope and Phasing](#mvp-scope-and-phasing)
6. [Feature Requirements](#feature-requirements)
7. [User Stories](#user-stories)
8. [Success Metrics](#success-metrics)
9. [Technical Considerations](#technical-considerations)
10. [Risks and Mitigations](#risks-and-mitigations)
11. [Appendix](#appendix)

---

## Executive Summary

CouponTracker is a native iOS application designed to help users track and manage their coupons, vouchers, and credit card rewards before they expire. The primary focus for the MVP is credit card rewards tracking, addressing the common problem of users losing value by forgetting to redeem time-sensitive benefits.

### Key Value Proposition

Users frequently lose hundreds of dollars annually in expired credit card rewards, unused vouchers, and forgotten coupons. CouponTracker provides timely reminders and a clear visualization of available benefits, ensuring users maximize the value of their financial products and promotional offers.

---

## Product Vision

**Vision Statement:** Empower users to never miss a reward again by providing a beautiful, intuitive system that tracks all time-sensitive benefits and proactively reminds them before expiration.

**Long-term Goals:**
- Become the definitive app for managing personal rewards and benefits
- Build a comprehensive database of credit card rewards updated in real-time
- Enable automatic syncing with financial institutions via secure APIs
- Expand to support loyalty programs, airline miles, and subscription benefits

---

## Problem Statement

### The Problem

1. **Forgotten Rewards:** Credit card holders frequently forget about quarterly credits, annual benefits, and promotional offers, resulting in lost value
2. **Tracking Complexity:** Users with multiple credit cards struggle to remember which rewards are available on which cards and when they expire
3. **No Centralized Solution:** Existing solutions require manual calendar entries or spreadsheet tracking, which is cumbersome and error-prone
4. **Lack of Visibility:** Users have no easy way to see at a glance what rewards are available vs. used

### Market Opportunity

- The average premium credit card holder has 3-4 cards with recurring rewards
- Estimated $2.5B+ in credit card rewards expire unused annually in the US
- No dominant mobile solution exists specifically for credit card reward tracking

---

## User Personas

### Primary Persona: Premium Card Collector - "Alex"

**Demographics:**
- Age: 28-45
- Income: $100K+
- Location: Urban/Suburban US
- Tech Savvy: High

**Behavior:**
- Holds 3-5 premium credit cards (Amex Platinum, Chase Sapphire, etc.)
- Actively maximizes credit card rewards but struggles to track them all
- Uses iPhone as primary device
- Checks financial apps 2-3 times per week

**Pain Points:**
- Has forgotten to use quarterly Amex credits multiple times
- Spends mental energy trying to remember which benefits are available
- Has created calendar reminders but finds them annoying and insufficient
- Wishes there was "one place to see everything"

**Goals:**
- Never miss a credit card benefit again
- Quick visual check of what rewards are available
- Timely reminders without notification fatigue

**Quote:** "I pay $695/year for my Amex Platinum. I should be getting every penny of value from it."

---

### Secondary Persona: Deal Hunter - "Sam"

**Demographics:**
- Age: 25-40
- Income: $50-100K
- Location: Suburban US
- Tech Savvy: Medium-High

**Behavior:**
- Uses coupons and promotional offers actively
- Has 1-2 credit cards with rewards programs
- Receives coupon books and promotional mailers
- Shops strategically based on available deals

**Pain Points:**
- Physical coupons get lost or forgotten
- Forgets about promotional offers until they expire
- Wishes for better organization of all available discounts

**Goals:**
- Keep all deals in one place
- Get reminded before coupons expire
- Quick reference while shopping

**Quote:** "I know I have a coupon for this store somewhere..."

---

### Tertiary Persona: Organized Optimizer - "Jordan"

**Demographics:**
- Age: 30-50
- Income: $75K+
- Location: Any US
- Tech Savvy: Medium

**Behavior:**
- Values organization and planning
- Uses productivity apps religiously
- Makes deliberate purchasing decisions
- Tracks personal finances carefully

**Pain Points:**
- Current tracking methods feel scattered and incomplete
- Wants a purpose-built solution rather than generic reminders
- Needs visual confirmation that benefits are used

**Goals:**
- Complete visibility into all available rewards
- Satisfaction of marking benefits as "used"
- Historical tracking of value captured

**Quote:** "I want to feel confident I'm not leaving money on the table."

---

## MVP Scope and Phasing

### Phase 1: Core MVP (Weeks 1-6)

**Objective:** Deliver the minimum feature set that provides clear value to the primary persona.

**In Scope:**
- Credit card management with pre-populated popular cards
- Manual reward tracking (mark as used/unused)
- Basic expiration notifications (iOS local notifications)
- Wallet-style card visualization
- Onboarding flow for card selection

**Out of Scope for Phase 1:**
- Physical coupon tracking
- Coupon book management
- API integration for automatic syncing
- Widget support
- Apple Watch app
- Cloud sync across devices

---

### Phase 2: Enhanced Tracking (Weeks 7-10)

**Objective:** Expand tracking capabilities and improve notification intelligence.

**In Scope:**
- Physical coupon/voucher tracking with manual entry
- Photo capture for coupon storage
- Enhanced notification options (daily/weekly snooze)
- Reward history and analytics
- Search and filter functionality

---

### Phase 3: Extended Features (Weeks 11-14)

**Objective:** Add advanced features for power users and improve data quality.

**In Scope:**
- Coupon book tracking
- Multiple instances of same card (with nicknames)
- Card comparison features
- Export/backup functionality
- Enhanced card graphics and customization

---

### Phase 4: Subscription & Coupon Tracking (Current)

**Objective:** Expand beyond credit card benefits to track recurring subscriptions and one-time coupons/rewards.

**In Scope:**
- Credit card annual fee tracking with ROI visualization
- Recurring subscription tracking (Netflix, Spotify, etc.)
- 20-30 pre-populated subscription templates
- Manual subscription entry with optional card linkage
- One-time coupon/reward tracking with expiration dates
- New "Tracker" tab for subscriptions and coupons
- Dashboard integration with subscription/coupon widgets
- Notification reminders for renewals and expirations

**User Stories:**
- US-4.1: Track annual fee and see if card benefits exceed the cost
- US-4.2: Add subscriptions from templates or manually
- US-4.3: Link subscriptions to payment cards (optional)
- US-4.4: Track one-time coupons with expiration reminders
- US-4.5: See total monthly/annual subscription spend

---

### Future Phases (Post-MVP)

- API integration with credit card providers
- Automatic reward detection and syncing
- Cloud sync with user accounts
- Widget support for home screen
- Apple Watch complications
- Siri shortcuts integration
- Shared household accounts
- Subscription price change detection
- Cancellation tracking and history

---

## Feature Requirements

### F1: Credit Card Management

#### F1.1: Pre-populated Card Database

**Description:** The app includes a curated database of popular credit cards with their standard rewards and benefits pre-configured.

**Requirements:**
- Database includes top 20 most popular US credit cards
- Each card entry includes: card name, issuer, card artwork, and standard recurring benefits
- Benefits include: credit type, value, frequency (monthly/quarterly/annual), and typical reset dates
- Database is bundled with the app (no network required for Phase 1)

**Supported Cards (Initial):**
| Card | Issuer | Key Recurring Benefits |
|------|--------|----------------------|
| Platinum Card | American Express | $200 airline credit (annual), $200 Uber credits ($15/mo), $100 Saks credit (semi-annual), $240 digital entertainment ($20/mo), $100 hotel credit (semi-annual), $189 CLEAR credit (annual) |
| Gold Card | American Express | $120 Uber credits ($10/mo), $120 dining credits ($10/mo) |
| Chase Sapphire Reserve | Chase | $300 travel credit (annual), $60 DoorDash DashPass, $5 Lyft Pink credit (mo) |
| Chase Sapphire Preferred | Chase | $50 hotel credit (annual) |
| Capital One Venture X | Capital One | $300 travel credit (annual), $100 experience credit (annual) |
| Citi Prestige | Citi | $250 travel credit (annual) |
| US Bank Altitude Reserve | US Bank | $325 travel credit (annual) |
| Hilton Aspire | American Express | $250 airline credit (annual), $250 Hilton resort credit (annual), Free night award (annual) |
| Marriott Bonvoy Brilliant | American Express | $300 dining credit ($25/mo), Free night award (annual) |
| Delta SkyMiles Reserve | American Express | $120 Resy credit ($10/mo) |

**Acceptance Criteria:**
- [ ] User can browse available cards in a searchable list
- [ ] Card entries display card artwork, name, and issuer
- [ ] Tapping a card shows detailed benefit information
- [ ] Cards are categorized by issuer for easy browsing

---

#### F1.2: Add Card to Wallet

**Description:** Users can add cards from the database to their personal wallet.

**Requirements:**
- One-tap addition from card database
- Confirmation shows card added with its benefits
- Benefits automatically populate with appropriate due dates based on calendar
- System calculates initial due dates based on current date and benefit frequency

**Acceptance Criteria:**
- [ ] User can add a card from the pre-populated list with single tap
- [ ] Added card appears in user's wallet immediately
- [ ] All standard benefits are automatically created for the card
- [ ] Benefits have appropriate expiration dates calculated

---

#### F1.3: Custom Card Entry

**Description:** Users can manually add cards not in the pre-populated database.

**Requirements:**
- Form to enter: card name, issuer (optional), nickname
- Option to add custom benefits with: name, value, frequency, expiration
- Custom card uses generic card artwork with customizable color

**Acceptance Criteria:**
- [ ] User can create a custom card with name and optional issuer
- [ ] User can add multiple custom benefits to the card
- [ ] Each benefit has configurable name, value, frequency, and due date
- [ ] Custom cards display with generic but visually distinct artwork

---

#### F1.4: Card Nicknames (Phase 3)

**Description:** Support for multiple instances of the same card with user-defined nicknames.

**Requirements:**
- User can add the same card type multiple times
- Each instance can have a unique nickname (e.g., "Personal Platinum", "Business Platinum")
- Nicknames display in wallet view for differentiation
- Each instance tracks benefits independently

**Acceptance Criteria:**
- [ ] User can add duplicate card types to wallet
- [ ] Each card instance can have a unique nickname
- [ ] Benefits are tracked separately per card instance
- [ ] Wallet displays nickname alongside card name

---

### F2: Reward/Benefit Tracking

#### F2.1: Benefit Status Display

**Description:** Clear visualization of benefit status (available vs. used).

**Requirements:**
- Each benefit shows: name, value, expiration date, and status
- Status options: Available, Used, Expired
- Visual differentiation between statuses (color coding)
- Benefits grouped by status in detail view

**Acceptance Criteria:**
- [ ] Benefits display with clear status indicator
- [ ] Available benefits are visually prominent
- [ ] Used benefits show completion date
- [ ] Expired benefits are visually de-emphasized

---

#### F2.2: Mark Benefit as Used

**Description:** Users can mark benefits as redeemed.

**Requirements:**
- One-tap action to mark benefit as used
- Confirmation dialog with optional usage details
- Usage date automatically recorded
- Ability to undo within short time window

**Acceptance Criteria:**
- [ ] User can mark any available benefit as used
- [ ] Marking as used prompts for confirmation
- [ ] Usage date is recorded automatically
- [ ] User can undo action within 10 seconds

---

#### F2.3: Benefit Reset Automation

**Description:** Benefits automatically reset based on their frequency.

**Requirements:**
- Benefits reset on appropriate schedule (monthly/quarterly/annual)
- Reset dates calculated based on benefit type and typical credit card cycles
- Used benefits return to "Available" status after reset
- User notified when benefits reset

**Acceptance Criteria:**
- [ ] Monthly benefits reset on the 1st of each month
- [ ] Quarterly benefits reset at quarter start (Jan/Apr/Jul/Oct)
- [ ] Annual benefits reset on calendar year or cardmember anniversary (configurable)
- [ ] Push notification sent when benefits reset to available

---

### F3: Notification System

#### F3.1: Expiration Reminders

**Description:** Proactive notifications before benefits expire.

**Requirements:**
- Default reminder: 7 days before expiration
- Configurable reminder timing per benefit or globally
- Notification includes: benefit name, card name, value, days remaining

**Acceptance Criteria:**
- [ ] Notifications delivered at configured time before expiration
- [ ] Notification content is clear and actionable
- [ ] Tapping notification opens directly to benefit detail
- [ ] Notifications respect device Do Not Disturb settings

---

#### F3.2: Notification Actions

**Description:** Quick actions available from notification.

**Requirements:**
- "Mark as Done" - marks benefit as used from notification
- "Snooze" - reschedules reminder
- Snooze options: 1 day, 3 days, 1 week
- "View Details" - opens app to benefit

**Acceptance Criteria:**
- [ ] User can mark benefit as used directly from notification
- [ ] User can snooze reminder from notification
- [ ] Snooze creates new scheduled reminder
- [ ] All actions work without fully opening the app

---

#### F3.3: Recurring Reminders

**Description:** Escalating reminders for unacknowledged benefits.

**Requirements:**
- If benefit not marked as used, follow-up reminder sent
- Configurable follow-up schedule: daily or weekly
- Reminders continue until benefit is used, snoozed, or expires
- Maximum reminder cap to prevent spam

**Acceptance Criteria:**
- [ ] Follow-up reminders sent based on user preference
- [ ] User can set reminder frequency (daily/weekly)
- [ ] Reminders stop when benefit is marked as used
- [ ] Maximum of 7 reminders before auto-stop

---

#### F3.4: Notification Preferences

**Description:** User control over notification behavior.

**Requirements:**
- Global notification enable/disable
- Per-card notification settings
- Quiet hours configuration
- Preferred notification time of day

**Acceptance Criteria:**
- [ ] User can disable all notifications globally
- [ ] User can disable notifications for specific cards
- [ ] User can set quiet hours (e.g., no notifications 10pm-8am)
- [ ] User can set preferred reminder time

---

### F4: Wallet UI

#### F4.1: Wallet View

**Description:** Visual wallet-style display of user's cards.

**Requirements:**
- Cards displayed as stacked visual representations
- Card artwork visible and recognizable
- Each card shows summary: total value available, urgent items
- Tap to expand card and see benefits

**Acceptance Criteria:**
- [ ] Cards display with authentic-looking artwork
- [ ] Wallet view shows all user cards at a glance
- [ ] Each card shows available value summary
- [ ] Cards with urgent expiring benefits are highlighted

---

#### F4.2: Card Detail View

**Description:** Expanded view showing all card benefits.

**Requirements:**
- Full card artwork display at top
- Benefits listed below, grouped by status
- Quick action buttons for each benefit
- Card management options (remove, edit nickname)

**Acceptance Criteria:**
- [ ] Card detail shows full card information
- [ ] Benefits clearly organized by status
- [ ] User can interact with individual benefits
- [ ] User can remove card from wallet

---

#### F4.3: Dashboard/Home View

**Description:** Overview of most important information.

**Requirements:**
- Summary cards showing: total value available, items expiring soon
- Quick list of benefits expiring within 7 days
- Recently used benefits
- Quick add button for new cards

**Acceptance Criteria:**
- [ ] Dashboard loads as default app view
- [ ] Expiring benefits prominently displayed
- [ ] Total available value shown
- [ ] One-tap access to add new cards

---

### F5: Onboarding

#### F5.1: Initial Setup Flow

**Description:** Guided experience for new users.

**Requirements:**
- Welcome screens explaining app value
- Card selection step showing popular cards
- Notification permission request with explanation
- Quick-start with pre-selected cards

**Acceptance Criteria:**
- [ ] Onboarding completes in under 2 minutes
- [ ] User can skip onboarding if desired
- [ ] Notification permission requested with context
- [ ] User has at least one card after onboarding

---

### F6: Physical Coupon Tracking (Phase 2 - Deferred to Phase 4)

*Moved to F8 with expanded scope*

---

### F7: Credit Card Annual Fee Tracking (Phase 4)

#### F7.1: Annual Fee on Card

**Description:** Track annual fee amount and renewal date for credit cards.

**Requirements:**
- Annual fee amount (Decimal, default 0)
- Annual fee renewal date (optional)
- Configurable reminder (days before fee)
- Display on card detail view

**Acceptance Criteria:**
- [ ] User can set/edit annual fee amount on any card
- [ ] User can set annual fee renewal date
- [ ] Annual fee displays on CardDetailView
- [ ] Reminder notification sent before fee date

---

#### F7.2: ROI Visualization

**Description:** Show whether card benefits exceed the annual fee.

**Requirements:**
- Calculate total benefits redeemed (current year)
- Compare to annual fee
- Visual indicator: positive ROI (green) vs negative (red)
- Progress bar showing redeemed vs fee

**Acceptance Criteria:**
- [ ] ROI card displays on CardDetailView
- [ ] Shows "Redeemed: $X / Annual Fee: $Y"
- [ ] Net value displayed with color coding
- [ ] Progress bar shows break-even progress

---

### F8: Subscription Tracking (Phase 4)

#### F8.1: Subscription Management

**Description:** Track recurring subscriptions with optional card linkage.

**Requirements:**
- Add subscription from template (20-30 popular services)
- Manual subscription entry
- Fields: name, price, frequency (weekly/monthly/quarterly/annual), next renewal date
- Optional link to payment card
- Category assignment (streaming, software, gaming, news, fitness, utilities, foodDelivery, other)

**Acceptance Criteria:**
- [ ] User can add subscription from template list
- [ ] User can create custom subscription manually
- [ ] Subscription can optionally link to a UserCard
- [ ] Subscription displays in Tracker tab

---

#### F8.2: Subscription Templates

**Description:** Pre-populated list of common subscription services.

**Requirements:**
- 20-30 popular services (Netflix, Spotify, Disney+, Adobe, etc.)
- Each template: name, suggested price, default frequency, category, icon
- Searchable/filterable template list
- User can override price when adding

**Template Categories:**
| Category | Examples |
|----------|----------|
| Streaming | Netflix, Spotify, Disney+, HBO Max, YouTube Premium |
| Software | Adobe CC, Microsoft 365, 1Password, Notion |
| Gaming | Xbox Game Pass, PlayStation Plus, Nintendo Online |
| News | NYT, WSJ, Medium, Substack |
| Fitness | Peloton, gym memberships, Apple Fitness+ |
| Utilities | iCloud, Google One, Dropbox |
| Food Delivery | DoorDash Pass, Uber One |

**Acceptance Criteria:**
- [ ] Template picker shows 20-30 services with icons
- [ ] Templates grouped by category
- [ ] Search filters templates in real-time
- [ ] Selected template pre-fills form fields

---

#### F8.3: Subscription Reminders

**Description:** Notification before subscription renewal.

**Requirements:**
- User-configurable reminder days (default: 7)
- Notification includes: service name, amount, renewal date
- Quick actions: Mark Paid, Snooze

**Acceptance Criteria:**
- [ ] Reminder sent N days before nextRenewalDate
- [ ] Notification actionable without opening app
- [ ] User can configure reminder timing per subscription

---

#### F8.4: Subscription Analytics

**Description:** Spending summary across subscriptions.

**Requirements:**
- Total monthly cost (normalized from all frequencies)
- Total annual cost
- Cost by category breakdown
- Upcoming renewals list

**Acceptance Criteria:**
- [ ] Dashboard widget shows total monthly subscription cost
- [ ] Tracker tab shows spending breakdown
- [ ] Upcoming renewals highlighted

---

### F9: Coupon/Reward Tracking (Phase 4)

#### F9.1: Manual Coupon Entry

**Description:** Track one-time coupons and rewards with expiration dates.

**Requirements:**
- Fields: name, description (optional), expiration date, category, value (optional), merchant (optional), code (optional)
- Categories: dining, shopping, travel, entertainment, services, grocery, other
- Status: available, used, expired
- Reminder before expiration

**Acceptance Criteria:**
- [ ] User can create coupon with required fields
- [ ] Coupon displays in Tracker tab (Coupons section)
- [ ] Expiration countdown shown
- [ ] Reminder notification sent before expiration

---

#### F9.2: Mark Coupon Used

**Description:** Track when coupons are redeemed.

**Requirements:**
- One-tap "Mark as Used" action
- Records used date
- Coupon moves to "Used" status
- Undo available briefly

**Acceptance Criteria:**
- [ ] User can mark coupon as used
- [ ] Used date recorded
- [ ] Undo available for 10 seconds
- [ ] Used coupons shown in separate section

---

#### F9.3: Coupon Urgency Display

**Description:** Visual urgency for expiring coupons.

**Requirements:**
- Countdown timer for <24 hours
- Red highlight for "Expires Today"
- Orange for "Expires This Week"
- Badge on Tracker tab for urgent coupons

**Acceptance Criteria:**
- [ ] Coupons grouped by urgency (Today, This Week, Later)
- [ ] Countdown timer for imminent expiration
- [ ] Tab badge shows urgent count

---

## User Stories

### Epic: Credit Card Management

#### US-1.1: Browse Pre-populated Cards
**As a** new user
**I want to** browse a list of popular credit cards
**So that** I can quickly find and add my cards without manual data entry

**Acceptance Criteria:**
- Given I am on the card selection screen
- When I scroll through the card list
- Then I see cards organized by issuer with card artwork visible
- And I can search by card name or issuer
- And tapping a card shows me its benefits before adding

**Priority:** P0
**Effort:** Medium

---

#### US-1.2: Add Card to My Wallet
**As a** user with credit cards
**I want to** add a card to my personal wallet
**So that** I can start tracking its benefits

**Acceptance Criteria:**
- Given I am viewing a card's details
- When I tap "Add to Wallet"
- Then the card is added to my wallet
- And all standard benefits are created with appropriate due dates
- And I receive confirmation of the addition

**Priority:** P0
**Effort:** Low

---

#### US-1.3: Create Custom Card
**As a** user with a card not in the database
**I want to** manually create a card entry
**So that** I can track benefits for any card I have

**Acceptance Criteria:**
- Given I am on the add card screen
- When I tap "Add Custom Card"
- Then I can enter card name and issuer
- And I can add custom benefits with values and due dates
- And the card appears in my wallet with generic artwork

**Priority:** P1
**Effort:** Medium

---

### Epic: Benefit Tracking

#### US-2.1: View My Available Benefits
**As a** user with cards in my wallet
**I want to** see all my available benefits at a glance
**So that** I know what rewards I can use

**Acceptance Criteria:**
- Given I have cards in my wallet
- When I open the app
- Then I see a summary of total available value
- And I see benefits expiring soon prominently displayed
- And I can tap into any card to see full benefit details

**Priority:** P0
**Effort:** Medium

---

#### US-2.2: Mark Benefit as Used
**As a** user who has redeemed a benefit
**I want to** mark the benefit as used
**So that** I have accurate tracking of what remains available

**Acceptance Criteria:**
- Given I am viewing a benefit marked as "Available"
- When I tap "Mark as Used"
- Then I see a confirmation dialog
- And after confirming, the benefit status changes to "Used"
- And the usage date is recorded
- And the benefit moves to the "Used" section

**Priority:** P0
**Effort:** Low

---

#### US-2.3: Benefit Auto-Reset
**As a** user tracking recurring benefits
**I want** benefits to automatically reset when they renew
**So that** I don't have to manually manage the renewal cycle

**Acceptance Criteria:**
- Given I have a monthly benefit marked as "Used"
- When the new month begins
- Then the benefit status automatically changes to "Available"
- And a new expiration date is set for the end of the month
- And I receive a notification that benefits have reset

**Priority:** P0
**Effort:** High

---

### Epic: Notifications

#### US-3.1: Receive Expiration Reminder
**As a** user with expiring benefits
**I want to** receive a reminder before benefits expire
**So that** I don't forget to use them

**Acceptance Criteria:**
- Given I have a benefit expiring in 7 days
- When the 7-day threshold is reached
- Then I receive a push notification
- And the notification shows benefit name, card, value, and days remaining
- And tapping the notification opens the benefit detail

**Priority:** P0
**Effort:** Medium

---

#### US-3.2: Quick Action from Notification
**As a** user who received a reminder
**I want to** mark the benefit as used directly from the notification
**So that** I can quickly acknowledge without opening the app

**Acceptance Criteria:**
- Given I received an expiration reminder notification
- When I long-press the notification
- Then I see "Mark as Done" and "Snooze" options
- And tapping "Mark as Done" updates the benefit status
- And I receive confirmation feedback

**Priority:** P1
**Effort:** Medium

---

#### US-3.3: Snooze Reminder
**As a** user who cannot use a benefit immediately
**I want to** snooze the reminder
**So that** I'm reminded again at a better time

**Acceptance Criteria:**
- Given I received an expiration reminder
- When I select "Snooze" from notification actions
- Then I see snooze duration options (1 day, 3 days, 1 week)
- And selecting an option schedules a new reminder
- And the current notification is dismissed

**Priority:** P1
**Effort:** Medium

---

#### US-3.4: Configure Notification Preferences
**As a** user
**I want to** control how and when I receive notifications
**So that** reminders work with my schedule

**Acceptance Criteria:**
- Given I am in app settings
- When I access notification preferences
- Then I can enable/disable notifications globally
- And I can set preferred reminder time
- And I can configure quiet hours
- And I can set default reminder lead time (3/7/14 days)

**Priority:** P1
**Effort:** Medium

---

### Epic: Wallet UI

#### US-4.1: View Wallet
**As a** user
**I want to** see my cards in a wallet-style view
**So that** the experience feels natural and visual

**Acceptance Criteria:**
- Given I have cards in my wallet
- When I navigate to the wallet view
- Then I see my cards displayed as visual card representations
- And cards show their artwork and brief summary
- And I can tap a card to expand its details

**Priority:** P0
**Effort:** High

---

#### US-4.2: See Urgent Benefits
**As a** user
**I want to** quickly see which benefits need immediate attention
**So that** I can prioritize using expiring rewards

**Acceptance Criteria:**
- Given I have benefits expiring within 7 days
- When I view the dashboard
- Then expiring benefits are displayed prominently
- And they are sorted by urgency (soonest first)
- And each shows days remaining with visual urgency indicator

**Priority:** P0
**Effort:** Medium

---

### Epic: Onboarding

#### US-5.1: Complete First-Time Setup
**As a** new user
**I want** a guided setup experience
**So that** I can quickly start tracking my cards

**Acceptance Criteria:**
- Given I am opening the app for the first time
- When the app launches
- Then I see welcome screens explaining the app
- And I am prompted to select my cards from popular options
- And I am asked to enable notifications with explanation
- And I can complete setup in under 2 minutes

**Priority:** P0
**Effort:** Medium

---

## Success Metrics

### Primary Metrics

| Metric | Definition | Target (3 months) |
|--------|------------|-------------------|
| **Monthly Active Users (MAU)** | Unique users who open app in 30-day period | 5,000 |
| **Benefit Redemption Rate** | % of benefits marked as used before expiration | 70% |
| **7-Day Retention** | % of new users who return within 7 days | 40% |
| **30-Day Retention** | % of new users who return within 30 days | 25% |

### Secondary Metrics

| Metric | Definition | Target |
|--------|------------|--------|
| **Cards per User** | Average cards added per active user | 2.5 |
| **Notification Engagement** | % of notifications that lead to app open or action | 30% |
| **Onboarding Completion** | % of new users who complete onboarding | 80% |
| **App Store Rating** | Average rating on App Store | 4.5+ |

### North Star Metric

**Value Captured:** Total dollar value of benefits marked as "used" by all users

This metric directly measures whether users are achieving the core value proposition of not missing rewards.

---

## Technical Considerations

### Platform Requirements
- iOS 17.0 minimum deployment target
- iPhone only for MVP (iPad support post-MVP)
- Swift 5.9+
- SwiftUI for UI layer

### Data Architecture
- Local data storage using SwiftData (Core Data successor)
- Pre-populated card database bundled with app binary
- No backend/cloud infrastructure for Phase 1
- Data model designed for future cloud sync extensibility

### Notification Implementation
- iOS UserNotifications framework
- Local notifications (no server required)
- Background refresh for benefit reset calculations
- Notification categories for inline actions

### Performance Requirements
- App launch < 1 second
- Card database search < 100ms
- Smooth 60fps scrolling in wallet view
- Battery impact < 1% daily

### Security Considerations
- No sensitive financial data stored (card numbers, etc.)
- Only card names and benefit information
- Biometric lock option for privacy
- No network transmission of user data in Phase 1

### Future API Considerations
- Architecture should support future OAuth integration with banks
- Data models should accommodate automatic benefit detection
- Service layer abstraction for swapping local vs. remote data sources

---

## Risks and Mitigations

### Risk 1: Card Database Accuracy
**Risk:** Pre-populated benefit information becomes outdated as credit cards change their offerings.

**Mitigation:**
- Include "last updated" date in card database
- Provide easy mechanism for users to edit/customize benefits
- Plan for regular app updates with database refreshes
- Consider crowdsourced corrections in future version

**Severity:** Medium
**Likelihood:** High

---

### Risk 2: Notification Fatigue
**Risk:** Users disable notifications due to too many reminders, defeating core value.

**Mitigation:**
- Smart grouping of notifications (max 1 per day unless urgent)
- Respectful default settings
- Easy snooze options to reduce friction
- Learning from user behavior to optimize timing

**Severity:** High
**Likelihood:** Medium

---

### Risk 3: Low Engagement After Initial Setup
**Risk:** Users add cards but don't return to app regularly.

**Mitigation:**
- Notifications drive engagement back to app
- Dashboard design surfaces actionable information
- Gamification elements (value tracked, streak)
- Widget support (post-MVP) for passive engagement

**Severity:** Medium
**Likelihood:** Medium

---

### Risk 4: Limited Market Due to Premium Cards Focus
**Risk:** Focus on premium credit cards limits addressable market.

**Mitigation:**
- Phase 2 expands to coupons and vouchers
- Custom card support allows any card to be tracked
- Expand card database to include mainstream rewards cards
- Marketing focuses on "never miss a reward" vs. "premium card tracking"

**Severity:** Low
**Likelihood:** Low

---

## Appendix

### A1: Competitive Analysis

| App | Strengths | Weaknesses |
|-----|-----------|------------|
| **MaxRewards** | Automatic card detection, spending optimization | Requires linking bank accounts, privacy concerns |
| **CardPointers** | Large card database, real-time deals | Focused on earning, not tracking benefits |
| **AwardWallet** | Comprehensive loyalty tracking | Complex UI, not focused on credit card benefits |
| **Generic Reminder Apps** | Flexible, free | No specialized features, manual setup |

**CouponTracker Differentiator:** Purpose-built for tracking time-sensitive credit card benefits with beautiful wallet UI and smart reminders, without requiring bank account linking.

---

### A2: Card Database Schema (Reference)

```
Card
  - id: UUID
  - name: String
  - issuer: String
  - cardArtworkURL: String
  - annualFee: Decimal?
  - benefits: [Benefit]
  - isCustom: Boolean

Benefit
  - id: UUID
  - name: String
  - description: String
  - value: Decimal
  - frequency: Frequency (monthly/quarterly/semi-annual/annual)
  - category: BenefitCategory
  - typicalResetDate: DateComponents?
```

---

### A3: Notification Copy Examples

**7-Day Reminder:**
> "Your $15 Uber credit from Amex Platinum expires in 7 days. Don't let it go to waste!"

**3-Day Reminder:**
> "Only 3 days left! Your $100 Saks credit (Amex Platinum) expires Jan 31."

**Final Day:**
> "Last chance! Your $100 Resy credit expires TODAY. Use it or lose it!"

**Benefit Reset:**
> "Fresh rewards available! Your Amex Gold benefits have reset for February."

---

### A4: Glossary

| Term | Definition |
|------|------------|
| **Benefit** | A reward, credit, or perk associated with a credit card |
| **Wallet** | The user's collection of added cards in the app |
| **Reset** | When a recurring benefit becomes available again after its period |
| **Snooze** | Postponing a reminder for a specified duration |
| **Card Database** | The pre-populated collection of credit cards and their benefits |

---

## Document History

| Version | Date | Author | Changes |
|---------|------|--------|---------|
| 1.0 | 2026-01-16 | Product Team | Initial PRD creation |

---

## Approval Sign-off

| Role | Name | Date | Signature |
|------|------|------|-----------|
| Product Manager | | | |
| Engineering Lead | | | |
| Design Lead | | | |
| Stakeholder | | | |
