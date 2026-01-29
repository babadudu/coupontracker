// CouponDetailView.swift
// CouponTracker
//
// Created: January 2026
// Purpose: Detail view for a single coupon.

import SwiftUI

/// Detail view for a single coupon.
///
/// Shows coupon details and allows marking as used,
/// copying code, and deletion.
struct CouponDetailView: View {

    // MARK: - Environment

    @Environment(\.dismiss) private var dismiss

    // MARK: - State

    @Bindable var viewModel: CouponDetailViewModel
    var onDelete: (() -> Void)?

    @State private var showingDeleteConfirmation = false

    // MARK: - Body

    var body: some View {
        Group {
            if viewModel.isLoading && viewModel.coupon == nil {
                LoadingView()
            } else if let coupon = viewModel.coupon {
                couponContent(coupon)
            } else {
                notFoundView
            }
        }
        .navigationTitle(viewModel.coupon?.name ?? "Coupon")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Error", isPresented: $viewModel.showingError) {
            Button("OK") { viewModel.dismissError() }
        } message: {
            Text(viewModel.errorMessage ?? "An error occurred")
        }
        .confirmationDialog(
            "Delete Coupon",
            isPresented: $showingDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("Delete", role: .destructive) {
                if viewModel.deleteCoupon() {
                    onDelete?()
                    dismiss()
                }
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Are you sure you want to delete this coupon?")
        }
        .overlay {
            if viewModel.showingCodeCopied {
                codeCopiedToast
            }
        }
        .onAppear {
            viewModel.loadCoupon()
        }
    }

    // MARK: - Coupon Content

    @ViewBuilder
    private func couponContent(_ coupon: Coupon) -> some View {
        ScrollView {
            VStack(spacing: DesignSystem.Spacing.lg) {
                // Header Card
                headerCard(coupon)

                // Code Section (if exists)
                if let code = coupon.code, !code.isEmpty {
                    codeSection(code)
                }

                // Details Section
                detailsSection(coupon)

                // Actions
                actionsSection(coupon)

                // Delete Button
                deleteSection
            }
            .padding(DesignSystem.Spacing.lg)
        }
        .background(DesignSystem.Colors.backgroundPrimary)
    }

    // MARK: - Header Card

