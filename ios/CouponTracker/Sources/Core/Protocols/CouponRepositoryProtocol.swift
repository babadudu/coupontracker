// CouponRepositoryProtocol.swift
// CouponTracker
//
// Protocol defining coupon repository operations.

import Foundation

/// Protocol defining coupon repository operations for managing coupons.
/// Abstracts the data layer to allow for different implementations and testing.
@MainActor
protocol CouponRepositoryProtocol {

    // MARK: - Read Operations

    /// Retrieves all coupons from storage, sorted by expiration date.
    /// - Returns: Array of all coupons
    /// - Throws: Repository error if fetch fails
    func getAllCoupons() throws -> [Coupon]

    /// Retrieves a specific coupon by its unique identifier.
    /// - Parameter id: The UUID of the coupon to retrieve
    /// - Returns: The coupon if found, nil otherwise
    /// - Throws: Repository error if fetch fails
    func getCoupon(by id: UUID) throws -> Coupon?

    /// Retrieves all valid (unused and not expired) coupons.
    /// - Returns: Array of valid coupons sorted by expiration date
    /// - Throws: Repository error if fetch fails
    func getValidCoupons() throws -> [Coupon]

    /// Retrieves coupons expiring within a specified number of days.
    /// - Parameter days: Number of days to look ahead
    /// - Returns: Array of coupons expiring within the timeframe
    /// - Throws: Repository error if fetch fails
    func getCouponsExpiringSoon(within days: Int) throws -> [Coupon]

    /// Retrieves coupons for a specific category.
    /// - Parameter category: The category to filter by
    /// - Returns: Array of coupons in the category
    /// - Throws: Repository error if fetch fails
    func getCoupons(by category: CouponCategory) throws -> [Coupon]

    // MARK: - Write Operations

    /// Adds a new coupon to storage.
    /// - Parameter coupon: The coupon to add
    /// - Throws: Repository error if creation fails
    func addCoupon(_ coupon: Coupon) throws

    /// Updates an existing coupon in storage.
    /// - Parameter coupon: The coupon with updated properties
    /// - Throws: Repository error if update fails
    func updateCoupon(_ coupon: Coupon) throws

    /// Deletes a coupon from storage.
    /// - Parameter coupon: The coupon to delete
    /// - Throws: Repository error if deletion fails
    func deleteCoupon(_ coupon: Coupon) throws
}
