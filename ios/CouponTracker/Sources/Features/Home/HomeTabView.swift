//
//  HomeTabView.swift
//  CouponTracker
//
//  Created: January 2026
//  Purpose: Home tab showing dashboard with benefit overview.
//

import SwiftUI
import SwiftData

// MARK: - Home Tab View

/// Home tab showing dashboard with benefit overview
struct HomeTabView: View {
    @Environment(AppContainer.self) private var container
    @Binding var viewModel: HomeViewModel?

    // MARK: - Navigation State
    @State private var showAddCard = false
    @State private var showExpiringList = false
    @State private var showValueBreakdown = false
    @State private var selectedBenefitCardId: UUID?
    @State private var selectedPeriod: BenefitPeriod = .monthly

    // Drill-down navigation state
    @State private var selectedCategoryForDrillDown: BenefitCategory?
    @State private var selectedPeriodForDrillDown: TimePeriodFilter?

    var onSwitchToWallet: (() -> Void)?
    var onSwitchToSettings: (() -> Void)?
    var onSwitchToTracker: (() -> Void)?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: DesignSystem.Spacing.xl) {
                    if let viewModel = viewModel {
                        // Insight Banner (if applicable)
                        if let insight = viewModel.currentInsight {
                            InsightBannerView(
                                insight: insight,
                                onTap: {
                                    switch insight {
                                    case .urgentExpiring:
                                        showExpiringList = true
                                    case .onboarding:
                                        showAddCard = true
                                    case .availableValue:
                                        showValueBreakdown = true
                                    case .subscriptionsRenewing, .couponsExpiring:
                                        onSwitchToTracker?()
                                    case .annualFeeDue:
                                        // Navigate to wallet tab (cards have the annual fee)
                                        onSwitchToWallet?()
                                    default:
                                        break
                                    }
                                }
                            )
                        }

                        // Progress Card (swipeable across periods)
                        ProgressCardView(
                            selectedPeriod: $selectedPeriod,
                            redeemedValue: viewModel.redeemedValue(for: selectedPeriod),
                            totalValue: viewModel.metrics(for: selectedPeriod).totalValue,
                            usedCount: viewModel.metrics(for: selectedPeriod).usedCount,
                            totalCount: viewModel.metrics(for: selectedPeriod).totalCount,
                            onTap: { showValueBreakdown = true }
                        )

                        // Summary Cards (Total Available + Expiring Soon)
                        dashboardSummary(viewModel: viewModel)

                        // Benefit Category Chart
                        if !viewModel.isEmpty {
                            BenefitCategoryChartView(
                                benefits: viewModel.allDisplayBenefits,
                                onMarkAsDone: { benefit in
                                    markBenefitAsDoneFromChart(benefit)
                                }
                            )
                        }

                        // Quick Stats (for empty state)
                        quickStats(viewModel: viewModel)
                    } else {
                        LoadingView()
                    }
                }
                .padding(.horizontal, DesignSystem.Spacing.lg)
                .padding(.vertical, DesignSystem.Spacing.md)
            }
            .background(DesignSystem.Colors.backgroundPrimary)
            .navigationTitle("Dashboard")
            .toolbar {
                ToolbarItem(placement: .principal) {
                    VStack(spacing: 0) {
                        Text("Dashboard")
                            .font(DesignSystem.Typography.headline)

                        if let lastRefreshed = viewModel?.lastRefreshedText {
                            Text(lastRefreshed)
                                .font(DesignSystem.Typography.caption)
                                .foregroundStyle(DesignSystem.Colors.textTertiary)
                        }
                    }
                }
            }
            .refreshable {
                await viewModel?.loadData()
                let generator = UINotificationFeedbackGenerator()
                generator.notificationOccurred(.success)
            }
            .sheet(isPresented: $showAddCard, onDismiss: {
                Task { await viewModel?.loadData() }
            }) {
                AddCardView(
                    viewModel: AddCardViewModel(
                        cardRepository: container.cardRepository,
                        templateLoader: container.templateLoader,
                        notificationService: container.notificationService,
                        modelContext: container.modelContext
                    )
                )
            }
            .sheet(isPresented: $showExpiringList) {
                if let viewModel = viewModel {
                    ExpiringBenefitsListView(
                        viewModel: viewModel,
                        container: container,
                        onSelectCard: { cardId in
                            showExpiringList = false
                            selectedBenefitCardId = cardId
                        }
                    )
                }
            }
            .sheet(isPresented: $showValueBreakdown) {
                if let viewModel = viewModel {
                    ValueBreakdownView(
                        viewModel: viewModel,
                        onSelectCard: { cardId in
                            showValueBreakdown = false
                            selectedBenefitCardId = cardId
                        },
                        onSelectCategory: { category in
                            showValueBreakdown = false
                            selectedCategoryForDrillDown = category
                        },
                        onSelectPeriod: { period in
                            showValueBreakdown = false
                            selectedPeriodForDrillDown = period
                        }
                    )
                }
            }
            .navigationDestination(isPresented: Binding(
                get: { selectedBenefitCardId != nil },
                set: { if !$0 { selectedBenefitCardId = nil } }
            )) {
                if let cardId = selectedBenefitCardId,
                   let viewModel = viewModel,
                   let cardAdapter = viewModel.displayCards.first(where: { $0.id == cardId }) {
                    CardDetailView(
                        card: cardAdapter.toPreviewCard(),
                        onMarkAsDone: { benefit in
                            markBenefitAsDone(benefit)
                        },
                        onSnooze: { benefit, days in
                            snoozeBenefit(benefit, days: days)
                        },
                        onUndo: { benefit in
                            undoMarkBenefitUsed(benefit)
                        },
                        onRemoveCard: {
                            deleteCard(cardId)
                        },
                        onEditCard: { }
                    )
                }
            }
            // Category drill-down navigation
            .navigationDestination(isPresented: Binding(
                get: { selectedCategoryForDrillDown != nil },
                set: { if !$0 { selectedCategoryForDrillDown = nil } }
            )) {
                if let category = selectedCategoryForDrillDown,
                   let viewModel = viewModel {
                    CategoryBenefitsView(
                        category: category,
                        viewModel: viewModel,
                        container: container,
                        onSelectCard: { cardId in
                            selectedCategoryForDrillDown = nil
                            selectedBenefitCardId = cardId
                        }
                    )
                }
            }
            // Period drill-down navigation
            .navigationDestination(isPresented: Binding(
                get: { selectedPeriodForDrillDown != nil },
                set: { if !$0 { selectedPeriodForDrillDown = nil } }
            )) {
                if let period = selectedPeriodForDrillDown,
                   let viewModel = viewModel {
                    PeriodBenefitsView(
                        period: period,
                        viewModel: viewModel,
                        container: container,
                        onSelectCard: { cardId in
                            selectedPeriodForDrillDown = nil
                            selectedBenefitCardId = cardId
                        }
                    )
                }
            }
        }
    }

    // MARK: - Dashboard Summary

    @ViewBuilder
    private func dashboardSummary(viewModel: HomeViewModel) -> some View {
        VStack(spacing: DesignSystem.Spacing.md) {
            HStack(spacing: DesignSystem.Spacing.md) {
                StatCard(
                    title: "Cards",
                    value: "\(viewModel.cardCount)",
                    icon: "creditcard.fill",
                    color: DesignSystem.Colors.primaryFallback
                )

                StatCard(
                    title: "Expiring Soon",
                    value: "\(viewModel.expiringThisWeekCount)",
                    icon: "clock.badge.exclamationmark.fill",
                    color: viewModel.expiringThisWeekCount > 0 ? DesignSystem.Colors.warning : DesignSystem.Colors.success,
                    onTap: { showExpiringList = true }
                )
            }

            // Subscription and Coupon Widgets
            trackerWidgets
        }
    }

    // MARK: - Tracker Widgets

    @ViewBuilder
    private var trackerWidgets: some View {
        HStack(spacing: DesignSystem.Spacing.md) {
            SubscriptionWidgetView(
                monthlyCost: subscriptionMonthlyCost,
                renewingSoonCount: subscriptionRenewingSoonCount,
                onTap: { onSwitchToTracker?() }
            )

            CouponWidgetView(
                validCount: couponValidCount,
                expiringSoonCount: couponExpiringSoonCount,
                totalSavings: couponTotalSavings,
                onTap: { onSwitchToTracker?() }
            )
        }
    }

    // MARK: - Tracker Widget Data (Computed from Repository)

    private var subscriptionMonthlyCost: Decimal {
        (try? container.subscriptionRepository.getActiveSubscriptions()
            .reduce(Decimal.zero) { $0 + $1.monthlyCost }) ?? 0
    }

    private var subscriptionRenewingSoonCount: Int {
        (try? container.subscriptionRepository.getSubscriptionsRenewingSoon(within: 7).count) ?? 0
    }

    private var couponValidCount: Int {
        (try? container.couponRepository.getValidCoupons().count) ?? 0
    }

    private var couponExpiringSoonCount: Int {
        (try? container.couponRepository.getCouponsExpiringSoon(within: 7).count) ?? 0
    }

    private var couponTotalSavings: Decimal {
        (try? container.couponRepository.getValidCoupons()
            .reduce(Decimal.zero) { $0 + ($1.value ?? 0) }) ?? 0
    }

    // MARK: - Quick Stats (Empty State)

    @ViewBuilder
    private func quickStats(viewModel: HomeViewModel) -> some View {
        if viewModel.isEmpty {
            VStack(spacing: DesignSystem.Spacing.lg) {
                Image(systemName: "creditcard.fill")
                    .font(.system(size: 60))
                    .foregroundStyle(DesignSystem.Colors.primaryFallback)
                    .symbolEffect(.pulse, options: .repeating)

                Text("Start Tracking Your Benefits")
                    .font(DesignSystem.Typography.title2)
                    .foregroundStyle(DesignSystem.Colors.textPrimary)
                    .multilineTextAlignment(.center)

                Text("Never miss a credit card benefit again.\nTrack expiring credits, earn more rewards,\nand maximize your card value.")
                    .font(DesignSystem.Typography.body)
                    .foregroundStyle(DesignSystem.Colors.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)

                Button(action: {
                    showAddCard = true
                }) {
                    HStack(spacing: DesignSystem.Spacing.sm) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 18, weight: .semibold))

                        Text("Add Your First Card")
                            .font(DesignSystem.Typography.headline)
                    }
                    .foregroundStyle(DesignSystem.Colors.onColor)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, DesignSystem.Spacing.md)
                    .background(
                        RoundedRectangle(cornerRadius: DesignSystem.Sizing.buttonCornerRadius)
                            .fill(DesignSystem.Colors.primaryFallback)
                    )
                }
                .padding(.top, DesignSystem.Spacing.sm)
                .accessibilityLabel("Add your first card")
                .accessibilityHint("Opens the add card screen")
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, DesignSystem.Spacing.xxl)
            .padding(.horizontal, DesignSystem.Spacing.lg)
        }
    }
}

