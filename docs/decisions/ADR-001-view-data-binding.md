# ADR-001: View-Data Binding Strategy

## Status

**Accepted** - January 17, 2026

## Context

### Problem Statement

During Sprint 3 integration, a data model mismatch was identified between the UI components and the domain layer:

- **UI Components** (`CardComponent`, `BenefitRowView`, `WalletView`, etc.) were built using `PreviewCard` and `PreviewBenefit` structs from `PreviewData.swift`
- **ViewModels** (`HomeViewModel`, `CardDetailViewModel`) provide `UserCard` and `Benefit` SwiftData entities
- These types have different property structures and access patterns

### Type Comparison

| Aspect | Preview Types | SwiftData Entities |
|--------|---------------|-------------------|
| `name` | Direct property | Requires template lookup or custom override |
| `issuer` | Direct property | Requires template lookup or custom override |
| `gradient` | `DesignSystem.CardGradient` | `customColorHex` (String) + template |
| Relationships | Embedded arrays | SwiftData `@Relationship` |
| Persistence | None (in-memory) | SwiftData managed |

### Options Considered

**Option A: Presentation Layer Adapters**
- Create extensions/mappers: `UserCard.toPreviewCard()`, `Benefit.toPreviewBenefit()`
- Keep UI components unchanged
- Pros: Minimal UI changes
- Cons: Runtime mapping overhead, maintenance burden, violates DRY

**Option B: Update UI Components Directly**
- Modify views to accept `UserCard` and `Benefit` directly
- Remove preview type dependency from production code
- Pros: Direct data flow
- Cons: SwiftData types in view layer, breaks preview workflow, harder testing

**Option C: Protocol-Based Views**
- Define display protocols (`CardDisplayable`, `BenefitDisplayable`)
- Both preview types and entity types conform to protocols
- Views accept protocol types
- Pros: Flexible, testable, aligns with project architecture
- Cons: Additional protocol definitions (minimal overhead)

## Decision

We adopt **Option C: Protocol-Based Views** with the following implementation:

### 1. Display Protocols

Define protocols that capture what views need to display, without exposing persistence details:

```swift
// CardDisplayable.swift
protocol CardDisplayable: Identifiable {
    var id: UUID { get }
    var displayName: String { get }
    var issuerName: String { get }
    var cardGradient: DesignSystem.CardGradient { get }
    var formattedTotalValue: String { get }
    var displayBenefits: [any BenefitDisplayable] { get }
    var availableBenefitsCount: Int { get }
    var expiringBenefitsCount: Int { get }
    var urgentBenefitsCount: Int { get }
    var isCustomCard: Bool { get }
}

// BenefitDisplayable.swift
protocol BenefitDisplayable: Identifiable {
    var id: UUID { get }
    var displayName: String { get }
    var displayValue: String { get }
    var rawValue: Decimal { get }
    var displayStatus: BenefitStatus { get }
    var daysRemaining: Int { get }
    var isExpiringSoon: Bool { get }
    var isUrgent: Bool { get }
    var categoryIcon: String { get }
    var frequencyLabel: String { get }
    var usedDateFormatted: String? { get }
}
```

### 2. Protocol Conformance

**For SwiftData Entities** (via extensions):

```swift
// UserCard+Displayable.swift
extension UserCard: CardDisplayable {
    var displayName: String {
        displayName(templateName: resolvedTemplateName)
    }

    var cardGradient: DesignSystem.CardGradient {
        // Resolve from customColorHex or template
        resolveGradient()
    }

    var displayBenefits: [any BenefitDisplayable] {
        benefits
    }
    // ... remaining conformance
}

// Benefit+Displayable.swift
extension Benefit: BenefitDisplayable {
    var displayName: String { effectiveName }
    var displayValue: String { formattedValue }
    var displayStatus: BenefitStatus { status }
    var daysRemaining: Int { daysUntilExpiration }
    // ... remaining conformance
}
```

**For Preview Types** (already mostly conformant):

```swift
// PreviewCard+Displayable.swift
extension PreviewCard: CardDisplayable {
    var displayName: String { nickname ?? name }
    var issuerName: String { issuer }
    var cardGradient: DesignSystem.CardGradient { gradient }
    var displayBenefits: [any BenefitDisplayable] { benefits }
    // ... remaining conformance
}
```

### 3. View Updates

Views accept protocol types instead of concrete types:

```swift
struct CardComponent: View {
    let card: any CardDisplayable  // Changed from PreviewCard
    // ... implementation unchanged
}

struct BenefitRowView: View {
    let benefit: any BenefitDisplayable  // Changed from PreviewBenefit
    // ... implementation unchanged
}
```

### 4. Template Resolution Service

For SwiftData entities that reference templates, introduce a service to resolve display properties:

```swift
protocol TemplateResolverProtocol {
    func resolveName(for card: UserCard) -> String
    func resolveIssuer(for card: UserCard) -> String
    func resolveGradient(for card: UserCard) -> DesignSystem.CardGradient
    func resolveName(for benefit: Benefit) -> String
    func resolveValue(for benefit: Benefit) -> Decimal
}
```

## Consequences

### Positive

