# Feature Recommendations - Market Research

**Research Date:** January 19, 2026
**Based on:** Analysis of top credit card tracker apps and user reviews

---

## Competitive Landscape

Top competitors analyzed:
1. **MaxRewards** - 4.7/5 rating, focus on rewards optimization
2. **CardPointers** - 5,000+ cards supported, AI-powered recommendations
3. **AwardWallet** - Multi-program loyalty tracking
4. **Kudos** - All-in-one financial companion

---

## Priority 1: Must-Have Features (High User Demand)

### 1.1 Welcome Bonus Tracker
**User Request Frequency:** Very High

Show progress toward welcome bonus spend requirements:
- Track how much spent vs. required amount
- Days remaining to complete bonus
- Visual progress bar with percentage
- Notification when approaching deadline

**Implementation Notes:**
- Add `welcomeBonusTarget` and `welcomeBonusDeadline` to UserCard
- Create WelcomeBonusProgressView component
- Include in card detail view

### 1.2 Best Card Recommendation at Checkout
**User Request Frequency:** Very High

Help users know which card to use for each purchase:
- Category-based recommendations (dining, gas, groceries)
- Merchant-specific bonuses
- Widget support for quick access

**Implementation Notes:**
- Create RecommendationEngine service
- Add merchant category mapping
- iOS Widget extension for home screen

### 1.3 Offer Auto-Activation
**User Request Frequency:** High

Automatically activate limited-time offers from card issuers:
- Amex offers
- Chase offers
- Citi merchant rewards

**Implementation Notes:**
- Would require bank API integrations (complex)
- Consider starting with manual offer tracking

---

## Priority 2: Highly Recommended Features

### 2.1 Annual Fee Tracking
**User Request Frequency:** High

Track when annual fees are due:
- Fee amount and due date
- Reminder before fee posts
- Calculate if benefits exceed fee (ROI)

**Files to Modify:**
- Add `annualFee` and `annualFeeDate` to UserCard
- Create fee reminder notifications

### 2.2 Credit Card 5/24 Status (Chase)
**User Request Frequency:** Medium-High

Track number of new cards opened in last 24 months:
- Chase's 5/24 rule affects approval odds
- Show when cards "fall off" the count

### 2.3 Points Balance Aggregation
**User Request Frequency:** Medium

Show total rewards balance across all cards:
- Aggregate points by program
- Estimated cash value
- Points expiration warnings

**Implementation Notes:**
- Would need user to manually enter balances
- Or integrate with bank APIs (privacy concerns)

### 2.4 Spending Analysis & Insights
**User Request Frequency:** Medium

Analyze spending patterns:
- Top categories by spend
- Missed rewards opportunities
- Month-over-month comparisons

---

## Priority 3: Nice-to-Have Features

### 3.1 Browser Extension
Chrome/Safari extension for web shopping:
- Show best card for current site
- Apply available offers automatically

### 3.2 Transaction Import
Import transactions from bank accounts:
- Auto-categorize spending
- Match to correct cards

### 3.3 Credit Score Monitoring
Integrate credit score tracking:
- Score updates
- Factors affecting score
- Hard inquiry tracking

### 3.4 Travel Benefits Lookup
Quick access to travel perks:
- Lounge access details
- Travel insurance coverage
- Global Entry/TSA PreCheck credits

---

## Quick Wins (Easy to Implement)

| Feature | Effort | Impact |
|---------|--------|--------|
| Annual fee reminder | Low | High |
| Benefit ROI calculator | Low | Medium |
| Card anniversary notification | Low | Medium |
| Export to CSV/PDF | Low | Medium |
| Share card benefits | Low | Low |

---

## User Pain Points to Address

Based on competitor reviews:

1. **Sync Issues** - MaxRewards users complain about needing to re-sync 2-4x/month
   - *Our advantage:* CouponTracker doesn't require bank login, avoiding sync issues

2. **Subscription Fatigue** - Users dislike $60+/year subscriptions
   - *Opportunity:* One-time purchase or freemium model

3. **Overwhelming Complexity** - Too many features can confuse casual users
   - *Our approach:* Focus on benefit tracking, keep UI simple

4. **Privacy Concerns** - Users wary of sharing bank credentials
   - *Our advantage:* No bank integration required

---

## Recommended Roadmap

### Phase 4A (Next Sprint)
1. Welcome bonus tracker
2. Annual fee tracking with reminders
3. Export functionality (JSON/CSV)

### Phase 4B
1. Best card recommendation engine
2. Spending category analysis
3. Widget support

### Phase 5
1. Points balance tracking (manual entry)
2. Travel benefits lookup
3. Family/household card sharing

---

## Sources

- [CNBC Select: Best Apps for Tracking Rewards](https://www.cnbc.com/select/best-apps-for-tracking-your-credit-card-rewards/)
- [MaxRewards Official](https://maxrewards.com/)
- [CardPointers App Store](https://apps.apple.com/us/app/cardpointers-for-credit-cards/id1472875808)
- [AwardWallet App Store](https://apps.apple.com/us/app/awardwallet-track-rewards/id388442727)
- [U.S. News: Best Credit Card Apps](https://money.usnews.com/credit-cards/articles/best-credit-card-apps-for-tracking-rewards)
- [Joinkudos MaxRewards Review](https://www.joinkudos.com/blog/maxrewards-credit-card-app-review)
- [ThoughtCard: CardPointers Review](https://thoughtcard.com/cardpointers-review/)

---

*Research compiled for CouponTracker product planning*
