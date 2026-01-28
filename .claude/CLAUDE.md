# CLAUDE.md

> Keep this file under 300 lines. Move task-specific instructions to `.claude/commands/`.

---

## 1. Token Efficiency Protocol (CRITICAL)

**These rules are NON-NEGOTIABLE. Token waste = slow responses + lost context.**

### Communication Rules
- **Concise responses only.** Acknowledge with "Done." or "Understood."
- **Never output full files.** Use Edit tool with search/replace blocks.
- **No exploratory reads.** Ask for specific file paths, never `ls -R` or read entire directories.

### Context Management
- **Use `/clear` between unrelated tasks** to reset context.
- **Use `/compact` when context fills** (~50%+) to summarize and continue.
- **Pipe data directly:** `cat logs.txt | claude` instead of copy-paste.
- **Use subagents for complex research** - preserves main context while exploring.

### Extended Thinking Triggers
Use these phrases to increase thinking budget when needed:
- `think` → standard thinking
- `think hard` → deeper analysis
- `think harder` → complex problems
- `ultrathink` → maximum reasoning

### Smart Reading Protocol
**Default:** Use Grep to find method signatures before reading full files.

**Technique:**
1. `Grep` for `func methodName` or `class ClassName` to locate
2. `Read` with `limit: 30-50` lines from that location for signature + docstring
3. Only `Read` full implementation if docstring is missing/unclear

**When full read is acceptable:**
- File < 100 lines
- Debugging a specific bug
- Docstring says "see implementation for details"
- User explicitly requests full context

**If forced to read implementation due to poor docs:**
Flag the file for documentation improvement.

### File Reference Efficiency
- **Tab-complete specific files** rather than broad searches
- **Mention files by path** when you know them
- **Disable unused MCP servers** via `/mcp` - each adds to system prompt

---

## 2. Workflow Protocol

### Session Start
1. **Plan Mode first** (Shift+Tab twice) for non-trivial tasks
2. Refine plan through discussion before implementation
3. Switch to auto-accept only when plan is approved

### Verification Loop (2-3x Quality Improvement)
> "Give Claude a way to verify its work." — Boris Cherny

Always provide feedback mechanisms:
- Run tests after changes
- Use browser/simulator for UI changes
- Check build output for type errors
- Verify with actual data, not assumptions

### Skills (Auto-Invoked)
Skills in `.claude/skills/<name>/SKILL.md` auto-invoke via `description` field:
- `/add-swift-file` — triggers when creating `.swift` files
- `/arch-check` — triggers when editing Views/ViewModels/Repositories
- `/pattern-check` — triggers after delete/navigation/aggregation changes

### Learning Loop
When Claude makes a mistake:
1. Correct it in the current session
2. Add the lesson to this file immediately (use `#` key)
3. Commit the CLAUDE.md update with related PR

---

## 3. Core Development Patterns

### Pattern 1: Close-Before-Delete
**Problem:** Deleting data while UI references it → crash.

```pseudocode
// ✅ CORRECT
closeDetailView()           // UI unmounts first
async: database.delete(id)  // Then delete
```

**Rule:** Dismiss UI → Capture ID → Delete async → Refresh.

---

### Pattern 2: Denormalize at Creation
**Problem:** Template lookups fail → broken display.

```pseudocode
// ✅ CORRECT: Copy essential fields
entity.name = template.name
entity.value = template.value
entity.category = template.category
```

**Rule:** Entity must render without loading its template.

---

### Pattern 3: ID-Based Navigation
**Problem:** Object snapshots become stale after updates.

```pseudocode
// ✅ CORRECT
selectedItemId = item.id
// Detail view fetches fresh: repository.findById(selectedItemId)
```

**Rule:** Navigate with IDs. Detail views fetch fresh data.

---

### Pattern 4: Single Dismiss Point
**Problem:** Multiple components dismissing → race conditions.

**Rule:** Parent owns navigation state. Children notify, parents navigate.

---

### Pattern 5: Eager Hydration for Aggregations
**Problem:** Lazy-loaded relationships → wrong totals (often 0).

**Warning signs:**
- Works with 1-2 records, fails with 3+
- Adding `print(value)` "fixes" the bug

**Rule:** Touch properties before aggregating, or use eager loading.

---

### Pattern 6: Schema Migration Safety
**Problem:** New properties without defaults → migration crash.

```pseudocode
// ✅ CORRECT: Default on property declaration
var notifyEnabled: Bool = true  // Migration uses this
```

**Rule:** All new model properties MUST have default values in declarations.

---

### Pattern 7: Fix Forward, Migrate Backward
**Problem:** Bug fix works for new data, old data stays broken.

**Rule:** When fixing entity creation bugs:
1. Fix creation logic for NEW records
2. Add startup migration to repair EXISTING records
3. Make migration idempotent (safe to run multiple times)

---

## 4. Quick Reference

### Anti-Patterns Table
| Don't | Do Instead |
|-------|------------|
| Delete then close UI | Close UI, then delete async |
| Template lookup for display | Denormalize at creation |
| Pass object to detail view | Pass ID, fetch fresh |
| Child dismisses itself | Parent controls navigation |
| Lazy aggregations | Eager load or touch properties |
| Init-only defaults | Default on property declaration |
| Fix creation only | Add startup migration too |

