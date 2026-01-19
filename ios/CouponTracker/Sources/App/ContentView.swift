// ContentView.swift
// CouponTracker
//
// Created: January 2026
// Purpose: Root content view that manages navigation flow between
//          onboarding and main app content based on user state.

import SwiftUI
import SwiftData

// MARK: - Content View

/// Root content view that handles navigation and onboarding state
struct ContentView: View {

    @Environment(AppContainer.self) private var container
    @Environment(\.modelContext) private var modelContext

    @State private var hasCompletedOnboarding: Bool = false
    @State private var isLoading: Bool = true

    var body: some View {
        Group {
            if isLoading {
                // Loading state while checking preferences
                LoadingView()
            } else if !hasCompletedOnboarding {
                // Show onboarding for new users
                OnboardingView(onComplete: completeOnboarding)
            } else {
                // Main app content
                MainTabView()
            }
        }
        .task {
            await loadUserPreferences()
        }
    }

    // MARK: - Private Methods

    /// Loads user preferences to check onboarding status
    private func loadUserPreferences() async {
        print("📋 Loading user preferences...")
        let descriptor = FetchDescriptor<UserPreferences>()

        do {
            let preferences = try modelContext.fetch(descriptor)
            if let userPrefs = preferences.first {
                hasCompletedOnboarding = userPrefs.hasCompletedOnboarding
                print("✅ User preferences loaded: onboarding=\(hasCompletedOnboarding)")
            } else {
                // Create default preferences for new user
                print("📝 Creating new user preferences...")
                let newPrefs = UserPreferences()
                modelContext.insert(newPrefs)
                try modelContext.save()
                hasCompletedOnboarding = false
                print("✅ New user preferences created")
            }
        } catch {
            // If we can't load preferences, assume new user
            print("⚠️ Failed to load preferences: \(error). Assuming new user.")
            hasCompletedOnboarding = false
        }

        isLoading = false
        print("✅ User preferences loading complete. Showing: \(hasCompletedOnboarding ? "Dashboard" : "Onboarding")")
    }

    /// Marks onboarding as complete and transitions to main app
    private func completeOnboarding() {
        let descriptor = FetchDescriptor<UserPreferences>()

        do {
            let preferences = try modelContext.fetch(descriptor)
            if let userPrefs = preferences.first {
                userPrefs.completeOnboarding()
                try modelContext.save()
            }
        } catch {
            // Log error but continue - user can use app without saved preference
            print("Failed to save onboarding completion: \(error)")
        }

        hasCompletedOnboarding = true
    }
}

// MARK: - Loading View

/// Simple loading view shown during initial data load
struct LoadingView: View {
    var body: some View {
        ZStack {
            DesignSystem.Colors.backgroundPrimary
                .ignoresSafeArea()

            VStack(spacing: DesignSystem.Spacing.lg) {
                ProgressView()
                    .scaleEffect(1.2)

                Text("Loading...")
                    .font(DesignSystem.Typography.body)
                    .foregroundStyle(DesignSystem.Colors.textSecondary)
            }
        }
    }
}

// MARK: - Onboarding View

/// Onboarding flow for new users (placeholder for Sprint 5)
struct OnboardingView: View {
    let onComplete: () -> Void

    var body: some View {
        VStack(spacing: DesignSystem.Spacing.xl) {
            Spacer()

            Image(systemName: "creditcard.fill")
                .font(.system(size: 80))
                .foregroundStyle(DesignSystem.Colors.primaryFallback)

            Text("Welcome to CouponTracker")
                .font(DesignSystem.Typography.title1)
                .foregroundStyle(DesignSystem.Colors.textPrimary)

            Text("Track your credit card benefits\nand never miss a reward again.")
                .font(DesignSystem.Typography.body)
                .foregroundStyle(DesignSystem.Colors.textSecondary)
                .multilineTextAlignment(.center)

            Spacer()

            Button(action: onComplete) {
                Text("Get Started")
                    .font(DesignSystem.Typography.headline)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, DesignSystem.Spacing.md)
                    .background(DesignSystem.Colors.primaryFallback)
                    .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Sizing.buttonCornerRadius))
            }
            .padding(.horizontal, DesignSystem.Spacing.screenPadding)
            .padding(.bottom, DesignSystem.Spacing.xxl)
        }
        .background(DesignSystem.Colors.backgroundPrimary)
    }
}

// MARK: - Main Tab View

/// Main tab-based navigation for the app
struct MainTabView: View {

