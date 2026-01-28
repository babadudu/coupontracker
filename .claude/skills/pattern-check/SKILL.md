---
name: pattern-check
description: Run after implementing delete operations, navigation changes, or data aggregation logic to detect anti-pattern violations
---

# Pattern Violation Check

Detects anti-patterns from project design rules.

## Pattern 1: Close-Before-Delete
```bash
# Delete called without prior dismiss
grep -rn -B5 "repository\.\(delete\|remove\)" ios/CouponTracker/Sources --include="*.swift" | head -20
```
Manual review: ensure UI dismissal happens BEFORE delete call.

## Pattern 2: Template Lookup in Display
```bash
# Views/ViewModels fetching template for display data
grep -rn "template\." ios/CouponTracker/Sources/Features --include="*.swift" | grep -v "templateId"
```
Should be empty - display data must be denormalized on entity.

## Pattern 3: Object Navigation (should use ID)
```bash
grep -rn "selectedCard\s*=" ios/CouponTracker/Sources --include="*.swift" | grep -v "selectedCardId"
grep -rn "selectedBenefit\s*=" ios/CouponTracker/Sources --include="*.swift" | grep -v "selectedBenefitId"
```

## Pattern 4: Child Dismissing
```bash
grep -rn "dismiss()" ios/CouponTracker/Sources/Features --include="*.swift"
```
Review: only parent/container views should call dismiss.

## Pattern 5: Lazy Aggregations
```bash
grep -rn "\.reduce\|\.map.*sum\|\.filter.*count" ios/CouponTracker/Sources/Features --include="*ViewModel.swift"
```
Review: ensure relationships are hydrated before aggregating.

## Pattern 6: Missing Defaults
```bash
grep -rn "var.*:.*[^=]$" ios/CouponTracker/Sources/Models --include="*.swift" | grep -v "//"
```

## Pattern 7: Missing Migration
```bash
grep -rn "StartupMigration\|migrat" ios/CouponTracker/Sources/Services --include="*.swift"
```
When fixing entity creation bugs, verify a migration exists for existing data.