// MARK: - Home Tab View Actions

extension HomeTabView {

    func markBenefitAsDone(_ benefit: PreviewBenefit) {
        Task {
            do {
                let allBenefits = try container.benefitRepository.getAllBenefits()
                if let matchingBenefit = allBenefits.first(where: { $0.id == benefit.id }) {
                    try container.benefitRepository.markBenefitUsed(matchingBenefit)
                    container.notificationService.cancelNotifications(for: matchingBenefit)
                    await viewModel?.loadData()
                }
            } catch {
                // Error marking benefit as done
            }
        }
    }

    func markBenefitAsDoneFromChart(_ benefit: any BenefitDisplayable) {
        Task {
            do {
                let allBenefits = try container.benefitRepository.getAllBenefits()
                if let matchingBenefit = allBenefits.first(where: { $0.id == benefit.id }) {
                    try container.benefitRepository.markBenefitUsed(matchingBenefit)
                    container.notificationService.cancelNotifications(for: matchingBenefit)
                    await viewModel?.loadData()
                }
            } catch {
                // Error marking benefit as done from chart
            }
        }
    }

    func snoozeBenefit(_ benefit: PreviewBenefit, days: Int) {
        Task {
            do {
                let allBenefits = try container.benefitRepository.getAllBenefits()
                if let matchingBenefit = allBenefits.first(where: { $0.id == benefit.id }) {
                    let snoozeDate = Calendar.current.date(byAdding: .day, value: days, to: Date()) ?? Date()
                    try container.benefitRepository.snoozeBenefit(matchingBenefit, until: snoozeDate)
                    if let preferences = fetchUserPreferences() {
                        container.notificationService.scheduleSnoozedNotification(
                            for: matchingBenefit,
                            snoozeDate: snoozeDate,
                            preferences: preferences
                        )
                    }
                    await viewModel?.loadData()
                }
            } catch {
                // Error snoozing benefit
            }
        }
    }