    @Environment(AppContainer.self) private var container
    @State private var selectedTab: Tab = .home
    @State private var sharedViewModel: HomeViewModel?

    enum Tab: String, CaseIterable {
        case home = "Home"
        case wallet = "Wallet"
        case settings = "Settings"

        var iconName: String {
            switch self {
            case .home: return "house.fill"
            case .wallet: return "creditcard.fill"
            case .settings: return "gearshape.fill"
            }
        }
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            HomeTabView(
                viewModel: $sharedViewModel,
                onSwitchToWallet: { selectedTab = .wallet },
                onSwitchToSettings: { selectedTab = .settings }
            )
            .tabItem {
                Label(Tab.home.rawValue, systemImage: Tab.home.iconName)
            }
            .tag(Tab.home)

            WalletTabView(viewModel: $sharedViewModel)
                .tabItem {
                    Label(Tab.wallet.rawValue, systemImage: Tab.wallet.iconName)
                }
                .tag(Tab.wallet)

            SettingsTabView()
                .tabItem {
                    Label(Tab.settings.rawValue, systemImage: Tab.settings.iconName)
                }
                .tag(Tab.settings)
        }
        .task {
            if sharedViewModel == nil {
                print("🏠 Creating HomeViewModel...")
                sharedViewModel = HomeViewModel(
                    cardRepository: container.cardRepository,
                    benefitRepository: container.benefitRepository,
                    templateLoader: container.templateLoader
                )
                print("📊 Loading initial data...")
                await sharedViewModel?.loadData()
                print("✅ HomeViewModel initialized and data loaded")
            }
        }
    }
}

