// AddCouponView.swift
// CouponTracker
//
// Created: January 2026
// Purpose: Sheet for adding new coupons.

import SwiftUI

/// Add coupon sheet view.
///
/// Allows adding coupons with name, code, expiration,
/// category, value, and merchant information.
struct AddCouponView: View {

    // MARK: - Environment

    @Environment(\.dismiss) private var dismiss

    // MARK: - State

    @Bindable var viewModel: AddCouponViewModel
    var onComplete: (() -> Void)?

    // MARK: - Body

    var body: some View {
        NavigationStack {
            Form {
                // Basic Info
                Section("Basic Info") {
                    TextField("Name", text: $viewModel.name)

                    TextField("Merchant (optional)", text: $viewModel.merchant)

                    Picker("Category", selection: $viewModel.category) {
                        ForEach(CouponCategory.allCases) { category in
                            Label(category.displayName, systemImage: category.iconName)
                                .tag(category)
                        }
                    }
                }

                // Value and Code
                Section("Value & Code") {
                    HStack {
                        Text("$")
                        TextField("Value (optional)", text: $viewModel.valueString)
                            .keyboardType(.decimalPad)
                    }

                    TextField("Coupon Code (optional)", text: $viewModel.code)
                        .autocapitalization(.allCharacters)
                        .autocorrectionDisabled()
                }

                // Expiration
                Section("Expiration") {
                    DatePicker(
                        "Expires On",
                        selection: $viewModel.expirationDate,
                        in: Date()...,
                        displayedComponents: .date
                    )

                    if viewModel.daysUntilExpiration > 0 {
                        HStack {
                            Image(systemName: "clock")
                                .foregroundStyle(DesignSystem.Colors.textTertiary)

                            Text("\(viewModel.daysUntilExpiration) days from now")
                                .font(DesignSystem.Typography.subhead)
                                .foregroundStyle(DesignSystem.Colors.textSecondary)
                        }
                    }
                }

                // Reminders
                Section("Reminders") {
                    Toggle("Enable Reminders", isOn: $viewModel.reminderEnabled)

                    if viewModel.reminderEnabled {
                        Picker("Remind me", selection: $viewModel.reminderDaysBefore) {
                            Text("1 day before").tag(1)
                            Text("3 days before").tag(3)
                            Text("7 days before").tag(7)
                        }
                    }
                }

                // Description and Notes
                Section("Additional Info (Optional)") {
                    TextField("Description", text: $viewModel.couponDescription, axis: .vertical)
                        .lineLimit(2...4)

                    TextField("Notes", text: $viewModel.notes, axis: .vertical)
                        .lineLimit(2...4)
                }
            }
            .navigationTitle("Add Coupon")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        addCoupon()
                    }
                    .disabled(!viewModel.isFormValid)
                }
            }
            .alert("Error", isPresented: $viewModel.showingError) {
                Button("OK") { viewModel.dismissError() }
            } message: {
                Text(viewModel.errorMessage ?? "An error occurred")
            }
        }
    }

    // MARK: - Actions

    private func addCoupon() {
        if let _ = viewModel.createCoupon() {
            onComplete?()
            dismiss()
        }
    }
}

// MARK: - Preview

#Preview("Add Coupon") {
    AddCouponView(viewModel: AddCouponViewModel.preview)
        .environment(AppContainer.preview)
        .modelContainer(AppContainer.previewModelContainer)
}
