// SubscriptionListView.swift
// CouponTracker
//
// Created: January 2026
// Purpose: List view showing all subscriptions with filtering and totals.

import SwiftUI

/// List view for all subscriptions.
///
/// Displays subscriptions with total costs, category filtering,
/// and navigation to detail views.
struct SubscriptionListView: View {

    // MARK: - Environment

    @Environment(AppContainer.self) private var container
    @Environment(\.dismiss) private var dismiss

    // MARK: - State

    @Bindable var viewModel: SubscriptionListViewModel
    @State private var showingAddSheet = false
    @State private var selectedSubscriptionId: UUID?
    @State private var subscriptionToDelete: UUID?

    // MARK: - Body

    var body: some View {
        ZStack {
            if viewModel.isLoading && viewModel.subscriptions.isEmpty {
                LoadingView()
            } else if viewModel.subscriptions.isEmpty {
                emptyState
            } else {
                mainContent
            }
        }
        .background(DesignSystem.Colors.backgroundPrimary)
        .navigationTitle("Subscriptions")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button(action: { showingAddSheet = true }) {
                    Image(systemName: "plus")
                }
            }
        }
        .searchable(text: $viewModel.searchQuery, prompt: "Search subscriptions")
        .sheet(isPresented: $showingAddSheet) {
            AddSubscriptionView(
                viewModel: AddSubscriptionViewModel(
                    subscriptionRepository: container.subscriptionRepository,
                    notificationService: container.notificationService
                ),
                onComplete: {
                    viewModel.refresh()
                }
            )
        }
        .navigationDestination(item: $selectedSubscriptionId) { subscriptionId in
            SubscriptionDetailView(
                viewModel: SubscriptionDetailViewModel(
                    subscriptionId: subscriptionId,
                    subscriptionRepository: container.subscriptionRepository,
                    notificationService: container.notificationService
                ),
                onDelete: {
                    selectedSubscriptionId = nil
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
            viewModel.loadSubscriptions()
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

            // Subscriptions List
            Section {
                ForEach(viewModel.filteredSubscriptions) { subscription in
                    SubscriptionRowView(subscription: subscription)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            selectedSubscriptionId = subscription.id
                        }
                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                            Button(role: .destructive) {
                                deleteSubscription(subscription.id)
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                }
            } header: {
                Text("\(viewModel.filteredSubscriptions.count) subscriptions")
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
                    Text("Monthly")
                        .font(DesignSystem.Typography.caption)
                        .foregroundStyle(DesignSystem.Colors.textSecondary)

                    Text(viewModel.formattedMonthlyCost)
                        .font(DesignSystem.Typography.valueMedium)
                        .foregroundStyle(DesignSystem.Colors.textPrimary)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: DesignSystem.Spacing.xs) {
                    Text("Annual")
                        .font(DesignSystem.Typography.caption)
                        .foregroundStyle(DesignSystem.Colors.textSecondary)

                    Text(viewModel.formattedAnnualCost)
                        .font(DesignSystem.Typography.valueMedium)
                        .foregroundStyle(DesignSystem.Colors.textPrimary)
                }
            }

            if viewModel.renewingSoonCount > 0 {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(DesignSystem.Colors.warning)

                    Text("\(viewModel.renewingSoonCount) renewing within 7 days")
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
            // Active Only Toggle
            Toggle("Show active only", isOn: $viewModel.showActiveOnly)

            // Category Picker
            HStack {
                Text("Category")
                Spacer()
                Picker("Category", selection: $viewModel.selectedCategory) {
                    Text("All").tag(nil as SubscriptionCategory?)
                    ForEach(SubscriptionCategory.allCases) { category in
                        Label(category.displayName, systemImage: category.iconName)
                            .tag(category as SubscriptionCategory?)
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
            Image(systemName: "repeat.circle")
                .font(.system(size: 64))
                .foregroundStyle(DesignSystem.Colors.textTertiary)

            Text("No Subscriptions")
                .font(DesignSystem.Typography.title2)
                .foregroundStyle(DesignSystem.Colors.textPrimary)

            Text("Track your recurring subscriptions to see your monthly and annual costs.")
                .font(DesignSystem.Typography.body)
                .foregroundStyle(DesignSystem.Colors.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, DesignSystem.Spacing.xxl)

            Button(action: { showingAddSheet = true }) {
                Label("Add Subscription", systemImage: "plus")
                    .font(DesignSystem.Typography.headline)
            }
            .buttonStyle(.borderedProminent)
        }
    }

    // MARK: - Private Methods

    private func deleteSubscription(_ id: UUID) {
        // Close-Before-Delete pattern: clear selection first
        if selectedSubscriptionId == id {
            selectedSubscriptionId = nil
        }
        _ = viewModel.deleteSubscription(id: id)
    }
}

// MARK: - Subscription Row View

struct SubscriptionRowView: View {
    let subscription: Subscription

    var body: some View {
        HStack(spacing: DesignSystem.Spacing.md) {
            // Category Icon
            Image(systemName: subscription.displayIconName)
                .font(.system(size: DesignSystem.Sizing.iconMedium))
                .foregroundStyle(subscription.category.color)
                .frame(width: 40, height: 40)
                .background(subscription.category.color.opacity(0.15))
                .clipShape(RoundedRectangle(cornerRadius: 8))

            // Info
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                Text(subscription.name)
                    .font(DesignSystem.Typography.headline)
                    .foregroundStyle(DesignSystem.Colors.textPrimary)

                HStack(spacing: DesignSystem.Spacing.sm) {
                    Text(subscription.formattedPrice)
                        .font(DesignSystem.Typography.subhead)
                        .foregroundStyle(DesignSystem.Colors.textSecondary)

                    if !subscription.isActive {
                        Text("Canceled")
                            .font(DesignSystem.Typography.caption)
                            .foregroundStyle(DesignSystem.Colors.neutral)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(DesignSystem.Colors.neutral.opacity(0.2))
                            .clipShape(Capsule())
                    }
                }
            }

            Spacer()

            // Renewal Info
            VStack(alignment: .trailing, spacing: DesignSystem.Spacing.xs) {
                if subscription.isActive {
                    Text(renewalText)
                        .font(DesignSystem.Typography.caption)
                        .foregroundStyle(renewalColor)
                }

                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(DesignSystem.Colors.textTertiary)
            }
        }
        .padding(.vertical, DesignSystem.Spacing.xs)
    }

    private var renewalText: String {
        let days = subscription.daysUntilRenewal
        if days == 0 { return "Today" }
        if days == 1 { return "Tomorrow" }
        if days < 0 { return "Past due" }
        return "in \(days) days"
    }

    private var renewalColor: Color {
        let days = subscription.daysUntilRenewal
        if days <= 0 { return DesignSystem.Colors.danger }
        if days <= 3 { return DesignSystem.Colors.danger }
        if days <= 7 { return DesignSystem.Colors.warning }
        return DesignSystem.Colors.textSecondary
    }
}

// MARK: - Preview

#Preview("Subscription List") {
    NavigationStack {
        SubscriptionListView(viewModel: SubscriptionListViewModel.preview)
    }
    .environment(AppContainer.preview)
    .modelContainer(AppContainer.previewModelContainer)
}