// MARK: - Tab Views (Placeholders for Sprint 3-5)

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
    var onSwitchToWallet: (() -> Void)?
    var onSwitchToSettings: (() -> Void)?

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
                                    default:
                                        break
                                    }
                                }
                            )
                        }

                        // Accomplishment Rings (Period Carousel)
                        if !viewModel.isEmpty {
                            DashboardPeriodSection(
                                benefits: viewModel.allBenefits,
                                selectedPeriod: $selectedPeriod
                            )
                        }

                        // Monthly Progress Card
                        MonthlyProgressCardView(
                            redeemedValue: viewModel.redeemedThisMonth,
                            totalValue: viewModel.totalAvailableValue,
                            usedCount: viewModel.usedBenefitsCount,
                            totalCount: viewModel.totalBenefitsCount,
                            onTap: { showValueBreakdown = true }
                        )

                        // Summary Cards (Total Available + Expiring Soon)
                        dashboardSummary(viewModel: viewModel)

                        // Benefit Category Chart
                        if !viewModel.isEmpty {
                            BenefitCategoryChartView(
                                benefits: viewModel.allDisplayBenefits
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
                // Success haptic feedback
                let generator = UINotificationFeedbackGenerator()
                generator.notificationOccurred(.success)
            }
            .sheet(isPresented: $showAddCard, onDismiss: {
                Task { await viewModel?.loadData() }
            }) {
                AddCardView(
                    viewModel: AddCardViewModel(
                        cardRepository: container.cardRepository,
                        templateLoader: container.templateLoader
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
        }
    }

    // MARK: - Actions

    private func markBenefitAsDone(_ benefit: PreviewBenefit) {
        Task {
            do {
                let allBenefits = try container.benefitRepository.getAllBenefits()
                if let matchingBenefit = allBenefits.first(where: { $0.id == benefit.id }) {
                    try container.benefitRepository.markBenefitUsed(matchingBenefit)
                    await viewModel?.loadData()
                    selectedBenefitCardId = nil
                }
            } catch {
                print("Failed to mark benefit as done: \(error)")
            }
        }
    }

    private func snoozeBenefit(_ benefit: PreviewBenefit, days: Int) {
        Task {
            do {
                let allBenefits = try container.benefitRepository.getAllBenefits()
                if let matchingBenefit = allBenefits.first(where: { $0.id == benefit.id }) {
                    let snoozeDate = Calendar.current.date(byAdding: .day, value: days, to: Date()) ?? Date()
                    try container.benefitRepository.snoozeBenefit(matchingBenefit, until: snoozeDate)
                    await viewModel?.loadData()
                    selectedBenefitCardId = nil
                }
            } catch {
                print("Failed to snooze benefit: \(error)")
            }
        }
    }

    private func undoMarkBenefitUsed(_ benefit: PreviewBenefit) {
        Task {
            do {
                let allBenefits = try container.benefitRepository.getAllBenefits()
                if let matchingBenefit = allBenefits.first(where: { $0.id == benefit.id }) {
                    try container.benefitRepository.undoMarkBenefitUsed(matchingBenefit)
                    await viewModel?.loadData()
                }
            } catch {
                print("Failed to undo mark benefit as used: \(error)")
            }
        }
    }

    private func deleteCard(_ cardId: UUID) {
        // CRITICAL: Clear ViewModel state FIRST to prevent UI accessing deleted objects
        viewModel?.removeCardFromState(cardId)
        selectedBenefitCardId = nil

        Task {
            do {
                let allCards = try container.cardRepository.getAllCards()
                if let matchingCard = allCards.first(where: { $0.id == cardId }) {
                    try container.cardRepository.deleteCard(matchingCard)
                    await viewModel?.loadData()
                }
            } catch {
                print("Failed to delete card: \(error)")
            }
        }
    }

    @ViewBuilder
    private func dashboardSummary(viewModel: HomeViewModel) -> some View {
        VStack(spacing: DesignSystem.Spacing.md) {
            // Total Available Value (tappable for breakdown)
            Button(action: {
                showValueBreakdown = true
            }) {
                VStack(spacing: DesignSystem.Spacing.xs) {
                    Text("Total Available")
                        .font(DesignSystem.Typography.subhead)
                        .foregroundStyle(DesignSystem.Colors.textSecondary)

                    HStack(alignment: .center, spacing: DesignSystem.Spacing.sm) {
                        Text(Formatters.formatCurrencyWhole(viewModel.totalAvailableValue))
                            .font(DesignSystem.Typography.valueLarge)
                            .foregroundStyle(DesignSystem.Colors.textPrimary)

                        Image(systemName: "chevron.right")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(DesignSystem.Colors.textTertiary)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, DesignSystem.Spacing.lg)
                .background(
                    RoundedRectangle(cornerRadius: DesignSystem.Sizing.cardCornerRadius)
                        .fill(DesignSystem.Colors.backgroundSecondary)
                )
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Total available \(Formatters.formatCurrencyWhole(viewModel.totalAvailableValue))")
            .accessibilityHint("Double tap to view breakdown")

            // Cards and Expiring counts
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
        }
    }

    @ViewBuilder
    private func expiringSoonSection(viewModel: HomeViewModel) -> some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
            Text("Expiring Soon")
                .font(DesignSystem.Typography.title3)
                .foregroundStyle(DesignSystem.Colors.textPrimary)

            ForEach(viewModel.displayExpiringBenefits.prefix(5), id: \.id) { item in
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(item.benefit.name)
                            .font(DesignSystem.Typography.headline)
                            .foregroundStyle(DesignSystem.Colors.textPrimary)

                        Text(item.card.displayName)
                            .font(DesignSystem.Typography.caption)
                            .foregroundStyle(DesignSystem.Colors.textSecondary)
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: 2) {
                        Text(item.benefit.formattedValue)
                            .font(DesignSystem.Typography.headline)
                            .foregroundStyle(DesignSystem.Colors.textPrimary)

                        Text(item.benefit.urgencyText)
                            .font(DesignSystem.Typography.caption)
                            .foregroundStyle(DesignSystem.Colors.urgencyColor(daysRemaining: item.benefit.daysRemaining))
                    }
                }
                .padding(DesignSystem.Spacing.md)
                .background(
                    RoundedRectangle(cornerRadius: DesignSystem.Sizing.buttonCornerRadius)
                        .fill(DesignSystem.Colors.backgroundSecondary)
                )
            }
        }
    }

    @ViewBuilder
    private func quickStats(viewModel: HomeViewModel) -> some View {
        if viewModel.isEmpty {
            VStack(spacing: DesignSystem.Spacing.lg) {
                // Animated icon
                Image(systemName: "creditcard.fill")
                    .font(.system(size: 60))
                    .foregroundStyle(DesignSystem.Colors.primaryFallback)
                    .symbolEffect(.pulse, options: .repeating)

                // Headline
                Text("Start Tracking Your Benefits")
                    .font(DesignSystem.Typography.title2)
                    .foregroundStyle(DesignSystem.Colors.textPrimary)
                    .multilineTextAlignment(.center)

                // Value proposition
                Text("Never miss a credit card benefit again.\nTrack expiring credits, earn more rewards,\nand maximize your card value.")
                    .font(DesignSystem.Typography.body)
                    .foregroundStyle(DesignSystem.Colors.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)

                // CTA Button
                Button(action: {
                    showAddCard = true
                }) {
                    HStack(spacing: DesignSystem.Spacing.sm) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 18, weight: .semibold))

                        Text("Add Your First Card")
                            .font(DesignSystem.Typography.headline)
                    }
                    .foregroundStyle(.white)
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

/// A small stat card for the dashboard
private struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    var onTap: (() -> Void)? = nil

    var body: some View {
        Group {
            if let onTap = onTap {
                Button(action: onTap) {
                    cardContent
                }
                .buttonStyle(.plain)
            } else {
                cardContent
            }
        }
    }

    private var cardContent: some View {
        VStack(spacing: DesignSystem.Spacing.sm) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundStyle(color)

            Text(value)
                .font(DesignSystem.Typography.title2)
                .foregroundStyle(DesignSystem.Colors.textPrimary)

            HStack(spacing: DesignSystem.Spacing.xs) {
                Text(title)
                    .font(DesignSystem.Typography.caption)
                    .foregroundStyle(DesignSystem.Colors.textSecondary)

                if onTap != nil {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(DesignSystem.Colors.textTertiary)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, DesignSystem.Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: DesignSystem.Sizing.buttonCornerRadius)
                .fill(DesignSystem.Colors.backgroundSecondary)
        )
    }
}

