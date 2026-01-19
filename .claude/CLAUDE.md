# CLAUDE.md - Project Context & Rules

## 🧠 The Architect Protocol (High Priority)
**Role:** Senior Software Architect
**Goal:** Maximize code reuse, minimize token usage, ensure scalability.

### 1. Token-Efficient Design Patterns
Before generating code, explicitly consider and apply these patterns to reduce verbosity:
* **Strategy Pattern:** Use this instead of massive `if/else` or `switch` blocks in a single file. Isolate logic into small, swappable classes.
* **Template Method:** Define the skeleton in a base class to avoid repeating boilerplate in subclasses.
* **Flyweight:** If creating many similar objects, share common state to reduce memory and code footprint.
* **Composite:** Use this for tree structures to treat individual objects and compositions uniformly (reduces complex iteration logic).

### 2. The "DRY" Mandate (Don't Repeat Yourself)
* **Strict Prohibition:** Never duplicate logic. If you write the same 3 lines of code twice, create a helper function immediately.
* **Centralized Constants:** Do not hardcode strings/numbers in multiple places. Put them in a `constants` or `config` file.

## 🛑 General Token Conservation Rules
1.  **No Chatty Responses:** Be extremely concise. Acknowledge with "Understood." or "Done."
2.  **Diff-Based Output:** When editing, NEVER output the full file. Use search/replace blocks.
3.  **Proactive Context Clearing:** Once a task is verified, prompt me: "Commit changes and restart session."
4.  **No "Exploratory" Reads:** Do not read `ls -R`. Ask for specific file paths.

## 🕵️ "Smart Read" Protocol (Token Saving)
When you need to understand a file, DO NOT use `cat` or `read` on the whole file immediately.
Instead, use the `read_interface` skill (defined below) to see **signatures and docstrings only**.

**Goal:** Understand the *contract* (inputs/outputs/behavior) without paying for the *implemention* details.

## 📝 Documentation Standards (The "Contract" Rule)
1.  **Interface First:** Before implementing complex logic, write the Class/Function skeleton with a full Docstring explaining:
    * `Args`: What goes in (types/constraints).
    * `Returns`: What comes out.
    * `Raises`: Potential errors.
2.  **Why?** This allows other Agents to use your code by reading *only* the Docstring, skipping the implementation logic to save tokens.

---

## 🛡️ Universal Development Patterns (Language-Agnostic)

These patterns apply across all tech stacks. Adapt syntax to your language/framework.

---

### 🗑️ Pattern 1: Close-Before-Delete (UI + Data Sync)

**Problem:** Deleting data while UI components still reference it causes crashes, null pointer exceptions, or stale state errors.

**Applies To:** Any reactive UI framework with ORM/database (React + Prisma, Vue + Sequelize, Angular + TypeORM, SwiftUI + CoreData/SwiftData, Flutter + Drift, etc.)

**Rule:** ALWAYS close/unmount/dismiss UI components BEFORE deleting their backing data.

```pseudocode
// ❌ WRONG: Delete then close
function handleDelete(item):
    database.delete(item)      // Data gone
    closeDetailView()          // UI crashes accessing deleted data

// ✅ CORRECT: Close then delete async
function handleDelete(item):
    itemId = item.id           // Capture ID
    closeDetailView()          // UI unmounts first

    async:
        database.deleteById(itemId)
        refreshList()
```

**Why It Happens:**
- Cascade deletes remove parent + children simultaneously
- UI components may still be rendering/accessing child properties
- Race condition between UI tear-down and data deletion

**Checklist:**
- [ ] UI component dismissed/unmounted before delete operation?
- [ ] ID captured before closing view (not object reference)?
- [ ] Delete operation is async/deferred?
- [ ] Parent component manages navigation state (not child)?

---

### 📋 Pattern 2: Denormalize at Creation (Template → Entity)

**Problem:** Entities that only store foreign keys to templates fail to display correctly when templates aren't loaded or lookup fails.

