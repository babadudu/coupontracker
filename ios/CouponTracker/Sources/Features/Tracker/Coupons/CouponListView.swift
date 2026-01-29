// CouponListView.swift
// CouponTracker
//
// Created: January 2026
// Purpose: List view showing all coupons with filtering.

import SwiftUI

/// List view for all coupons.
///
/// Displays coupons with status filtering, category filtering,
/// and navigation to detail views.
struct CouponListView: View {

    // MARK: - Environment

    @Environment(AppContainer.self) private var container
    @Environment(\.dismiss) private var dismiss

    // MARK: - State

    @Bindable var viewModel: CouponListViewModel
    @State private var showingAddSheet = false
    @State private var selectedCouponId: UUID?

    // MARK: - Body

    var body: some View {
        ZStack {
            if viewModel.isLoading && viewModel.coupons.isEmpty {
                LoadingView()
            } else if viewModel.coupons.isEmpty {
                emptyState
            } else {
                mainContent
            }
        }
        .background(DesignSystem.Colors.backgroundPrimary)
        .navigationTitle("Coupons")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button(action: { showingAddSheet = true }) {
                    Image(systemName: "plus")
                }
            }
        }
        .searchable(text: $viewModel.searchQuery, prompt: "Search coupons")
        .sheet(isPresented: $showingAddSheet) {
            AddCouponView(
                viewModel: AddCouponViewModel(
                    couponRepository: container.couponRepository,
                    notificationService: container.notificationService
                ),
                onComplete: {
                    viewModel.refresh()
                }
            )
        }
        .navigationDestination(item: $selectedCouponId) { couponId in
            CouponDetailView(
                viewModel: CouponDetailViewModel(
                    couponId: couponId,
                    couponRepository: container.couponRepository,
                    notificationService: container.notificationService
                ),
                onDelete: {
                    selectedCouponId = nil
                    viewModel.refresh()
                }
            )
        }
        .alert("Error", isPresented: $viewModel.showingError) {
            Button("OK") { viewModel.dismissError() }
        } message: {
            Text(viewModel.errorMessage ?? "An error occurred")
        }
        .onAppear {
            viewModel.loadCoupons()
        }
        .refreshable {
            viewModel.refresh()
        }
    }

    // MARK: - Main Content

    @ViewBuilder
    private var mainContent: some View {
        List {
            // Summary Section
            Section {
                summaryCard
            }
            .listRowInsets(EdgeInsets())
            .listRowBackground(Color.clear)

            // Filter Section
            Section {
                filterControls
            }

            // Coupons List
            Section {
                ForEach(viewModel.filteredCoupons) { coupon in
                    CouponRowView(coupon: coupon)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            selectedCouponId = coupon.id
                        }
                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                            Button(role: .destructive) {
                                deleteCoupon(coupon.id)
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }

                            if coupon.isValid {
                                Button {
                                    markCouponAsUsed(coupon)
                                } label: {
                                    Label("Used", systemImage: "checkmark")
                                }
                                .tint(DesignSystem.Colors.success)
                            }
                        }
                }
            } header: {
                Text("\(viewModel.filteredCoupons.count) coupons")
            }
        }
        .listStyle(.insetGrouped)
    }

    // MARK: - Summary Card

    @ViewBuilder
    private var summaryCard: some View {
        VStack(spacing: DesignSystem.Spacing.md) {
            HStack {
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                    Text("Total Value")
                        .font(DesignSystem.Typography.caption)
                        .foregroundStyle(DesignSystem.Colors.textSecondary)

                    Text(viewModel.formattedTotalValue)
                        .font(DesignSystem.Typography.valueMedium)
                        .foregroundStyle(DesignSystem.Colors.textPrimary)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: DesignSystem.Spacing.xs) {
                    Text("Valid Coupons")
                        .font(DesignSystem.Typography.caption)
                        .foregroundStyle(DesignSystem.Colors.textSecondary)

                    Text("\(viewModel.validCoupons.count)")
                        .font(DesignSystem.Typography.valueMedium)
                        .foregroundStyle(DesignSystem.Colors.textPrimary)
                }
            }

            if viewModel.expiringSoonCount > 0 {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(DesignSystem.Colors.warning)

                    Text("\(viewModel.expiringSoonCount) expiring within 3 days")
                        .font(DesignSystem.Typography.footnote)
                        .foregroundStyle(DesignSystem.Colors.textSecondary)

                    Spacer()
                }
            }
        }
        .padding(DesignSystem.Spacing.lg)
        .background(DesignSystem.Colors.backgroundSecondary)
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Sizing.cardCornerRadius))
    }

    // MARK: - Filter Controls

    @ViewBuilder
    private var filterControls: some View {
        VStack(spacing: DesignSystem.Spacing.sm) {
            // Status Filter
            Picker("Status", selection: $viewModel.statusFilter) {
                ForEach(CouponListViewModel.CouponStatusFilter.allCases) { filter in
                    Text(filter.rawValue).tag(filter)
                }
            }
            .pickerStyle(.segmented)

            // Category Picker
            HStack {
                Text("Category")
                Spacer()
                Picker("Category", selection: $viewModel.selectedCategory) {
                    Text("All").tag(nil as CouponCategory?)
                    ForEach(CouponCategory.allCases) { category in
                        Label(category.displayName, systemImage: category.iconName)
                            .tag(category as CouponCategory?)
                    }
                }
                .pickerStyle(.menu)
            }
        }
    }

    // MARK: - Empty State

    @ViewBuilder
    private var emptyState: some View {
        VStack(spacing: DesignSystem.Spacing.lg) {
            Image(systemName: "tag")
                .font(.system(size: 64))
                .foregroundStyle(DesignSystem.Colors.textTertiary)

            Text("No Coupons")
                .font(DesignSystem.Typography.title2)
                .foregroundStyle(DesignSystem.Colors.textPrimary)

            Text("Track your coupons and discount codes to never miss a deal.")
                .font(DesignSystem.Typography.body)
                .foregroundStyle(DesignSystem.Colors.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, DesignSystem.Spacing.xxl)

            Button(action: { showingAddSheet = true }) {
                Label("Add Coupon", systemImage: "plus")
                    .font(DesignSystem.Typography.headline)
            }
            .buttonStyle(.borderedProminent)
        }
    }

    // MARK: - Private Methods

    private func deleteCoupon(_ id: UUID) {
        // Close-Before-Delete pattern: clear selection first
        if selectedCouponId == id {
            selectedCouponId = nil
        }
        _ = viewModel.deleteCoupon(id: id)
    }

    private func markCouponAsUsed(_ coupon: Coupon) {
        do {
            coupon.markAsUsed()
            try container.couponRepository.updateCoupon(coupon)
            viewModel.refresh()
        } catch {
            // Error handled silently for swipe action
        }
    }
}

