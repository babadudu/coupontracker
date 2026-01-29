// SubscriptionDetailView.swift
// CouponTracker
//
// Created: January 2026
// Purpose: Detail view for a single subscription.

import SwiftUI

/// Detail view for a single subscription.
///
/// Shows subscription details, payment history, and allows
/// mark as paid, cancel, reactivate, and delete actions.
struct SubscriptionDetailView: View {

    // MARK: - Environment

    @Environment(\.dismiss) private var dismiss

    // MARK: - State

    @Bindable var viewModel: SubscriptionDetailViewModel
    var onDelete: (() -> Void)?

    @State private var showingDeleteConfirmation = false

    // MARK: - Body

    var body: some View {
        Group {
            if viewModel.isLoading && viewModel.subscription == nil {
                LoadingView()
            } else if let subscription = viewModel.subscription {
                subscriptionContent(subscription)
            } else {
                notFoundView
            }
        }
        .navigationTitle(viewModel.subscription?.name ?? "Subscription")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Error", isPresented: $viewModel.showingError) {
            Button("OK") { viewModel.dismissError() }
        } message: {
            Text(viewModel.errorMessage ?? "An error occurred")
        }
        .confirmationDialog(
            "Delete Subscription",
            isPresented: $showingDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("Delete", role: .destructive) {
                if viewModel.deleteSubscription() {
                    onDelete?()
                    dismiss()
                }
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Are you sure you want to delete this subscription? This will also delete all payment history.")
        }
        .confirmationDialog(
            "Record Payment",
            isPresented: $viewModel.showingPaymentConfirmation,
            titleVisibility: .visible
        ) {
            Button("Record Payment") {
                viewModel.markAsPaid()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            if let subscription = viewModel.subscription {
                Text("Record a payment of \(subscription.formattedPrice) and advance to the next renewal period?")
            }
        }
        .confirmationDialog(
            "Cancel Subscription",
            isPresented: $viewModel.showingCancelConfirmation,
            titleVisibility: .visible
        ) {
            Button("Cancel Subscription", role: .destructive) {
                viewModel.cancelSubscription()
            }
            Button("Keep Active", role: .cancel) { }
        } message: {
            Text("Are you sure you want to mark this subscription as canceled?")
        }
        .onAppear {
            viewModel.loadSubscription()
        }
    }

    // MARK: - Subscription Content

    @ViewBuilder
    private func subscriptionContent(_ subscription: Subscription) -> some View {
        ScrollView {
            VStack(spacing: DesignSystem.Spacing.lg) {
                // Header Card
                headerCard(subscription)

                // Details Section
                detailsSection(subscription)

                // Payment History
                if !subscription.paymentHistory.isEmpty {
                    paymentHistorySection(subscription)
                }

                // Actions
                actionsSection(subscription)

                // Delete Button
                deleteSection
            }
            .padding(DesignSystem.Spacing.lg)
        }
        .background(DesignSystem.Colors.backgroundPrimary)
    }

    // MARK: - Header Card

    @ViewBuilder
    private func headerCard(_ subscription: Subscription) -> some View {
        VStack(spacing: DesignSystem.Spacing.md) {
            // Icon and Name
            Image(systemName: subscription.displayIconName)
                .font(.system(size: 48))
                .foregroundStyle(subscription.category.color)
                .frame(width: 80, height: 80)
                .background(subscription.category.color.opacity(0.15))
                .clipShape(RoundedRectangle(cornerRadius: 16))

            Text(subscription.name)
                .font(DesignSystem.Typography.title2)
                .foregroundStyle(DesignSystem.Colors.textPrimary)

            // Status Badge
            HStack(spacing: DesignSystem.Spacing.sm) {
                Circle()
                    .fill(subscription.isActive ? DesignSystem.Colors.success : DesignSystem.Colors.neutral)
                    .frame(width: 8, height: 8)

                Text(subscription.isActive ? "Active" : "Canceled")
                    .font(DesignSystem.Typography.subhead)
                    .foregroundStyle(DesignSystem.Colors.textSecondary)
            }

            // Price
            Text(subscription.formattedPrice)
                .font(DesignSystem.Typography.valueLarge)
                .foregroundStyle(DesignSystem.Colors.textPrimary)

            // Next Renewal
            if subscription.isActive {
                HStack(spacing: DesignSystem.Spacing.xs) {
                    Image(systemName: "calendar")
                    Text("Next renewal: \(Formatters.mediumDate.string(from: subscription.nextRenewalDate))")
                }
                .font(DesignSystem.Typography.footnote)
                .foregroundStyle(renewalColor(for: subscription))
            }
        }
        .frame(maxWidth: .infinity)
        .padding(DesignSystem.Spacing.xl)
        .background(DesignSystem.Colors.backgroundSecondary)
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Sizing.cardCornerRadius))
    }

    // MARK: - Details Section

    @ViewBuilder
    private func detailsSection(_ subscription: Subscription) -> some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
            Text("Details")
                .font(DesignSystem.Typography.headline)
                .foregroundStyle(DesignSystem.Colors.textPrimary)

            VStack(spacing: 0) {
                detailRow(label: "Category", value: subscription.category.displayName)
                Divider()
                detailRow(label: "Frequency", value: subscription.frequency.displayName)
                Divider()
                detailRow(label: "Annual Cost", value: subscription.formattedAnnualCost)
                Divider()
                detailRow(label: "Start Date", value: Formatters.mediumDate.string(from: subscription.startDate))

                if let card = subscription.cardNameSnapshot {
                    Divider()
                    detailRow(label: "Payment Card", value: card)
                }

                if let notes = subscription.notes, !notes.isEmpty {
                    Divider()
                    detailRow(label: "Notes", value: notes)
                }
            }
            .background(DesignSystem.Colors.backgroundSecondary)
            .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Sizing.cardCornerRadius))
        }
    }

    @ViewBuilder
    private func detailRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(DesignSystem.Typography.body)
                .foregroundStyle(DesignSystem.Colors.textSecondary)

            Spacer()

            Text(value)
                .font(DesignSystem.Typography.body)
                .foregroundStyle(DesignSystem.Colors.textPrimary)
                .multilineTextAlignment(.trailing)
        }
        .padding(DesignSystem.Spacing.md)
    }

    // MARK: - Payment History Section

    @ViewBuilder
    private func paymentHistorySection(_ subscription: Subscription) -> some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
            HStack {
                Text("Payment History")
                    .font(DesignSystem.Typography.headline)
                    .foregroundStyle(DesignSystem.Colors.textPrimary)

                Spacer()

                Text("Total: \(viewModel.formattedTotalPaid)")
                    .font(DesignSystem.Typography.subhead)
                    .foregroundStyle(DesignSystem.Colors.textSecondary)
            }

            VStack(spacing: 0) {
                ForEach(subscription.paymentHistory.sorted { $0.paymentDate > $1.paymentDate }.prefix(5)) { payment in
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(Formatters.mediumDate.string(from: payment.paymentDate))
                                .font(DesignSystem.Typography.body)
                                .foregroundStyle(DesignSystem.Colors.textPrimary)

                            if payment.wasAutoRecorded {
                                Text("Auto-recorded")
                                    .font(DesignSystem.Typography.caption)
                                    .foregroundStyle(DesignSystem.Colors.textTertiary)
                            }
                        }

                        Spacer()

                        Text(Formatters.formatCurrency(payment.amount))
                            .font(DesignSystem.Typography.body)
                            .foregroundStyle(DesignSystem.Colors.textPrimary)
                    }
                    .padding(DesignSystem.Spacing.md)

                    if payment.id != subscription.paymentHistory.sorted(by: { $0.paymentDate > $1.paymentDate }).prefix(5).last?.id {
                        Divider()
                    }
                }
            }
            .background(DesignSystem.Colors.backgroundSecondary)
            .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Sizing.cardCornerRadius))
        }
    }

    // MARK: - Actions Section

    @ViewBuilder
    private func actionsSection(_ subscription: Subscription) -> some View {
        VStack(spacing: DesignSystem.Spacing.md) {
            if subscription.isActive {
                // Mark as Paid Button
                Button(action: { viewModel.showingPaymentConfirmation = true }) {
                    Label("Record Payment", systemImage: "checkmark.circle.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)

                // Cancel Button
                Button(action: { viewModel.showingCancelConfirmation = true }) {
                    Label("Cancel Subscription", systemImage: "xmark.circle")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .tint(DesignSystem.Colors.danger)
            } else {
                // Reactivate Button
                Button(action: { viewModel.reactivateSubscription() }) {
                    Label("Reactivate Subscription", systemImage: "arrow.clockwise.circle.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
            }
        }
    }

    // MARK: - Delete Section

    @ViewBuilder
    private var deleteSection: some View {
        VStack(spacing: DesignSystem.Spacing.md) {
            Divider()

            Button(role: .destructive, action: { showingDeleteConfirmation = true }) {
                Label("Delete Subscription", systemImage: "trash")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .tint(DesignSystem.Colors.danger)
        }
        .padding(.top, DesignSystem.Spacing.lg)
    }

    // MARK: - Not Found View

    @ViewBuilder
    private var notFoundView: some View {
        VStack(spacing: DesignSystem.Spacing.lg) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 48))
                .foregroundStyle(DesignSystem.Colors.warning)

            Text("Subscription Not Found")
                .font(DesignSystem.Typography.title2)
                .foregroundStyle(DesignSystem.Colors.textPrimary)

            Button("Go Back") {
                dismiss()
            }
            .buttonStyle(.bordered)
        }
    }

    // MARK: - Helpers

    private func renewalColor(for subscription: Subscription) -> Color {
        let days = subscription.daysUntilRenewal
        if days <= 0 { return DesignSystem.Colors.danger }
        if days <= 3 { return DesignSystem.Colors.danger }
        if days <= 7 { return DesignSystem.Colors.warning }
        return DesignSystem.Colors.textSecondary
    }
}

// MARK: - Preview

#Preview("Subscription Detail") {
    NavigationStack {
        SubscriptionDetailView(viewModel: SubscriptionDetailViewModel.preview)
    }
    .environment(AppContainer.preview)
    .modelContainer(AppContainer.previewModelContainer)
}