/// Wallet tab showing user's cards and benefits
struct WalletTabView: View {
    @Environment(AppContainer.self) private var container
    @Binding var viewModel: HomeViewModel?
    @State private var selectedCardId: UUID?
    @State private var showAddCard = false
    @State private var showEditCard = false
    @State private var showExpiringList = false

    /// Current selected card derived from viewModel (reactive)
    private var selectedCard: PreviewCard? {
        guard let cardId = selectedCardId,
              let viewModel = viewModel else { return nil }
        return viewModel.displayCards.first { $0.id == cardId }?.toPreviewCard()
    }

    var body: some View {
        NavigationStack {
            Group {
                if let viewModel = viewModel {
                    WalletView(
                        cards: viewModel.displayCards.map { $0.toPreviewCard() },
                        onCardTap: { card in
                            selectedCardId = card.id
                        },
                        onAddCard: {
                            showAddCard = true
                        },
                        onBenefitMarkAsDone: { benefit in
                            markBenefitAsDone(benefit)
                        },
                        onSeeAllExpiring: {
                            showExpiringList = true
                        }
                    )
                } else {
                    LoadingView()
                }
            }
            .refreshable {
                await viewModel?.refresh()
            }
            .navigationDestination(isPresented: Binding(
                get: { selectedCard != nil },
                set: { if !$0 { selectedCardId = nil } }
            )) {
                if let card = selectedCard {
                    CardDetailView(
                        card: card,
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
                            deleteCard(card)
                        },
                        onEditCard: {
                            showEditCard = true
                        }
                    )
                }
            }
            .sheet(isPresented: $showAddCard, onDismiss: {
                Task {
                    await viewModel?.loadData()
                }
            }) {
                AddCardView(
                    viewModel: AddCardViewModel(
                        cardRepository: container.cardRepository,
                        templateLoader: container.templateLoader
                    )
                )
            }
            .sheet(isPresented: $showEditCard) {
                // Edit card sheet - for now shows a simple placeholder
                EditCardSheet(
                    cardId: selectedCardId,
                    container: container,
                    onSave: {
                        showEditCard = false
                        Task {
                            await viewModel?.loadData()
                        }
                    },
                    onCancel: {
                        showEditCard = false
                    }
                )
            }
            .sheet(isPresented: $showExpiringList) {
                if let viewModel = viewModel {
                    ExpiringBenefitsListView(
                        viewModel: viewModel,
                        container: container,
                        onSelectCard: { cardId in
                            showExpiringList = false
                            selectedCardId = cardId
                        }
                    )
                }
            }
        }
    }

    // MARK: - Actions

    private func markBenefitAsDone(_ benefit: PreviewBenefit) {
        Task {
            do {
                let allBenefits = try container.benefitRepository.getAllBenefits()
                if let matchingBenefit = allBenefits.first(where: { $0.id == benefit.id }) {
                    try container.benefitRepository.markBenefitUsed(matchingBenefit)
                    await viewModel?.loadData()
                    // Dismiss to show updated card in wallet
                    selectedCardId = nil
                }
            } catch {
                print("Failed to mark benefit as done: \(error)")
            }
        }
    }

    private func snoozeBenefit(_ benefit: PreviewBenefit, days: Int) {
        Task {
            do {
                let allBenefits = try container.benefitRepository.getAllBenefits()
                if let matchingBenefit = allBenefits.first(where: { $0.id == benefit.id }) {
                    let snoozeDate = Calendar.current.date(byAdding: .day, value: days, to: Date()) ?? Date()
                    try container.benefitRepository.snoozeBenefit(matchingBenefit, until: snoozeDate)
                    await viewModel?.loadData()
                    // Dismiss to show updated card in wallet
                    selectedCardId = nil
                }
            } catch {
                print("Failed to snooze benefit: \(error)")
            }
        }
    }

    private func undoMarkBenefitUsed(_ benefit: PreviewBenefit) {
        Task {
            do {
                let allBenefits = try container.benefitRepository.getAllBenefits()
                if let matchingBenefit = allBenefits.first(where: { $0.id == benefit.id }) {
                    try container.benefitRepository.undoMarkBenefitUsed(matchingBenefit)
                    await viewModel?.loadData()
                }
            } catch {
                print("Failed to undo mark benefit as used: \(error)")
            }
        }
    }

    private func deleteCard(_ card: PreviewCard) {
        // Capture the card ID before dismissing
        let cardIdToDelete = card.id

        // CRITICAL: Clear ViewModel state FIRST to prevent UI accessing deleted objects
        viewModel?.removeCardFromState(cardIdToDelete)

        // Dismiss the detail view
        selectedCardId = nil

        // Then delete the card asynchronously
        Task {
            do {
                let allCards = try container.cardRepository.getAllCards()
                if let matchingCard = allCards.first(where: { $0.id == cardIdToDelete }) {
                    try container.cardRepository.deleteCard(matchingCard)
                    await viewModel?.loadData()
                }
            } catch {
                print("Failed to delete card: \(error)")
            }
        }
    }
}