**Applies To:** Any system with templates/blueprints that create instances (product catalogs, configuration templates, card templates, user preferences, etc.)

**Rule:** Copy essential display fields from template to entity at creation time. Don't rely solely on runtime lookups.

```pseudocode
// ❌ WRONG: Only store reference
entity = Entity(
    templateId: template.id,
    // name and value fetched at display time... risky!
)

// ✅ CORRECT: Denormalize essential fields
entity = Entity(
    templateId: template.id,
    name: template.name,         // Copy for display
    value: template.value,       // Copy for calculations
    category: template.category  // Copy for filtering
)
```

**Why It Happens:**
- Template lookup can fail (deleted, not loaded, network issue)
- Display logic assumes fields exist but they're null/undefined
- Performance: N+1 queries to resolve template for each entity

**Checklist:**
- [ ] All display-critical fields copied from template?
- [ ] Computed values (like `effectiveValue`) have fallbacks?
- [ ] Entity can render without template being loaded?
- [ ] Template changes don't break existing entities?

---

### 🧪 Pattern 3: Test Mock Hygiene

**Problem:** Test mocks cause compilation errors, naming collisions, or visibility issues across test files.

**Rule:**
1. Use unique, descriptive names: `{TestClass}{MockPurpose}`
2. Keep mock visibility accessible to test class properties
3. Never use generic names like `MockRepository` that collide

```pseudocode
// ❌ WRONG: Generic private mock
private class MockUserService { }
var userService: MockUserService  // Visibility conflict!

// ✅ CORRECT: Unique accessible mock
class UserControllerTestMockUserService { }
var userService: UserControllerTestMockUserService  // Works
```

**Naming Convention:**
```
{TestClassName}{Mock|Stub|Fake}{DependencyName}

Examples:
- HomeViewModelMockTemplateLoader
- PaymentControllerStubPaymentGateway
- AuthServiceFakeTokenProvider
```

**Checklist:**
- [ ] Mock names are globally unique across test suite?
- [ ] Mock visibility matches test property requirements?
- [ ] Mock implements full interface/protocol (no partial mocks)?
- [ ] Mocks are in same file as tests or shared test utilities?

---

### 🧭 Pattern 4: ID-Based Navigation (Not Object Snapshots)

**Problem:** Passing entire objects to detail views causes stale data after updates, or crashes after deletion.

**Rule:** Navigate using IDs. Detail views fetch fresh data by ID.

```pseudocode
// ❌ WRONG: Pass object snapshot
function showDetail(item):
    navigate(DetailView(item: item))  // Stale if item changes

// ✅ CORRECT: Pass ID, fetch fresh
function showDetail(item):
    selectedItemId = item.id

DetailView:
    item = repository.findById(selectedItemId)  // Always fresh
```

**Checklist:**
- [ ] Navigation state stores ID, not object?
- [ ] Detail view fetches by ID on mount/render?
- [ ] Parent owns navigation state (selectedId)?
- [ ] Handles "not found" when item was deleted?

---

### 🔄 Pattern 5: Single Dismiss Point

**Problem:** Multiple components calling close/dismiss/navigate-back causes race conditions and unpredictable behavior.

**Rule:** Only ONE component should control navigation state. Usually the parent.

```pseudocode
// ❌ WRONG: Child dismisses itself
DetailView:
    onDelete:
        parentCallback.delete(item)
        this.dismiss()  // Race with parent!

// ✅ CORRECT: Parent controls dismissal
ParentView:
    onChildDelete(item):
        selectedItemId = null  // Dismisses child
        async: repository.delete(item)

DetailView:
    onDelete:
        parentCallback.delete(item)  // Just notify, don't dismiss
```

**Checklist:**
- [ ] Child views don't call dismiss/close/navigate-back on delete?
- [ ] Parent component owns and controls navigation state?
- [ ] Delete callbacks are fire-and-forget (parent handles rest)?

---

### 📋 Pre-Implementation Checklists

