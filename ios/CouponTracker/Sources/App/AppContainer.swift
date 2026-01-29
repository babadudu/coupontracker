// AppContainer.swift
// CouponTracker
//
// Created: January 2026
// Purpose: Dependency injection container that manages service initialization
//          and provides factory methods for repositories and services.

import SwiftUI
import SwiftData
import Observation
import os

/// Centralized dependency injection container for the application.
///
/// AppContainer follows the composition root pattern, creating and managing
/// all dependencies at app startup. Services are lazily initialized when first accessed.
///
/// Usage:
/// ```swift
/// @Environment(AppContainer.self) var container
/// let cardRepo = container.cardRepository
/// ```
@Observable
@MainActor
final class AppContainer {

    // MARK: - Core Dependencies

    /// SwiftData model container
    let modelContainer: ModelContainer

    /// Main model context for SwiftData operations
    var modelContext: ModelContext {
        modelContainer.mainContext
    }

    // MARK: - Repositories (Lazy Initialization)

    private var _cardRepository: CardRepositoryProtocol?
    private var _benefitRepository: BenefitRepositoryProtocol?
    private var _subscriptionRepository: SubscriptionRepositoryProtocol?
    private var _couponRepository: CouponRepositoryProtocol?
    private var _templateLoader: TemplateLoader?

    /// Repository for card operations (conforms to CardRepositoryProtocol)
    var cardRepository: CardRepositoryProtocol {
        if _cardRepository == nil {
            _cardRepository = CardRepository(modelContext: modelContext)
        }
        return _cardRepository!
    }

    /// Repository for benefit operations (conforms to BenefitRepositoryProtocol)
    var benefitRepository: BenefitRepositoryProtocol {
        if _benefitRepository == nil {
            _benefitRepository = BenefitRepository(modelContext: modelContext)
        }
        return _benefitRepository!
    }

    /// Repository for subscription operations
    var subscriptionRepository: SubscriptionRepositoryProtocol {
        if _subscriptionRepository == nil {
            _subscriptionRepository = SubscriptionRepository(modelContext: modelContext)
        }
        return _subscriptionRepository!
    }

    /// Repository for coupon operations
    var couponRepository: CouponRepositoryProtocol {
        if _couponRepository == nil {
            _couponRepository = CouponRepository(modelContext: modelContext)
        }
        return _couponRepository!
    }

    /// Template loader for card templates from bundled JSON
    var templateLoader: TemplateLoaderProtocol {
        if _templateLoader == nil {
            _templateLoader = TemplateLoader()
        }
        return _templateLoader!
    }

    // MARK: - Services (Lazy Initialization)

    private var _notificationService: NotificationService?
    private var _benefitResetService: BenefitResetService?
    private var _recommendationService: CardRecommendationService?

    /// Service for managing notifications
    var notificationService: NotificationService {
        if _notificationService == nil {
            _notificationService = NotificationService()
        }
        return _notificationService!
    }

    /// Service for resetting benefit periods
    var benefitResetService: BenefitResetService {
        if _benefitResetService == nil {
            _benefitResetService = BenefitResetService(
                benefitRepository: benefitRepository,
                templateLoader: templateLoader,
                modelContext: modelContext
            )
        }
        return _benefitResetService!
    }

    /// Service for card recommendations
    var recommendationService: CardRecommendationServiceProtocol {
        if _recommendationService == nil {
            _recommendationService = CardRecommendationService(
                cardRepository: cardRepository,
                templateLoader: templateLoader
            )
        }
        return _recommendationService!
    }

    // MARK: - Initialization

    /// Standard initializer with model container
    init(modelContainer: ModelContainer) {
        self.modelContainer = modelContainer
    }

    /// Initializer for testing with injectable dependencies
    init(
        modelContainer: ModelContainer,
        cardRepository: CardRepositoryProtocol? = nil,
        benefitRepository: BenefitRepositoryProtocol? = nil,
        templateLoader: TemplateLoader? = nil
    ) {
        self.modelContainer = modelContainer
        self._cardRepository = cardRepository
        self._benefitRepository = benefitRepository
        self._templateLoader = templateLoader
    }

    // MARK: - Factory Methods

    /// Creates a new model context for background operations
    func createBackgroundContext() -> ModelContext {
        ModelContext(modelContainer)
    }

    /// Factory for testing with mock dependencies
    @MainActor
    static func forTesting(
        modelContext: ModelContext,
        cardRepository: CardRepositoryProtocol? = nil,
        benefitRepository: BenefitRepositoryProtocol? = nil
    ) -> AppContainer {
        let schema = Schema([
            UserCard.self,
            Benefit.self,
            BenefitUsage.self,
            UserPreferences.self,
            Subscription.self,
            SubscriptionPayment.self,
            Coupon.self
        ])

        let configuration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: true
        )

        guard let container = try? ModelContainer(
            for: schema,
            configurations: [configuration]
        ) else {
            fatalError("Failed to create test ModelContainer")
        }

