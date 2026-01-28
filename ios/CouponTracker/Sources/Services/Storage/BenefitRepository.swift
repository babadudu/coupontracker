//
//  BenefitRepository.swift
//  CouponTracker
//
//  Created by Junior Engineer 3 on 2026-01-17.
//

import Foundation
import SwiftData

/// SwiftData implementation of BenefitRepositoryProtocol.
/// Provides operations for managing Benefit entities and their lifecycle.
///
/// Note: Business logic for state transitions is delegated to BenefitStateService.
/// The repository handles persistence and coordination only.
@MainActor
final class BenefitRepository: BenefitRepositoryProtocol {

    // MARK: - Properties

    private let modelContext: ModelContext
    private let stateService: BenefitStateServiceProtocol

    // MARK: - Initialization

    /// Initializes the repository with a SwiftData model context.
    /// - Parameters:
    ///   - modelContext: The SwiftData model context for persistence operations
    ///   - stateService: Service for benefit state logic (defaults to BenefitStateService)
    init(
        modelContext: ModelContext,
        stateService: BenefitStateServiceProtocol = BenefitStateService()
    ) {
        self.modelContext = modelContext
        self.stateService = stateService
    }

    // MARK: - BenefitRepositoryProtocol Implementation

    func getBenefit(by id: UUID) throws -> Benefit? {
        let benefitId = id
        let descriptor = FetchDescriptor<Benefit>(
            predicate: #Predicate<Benefit> { benefit in
                benefit.id == benefitId
            }
        )
        return try modelContext.fetch(descriptor).first
    }

    func getBenefits(for card: UserCard) throws -> [Benefit] {
        let descriptor = FetchDescriptor<Benefit>(
            sortBy: [SortDescriptor(\.currentPeriodEnd, order: .forward)]
        )
        let allBenefits = try modelContext.fetch(descriptor)
        return allBenefits.filter { $0.userCard?.id == card.id }
    }

    func getAllBenefits() throws -> [Benefit] {
        let descriptor = FetchDescriptor<Benefit>(
            sortBy: [SortDescriptor(\.currentPeriodEnd, order: .forward)]
        )
        let benefits = try modelContext.fetch(descriptor)

        // Force properties to load (trigger lazy loading)
        for benefit in benefits {
            _ = benefit.customValue
            _ = benefit.customName
            _ = benefit.status
        }

        return benefits
    }

    func getAvailableBenefits() throws -> [Benefit] {
        let descriptor = FetchDescriptor<Benefit>(
            sortBy: [SortDescriptor(\.currentPeriodEnd, order: .forward)]
        )
        let allBenefits = try modelContext.fetch(descriptor)
        return allBenefits.filter { $0.status == .available }
    }

    func getExpiringBenefits(within days: Int) throws -> [Benefit] {
        let calendar = Calendar.current
        let now = Date()
        let threshold = calendar.date(byAdding: .day, value: days, to: now) ?? now

        let descriptor = FetchDescriptor<Benefit>(
            sortBy: [SortDescriptor(\.currentPeriodEnd, order: .forward)]
        )
        let allBenefits = try modelContext.fetch(descriptor)
        return allBenefits.filter {
            $0.status == .available && $0.currentPeriodEnd <= threshold
        }
    }

    func markBenefitUsed(_ benefit: Benefit) throws {
        // Validate that benefit is available using state service
        guard stateService.canMarkAsUsed(benefit) else {
            throw BenefitRepositoryError.invalidStatusTransition(
                from: benefit.status,
                to: .used
            )
        }

        // Update benefit status
        benefit.status = .used
        benefit.updatedAt = Date()

        // Create usage history record
        let usage = BenefitUsage(
            benefit: benefit,
            usedDate: Date(),
            periodStart: benefit.currentPeriodStart,
            periodEnd: benefit.currentPeriodEnd,
            valueRedeemed: benefit.effectiveValue,
            wasAutoExpired: false,
            cardNameSnapshot: benefit.userCard?.displayName(templateName: nil) ?? "Unknown Card",
            benefitNameSnapshot: benefit.effectiveName
        )

        modelContext.insert(usage)
        try modelContext.save()
    }

    func resetBenefitForNewPeriod(_ benefit: Benefit) throws {
        // Calculate next period dates using state service
        let periodDates = stateService.calculateNextPeriod(for: benefit)

        // Reset the benefit
        benefit.status = .available
        benefit.currentPeriodStart = periodDates.start
        benefit.currentPeriodEnd = periodDates.end
        benefit.nextResetDate = periodDates.nextReset
        benefit.lastReminderDate = nil
        benefit.scheduledNotificationId = nil
        benefit.updatedAt = Date()

        try modelContext.save()
    }

    func snoozeBenefit(_ benefit: Benefit, until date: Date) throws {
        // Update the last reminder date to effectively snooze the reminder
        benefit.lastReminderDate = date

        // Cancel scheduled notification by clearing the ID
        // The notification scheduler will need to check lastReminderDate to reschedule
        benefit.scheduledNotificationId = nil

        benefit.updatedAt = Date()

        try modelContext.save()
    }

    func undoMarkBenefitUsed(_ benefit: Benefit) throws {
        // Validate that benefit is currently used using state service
        guard stateService.canUndo(benefit) else {
            throw BenefitRepositoryError.invalidStatusTransition(
                from: benefit.status,
                to: .available
            )
        }

        // Revert the benefit status back to available
        benefit.undoMarkAsUsed()

        // Remove the most recent usage history record for this period
        // Find and delete the usage record that matches the current period
        if let recentUsage = benefit.usageHistory
            .filter({ usage in
                usage.periodStart == benefit.currentPeriodStart &&
                usage.periodEnd == benefit.currentPeriodEnd
            })
            .sorted(by: { $0.usedDate > $1.usedDate })
            .first {
            modelContext.delete(recentUsage)
        }

        try modelContext.save()
    }

    // MARK: - Historical Queries

    func getRedeemedValue(for period: BenefitPeriod, referenceDate: Date = Date()) throws -> Decimal {
        let (viewStart, viewEnd) = period.periodDates(for: referenceDate)

        let descriptor = FetchDescriptor<BenefitUsage>(
            predicate: #Predicate { usage in
                !usage.wasAutoExpired &&
                usage.periodStart >= viewStart &&
                usage.periodStart <= viewEnd
            }
        )

        let usages = try modelContext.fetch(descriptor)
        return usages.reduce(Decimal.zero) { $0 + $1.valueRedeemed }
    }

    func getRedeemedValue(for period: BenefitPeriod, frequency: BenefitFrequency, referenceDate: Date = Date()) throws -> Decimal {
        let (viewStart, viewEnd) = period.periodDates(for: referenceDate)

        let descriptor = FetchDescriptor<BenefitUsage>(
            predicate: #Predicate { usage in
                !usage.wasAutoExpired &&
                usage.periodStart >= viewStart &&
                usage.periodStart <= viewEnd
            }
        )

        let usages = try modelContext.fetch(descriptor)
        // Filter by frequency in-memory (SwiftData predicates don't support optional relationship properties)
        return usages
            .filter { $0.benefit?.frequency == frequency }
            .reduce(Decimal.zero) { $0 + $1.valueRedeemed }
    }

}

// MARK: - Error Types

/// Errors that can occur during benefit repository operations.
enum BenefitRepositoryError: LocalizedError {
    case invalidStatusTransition(from: BenefitStatus, to: BenefitStatus)

    var errorDescription: String? {
        switch self {
        case .invalidStatusTransition(let from, let to):
            return "Cannot transition benefit from \(from.displayName) to \(to.displayName)"
        }
    }
}