#### Data Layer Checklist
- [ ] Cascade delete relationships identified and documented?
- [ ] Essential template fields denormalized to entities?
- [ ] All CRUD operations handle not-found gracefully?
- [ ] Database operations run on appropriate thread/context?
- [ ] In-memory database configured for tests?
- [ ] Aggregations across relationships use eager loading or explicit hydration?
- [ ] Tested aggregations with 3+ parent records?
- [ ] Bug fixes include startup migration for existing stale data?

#### UI/Navigation Checklist
- [ ] Navigation uses IDs, not object references?
- [ ] Parent component owns navigation state?
- [ ] Detail views don't self-dismiss on delete?
- [ ] Loading/error states handled for async operations?
- [ ] UI unmounts before data deletion?

#### Enum/Taxonomy Checklist
- [ ] Is the category count between 5-9?
- [ ] Are categories mutually exclusive?
- [ ] Have you defined display properties (color, icon, label) on the enum?
- [ ] Is there a fallback/default case for unknown values?
- [ ] Are all switch statements exhaustive (compiler-enforced)?

#### Project Structure Checklist
- [ ] All source files in designated directories?
- [ ] No source files in IDE bundles or build output?
- [ ] File location checks in CI/CD?
- [ ] Project structure documented?

#### Testing Checklist
- [ ] Mock names are unique and descriptive?
- [ ] Mock visibility compatible with test class?
- [ ] Tests verify actual behavior, not assumptions?
- [ ] Edge cases covered: empty, single item, deletion, error?
- [ ] Async tests use proper waiting/assertion mechanisms?

---

### 🚫 Universal Anti-Patterns

| Anti-Pattern | Why It's Bad | Better Approach |
|--------------|--------------|-----------------|
| Delete then close UI | Race condition, crash | Close UI first, then delete async |
| Template lookup for display | Can fail, slow, N+1 | Denormalize at creation |
| Generic mock names | Collisions, confusion | `{Test}{Mock}{Dependency}` naming |
| Object snapshots for nav | Stale data | ID-based navigation |
| Child controls own dismissal | Race conditions | Parent owns navigation state |
| Test assumed behavior | Tests pass but app broken | Test actual system behavior |
| Tight coupling to framework | Hard to test, migrate | Repository/service abstractions |
| Lazy aggregations | Silent wrong totals | Eager load or touch properties |
| Over-designed enums | Overlap, unused cases | 5-9 categories, user mental model |
| Scattered switch statements | Cascade changes on enum edit | Centralize on enum or config |
| Files in wrong directories | Build/VCS issues | Periodic location audits |
| Init-only defaults for ORM | Migration failures | Default values on property declarations |
| No enum migration decoder | Old data can't decode | Custom init(from:) with legacy mapping |
| Fix creation without migration | Old data stays broken | Startup migration for existing records |

---

### 🔍 Code Review Focus Areas

1. **Deletion flows** - Can UI access data after delete is called?
2. **Navigation state** - Who owns it? IDs or objects?
3. **Entity creation** - All required fields populated?
4. **Mock quality** - Unique names? Proper visibility?
5. **Thread safety** - UI updates on main thread?
6. **Error handling** - Graceful degradation?
7. **ORM aggregations** - Eager loading for relationship aggregations?
8. **Enum design** - 5-9 cases? Mutually exclusive? Properties centralized?
9. **File locations** - All source files in correct directories?
10. **Schema migrations** - New properties have defaults? Enum decoders handle old values?
11. **Data migrations** - Does bug fix need startup migration for existing records?

---

### 🎯 Key Principles

1. **UI Lifecycle > Data Lifecycle**
   - Close views before deleting their data
   - Never assume UI will gracefully handle missing data

2. **Denormalize for Resilience**
   - Copy essential display data at creation
   - Entity should be displayable without external lookups

3. **Test Infrastructure is Production Code**
   - Name mocks carefully
   - Plan visibility requirements upfront

4. **Single Source of Truth for Navigation**
   - One component owns navigation state
   - Children notify, parents navigate

