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
@MainActor
final class BenefitRepository: BenefitRepositoryProtocol {

    // MARK: - Properties

    private let modelContext: ModelContext

    // MARK: - Initialization

    /// Initializes the repository with a SwiftData model context.
    /// - Parameter modelContext: The SwiftData model context for persistence operations
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    // MARK: - BenefitRepositoryProtocol Implementation

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
        let threshold = calendar.date(byAdding: .day, value: days, to: Date())!

        let descriptor = FetchDescriptor<Benefit>(
            sortBy: [SortDescriptor(\.currentPeriodEnd, order: .forward)]
        )
        let allBenefits = try modelContext.fetch(descriptor)
        return allBenefits.filter {
            $0.status == .available && $0.currentPeriodEnd <= threshold
        }
    }

    func markBenefitUsed(_ benefit: Benefit) throws {
        // Validate that benefit is available
        guard benefit.status == .available else {
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
        // Get the frequency from custom override or infer from period length
        let frequency = benefit.customFrequency ?? inferFrequencyFromPeriod(benefit)

        // Calculate next period dates using the day after current period end
        let calendar = Calendar.current
        let nextStart = calendar.date(byAdding: .day, value: 1, to: benefit.currentPeriodEnd)!

        // Use the BenefitFrequency enum's built-in period calculation
        let (newPeriodStart, newPeriodEnd, nextReset) = frequency.calculatePeriodDates(
            from: nextStart,
            resetDayOfMonth: nil // Use calendar boundaries for resets
        )

        // Reset the benefit
        benefit.status = .available
        benefit.currentPeriodStart = newPeriodStart
        benefit.currentPeriodEnd = newPeriodEnd
        benefit.nextResetDate = nextReset
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
        // Validate that benefit is currently used
        guard benefit.status == .used else {
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

    // MARK: - Private Helper Methods

    /// Infers the benefit frequency from the period length.
    /// This is used when custom frequency is not set and template lookup is unavailable.
    /// - Parameter benefit: The benefit to infer frequency for
    /// - Returns: The inferred benefit frequency
    private func inferFrequencyFromPeriod(_ benefit: Benefit) -> BenefitFrequency {
        let calendar = Calendar.current
        let components = calendar.dateComponents(
            [.month],
            from: benefit.currentPeriodStart,
            to: benefit.currentPeriodEnd
        )

        guard let months = components.month else {
            return .monthly // Default fallback
        }

        // Infer based on period length
        switch months {
        case 0...1:
            return .monthly
        case 2...4:
            return .quarterly
        case 5...7:
            return .semiAnnual
        default:
            return .annual
        }
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
