//
//  ContentView.swift
//  CouponTracker
//
//  Created: January 2026
//  Purpose: Root content view that manages navigation flow between
//           onboarding and main app content based on user state.
//

import SwiftUI
import SwiftData
import os

// MARK: - Content View

/// Root content view that handles navigation and onboarding state
struct ContentView: View {

    @Environment(AppContainer.self) private var container
    @Environment(\.modelContext) private var modelContext

    @State private var hasCompletedOnboarding: Bool = false
    @State private var isLoading: Bool = true
    @State private var appearanceMode: AppearanceMode = .system

    var body: some View {
        Group {
            if isLoading {
                LoadingView()
            } else if !hasCompletedOnboarding {
                OnboardingFlowView(onComplete: completeOnboarding)
            } else {
                MainTabView()
            }
        }
        .preferredColorScheme(appearanceMode.scheme)
        .task {
            await loadUserPreferences()
        }
        .onReceive(NotificationCenter.default.publisher(for: .userPreferencesChanged)) { _ in
            Task {
                await loadUserPreferences()
            }
        }
    }

    // MARK: - Private Methods

    private func loadUserPreferences() async {
        let descriptor = FetchDescriptor<UserPreferences>()

        do {
            let preferences = try modelContext.fetch(descriptor)
            if let userPrefs = preferences.first {
                hasCompletedOnboarding = userPrefs.hasCompletedOnboarding
                appearanceMode = userPrefs.appearanceMode
            } else {
                let newPrefs = UserPreferences()
                modelContext.insert(newPrefs)
                try modelContext.save()
                hasCompletedOnboarding = false
                appearanceMode = .system
            }
        } catch {
            hasCompletedOnboarding = false
            appearanceMode = .system
        }

        isLoading = false
    }

    private func completeOnboarding() {
        let descriptor = FetchDescriptor<UserPreferences>()

        do {
            let preferences = try modelContext.fetch(descriptor)
            if let userPrefs = preferences.first {
                userPrefs.completeOnboarding()
                try modelContext.save()
            }
        } catch {
            AppLogger.data.error("Failed to complete onboarding: \(error.localizedDescription)")
        }

        hasCompletedOnboarding = true
    }
}

// MARK: - Main Tab View

/// Main tab-based navigation for the app
struct MainTabView: View {

    @Environment(AppContainer.self) private var container
    @State private var selectedTab: Tab = .home
    @State private var sharedViewModel: HomeViewModel?
    @State private var deepLinkBenefitId: UUID?

    enum Tab: String, CaseIterable {
        case home = "Home"
        case wallet = "Wallet"
        case tracker = "Tracker"
        case settings = "Settings"

        var iconName: String {
            switch self {
            case .home: return "house.fill"
            case .wallet: return "creditcard.fill"
            case .tracker: return "repeat.circle.fill"
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

            TrackerTabView()
                .tabItem {
                    Label(Tab.tracker.rawValue, systemImage: Tab.tracker.iconName)
                }
                .tag(Tab.tracker)

            SettingsTabView()
                .tabItem {
                    Label(Tab.settings.rawValue, systemImage: Tab.settings.iconName)
                }
                .tag(Tab.settings)
        }
        .task {
            if sharedViewModel == nil {
                sharedViewModel = HomeViewModel(
                    cardRepository: container.cardRepository,
                    benefitRepository: container.benefitRepository,
                    templateLoader: container.templateLoader,
                    notificationService: container.notificationService
                )
                sharedViewModel?.setRecommendationService(container.recommendationService)
                await sharedViewModel?.loadData()
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .navigateToBenefit)) { notification in
            handleNavigateToBenefit(notification)
        }
        .onReceive(NotificationCenter.default.publisher(for: .markBenefitUsed)) { notification in
            handleMarkBenefitUsed(notification)
        }
        .onReceive(NotificationCenter.default.publisher(for: .snoozeBenefit)) { notification in
            handleSnoozeBenefit(notification)
        }
        .onChange(of: deepLinkBenefitId) { _, newValue in
            if newValue != nil {
                selectedTab = .wallet
            }
        }
    }

    // MARK: - Deep Link Handlers

    private func handleNavigateToBenefit(_ notification: Notification) {
        guard let benefitId = notification.userInfo?[NotificationUserInfoKey.benefitId] as? UUID else {
            return
        }

        Task {
            if let viewModel = sharedViewModel {
                await viewModel.loadData()
                for cardAdapter in viewModel.displayCards {
                    if cardAdapter.benefits.contains(where: { $0.id == benefitId }) {
                        deepLinkBenefitId = benefitId
                        NotificationCenter.default.post(
                            name: Notification.Name("CouponTracker.selectCard"),
                            object: nil,
                            userInfo: ["cardId": cardAdapter.id, "benefitId": benefitId]
                        )
                        break
                    }
                }
            }
        }
    }

    private func handleMarkBenefitUsed(_ notification: Notification) {
        guard let benefitId = notification.userInfo?[NotificationUserInfoKey.benefitId] as? UUID else {
            return
        }

        Task {
            do {
                let allBenefits = try container.benefitRepository.getAllBenefits()
                if let benefit = allBenefits.first(where: { $0.id == benefitId }) {
                    try container.benefitRepository.markBenefitUsed(benefit)
                    await sharedViewModel?.loadData()
                }
            } catch {
                AppLogger.benefits.error("Failed to mark benefit as used from notification: \(error.localizedDescription)")
            }
        }
    }

    private func handleSnoozeBenefit(_ notification: Notification) {
        guard let benefitId = notification.userInfo?[NotificationUserInfoKey.benefitId] as? UUID,
              let days = notification.userInfo?[NotificationUserInfoKey.snoozeDays] as? Int else {
            return
        }

        Task {
            do {
                let allBenefits = try container.benefitRepository.getAllBenefits()
                if let benefit = allBenefits.first(where: { $0.id == benefitId }) {
                    let snoozeDate = Calendar.current.date(byAdding: .day, value: days, to: Date()) ?? Date()
                    try container.benefitRepository.snoozeBenefit(benefit, until: snoozeDate)
                    await sharedViewModel?.loadData()
                }
            } catch {
                AppLogger.benefits.error("Failed to snooze benefit from notification: \(error.localizedDescription)")
            }
        }
    }
}

// MARK: - Settings Tab View

/// Settings tab for user preferences
struct SettingsTabView: View {
    var body: some View {
        SettingsView()
    }
}

// MARK: - Previews

#Preview("ContentView") {
    ContentView()
        .environment(AppContainer.preview)
        .modelContainer(AppContainer.previewModelContainer)
}

#Preview("Main Tab View") {
    MainTabView()
        .environment(AppContainer.preview)
        .modelContainer(AppContainer.previewModelContainer)
}