// MARK: - Coupon Row View

struct CouponRowView: View {
    let coupon: Coupon

    var body: some View {
        HStack(spacing: DesignSystem.Spacing.md) {
            // Category Icon
            Image(systemName: coupon.category.iconName)
                .font(.system(size: DesignSystem.Sizing.iconMedium))
                .foregroundStyle(iconColor)
                .frame(width: 40, height: 40)
                .background(iconColor.opacity(0.15))
                .clipShape(RoundedRectangle(cornerRadius: 8))

            // Info
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                Text(coupon.name)
                    .font(DesignSystem.Typography.headline)
                    .foregroundStyle(DesignSystem.Colors.textPrimary)
                    .strikethrough(coupon.isUsed || coupon.isExpired)

                HStack(spacing: DesignSystem.Spacing.sm) {
                    if let merchant = coupon.merchant {
                        Text(merchant)
                            .font(DesignSystem.Typography.subhead)
                            .foregroundStyle(DesignSystem.Colors.textSecondary)
                    } else {
                        Text(coupon.category.displayName)
                            .font(DesignSystem.Typography.subhead)
                            .foregroundStyle(DesignSystem.Colors.textSecondary)
                    }

                    if coupon.code != nil {
                        Image(systemName: "qrcode")
                            .font(.system(size: 12))
                            .foregroundStyle(DesignSystem.Colors.textTertiary)
                    }
                }
            }

            Spacer()

            // Value and Status
            VStack(alignment: .trailing, spacing: DesignSystem.Spacing.xs) {
                if let value = coupon.formattedValue {
                    Text(value)
                        .font(DesignSystem.Typography.headline)
                        .foregroundStyle(DesignSystem.Colors.textPrimary)
                }

                Text(coupon.statusText)
                    .font(DesignSystem.Typography.caption)
                    .foregroundStyle(statusColor)

                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(DesignSystem.Colors.textTertiary)
            }
        }
        .padding(.vertical, DesignSystem.Spacing.xs)
    }

    private var iconColor: Color {
        if coupon.isUsed || coupon.isExpired {
            return DesignSystem.Colors.neutral
        }
        return coupon.category.color
    }

    private var statusColor: Color {
        if coupon.isUsed { return DesignSystem.Colors.success }
        if coupon.isExpired { return DesignSystem.Colors.neutral }
        if coupon.isUrgent { return DesignSystem.Colors.danger }
        if coupon.isExpiringSoon { return DesignSystem.Colors.warning }
        return DesignSystem.Colors.success
    }
}

// MARK: - Preview

#Preview("Coupon List") {
    NavigationStack {
        CouponListView(viewModel: CouponListViewModel.preview)
    }
    .environment(AppContainer.preview)
    .modelContainer(AppContainer.previewModelContainer)
}