### Pre-Implementation Checklist
- [ ] UI unmounts before data deletion?
- [ ] Essential fields denormalized from templates?
- [ ] Navigation uses IDs, not objects?
- [ ] Parent owns navigation state?
- [ ] New properties have default values?
- [ ] Aggregations tested with 3+ records?
- [ ] Bug fix includes startup migration?

### Code Review Focus
1. Can UI access data after delete?
2. Who owns navigation state?
3. All required fields populated at creation?
4. New properties have defaults?
5. Aggregations use eager loading?

---

## 5. Design Guidelines

### Enum/Taxonomy Design
- **5-9 categories** (Miller's Law)
- **Mutually exclusive** - each item fits one category
- **Properties on enum** - centralize color, icon, label
- **Migration decoder** for renamed/removed cases

### UI Consolidation
- **One entry point per destination** - no redundant navigation
- **Tappable summary cards** with drill-down
- **Show navigation if destination exists** - not arbitrary thresholds

### Documentation Standard (Language-Agnostic)

**Class/Module Level:**
- One-line purpose statement
- List relationships/dependencies if applicable

**Public Method/Function Level:**
- One-line description of WHAT it does (not HOW)
- Parameters: name, type, constraints
- Returns: type and meaning
- Throws/Errors: conditions that cause failure

**When to Skip:**
- Private helpers < 10 lines with obvious intent
- Getters/setters with no logic
- Test methods (name should be self-documenting)

**Quality Check:**
Can someone use this method correctly by reading ONLY the signature + docstring?
If no → improve the docstring.

---

## 6. Implementation Protocol

### ASK Before Implementing
- Adding new UI elements?
- Removing existing functionality?
- Changing navigation flow?
- Multiple valid approaches?

### Clarification Template
```
I'm about to [action]. This will [effect].
Current: [X]
Proposed: [Y]
Should I proceed?
```

---

## 7. Architectural Constraints

### File Size Limits
| Layer | Max Lines | Action if Exceeded |
|-------|-----------|-------------------|
| Views | 400 | Extract subviews or use configuration pattern |
| ViewModels | 300 | Extract services for business logic |
| Repositories | 150 | CRUD only - move logic to services |

### Layering Rules
```
Views → ViewModels → Services → Repositories → SwiftData
```

| Layer | Allowed Dependencies | Forbidden |
|-------|---------------------|-----------|
| View | ViewModel, DesignSystem | Repository, Service, SwiftData |
| ViewModel | Service, Repository, Protocol | SwiftData Models directly |
| Service | Repository, Protocol | View, ViewModel |
| Repository | SwiftData, Protocol | Service, ViewModel, Business Logic |

### Repository Rules
- **CRUD operations only** - no calculations, no business rules
- Move `inferFrequency`, status transitions, aggregations to Services
- Exception: Simple fetch filtering (e.g., `status == .available`)

### Protocol Compliance
- Views accepting model data MUST use `BenefitDisplayable` or `CardDisplayable`
- Never use concrete `PreviewBenefit` in production Views
- Exception: Preview blocks only

### Mock Consolidation
- All mocks in `SharedMockRepositories.swift`
- Never create per-test or per-ViewModel mock classes
- Test files import shared mocks only

### Calendar/Date Operations
- Use `Date` extensions for period logic
- Never call `Calendar.current.dateComponents` directly in ViewModels
- Exception: Simple "days remaining" calculations

### Business Logic Placement
Before adding logic to ViewModel, ask:
- Reusable across screens? → **Service**
- Date/period calculations? → **PeriodCalculationService**
- Aggregates entities? → **AggregationService**
- Presentation-only (formatting, loading)? → **ViewModel (OK)**

---

## 8. Project-Specific (CouponTracker)

### Tech Stack
- SwiftUI + SwiftData
- MVVM + Services architecture
- Repository pattern for data access

### SwiftUI + SwiftData Specifics
Clear ViewModel state BEFORE repository deletion:
```swift
viewModel.removeCardFromState(card.id)  // Clear arrays
selectedCardId = nil                     // Dismiss UI
Task { try cardRepository.deleteCard(card) }
```

### @Observable Limitation
`@Observable` classes with `private(set)` properties **cannot** conform to protocols requiring settable properties. Don't create shared `Loadable` protocols for `isLoading`/`error` - each ViewModel manages its own.

### Protocol Naming
When adding protocols with common property names, use unique identifiers:
- ❌ `protocol HasValue { var value: Decimal }` (conflicts)
- ✅ `protocol HasMonetaryValue { var monetaryValue: Decimal }` (unique)

### Category Taxonomy (7 categories)
travel, dining, transportation, shopping, entertainment, business, lifestyle

### Skills (Auto-Invoke via Description)
All skills in `.claude/skills/` auto-invoke based on their `description` frontmatter:
- `/add-swift-file` — new `.swift` file in `ios/`
- `/arch-check` — editing Views/ViewModels/Repositories
- `/pattern-check` — delete ops, navigation, aggregation logic

---

## Sources & Further Reading
- [Anthropic: Claude Code Best Practices](https://www.anthropic.com/engineering/claude-code-best-practices)
- [How Boris Uses Claude Code](https://howborisusesclaudecode.com/)
- [Token-Efficient Tool Use](https://docs.claude.com/en/docs/agents-and-tools/tool-use/token-efficient-tool-use)
- [Writing a Good CLAUDE.md](https://www.humanlayer.dev/blog/writing-a-good-claude-md)