        return AppContainer(
            modelContainer: container,
            cardRepository: cardRepository,
            benefitRepository: benefitRepository
        )
    }

    /// Performs setup tasks that should run on app launch
    func performStartupTasks() async {
        // 1. Migrate benefits with nil customFrequency (data fix for pre-denormalization cards)
        await migrateNilFrequencyBenefits()

        // 2. Check for expired benefit periods and reset
        await benefitResetService.processExpiredPeriods()

        // 3. Pre-load templates (cached after first load)
        _ = try? templateLoader.loadAllTemplates()
    }

    /// Migrates existing benefits that have nil customFrequency by looking up their template.
    /// This fixes cards added before the denormalization fix was applied.
    private func migrateNilFrequencyBenefits() async {
        do {
            let allBenefits = try benefitRepository.getAllBenefits()
            var migratedCount = 0

            for benefit in allBenefits {
                // Only migrate benefits with nil customFrequency
                guard benefit.customFrequency == nil else { continue }

                // Look up the template to get the correct frequency
                if let templateId = benefit.templateBenefitId,
                   let template = try? templateLoader.getBenefitTemplate(by: templateId) {
                    benefit.customFrequency = template.frequency
                    benefit.customCategory = template.category
                    benefit.updatedAt = Date()
                    migratedCount += 1
                }
            }

            if migratedCount > 0 {
                try modelContext.save()
            }
        } catch {
            AppLogger.data.error("Failed to migrate nil frequency benefits: \(error.localizedDescription)")
        }
    }
}

// MARK: - Preview Support

extension AppContainer {

    /// Preview container with in-memory storage
    static var preview: AppContainer {
        AppContainer(modelContainer: previewModelContainer)
    }

    /// Preview model container with in-memory storage
    static var previewModelContainer: ModelContainer {
        let schema = Schema([
            UserCard.self,
            Benefit.self,
            BenefitUsage.self,
            UserPreferences.self,
            Subscription.self,
            SubscriptionPayment.self,
            Coupon.self
        ])

        let configuration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: true
        )

        do {
            let container = try ModelContainer(
                for: schema,
                configurations: [configuration]
            )

            // Add preview data
            Task { @MainActor in
                insertPreviewData(into: container.mainContext)
            }

            return container
        } catch {
            fatalError("Failed to create preview ModelContainer: \(error)")
        }
    }

    /// Inserts sample data for previews
    @MainActor
    private static func insertPreviewData(into context: ModelContext) {
        // Create sample card
        let card = UserCard(
            cardTemplateId: UUID(uuidString: "550e8400-e29b-41d4-a716-446655440001"),
            nickname: "Personal",
            isCustom: false
        )
        context.insert(card)

        // Create sample benefits
        let calendar = Calendar.current
        let now = Date()
        let periodStart = calendar.date(from: calendar.dateComponents([.year, .month], from: now)) ?? now
        let periodEnd = calendar.date(byAdding: DateComponents(month: 1, day: -1), to: periodStart) ?? now

        let benefit1 = Benefit(
            userCard: card,
            templateBenefitId: UUID(uuidString: "550e8400-e29b-41d4-a716-446655440101"),
            customName: "Uber Credits",
            customValue: 15,
            status: .available,
            currentPeriodStart: periodStart,
            currentPeriodEnd: periodEnd
        )
        context.insert(benefit1)

        let benefit2 = Benefit(
            userCard: card,
            templateBenefitId: UUID(uuidString: "550e8400-e29b-41d4-a716-446655440104"),
            customName: "Digital Entertainment Credit",
            customValue: 20,
            status: .used,
            currentPeriodStart: periodStart,
            currentPeriodEnd: periodEnd
        )
        context.insert(benefit2)

        // Create preferences
        let prefs = UserPreferences()
        prefs.hasCompletedOnboarding = true
        context.insert(prefs)

        try? context.save()
    }
}

// MARK: - Environment Key

/// Environment key for accessing AppContainer
private struct AppContainerKey: EnvironmentKey {
    static let defaultValue: AppContainer? = nil
}

extension EnvironmentValues {
    var appContainer: AppContainer? {
        get { self[AppContainerKey.self] }
        set { self[AppContainerKey.self] = newValue }
    }
}

// MARK: - Service Implementations

/// Benefit reset service for processing expired periods
@MainActor
final class BenefitResetService {

    private let benefitRepository: BenefitRepositoryProtocol
    private let templateLoader: TemplateLoaderProtocol
    private let modelContext: ModelContext

    init(
        benefitRepository: BenefitRepositoryProtocol,
        templateLoader: TemplateLoaderProtocol,
        modelContext: ModelContext
    ) {
        self.benefitRepository = benefitRepository
        self.templateLoader = templateLoader
        self.modelContext = modelContext
    }

    /// Processes all benefits that need period reset
    func processExpiredPeriods() async {
        do {
            // Get all benefits and filter those needing reset
            let allBenefits = try benefitRepository.getAllBenefits()
            let benefitsNeedingReset = allBenefits.filter { $0.needsReset }

            for benefit in benefitsNeedingReset {
                await processBenefitReset(benefit)
            }
        } catch {
            AppLogger.data.error("Failed to process expired periods: \(error.localizedDescription)")
        }
    }

    /// Processes a single benefit reset
    private func processBenefitReset(_ benefit: Benefit) async {
        // If benefit was available, create an expiration record
        if benefit.status == .available {
            benefit.markAsExpired()

            // Create usage record for expired benefit
            let usage = BenefitUsage.createForExpiration(
                benefit: benefit,
                cardName: benefit.userCard?.displayName(templateName: nil) ?? "Unknown",
                benefitName: benefit.effectiveName,
                value: benefit.effectiveValue
            )
            modelContext.insert(usage)
        }

        // Reset to new period using repository
        do {
            try benefitRepository.resetBenefitForNewPeriod(benefit)
        } catch {
            AppLogger.benefits.error("Failed to reset benefit for new period: \(error.localizedDescription)")
        }
    }
}