5. **Test Reality, Not Assumptions**
   - Verify what the system actually does
   - Update tests when behavior intentionally changes

6. **Explicit Over Implicit (ORM)**
   - Don't trust lazy loading for aggregations
   - Test with realistic data volumes (3+ records)

7. **Less is More (Taxonomy)**
   - Fewer, broader categories beat many narrow ones
   - User mental model > internal organization

8. **Centralize Change Impact**
   - Enum properties belong on the enum
   - One change location beats scattered switches

9. **Plan for Migration**
   - Schema changes need default values for existing data
   - Enum changes need decoders for legacy values

10. **Fix Forward, Migrate Backward**
    - Bug fixes change how NEW data is created
    - Startup migrations repair EXISTING data
    - Both are required for complete fix

---

## 🎨 UI/UX Implementation Rules (CouponTracker Specific)

### Pattern 6: ViewModel State Clearing (SwiftData + SwiftUI)

**Problem:** SwiftUI re-renders while ViewModel still holds references to deleted SwiftData objects, causing crashes when accessing properties like `benefit.status`.

**Rule:** Clear ViewModel in-memory state BEFORE repository deletion.

```swift
// ❌ WRONG: Delete then reload
func deleteCard(_ card: UserCard) {
    try cardRepository.deleteCard(card)  // SwiftData deletes
    await viewModel.loadData()            // Too late - UI already crashed
}

// ✅ CORRECT: Clear state first
func deleteCard(_ card: UserCard) {
    viewModel.removeCardFromState(card.id)  // Clear in-memory arrays
    selectedCardId = nil                     // Dismiss UI
    Task {
        try cardRepository.deleteCard(card)
        await viewModel.loadData()
    }
}

// In ViewModel:
func removeCardFromState(_ cardId: UUID) {
    cards.removeAll { $0.id == cardId }
    expiringBenefits.removeAll { $0.userCard?.id == cardId }
}
```

**Why:** SwiftUI's reactive rendering may access computed properties (like `displayCards`) between delete and reload.

---

### Pattern 7: UI Consolidation (No Redundant Navigation)

**Problem:** Multiple UI elements providing the same navigation create confusion and clutter.

**Rule:** One entry point per destination. Prefer existing navigation patterns (tab bar, existing cards) over adding new buttons.

```
❌ WRONG: Redundant navigation
- Tab bar has "Wallet" tab
- Dashboard has "View All Cards" button  ← Redundant!
- Dashboard has "Settings" button        ← Tab bar already has this!

✅ CORRECT: Single entry point
- Tab bar handles main navigation (Wallet, Settings)
- Dashboard shows data summaries with drill-down to details
- Stat cards are tappable for related detail views
```

**Checklist:**
- [ ] Is this navigation already available via tab bar?
- [ ] Can an existing element (stat card, section header) be made tappable instead?
- [ ] Does adding this button provide unique value?

---

### Pattern 8: Tappable Summary Cards

**Problem:** Dashboard shows summary stats but users can't drill into details.

**Rule:** Summary cards showing counts/values should be tappable to view the underlying data.

```swift
// ✅ CORRECT: Stat cards with drill-down
StatCard(
    title: "Expiring Soon",
    value: "\(count)",
    icon: "clock.badge.exclamationmark.fill",
    color: count > 0 ? .warning : .success,
    onTap: { showExpiringList = true }  // Opens detail view
)
```

**Visual Indicator:** Show chevron (›) on tappable cards to indicate interactivity.

---

### Pattern 9: Conditional UI Visibility

**Problem:** "See All" or "View More" buttons hidden when count is low, but users still want to access the full view.

**Rule:** Navigation buttons should appear based on whether the destination exists, not arbitrary thresholds.

```swift
// ❌ WRONG: Arbitrary threshold
var shouldShowSeeAll: Bool {
    totalCount > 5  // User with 3 items can't access full view!
}

// ✅ CORRECT: Show if destination has value
var shouldShowSeeAll: Bool {
    onSeeAll != nil  // Always show if navigation is wired
}
```