/// Simple edit card sheet for updating card nickname
struct EditCardSheet: View {
    let cardId: UUID?
    let container: AppContainer
    let onSave: () -> Void
    let onCancel: () -> Void

    @State private var nickname: String = ""
    @State private var card: UserCard?

    var body: some View {
        NavigationStack {
            Form {
                Section("Card Nickname") {
                    TextField("Nickname (optional)", text: $nickname)
                }

                Section {
                    Text("Edit the nickname to help identify this card in your wallet.")
                        .font(DesignSystem.Typography.caption)
                        .foregroundStyle(DesignSystem.Colors.textSecondary)
                }
            }
            .navigationTitle("Edit Card")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { onCancel() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { saveChanges() }
                }
            }
            .task {
                loadCard()
            }
        }
    }

    private func loadCard() {
        guard let cardId = cardId else { return }
        do {
            card = try container.cardRepository.getCard(by: cardId)
            nickname = card?.nickname ?? ""
        } catch {
            print("Failed to load card: \(error)")
        }
    }

    private func saveChanges() {
        guard let card = card else {
            onCancel()
            return
        }

        do {
            card.nickname = nickname.isEmpty ? nil : nickname
            try container.cardRepository.updateCard(card)
            onSave()
        } catch {
            print("Failed to save card: \(error)")
            onCancel()
        }
    }
}

/// Settings tab for user preferences
struct SettingsTabView: View {
    var body: some View {
        NavigationStack {
            SettingsPlaceholderView()
                .navigationTitle("Settings")
        }
    }
}

/// Placeholder settings view - to be implemented in later sprint
private struct SettingsPlaceholderView: View {
    var body: some View {
        List {
            Section("About") {
                HStack {
                    Text("Version")
                    Spacer()
                    Text("1.0.0")
                        .foregroundStyle(DesignSystem.Colors.textSecondary)
                }
            }
            
            Section("Support") {
                Link(destination: URL(string: "https://example.com/support")!) {
                    HStack {
                        Text("Help & Support")
                        Spacer()
                        Image(systemName: "arrow.up.forward")
                            .font(.caption)
                            .foregroundStyle(DesignSystem.Colors.textTertiary)
                    }
                }
            }
            
            Section {
                Text("More settings coming soon")
                    .font(DesignSystem.Typography.caption)
                    .foregroundStyle(DesignSystem.Colors.textSecondary)
            }
        }
    }
}

// MARK: - Preview

#Preview("ContentView") {
    ContentView()
        .environment(AppContainer.preview)
        .modelContainer(AppContainer.previewModelContainer)
}

#Preview("Loading View") {
    LoadingView()
}

#Preview("Onboarding View") {
    OnboardingView(onComplete: {})
}

#Preview("Main Tab View") {
    MainTabView()
        .environment(AppContainer.preview)
        .modelContainer(AppContainer.previewModelContainer)
}