    func undoMarkBenefitUsed(_ benefit: PreviewBenefit) {
        Task {
            do {
                let allBenefits = try container.benefitRepository.getAllBenefits()
                if let matchingBenefit = allBenefits.first(where: { $0.id == benefit.id }) {
                    try container.benefitRepository.undoMarkBenefitUsed(matchingBenefit)
                    if let preferences = fetchUserPreferences() {
                        await container.notificationService.scheduleNotifications(
                            for: matchingBenefit,
                            preferences: preferences
                        )
                    }
                    await viewModel?.loadData()
                }
            } catch {
                // Error undoing mark benefit as used
            }
        }
    }

    func deleteCard(_ cardId: UUID) {
        viewModel?.removeCardFromState(cardId)
        selectedBenefitCardId = nil

        Task {
            do {
                let allCards = try container.cardRepository.getAllCards()
                if let matchingCard = allCards.first(where: { $0.id == cardId }) {
                    container.notificationService.cancelNotifications(
                        forCardId: matchingCard.id,
                        benefits: Array(matchingCard.benefits)
                    )
                    try container.cardRepository.deleteCard(matchingCard)
                    await viewModel?.loadData()
                }
            } catch {
                // Error deleting card
            }
        }
    }

    func fetchUserPreferences() -> UserPreferences? {
        let descriptor = FetchDescriptor<UserPreferences>()
        return try? container.modelContext.fetch(descriptor).first
    }
}
