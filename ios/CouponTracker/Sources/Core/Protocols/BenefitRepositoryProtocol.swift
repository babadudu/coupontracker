//
//  BenefitRepositoryProtocol.swift
//  CouponTracker
//
//  Created by Junior Engineer 3 on 2026-01-17.
//

import Foundation

/// Protocol defining benefit repository operations for managing card benefits.
/// This protocol abstracts the data layer to allow for different implementations
/// and facilitates testing with mock repositories.
@MainActor
protocol BenefitRepositoryProtocol {

    // MARK: - Read Operations

    /// Retrieves a single benefit by its unique identifier.
    ///
    /// - Parameter id: The UUID of the benefit to retrieve
    /// - Returns: The benefit if found, nil otherwise
    /// - Throws: Repository error if fetch fails
    func getBenefit(by id: UUID) throws -> Benefit?

    /// Retrieves all benefits for a specific user card.
    /// Benefits are sorted by status (available first) and then by expiration date.
    ///
    /// - Parameter card: The user card to get benefits for
    /// - Returns: Array of benefits for the specified card
    /// - Throws: Repository error if fetch fails
    func getBenefits(for card: UserCard) throws -> [Benefit]

    /// Retrieves all benefits across all cards.
    /// This is useful for dashboard views showing all available benefits.
    ///
    /// - Returns: Array of all benefits
    /// - Throws: Repository error if fetch fails
    func getAllBenefits() throws -> [Benefit]

    /// Retrieves all available benefits across all cards.
    /// Only returns benefits with status = available.
    /// Results are sorted by expiration date (soonest first).
    ///
    /// - Returns: Array of available benefits
    /// - Throws: Repository error if fetch fails
    func getAvailableBenefits() throws -> [Benefit]

    /// Retrieves benefits that are expiring within a specified number of days.
    /// Only returns benefits with status = available.
    /// Results are sorted by expiration date (soonest first).
    ///
    /// - Parameter days: Number of days to look ahead for expiring benefits
    /// - Returns: Array of benefits expiring within the specified timeframe
    /// - Throws: Repository error if fetch fails
    func getExpiringBenefits(within days: Int) throws -> [Benefit]

    // MARK: - Historical Queries

    /// Retrieves the total redeemed value from BenefitUsage records for a period.
    /// Queries actual historical redemptions, not current benefit status.
    ///
    /// - Parameters:
    ///   - period: The view period (monthly/quarterly/semiAnnual/annual)
    ///   - referenceDate: The reference date for period calculation
    /// - Returns: Sum of valueRedeemed for non-expired usages in the period
    /// - Throws: Repository error if fetch fails
    func getRedeemedValue(for period: BenefitPeriod, referenceDate: Date) throws -> Decimal

    /// Gets total redeemed value for a specific period, filtered by benefit frequency.
    ///
    /// - Parameters:
    ///   - period: The view period (monthly/quarterly/semiAnnual/annual)
    ///   - frequency: Only include benefits with this frequency
    ///   - referenceDate: The reference date for period calculation
    /// - Returns: Sum of valueRedeemed for matching usages in the period
    /// - Throws: Repository error if fetch fails
    func getRedeemedValue(for period: BenefitPeriod, frequency: BenefitFrequency, referenceDate: Date) throws -> Decimal

    // MARK: - Write Operations

    /// Marks a benefit as used and creates a usage history record.
    /// This method will:
    /// 1. Update the benefit's status to .used
    /// 2. Create a BenefitUsage record with the current period information
    /// 3. Update timestamps
    ///
    /// - Parameter benefit: The benefit to mark as used
    /// - Throws: Repository error if update fails or benefit is not available
    func markBenefitUsed(_ benefit: Benefit) throws

    /// Resets a benefit to a new period after expiration.
    /// This method will:
    /// 1. Calculate new period dates based on the benefit's frequency
    /// 2. Reset the status to .available
    /// 3. Clear notification state
    /// 4. Update timestamps
    ///
    /// - Parameter benefit: The benefit to reset for a new period
    /// - Throws: Repository error if update fails
    func resetBenefitForNewPeriod(_ benefit: Benefit) throws

    /// Snoozes a benefit's reminder until a specified date.
    /// This method will:
    /// 1. Update the lastReminderDate to postpone notifications
    /// 2. Cancel any scheduled notifications
    /// 3. Update timestamps
    ///
    /// - Parameters:
    ///   - benefit: The benefit to snooze
    ///   - date: The date until which to snooze the reminder
    /// - Throws: Repository error if update fails
    func snoozeBenefit(_ benefit: Benefit, until date: Date) throws

    /// Reverts a benefit from used back to available status.
    /// This allows users to undo accidentally marking a benefit as used.
    /// This method will:
    /// 1. Update the benefit's status back to .available
    /// 2. Remove the most recent usage history record for this period
    /// 3. Update timestamps
    ///
    /// - Parameter benefit: The benefit to revert
    /// - Throws: Repository error if update fails or benefit is not used
    func undoMarkBenefitUsed(_ benefit: Benefit) throws
}
