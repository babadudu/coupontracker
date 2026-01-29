// CouponListViewModel.swift
// CouponTracker
//
// Created: January 2026
// Purpose: ViewModel for coupon list managing state and operations.

import Foundation
import Observation

/// ViewModel for the coupon list screen.
///
/// Manages loading coupons, filtering by category/status, and deletion.
/// Uses ID-based navigation pattern (Pattern 3) for detail navigation.
@Observable
@MainActor
final class CouponListViewModel {

    // MARK: - Dependencies

    private let couponRepository: CouponRepositoryProtocol

    // MARK: - State

    /// All coupons from the repository
    private(set) var coupons: [Coupon] = []

    /// Loading state
    private(set) var isLoading = false

    /// Error message
    private(set) var errorMessage: String?

    /// Whether to show error alert
    var showingError = false

    /// Search query for filtering
    var searchQuery: String = ""

    /// Selected category filter
    var selectedCategory: CouponCategory?

    /// Status filter
    var statusFilter: CouponStatusFilter = .valid

    // MARK: - Filter Options

    enum CouponStatusFilter: String, CaseIterable, Identifiable {
        case all = "All"
        case valid = "Valid"
        case expiringSoon = "Expiring Soon"
        case used = "Used"
        case expired = "Expired"

        var id: String { rawValue }
    }

    // MARK: - Computed Properties

    /// Filtered coupons based on search and filters
    var filteredCoupons: [Coupon] {
        var result = coupons

        // Filter by status
        switch statusFilter {
        case .all:
            break
        case .valid:
            result = result.filter { $0.isValid }
        case .expiringSoon:
            result = result.filter { $0.isExpiringSoon }
        case .used:
            result = result.filter { $0.isUsed }
        case .expired:
            result = result.filter { $0.isExpired }
        }

        // Filter by category
        if let category = selectedCategory {
            result = result.filter { $0.category == category }
        }

        // Filter by search query
        if !searchQuery.isEmpty {
            let query = searchQuery.lowercased()
            result = result.filter {
                $0.name.lowercased().contains(query) ||
                ($0.merchant?.lowercased().contains(query) ?? false) ||
                ($0.code?.lowercased().contains(query) ?? false)
            }
        }

        return result.sorted { $0.expirationDate < $1.expirationDate }
    }

    /// Valid (unused, not expired) coupons
    var validCoupons: [Coupon] {
        coupons.filter { $0.isValid }
    }

    /// Coupons expiring soon (within 3 days)
    var expiringSoonCoupons: [Coupon] {
        coupons.filter { $0.isExpiringSoon }
    }

    /// Total value of valid coupons (only those with values)
    var totalValidValue: Decimal {
        validCoupons.compactMap { $0.value }.reduce(Decimal.zero, +)
    }

    /// Formatted total value
    var formattedTotalValue: String {
        Formatters.formatCurrency(totalValidValue)
    }

    /// Count of coupons expiring soon
    var expiringSoonCount: Int {
        expiringSoonCoupons.count
    }

    /// Coupons grouped by category
    var couponsByCategory: [CouponCategory: [Coupon]] {
        Dictionary(grouping: filteredCoupons, by: { $0.category })
    }

    // MARK: - Initialization

    init(couponRepository: CouponRepositoryProtocol) {
        self.couponRepository = couponRepository
    }

    // MARK: - Actions

    /// Loads all coupons from the repository
    func loadCoupons() {
        isLoading = true
        errorMessage = nil

        do {
            coupons = try couponRepository.getAllCoupons()
            isLoading = false
        } catch {
            isLoading = false
            handleError(error, context: "loading coupons")
        }
    }

    /// Refreshes the coupon list
    func refresh() {
        loadCoupons()
    }

    /// Deletes a coupon (Close-Before-Delete pattern)
    /// - Parameter id: The ID of the coupon to delete
    /// - Returns: True if deletion was successful
    func deleteCoupon(id: UUID) -> Bool {
        do {
            guard let coupon = try couponRepository.getCoupon(by: id) else {
                return false
            }
            try couponRepository.deleteCoupon(coupon)
            // Remove from local state
            coupons.removeAll { $0.id == id }
            return true
        } catch {
            handleError(error, context: "deleting coupon")
            return false
        }
    }

    /// Clears all filters
    func clearFilters() {
        searchQuery = ""
        selectedCategory = nil
        statusFilter = .valid
    }

    // MARK: - Error Handling

    private func handleError(_ error: Error, context: String) {
        errorMessage = "Error \(context): \(error.localizedDescription)"
        showingError = true
    }

    func dismissError() {
        showingError = false
        errorMessage = nil
    }
}

// MARK: - Preview Helper

#if DEBUG
extension CouponListViewModel {
    @MainActor
    static var preview: CouponListViewModel {
        let mockRepo = MockCouponRepository()
        mockRepo.coupons = MockCouponFactory.makeSampleCoupons()
        return CouponListViewModel(couponRepository: mockRepo)
    }
}
#endif