---

### 🔄 Pattern 10: Eager Hydration for Computed Aggregations

**Problem:** ORM frameworks use lazy loading for relationships. When aggregating values across multiple parent entities (e.g., "total value across all cards"), child properties may not be hydrated, causing:
- Incorrect totals (often 0 or partial)
- Works with small datasets (1-2 items) but fails with more
- Silent failures - no errors, just wrong numbers

**Applies To:** Any ORM with lazy-loaded relationships: SwiftData, CoreData, Hibernate, JPA, Entity Framework, Prisma, Sequelize, ActiveRecord, TypeORM, Django ORM, SQLAlchemy.

**Rule:** When computing aggregations across relationships, explicitly access/touch the properties BEFORE aggregating, or use eager loading hints.

```pseudocode
// ❌ WRONG: Lazy-loaded children may not be hydrated
function getTotalValue(parents):
    return parents.sum(p => p.children.sum(c => c.value))
    // May return 0 if children aren't loaded!

// ✅ CORRECT Option A: Touch properties to trigger hydration
function getTotalValue(parents):
    for parent in parents:
        for child in parent.children:
            _ = child.value        // Access property to hydrate
    return parents.sum(p => p.children.sum(c => c.value))

// ✅ CORRECT Option B: Use eager loading
function getTotalValue():
    parents = repository.findAll(include: ["children"])
    return parents.sum(p => p.children.sum(c => c.value))

// ✅ CORRECT Option C: Database-level aggregation
function getTotalValue():
    return database.query("SELECT SUM(value) FROM children")
```

**Warning Signs:**
- Aggregations work with 1-2 parent records but fail with 3+
- Totals are 0 or obviously wrong without throwing errors
- Adding `print(child.value)` "fixes" the bug

**Checklist:**
- [ ] Are you aggregating across lazy-loaded relationships?
- [ ] Do you have eager loading configured for aggregation queries?
- [ ] Have you tested with 3+ parent entities?
- [ ] Consider database-level aggregation for performance-critical paths?

---

### 📊 Pattern 11: Enum Consolidation Principle (Taxonomy Design)

**Problem:** Enums representing categories/types often start over-designed with too many cases. This leads to:
- Unused cases cluttering codebases
- Overlapping/ambiguous categories
- User confusion about which to select
- Cascading changes when consolidating later

**Applies To:** Any categorical enumeration: product types, user roles, status codes, content categories, priority levels.

**Rule:** Start with fewer, broader categories. It's easier to split later than to merge. Follow Miller's Law (7±2 items).

```pseudocode
// ❌ WRONG: Over-designed taxonomy (11 categories)
enum Category:
    travel, dining, entertainment, shopping,
    transportation, wellness, hotel, airline,
    streaming, rideshare, other  // Many overlap!

// ✅ CORRECT: Consolidated taxonomy (7 categories)
enum Category:
    travel,         // Flights, hotels, CLEAR, miles
    dining,         // Restaurants, food delivery
    transportation, // Rideshare, transit, local
    shopping,       // Retail, online
    entertainment,  // Streaming, events, content
    business,       // Office, wireless, professional
    lifestyle       // Wellness, subscriptions, other
```

**Category Design Principles:**
1. **Mutually Exclusive:** Each item belongs to exactly one category
2. **Collectively Exhaustive:** Every item can be categorized
3. **User Mental Model:** Match how users think, not system internals
4. **Room to Grow:** Prefer broad categories that can accept new subtypes
5. **5-9 Items:** Human working memory handles 5-9 options comfortably

**Checklist:**
- [ ] Can you justify each category with 3+ distinct examples?
- [ ] Do any categories significantly overlap?
- [ ] Would a user intuitively know where an item belongs?
- [ ] Is the total count between 5-9?

---

### 📁 Pattern 12: Source File Location Hygiene

**Problem:** Source files accidentally placed in wrong locations cause:
- Build failures or stale code execution
- Files not tracked by version control
- IDE/tooling confusion
- "It works on my machine" scenarios