1. **Testability**: Views can be unit tested with mock protocol implementations
2. **Preview Support**: `PreviewCard`/`PreviewBenefit` continue working in SwiftUI previews
3. **Flexibility**: New data sources (e.g., network responses) can conform to protocols
4. **Separation of Concerns**: SwiftData implementation details stay in the data layer
5. **Alignment**: Matches project's stated "Protocol-Oriented Design" principle
6. **Type Safety**: Compile-time enforcement of required display properties
7. **Minimal UI Changes**: View implementations remain largely unchanged

### Negative

1. **Protocol Overhead**: Small amount of boilerplate for protocol definitions
2. **Existential Types**: Using `any Protocol` has minor runtime overhead (acceptable for UI layer)
3. **Template Resolution Complexity**: Need to inject template resolver for full property resolution

### Neutral

1. **Enum Consolidation**: Should consolidate duplicate enums (`BenefitStatus`, `BenefitFrequency`, `BenefitCategory`) into single definitions used by both layers
2. **Migration Effort**: One-time effort to add protocol conformance and update view signatures

## Implementation Plan

### Phase 1: Protocol Definitions (Sprint 3, Day 1)
- Create `CardDisplayable` protocol in `Core/Protocols/`
- Create `BenefitDisplayable` protocol in `Core/Protocols/`
- Ensure protocols cover all properties used by current views

### Phase 2: Preview Type Conformance (Sprint 3, Day 1)
- Add `CardDisplayable` conformance to `PreviewCard`
- Add `BenefitDisplayable` conformance to `PreviewBenefit`
- Verify all previews still compile and render

### Phase 3: Entity Conformance (Sprint 3, Day 2)
- Create `TemplateResolverService` for template lookups
- Add `CardDisplayable` conformance to `UserCard` (with template resolution)
- Add `BenefitDisplayable` conformance to `Benefit`

### Phase 4: View Migration (Sprint 3, Day 2-3)
- Update `CardComponent` to accept `any CardDisplayable`
- Update `BenefitRowView` to accept `any BenefitDisplayable`
- Update `WalletView`, `CardDetailView`, and other views
- Update ViewModels to expose protocol types

### Phase 5: Enum Consolidation (Sprint 3, Day 3)
- Remove duplicate enum definitions from `PreviewData.swift`
- Update `PreviewBenefit` to use shared `BenefitStatus`, `BenefitFrequency`, `BenefitCategory`

### Phase 6: Testing and Cleanup (Sprint 3, Day 4)
- Add unit tests for protocol conformance
- Remove any unused preview-specific code
- Update documentation

## References

- [Swift Protocol-Oriented Programming - WWDC](https://developer.apple.com/videos/play/wwdc2015/408/)
- [Dependency Inversion Principle](https://en.wikipedia.org/wiki/Dependency_inversion_principle)
- Project Architecture: `docs/architecture/README.md`

## Appendix: Full Protocol Definitions

### CardDisplayable

```swift
import Foundation

/// Protocol defining the display requirements for a credit card in the UI layer.
/// Both SwiftData entities and preview types conform to this protocol,
/// enabling views to work with either data source.
protocol CardDisplayable: Identifiable, Hashable {
    /// Unique identifier
    var id: UUID { get }

    /// Display name (nickname if set, otherwise card name)
    var displayName: String { get }

    /// Card issuer name (e.g., "American Express", "Chase")
    var issuerName: String { get }

    /// Visual gradient for card rendering
    var cardGradient: DesignSystem.CardGradient { get }

    /// Formatted total available value (e.g., "$450")
    var formattedTotalValue: String { get }

    /// Total available value as Decimal
    var totalAvailableValue: Decimal { get }

    /// Benefits associated with this card
    var displayBenefits: [any BenefitDisplayable] { get }

    /// Count of currently available benefits
    var availableBenefitsCount: Int { get }

    /// Count of benefits expiring within 7 days
    var expiringBenefitsCount: Int { get }

    /// Count of urgent benefits (expiring within 3 days)
    var urgentBenefitsCount: Int { get }

    /// Whether this is a user-created custom card
    var isCustomCard: Bool { get }

    /// Optional nickname
    var nickname: String? { get }

    /// Annual fee (optional, for display)
    var annualFee: Decimal? { get }
}
```

### BenefitDisplayable

```swift
import Foundation

/// Protocol defining the display requirements for a benefit in the UI layer.
protocol BenefitDisplayable: Identifiable, Hashable {
    /// Unique identifier
    var id: UUID { get }

    /// Display name of the benefit
    var displayName: String { get }

    /// Formatted value string (e.g., "$15")
    var displayValue: String { get }

    /// Raw decimal value
    var rawValue: Decimal { get }

    /// Current status (available, used, expired)
    var displayStatus: BenefitStatus { get }

    /// Days until expiration (negative if expired)
    var daysRemaining: Int { get }

    /// Whether benefit expires within 7 days
    var isExpiringSoon: Bool { get }

    /// Whether benefit expires within 3 days
    var isUrgent: Bool { get }

    /// SF Symbol name for the category
    var categoryIcon: String { get }

    /// Frequency label (e.g., "/mo", "/yr")
    var frequencyLabel: String { get }

    /// Formatted date when benefit was used (if applicable)
    var usedDateFormatted: String? { get }

    /// Human-readable urgency text (e.g., "3 days left")
    var urgencyText: String { get }

    /// Optional description
    var benefitDescription: String? { get }

    /// Optional merchant name
    var merchantName: String? { get }
}
```