    @ViewBuilder
    private func headerCard(_ coupon: Coupon) -> some View {
        VStack(spacing: DesignSystem.Spacing.md) {
            // Icon and Name
            Image(systemName: coupon.category.iconName)
                .font(.system(size: 48))
                .foregroundStyle(headerIconColor(coupon))
                .frame(width: 80, height: 80)
                .background(headerIconColor(coupon).opacity(0.15))
                .clipShape(RoundedRectangle(cornerRadius: 16))

            Text(coupon.name)
                .font(DesignSystem.Typography.title2)
                .foregroundStyle(DesignSystem.Colors.textPrimary)
                .strikethrough(coupon.isUsed || coupon.isExpired)

            // Status Badge
            statusBadge(coupon)

            // Value
            if let value = coupon.formattedValue {
                Text(value)
                    .font(DesignSystem.Typography.valueLarge)
                    .foregroundStyle(DesignSystem.Colors.textPrimary)
            }

            // Expiration
            HStack(spacing: DesignSystem.Spacing.xs) {
                Image(systemName: "calendar")
                Text("Expires: \(coupon.formattedExpirationDate)")
            }
            .font(DesignSystem.Typography.footnote)
            .foregroundStyle(expirationColor(coupon))
        }
        .frame(maxWidth: .infinity)
        .padding(DesignSystem.Spacing.xl)
        .background(DesignSystem.Colors.backgroundSecondary)
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Sizing.cardCornerRadius))
    }

    @ViewBuilder
    private func statusBadge(_ coupon: Coupon) -> some View {
        HStack(spacing: DesignSystem.Spacing.sm) {
            Circle()
                .fill(statusBadgeColor(coupon))
                .frame(width: 8, height: 8)

            Text(coupon.statusText)
                .font(DesignSystem.Typography.subhead)
                .foregroundStyle(DesignSystem.Colors.textSecondary)
        }
        .padding(.horizontal, DesignSystem.Spacing.md)
        .padding(.vertical, DesignSystem.Spacing.xs)
        .background(statusBadgeColor(coupon).opacity(0.1))
        .clipShape(Capsule())
    }

    // MARK: - Code Section

    @ViewBuilder
    private func codeSection(_ code: String) -> some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
            Text("Coupon Code")
                .font(DesignSystem.Typography.headline)
                .foregroundStyle(DesignSystem.Colors.textPrimary)

            Button(action: { viewModel.copyCode() }) {
                HStack {
                    Text(code)
                        .font(.system(.title2, design: .monospaced))
                        .foregroundStyle(DesignSystem.Colors.textPrimary)

                    Spacer()

                    Image(systemName: "doc.on.doc")
                        .font(.system(size: DesignSystem.Sizing.iconMedium))
                        .foregroundStyle(DesignSystem.Colors.primaryFallback)
                }
                .padding(DesignSystem.Spacing.lg)
                .background(DesignSystem.Colors.primaryFallback.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Sizing.cardCornerRadius))
                .overlay(
                    RoundedRectangle(cornerRadius: DesignSystem.Sizing.cardCornerRadius)
                        .strokeBorder(
                            DesignSystem.Colors.primaryFallback,
                            style: StrokeStyle(lineWidth: 2, dash: [8, 4])
                        )
                )
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - Details Section

    @ViewBuilder
    private func detailsSection(_ coupon: Coupon) -> some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
            Text("Details")
                .font(DesignSystem.Typography.headline)
                .foregroundStyle(DesignSystem.Colors.textPrimary)

            VStack(spacing: 0) {
                detailRow(label: "Category", value: coupon.category.displayName)

                if let merchant = coupon.merchant {
                    Divider()
                    detailRow(label: "Merchant", value: merchant)
                }

                if let description = coupon.couponDescription {
                    Divider()
                    detailRow(label: "Description", value: description)
                }

                Divider()
                detailRow(label: "Days Remaining", value: daysRemainingText(coupon))

                if coupon.isUsed, let usedDate = coupon.usedDate {
                    Divider()
                    detailRow(label: "Used On", value: Formatters.mediumDate.string(from: usedDate))
                }

                if let notes = coupon.notes, !notes.isEmpty {
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

    // MARK: - Actions Section

    @ViewBuilder
    private func actionsSection(_ coupon: Coupon) -> some View {
        VStack(spacing: DesignSystem.Spacing.md) {
            if coupon.isValid {
                // Mark as Used Button
                Button(action: { viewModel.markAsUsed() }) {
                    Label("Mark as Used", systemImage: "checkmark.circle.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
            } else if coupon.isUsed {
                // Undo Button
                Button(action: { viewModel.undoMarkAsUsed() }) {
                    Label("Undo Mark as Used", systemImage: "arrow.uturn.backward.circle")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
            }
        }
    }

    // MARK: - Delete Section

    @ViewBuilder
    private var deleteSection: some View {
        VStack(spacing: DesignSystem.Spacing.md) {
            Divider()

            Button(role: .destructive, action: { showingDeleteConfirmation = true }) {
                Label("Delete Coupon", systemImage: "trash")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .tint(DesignSystem.Colors.danger)
        }
        .padding(.top, DesignSystem.Spacing.lg)
    }

    // MARK: - Code Copied Toast

    @ViewBuilder
    private var codeCopiedToast: some View {
        VStack {
            Spacer()

            HStack(spacing: DesignSystem.Spacing.sm) {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(DesignSystem.Colors.success)

                Text("Code copied!")
                    .font(DesignSystem.Typography.headline)
                    .foregroundStyle(DesignSystem.Colors.textPrimary)
            }
            .padding(DesignSystem.Spacing.lg)
            .background(DesignSystem.Colors.backgroundSecondary)
            .clipShape(Capsule())
            .shadow(DesignSystem.Shadow.level2)
            .padding(.bottom, DesignSystem.Spacing.xxl)
        }
        .transition(.move(edge: .bottom).combined(with: .opacity))
        .animation(.spring(), value: viewModel.showingCodeCopied)
    }

    // MARK: - Not Found View

    @ViewBuilder
    private var notFoundView: some View {
        VStack(spacing: DesignSystem.Spacing.lg) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 48))
                .foregroundStyle(DesignSystem.Colors.warning)

            Text("Coupon Not Found")
                .font(DesignSystem.Typography.title2)
                .foregroundStyle(DesignSystem.Colors.textPrimary)

            Button("Go Back") {
                dismiss()
            }
            .buttonStyle(.bordered)
        }
    }

    // MARK: - Helpers

    private func headerIconColor(_ coupon: Coupon) -> Color {
        if coupon.isUsed || coupon.isExpired {
            return DesignSystem.Colors.neutral
        }
        return coupon.category.color
    }

    private func statusBadgeColor(_ coupon: Coupon) -> Color {
        if coupon.isUsed { return DesignSystem.Colors.success }
        if coupon.isExpired { return DesignSystem.Colors.neutral }
        if coupon.isUrgent { return DesignSystem.Colors.danger }
        if coupon.isExpiringSoon { return DesignSystem.Colors.warning }
        return DesignSystem.Colors.success
    }

    private func expirationColor(_ coupon: Coupon) -> Color {
        if coupon.isExpired { return DesignSystem.Colors.neutral }
        if coupon.isUrgent { return DesignSystem.Colors.danger }
        if coupon.isExpiringSoon { return DesignSystem.Colors.warning }
        return DesignSystem.Colors.textSecondary
    }

    private func daysRemainingText(_ coupon: Coupon) -> String {
        if coupon.isUsed { return "N/A" }
        let days = coupon.daysUntilExpiration
        if days < 0 { return "Expired" }
        if days == 0 { return "Expires today" }
        if days == 1 { return "1 day" }
        return "\(days) days"
    }
}

// MARK: - Preview

#Preview("Coupon Detail") {
    NavigationStack {
        CouponDetailView(viewModel: CouponDetailViewModel.preview)
    }
    .environment(AppContainer.preview)
    .modelContainer(AppContainer.previewModelContainer)
}