**Common Misplacement Locations:**
- Inside IDE project bundles (`.xcodeproj`, `.idea`, `.vscode`)
- Build output directories (`build/`, `dist/`, `target/`, `node_modules/`)
- Cache directories
- Symlinked paths that differ between machines

**Rule:** Periodically audit file locations. Use glob patterns to detect misplaced files.

```bash
# Find source files in wrong locations
find . -name "*.swift" -path "*/.xcodeproj/*"
find . -name "*.ts" -path "*/node_modules/*"
find ./build -name "*.java" -o -name "*.kt"
find ./.idea -name "*.py"
```

**Prevention Measures:**
1. Add misplacement patterns to `.gitignore` to prevent accidental commits
2. Include file location check in CI/CD pipeline
3. IDE settings to warn when creating files in wrong directories
4. Code review checklist item for new file paths

**Checklist:**
- [ ] Are all source files in designated source directories?
- [ ] Are IDE bundle directories excluded from source searches?
- [ ] Does CI fail if source files appear in build output?
- [ ] Is there a documented project structure?

---

### 🔗 Pattern 13: Enum Change Impact Mitigation

**Problem:** When an enum case changes (renamed, added, removed, consolidated), updates cascade through:
- Enum definition file
- Data files (JSON, YAML, database seeds)
- Switch statements for display (colors, icons, labels)
- Switch statements for logic
- Test files and fixtures
- Default/fallback values
- Serialization/deserialization code

**Rule:** Centralize all enum-dependent mappings in ONE location per concern. Use lookup tables instead of scattered switch statements.

```pseudocode
// ❌ WRONG: Scattered switch statements
// File 1: EnumDefinition
enum Category { travel, dining, shopping }

// File 2: Colors
func color(for cat): switch cat { case .travel: blue ... }

// File 3: Icons
func icon(for cat): switch cat { case .travel: "airplane" ... }

// When adding "entertainment", must update 3+ files!

// ✅ CORRECT: Centralized on enum
enum Category {
    travel, dining, shopping

    var displayName: String { ... }  // All in one place
    var iconName: String { ... }
    var color: Color { ... }
}

// ✅ ALTERNATIVE: Configuration-driven
CategoryConfig = {
    travel: { icon: "airplane", color: "#007AFF", label: "Travel" },
    dining: { icon: "fork.knife", color: "#FF9500", label: "Dining" },
}
```

**Checklist for Adding/Changing Enum Cases:**
- [ ] Enum definition updated
- [ ] All switch statements handle new case (use exhaustive switches)
- [ ] Data files/seeds updated
- [ ] Test fixtures updated
- [ ] Documentation updated
- [ ] Migration path for persisted data using old values

**Best Practices:**
1. Use exhaustive switch statements (compiler-enforced when possible)
2. Avoid stringly-typed references to enum names
3. Keep enum display properties ON the enum itself
4. Use configuration files for frequently-changing mappings
5. Write tests that enumerate all cases

---

### 🔄 Pattern 14: ORM Schema Migration Requirements

**Problem:** Adding new properties to ORM models without default values causes migration failures. The ORM cannot populate existing records with the new required fields.

**Applies To:** Any ORM with schema migration: SwiftData, CoreData, Entity Framework, Django ORM, SQLAlchemy, Prisma, TypeORM.

**Symptoms:**
- "Validation error missing attribute values on mandatory destination attribute"
- App crashes on launch after schema change
- Works on fresh install but fails on upgrade

**Rule:** All new model properties MUST have default values in their declarations (not just in init).

```pseudocode
// ❌ WRONG: No default value on property
class UserPreferences {
    var notifyEnabled: Bool      // Migration fails!

    init() {
        notifyEnabled = true     // Default here doesn't help migration
    }
}

// ✅ CORRECT: Default value on property declaration
class UserPreferences {
    var notifyEnabled: Bool = true   // Migration can use this default

    init() {
        // init can still set values if needed
    }
}
```

**Enum Migration:** When consolidating/renaming enum cases, add a custom decoder:

```pseudocode
// Handle legacy values during decoding
init(from decoder: Decoder) {
    let rawValue = decode(String)

    switch rawValue {
    case "oldValue1": self = .newValue1
    case "oldValue2": self = .newValue2
    default: self.init(rawValue: rawValue)
    }
}
```

**Checklist:**
- [ ] All new properties have default values in declarations?
- [ ] Enum changes include migration decoder for old values?
- [ ] Tested upgrade path from previous schema version?
- [ ] Simulator/test database cleared after schema changes?

---

### 🔧 Pattern 15: Startup Data Migration (Fixing Stale Data)

**Problem:** When a bug fix changes how data is created (e.g., denormalizing fields at creation), existing records created before the fix remain broken. Users see incorrect calculations, wrong values, or crashes until they delete and recreate their data.

**Applies To:** Any application with persistent storage where a bug fix changes entity creation logic: mobile apps with local databases, web apps with user data, desktop applications with config files.

**Symptoms:**
- Bug fix works for new data but not existing data
- Users report "it still doesn't work" after update
- Works on fresh install but fails on upgrade
- Incorrect aggregations/calculations for old records

**Rule:** When fixing bugs in entity creation logic, add a startup migration to repair existing records.

```pseudocode
// ❌ WRONG: Fix creation but ignore existing data
// In CardRepository.createBenefit():
benefit.frequency = template.frequency  // Fixed! But old benefits still have nil

// ✅ CORRECT: Fix creation AND migrate existing data
// Step 1: Fix creation (same as above)
benefit.frequency = template.frequency

// Step 2: Add startup migration in AppContainer/AppDelegate
func performStartupTasks():
    await migrateStaleData()
    // ... other startup tasks

func migrateStaleData():
    allEntities = repository.getAll()
    migratedCount = 0

    for entity in allEntities:
        if entity.needsMigration():  // e.g., frequency == nil
            template = templateLoader.getTemplate(entity.templateId)
            if template:
                entity.frequency = template.frequency
                entity.updatedAt = now()
                migratedCount++

    if migratedCount > 0:
        repository.save()
        log("✅ Migrated {migratedCount} entities")
```

**Migration Design Principles:**
1. **Idempotent:** Running multiple times produces same result
2. **Safe:** Check for nil/missing data before accessing
3. **Logged:** Print count of migrated records for debugging
4. **Fast:** Run before UI loads, keep lightweight
5. **Graceful:** Skip records that can't be migrated (missing template)

**When to Add Startup Migration:**
- Bug fix changes how required fields are populated at creation
- Denormalization fix adds fields that were previously looked up
- Enum consolidation changes stored values
- Default value changes for existing nullable fields

**Checklist:**
- [ ] Does the bug fix change entity creation logic?
- [ ] Are there existing records created before the fix?
- [ ] Is there a way to identify stale records (nil field, old enum value)?
- [ ] Can the correct value be determined from templates/config?
- [ ] Is the migration idempotent (safe to run multiple times)?
- [ ] Does the migration log its activity for debugging?

---

## ⚠️ Implementation Protocol

### ASK BEFORE IMPLEMENTING when:

1. **Adding new UI elements** - "Should this be a new button, or can an existing element be made tappable?"
2. **Removing functionality** - "This seems redundant with X. Should I remove it or keep both?"
3. **Changing navigation flow** - "Currently X opens Y. Should it open Z instead?"
4. **Layout decisions** - "Should this section go above or below X?"
5. **Threshold/visibility logic** - "Should this button show always, or only when count > N?"

### DO NOT ASSUME:

- That adding more buttons improves UX (often the opposite)
- That hiding elements when empty is always correct
- That the user wants both a summary AND a detailed view of the same data
- That navigation patterns from the plan match user expectations

### ALWAYS CLARIFY:

```
"I'm about to [action]. This will [effect].
Current behavior: [X]
Proposed behavior: [Y]
Should I proceed, or would you prefer [alternative]?"
```
