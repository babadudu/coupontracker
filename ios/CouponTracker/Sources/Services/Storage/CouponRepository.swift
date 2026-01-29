// CouponRepository.swift
// CouponTracker
//
// SwiftData implementation of CouponRepositoryProtocol.

import Foundation
import SwiftData

/// SwiftData implementation of CouponRepositoryProtocol.
/// Provides CRUD operations for Coupon entities.
@MainActor
final class CouponRepository: CouponRepositoryProtocol {

    // MARK: - Properties

    private let modelContext: ModelContext

    // MARK: - Initialization

    /// Initializes the repository with a SwiftData model context.
    /// - Parameter modelContext: The SwiftData model context for persistence operations
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    // MARK: - Read Operations

    func getAllCoupons() throws -> [Coupon] {
        let descriptor = FetchDescriptor<Coupon>(
            sortBy: [SortDescriptor(\.expirationDate, order: .forward)]
        )
        return try modelContext.fetch(descriptor)
    }

    func getCoupon(by id: UUID) throws -> Coupon? {
        let couponId = id
        let descriptor = FetchDescriptor<Coupon>(
            predicate: #Predicate<Coupon> { coupon in
                coupon.id == couponId
            }
        )
        return try modelContext.fetch(descriptor).first
    }

    func getValidCoupons() throws -> [Coupon] {
        let now = Date()
        let descriptor = FetchDescriptor<Coupon>(
            sortBy: [SortDescriptor(\.expirationDate, order: .forward)]
        )
        let all = try modelContext.fetch(descriptor)
        return all.filter { !$0.isUsed && $0.expirationDate >= now }
    }

    func getCouponsExpiringSoon(within days: Int) throws -> [Coupon] {
        let calendar = Calendar.current
        let now = Date()
        let threshold = calendar.date(byAdding: .day, value: days, to: now) ?? now

        let descriptor = FetchDescriptor<Coupon>(
            sortBy: [SortDescriptor(\.expirationDate, order: .forward)]
        )
        let all = try modelContext.fetch(descriptor)
        return all.filter {
            !$0.isUsed && $0.expirationDate >= now && $0.expirationDate <= threshold
        }
    }

    func getCoupons(by category: CouponCategory) throws -> [Coupon] {
        let categoryRaw = category.rawValue
        let descriptor = FetchDescriptor<Coupon>(
            predicate: #Predicate<Coupon> { coupon in
                coupon.categoryRawValue == categoryRaw
            },
            sortBy: [SortDescriptor(\.expirationDate, order: .forward)]
        )
        return try modelContext.fetch(descriptor)
    }

    // MARK: - Write Operations

    func addCoupon(_ coupon: Coupon) throws {
        modelContext.insert(coupon)
        try modelContext.save()
    }

    func updateCoupon(_ coupon: Coupon) throws {
        coupon.updatedAt = Date()
        try modelContext.save()
    }

    func deleteCoupon(_ coupon: Coupon) throws {
        modelContext.delete(coupon)
        try modelContext.save()
    }
}
