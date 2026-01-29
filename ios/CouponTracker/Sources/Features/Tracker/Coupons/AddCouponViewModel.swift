// AddCouponViewModel.swift
// CouponTracker
//
// Created: January 2026
// Purpose: ViewModel for adding new coupons.

import Foundation
import Observation

/// ViewModel for the add coupon screen.
///
/// Manages form validation and coupon creation.
@Observable
@MainActor
final class AddCouponViewModel {

    // MARK: - Dependencies

    private let couponRepository: CouponRepositoryProtocol
    private let notificationService: NotificationService

    // MARK: - State

    /// Loading state
    private(set) var isLoading = false

    /// Error message
    private(set) var errorMessage: String?

    /// Whether to show error alert
    var showingError = false

    // MARK: - Form Fields

    var name: String = ""
    var couponDescription: String = ""
    var expirationDate: Date = Calendar.current.date(byAdding: .month, value: 1, to: Date()) ?? Date()
    var category: CouponCategory = .other
    var valueString: String = ""
    var merchant: String = ""
    var code: String = ""
    var notes: String = ""
    var reminderEnabled: Bool = true
    var reminderDaysBefore: Int = 3

    // MARK: - Computed Properties

    /// Whether form is valid for submission
    var isFormValid: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty &&
        expirationDate > Date()
    }

    /// Parsed value (optional)
    var parsedValue: Decimal? {
        guard !valueString.isEmpty else { return nil }
        let cleaned = valueString.replacingOccurrences(of: "$", with: "")
            .replacingOccurrences(of: ",", with: "")
        return Decimal(string: cleaned)
    }

    /// Formatted expiration date
    var formattedExpirationDate: String {
        Formatters.mediumDate.string(from: expirationDate)
    }

    /// Days until expiration
    var daysUntilExpiration: Int {
        let calendar = Calendar.current
        let components = calendar.dateComponents(
            [.day],
            from: calendar.startOfDay(for: Date()),
            to: calendar.startOfDay(for: expirationDate)
        )
        return components.day ?? 0
    }

    // MARK: - Initialization

    init(
        couponRepository: CouponRepositoryProtocol,
        notificationService: NotificationService
    ) {
        self.couponRepository = couponRepository
        self.notificationService = notificationService
    }

    // MARK: - Actions

    /// Resets all form state
    func reset() {
        name = ""
        couponDescription = ""
        expirationDate = Calendar.current.date(byAdding: .month, value: 1, to: Date()) ?? Date()
        category = .other
        valueString = ""
        merchant = ""
        code = ""
        notes = ""
        reminderEnabled = true
        reminderDaysBefore = 3
    }

    /// Creates a coupon from current form state
    /// - Returns: The created coupon, or nil on failure
    func createCoupon() -> Coupon? {
        let trimmedName = name.trimmingCharacters(in: .whitespaces)
        guard !trimmedName.isEmpty else {
            showError("Please enter a coupon name.")
            return nil
        }

        guard expirationDate > Date() else {
            showError("Expiration date must be in the future.")
            return nil
        }

        isLoading = true
        errorMessage = nil

        do {
            let coupon = Coupon(
                name: trimmedName,
                couponDescription: couponDescription.isEmpty ? nil : couponDescription,
                expirationDate: expirationDate,
                category: category,
                value: parsedValue,
                merchant: merchant.isEmpty ? nil : merchant,
                code: code.isEmpty ? nil : code,
                isUsed: false,
                reminderEnabled: reminderEnabled,
                reminderDaysBefore: reminderDaysBefore,
                notes: notes.isEmpty ? nil : notes
            )

            try couponRepository.addCoupon(coupon)

            // Schedule notification if enabled
            if reminderEnabled {
                Task {
                    await notificationService.scheduleCouponExpirationNotification(
                        for: coupon,
                        preferences: UserPreferences()
                    )
                }
            }

            isLoading = false
            return coupon
        } catch {
            isLoading = false
            handleError(error, context: "creating coupon")
            return nil
        }
    }

    // MARK: - Error Handling

    private func handleError(_ error: Error, context: String) {
        errorMessage = "Error \(context): \(error.localizedDescription)"
        showingError = true
    }

    private func showError(_ message: String) {
        errorMessage = message
        showingError = true
    }

    func dismissError() {
        showingError = false
        errorMessage = nil
    }
}

// MARK: - Preview Helper

#if DEBUG
extension AddCouponViewModel {
    @MainActor
    static var preview: AddCouponViewModel {
        let mockRepo = MockCouponRepository()
        return AddCouponViewModel(
            couponRepository: mockRepo,
            notificationService: NotificationService()
        )
    }
}
#endif
