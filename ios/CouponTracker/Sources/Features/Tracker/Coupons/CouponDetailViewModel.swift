// CouponDetailViewModel.swift
// CouponTracker
//
// Created: January 2026
// Purpose: ViewModel for coupon detail view managing single coupon operations.

import Foundation
import Observation
import UIKit

/// ViewModel for coupon detail screen.
///
/// Manages viewing coupon details, marking as used, and deletion.
@Observable
@MainActor
final class CouponDetailViewModel {

    // MARK: - Dependencies

    private let couponRepository: CouponRepositoryProtocol
    private let notificationService: NotificationService

    // MARK: - State

    /// The coupon ID being managed
    let couponId: UUID

    /// The coupon data (fetched fresh)
    private(set) var coupon: Coupon?

    /// Loading state
    private(set) var isLoading = false

    /// Error message
    private(set) var errorMessage: String?

    /// Whether to show error alert
    var showingError = false

    /// Whether to show delete confirmation
    var showingDeleteConfirmation = false

    /// Whether to show code copied toast
    var showingCodeCopied = false

    // MARK: - Computed Properties

    /// Whether the coupon can be marked as used
    var canMarkAsUsed: Bool {
        guard let coupon = coupon else { return false }
        return coupon.isValid
    }

    /// Whether the coupon can be unmarked
    var canUndoMarkAsUsed: Bool {
        guard let coupon = coupon else { return false }
        return coupon.isUsed
    }

    /// Status display text
    var statusText: String {
        coupon?.statusText ?? "Unknown"
    }

    /// Status color name for UI
    var statusColorName: String {
        guard let coupon = coupon else { return "neutral" }
        if coupon.isUsed { return "success" }
        if coupon.isExpired { return "neutral" }
        if coupon.isUrgent { return "danger" }
        if coupon.isExpiringSoon { return "warning" }
        return "success"
    }

    // MARK: - Initialization

    init(
        couponId: UUID,
        couponRepository: CouponRepositoryProtocol,
        notificationService: NotificationService
    ) {
        self.couponId = couponId
        self.couponRepository = couponRepository
        self.notificationService = notificationService
    }

    // MARK: - Actions

    /// Loads the coupon from repository (fetches fresh - Pattern 3)
    func loadCoupon() {
        isLoading = true
        errorMessage = nil

        do {
            coupon = try couponRepository.getCoupon(by: couponId)
            isLoading = false
        } catch {
            isLoading = false
            handleError(error, context: "loading coupon")
        }
    }

    /// Marks the coupon as used
    func markAsUsed() {
        guard let coupon = coupon, coupon.isValid else { return }

        isLoading = true
        errorMessage = nil

        do {
            coupon.markAsUsed()
            try couponRepository.updateCoupon(coupon)

            // Cancel any scheduled notifications
            notificationService.cancelCouponNotification(for: coupon)

            isLoading = false
        } catch {
            isLoading = false
            handleError(error, context: "marking coupon as used")
        }
    }

    /// Undoes marking the coupon as used
    func undoMarkAsUsed() {
        guard let coupon = coupon, coupon.isUsed else { return }

        isLoading = true
        errorMessage = nil

        do {
            coupon.undoMarkAsUsed()
            try couponRepository.updateCoupon(coupon)

            // Reschedule notification if not expired
            if !coupon.isExpired && coupon.reminderEnabled {
                Task {
                    await notificationService.scheduleCouponExpirationNotification(
                        for: coupon,
                        preferences: UserPreferences()
                    )
                }
            }

            isLoading = false
        } catch {
            isLoading = false
            handleError(error, context: "undoing coupon usage")
        }
    }

    /// Copies the coupon code to clipboard
    func copyCode() {
        guard let code = coupon?.code, !code.isEmpty else { return }

        #if os(iOS)
        UIPasteboard.general.string = code
        showingCodeCopied = true

        // Auto-hide after 2 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) { [weak self] in
            self?.showingCodeCopied = false
        }
        #endif
    }

    /// Deletes the coupon
    /// - Returns: True if successful
    func deleteCoupon() -> Bool {
        guard let coupon = coupon else { return false }

        isLoading = true
        errorMessage = nil

        do {
            notificationService.cancelCouponNotification(for: coupon)
            try couponRepository.deleteCoupon(coupon)
            isLoading = false
            return true
        } catch {
            isLoading = false
            handleError(error, context: "deleting coupon")
            return false
        }
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
extension CouponDetailViewModel {
    @MainActor
    static var preview: CouponDetailViewModel {
        let mockRepo = MockCouponRepository()
        let sample = MockCouponFactory.makeSampleCoupons().first!
        mockRepo.coupons = [sample]

        let vm = CouponDetailViewModel(
            couponId: sample.id,
            couponRepository: mockRepo,
            notificationService: NotificationService()
        )
        vm.loadCoupon()
        return vm
    }
}
#endif
