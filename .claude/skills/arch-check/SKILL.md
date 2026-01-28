---
name: arch-check
description: Run when creating/editing Views, ViewModels, or Repositories to validate file size limits and layer violations
---

# Architecture Check

Validates file sizes and layer violations per project constraints.

## File Size Limits

```bash
# Views > 400 lines
find ios/CouponTracker/Sources/Features -name "*.swift" -path "*View*" -exec wc -l {} + | awk '$1 > 400 {print "VIOLATION:", $2, "("$1" lines)"}'

# ViewModels > 300 lines
find ios/CouponTracker/Sources/Features -name "*ViewModel.swift" -exec wc -l {} + | awk '$1 > 300 {print "VIOLATION:", $2, "("$1" lines)"}'

# Repositories > 150 lines
find ios/CouponTracker/Sources/Services/Storage -name "*Repository.swift" -exec wc -l {} + | awk '$1 > 150 {print "VIOLATION:", $2, "("$1" lines)"}'
```

## Layer Violations

```bash
# Views importing Repository/Service directly (forbidden)
grep -rn "import.*Repository\|import.*Service" ios/CouponTracker/Sources/Features --include="*View.swift"

# Repositories with business logic (look for calculations, not CRUD)
grep -rn "reduce\|map.*filter\|\.count\s*>\|inferFrequency" ios/CouponTracker/Sources/Services/Storage --include="*.swift"
```

## Expected Output
No output = clean architecture. Any output = violation to fix.
