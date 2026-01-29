// TrackerTabView.swift
// CouponTracker
//
// Created: January 2026
// Purpose: Main tracker tab showing subscriptions and coupons sections.

import SwiftUI

/// Main view for the Tracker tab showing subscriptions and coupons.
///
/// Provides navigation to subscription list and coupon list,
/// with summary cards showing key metrics.
struct TrackerTabView: View {

    // MARK: - Environment

    @Environment(AppContainer.self) private var container

    // MARK: - State

    @State private var subscriptionViewModel: SubscriptionListViewModel?
    @State private var couponViewModel: CouponListViewModel?
    @State private var selectedSection: TrackerSection?

    enum TrackerSection: Hashable {
        case subscriptions
        case coupons
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: DesignSystem.Spacing.lg) {
                    // Subscriptions Section
                    subscriptionsSection

                    // Coupons Section
                    couponsSection
                }
                .padding(.horizontal, DesignSystem.Spacing.lg)
                .padding(.vertical, DesignSystem.Spacing.md)
            }
            .background(DesignSystem.Colors.backgroundPrimary)
            .navigationTitle("Tracker")
            .navigationDestination(for: TrackerSection.self) { section in
                switch section {
                case .subscriptions:
                    if let vm = subscriptionViewModel {
                        SubscriptionListView(viewModel: vm)
                    }
                case .coupons:
                    if let vm = couponViewModel {
                        CouponListView(viewModel: vm)
                    }
                }
            }
            .task {
                await initializeViewModels()
            }
            .refreshable {
                await refresh()
            }
        }
    }

    // MARK: - Subscriptions Section

    @ViewBuilder
    private var subscriptionsSection: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
            // Section Header
            HStack {
                Label("Subscriptions", systemImage: "repeat.circle.fill")
                    .font(DesignSystem.Typography.title3)
                    .foregroundStyle(DesignSystem.Colors.textPrimary)

                Spacer()

                NavigationLink(value: TrackerSection.subscriptions) {
                    Text("See All")
                        .font(DesignSystem.Typography.subhead)
                        .foregroundStyle(DesignSystem.Colors.primaryFallback)
                }
            }

            // Summary Card
            NavigationLink(value: TrackerSection.subscriptions) {
                subscriptionSummaryCard
            }
            .buttonStyle(.plain)
        }
    }

    @ViewBuilder
    private var subscriptionSummaryCard: some View {
        VStack(spacing: DesignSystem.Spacing.md) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                    Text("Monthly Cost")
                        .font(DesignSystem.Typography.caption)
                        .foregroundStyle(DesignSystem.Colors.textSecondary)

                    Text(subscriptionViewModel?.formattedMonthlyCost ?? "$0")
                        .font(DesignSystem.Typography.valueMedium)
                        .foregroundStyle(DesignSystem.Colors.textPrimary)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: DesignSystem.Spacing.xs) {
                    Text("Annual Cost")
                        .font(DesignSystem.Typography.caption)
                        .foregroundStyle(DesignSystem.Colors.textSecondary)

                    Text(subscriptionViewModel?.formattedAnnualCost ?? "$0")
                        .font(DesignSystem.Typography.headline)
                        .foregroundStyle(DesignSystem.Colors.textPrimary)
                }
            }

            Divider()

            HStack {
                Label(
                    "\(subscriptionViewModel?.activeSubscriptions.count ?? 0) active",
                    systemImage: "checkmark.circle.fill"
                )
                .font(DesignSystem.Typography.footnote)
                .foregroundStyle(DesignSystem.Colors.success)

                Spacer()

                if let renewingCount = subscriptionViewModel?.renewingSoonCount, renewingCount > 0 {
                    Label(
                        "\(renewingCount) renewing soon",
                        systemImage: "exclamationmark.triangle.fill"
                    )
                    .font(DesignSystem.Typography.footnote)
                    .foregroundStyle(DesignSystem.Colors.warning)
                }
            }
        }
        .padding(DesignSystem.Spacing.lg)
        .background(DesignSystem.Colors.backgroundSecondary)
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Sizing.cardCornerRadius))
        .shadow(DesignSystem.Shadow.level1)
    }

    // MARK: - Coupons Section

    @ViewBuilder
    private var couponsSection: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
            // Section Header
            HStack {
                Label("Coupons", systemImage: "tag.fill")
                    .font(DesignSystem.Typography.title3)
                    .foregroundStyle(DesignSystem.Colors.textPrimary)

                Spacer()

                NavigationLink(value: TrackerSection.coupons) {
                    Text("See All")
                        .font(DesignSystem.Typography.subhead)
                        .foregroundStyle(DesignSystem.Colors.primaryFallback)
                }
            }

            // Summary Card
            NavigationLink(value: TrackerSection.coupons) {
                couponSummaryCard
            }
            .buttonStyle(.plain)
        }
    }

    @ViewBuilder
    private var couponSummaryCard: some View {
        VStack(spacing: DesignSystem.Spacing.md) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                    Text("Total Value")
                        .font(DesignSystem.Typography.caption)
                        .foregroundStyle(DesignSystem.Colors.textSecondary)

                    Text(couponViewModel?.formattedTotalValue ?? "$0")
                        .font(DesignSystem.Typography.valueMedium)
                        .foregroundStyle(DesignSystem.Colors.textPrimary)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: DesignSystem.Spacing.xs) {
                    Text("Valid Coupons")
                        .font(DesignSystem.Typography.caption)
                        .foregroundStyle(DesignSystem.Colors.textSecondary)

                    Text("\(couponViewModel?.validCoupons.count ?? 0)")
                        .font(DesignSystem.Typography.headline)
                        .foregroundStyle(DesignSystem.Colors.textPrimary)
                }
            }

            Divider()

            HStack {
                if let expiring = couponViewModel?.expiringSoonCount, expiring > 0 {
                    Label(
                        "\(expiring) expiring soon",
                        systemImage: "exclamationmark.triangle.fill"
                    )
                    .font(DesignSystem.Typography.footnote)
                    .foregroundStyle(DesignSystem.Colors.warning)
                } else {
                    Label(
                        "No coupons expiring soon",
                        systemImage: "checkmark.circle.fill"
                    )
                    .font(DesignSystem.Typography.footnote)
                    .foregroundStyle(DesignSystem.Colors.success)
                }

                Spacer()
            }
        }
        .padding(DesignSystem.Spacing.lg)
        .background(DesignSystem.Colors.backgroundSecondary)
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Sizing.cardCornerRadius))
        .shadow(DesignSystem.Shadow.level1)
    }

    // MARK: - Private Methods

    private func initializeViewModels() async {
        if subscriptionViewModel == nil {
            subscriptionViewModel = SubscriptionListViewModel(
                subscriptionRepository: container.subscriptionRepository
            )
            subscriptionViewModel?.loadSubscriptions()
        }

        if couponViewModel == nil {
            couponViewModel = CouponListViewModel(
                couponRepository: container.couponRepository
            )
            couponViewModel?.loadCoupons()
        }
    }

    private func refresh() async {
        subscriptionViewModel?.refresh()
        couponViewModel?.refresh()
    }
}

// MARK: - Preview

#Preview("Tracker Tab") {
    TrackerTabView()
        .environment(AppContainer.preview)
        .modelContainer(AppContainer.previewModelContainer)
}
