// AddSubscriptionViewModel.swift
// CouponTracker
//
// Created: January 2026
// Purpose: ViewModel for adding new subscriptions from templates or custom.

import Foundation
import Observation

/// ViewModel for the add subscription screen.
///
/// Manages loading templates, creating subscriptions from templates
/// or custom input, and validation.
@Observable
@MainActor
final class AddSubscriptionViewModel {

    // MARK: - Dependencies

    private let subscriptionRepository: SubscriptionRepositoryProtocol
    private let notificationService: NotificationService

    // MARK: - State

    /// Available subscription templates
    private(set) var templates: [SubscriptionTemplate] = []

    /// Loading state
    private(set) var isLoading = false

    /// Error message
    private(set) var errorMessage: String?

    /// Whether to show error alert
    var showingError = false

    /// Search query for templates
    var searchQuery: String = ""

    /// Selected template (nil = custom)
    var selectedTemplate: SubscriptionTemplate?

    // MARK: - Form Fields (Custom Entry)

    var customName: String = ""
    var customPrice: String = ""
    var customFrequency: SubscriptionFrequency = .monthly
    var customCategory: SubscriptionCategory = .other
    var customStartDate: Date = Date()
    var customNotes: String = ""
    var reminderEnabled: Bool = true
    var reminderDaysBefore: Int = 7

    // MARK: - Computed Properties

    /// Filtered templates based on search
    var filteredTemplates: [SubscriptionTemplate] {
        guard !searchQuery.isEmpty else {
            return templates.sorted { $0.name < $1.name }
        }
        let query = searchQuery.lowercased()
        return templates.filter {
            $0.name.lowercased().contains(query)
        }.sorted { $0.name < $1.name }
    }

    /// Templates grouped by category
    var templatesByCategory: [SubscriptionCategory: [SubscriptionTemplate]] {
        Dictionary(grouping: filteredTemplates, by: { $0.category })
    }

    /// Whether custom form is valid
    var isCustomFormValid: Bool {
        !customName.trimmingCharacters(in: .whitespaces).isEmpty &&
        parsedPrice != nil &&
        (parsedPrice ?? 0) > 0
    }

    /// Parsed price from string
    var parsedPrice: Decimal? {
        let cleaned = customPrice.replacingOccurrences(of: "$", with: "")
            .replacingOccurrences(of: ",", with: "")
        return Decimal(string: cleaned)
    }

    /// Whether a template is selected
    var isTemplateMode: Bool {
        selectedTemplate != nil
    }

    // MARK: - Initialization

    init(
        subscriptionRepository: SubscriptionRepositoryProtocol,
        notificationService: NotificationService
    ) {
        self.subscriptionRepository = subscriptionRepository
        self.notificationService = notificationService
    }

    // MARK: - Actions

    /// Loads subscription templates from bundled JSON
    func loadTemplates() {
        isLoading = true

        do {
            let url = Bundle.main.url(forResource: "SubscriptionTemplates", withExtension: "json")
            guard let url = url else {
                templates = []
                isLoading = false
                return
            }

            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let database = try decoder.decode(SubscriptionTemplateDatabase.self, from: data)
            templates = database.subscriptions
            isLoading = false
        } catch {
            isLoading = false
            handleError(error, context: "loading templates")
        }
    }

    /// Selects a template and pre-fills form
    func selectTemplate(_ template: SubscriptionTemplate) {
        selectedTemplate = template
        customName = template.name
        customFrequency = template.frequency
        customCategory = template.category
        // Use frequency-aware pricing
        if let price = template.price(for: template.frequency) {
            customPrice = "\(price)"
        } else {
            customPrice = "\(template.defaultPrice)"
        }
    }

    /// Updates the price when frequency changes (only for template-based subscriptions)
    /// - Parameter newFrequency: The newly selected frequency
    func onFrequencyChanged(to newFrequency: SubscriptionFrequency) {
        guard let template = selectedTemplate else { return }
        if let price = template.price(for: newFrequency) {
            customPrice = "\(price)"
        }
    }

    /// Clears template selection for custom entry
    func clearSelection() {
        selectedTemplate = nil
        customName = ""
        customPrice = ""
        customFrequency = .monthly
        customCategory = .other
    }

    /// Resets all form state
    func reset() {
        selectedTemplate = nil
        searchQuery = ""
        customName = ""
        customPrice = ""
        customFrequency = .monthly
        customCategory = .other
        customStartDate = Date()
        customNotes = ""
        reminderEnabled = true
        reminderDaysBefore = 7
    }

    /// Creates a subscription from current form state
    /// - Returns: The created subscription, or nil on failure
    func createSubscription() -> Subscription? {
        guard let price = parsedPrice else {
            showError("Please enter a valid price.")
            return nil
        }

        let name = customName.trimmingCharacters(in: .whitespaces)
        guard !name.isEmpty else {
            showError("Please enter a subscription name.")
            return nil
        }

        isLoading = true
        errorMessage = nil

        do {
            let subscription = Subscription(
                userCard: nil,
                templateId: selectedTemplate?.id,
                name: name,
                subscriptionDescription: selectedTemplate?.description,
                price: price,
                frequency: customFrequency,
                category: customCategory,
                startDate: customStartDate,
                nextRenewalDate: customStartDate,
                isActive: true,
                reminderEnabled: reminderEnabled,
                reminderDaysBefore: reminderDaysBefore,
                iconName: selectedTemplate?.iconName,
                websiteUrl: selectedTemplate?.websiteUrl,
                notes: customNotes.isEmpty ? nil : customNotes
            )

            try subscriptionRepository.addSubscription(subscription)

            // Schedule notification if enabled
            if reminderEnabled {
                Task {
                    await notificationService.scheduleSubscriptionRenewalNotification(
                        for: subscription,
                        preferences: UserPreferences()
                    )
                }
            }

            isLoading = false
            return subscription
        } catch {
            isLoading = false
            handleError(error, context: "creating subscription")
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
extension AddSubscriptionViewModel {
    @MainActor
    static var preview: AddSubscriptionViewModel {
        let mockRepo = MockSubscriptionRepository()
        let vm = AddSubscriptionViewModel(
            subscriptionRepository: mockRepo,
            notificationService: NotificationService()
        )
        vm.loadTemplates()
        return vm
    }
}
#endif
