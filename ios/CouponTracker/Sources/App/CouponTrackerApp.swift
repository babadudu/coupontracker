// CouponTrackerApp.swift
// CouponTracker
//
// Created: January 2026
// Purpose: Main SwiftUI App entry point with SwiftData model container setup
//          and dependency injection configuration.

import SwiftUI
import SwiftData
import UserNotifications

/// Main application entry point for CouponTracker.
///
/// Responsibilities:
/// - Configure SwiftData ModelContainer with all entity types
/// - Set up dependency injection via AppContainer
/// - Handle app lifecycle events
/// - Configure navigation root view
@main
struct CouponTrackerApp: App {

    // MARK: - State

    /// Shared application container for dependency injection
    @State private var appContainer: AppContainer

    /// SwiftData model container
    private let modelContainer: ModelContainer

    // MARK: - Initialization

    init() {
        // Configure SwiftData model container with all entity types
        let schema = Schema([
            UserCard.self,
            Benefit.self,
            BenefitUsage.self,
            UserPreferences.self
        ])

        let modelConfiguration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false,
            allowsSave: true
        )

        do {
            modelContainer = try ModelContainer(
                for: schema,
                configurations: [modelConfiguration]
            )

            // Initialize app container with the model container
            let container = AppContainer(modelContainer: modelContainer)
            _appContainer = State(initialValue: container)

            // Set up notification delegate
            UNUserNotificationCenter.current().delegate = container.notificationService

            // Configure appearance and global settings
            Self.configureAppearance()

        } catch {
            // Fatal error - app cannot function without data storage
            fatalError("Failed to create ModelContainer: \(error.localizedDescription)")
        }
    }

    // MARK: - Body

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(appContainer)
                .modelContainer(modelContainer)
                .task {
                    print("🚀 CouponTracker: App launched, performing startup tasks...")
                    // Perform startup tasks (benefit reset, template preload)
                    await appContainer.performStartupTasks()
                    print("✅ CouponTracker: Startup tasks completed successfully")
                }
        }
    }

    // MARK: - Configuration

    /// Configures global appearance settings for navigation and tab bars
    private static func configureAppearance() {
        // Configure navigation bar appearance
        let navigationBarAppearance = UINavigationBarAppearance()
        navigationBarAppearance.configureWithDefaultBackground()
        UINavigationBar.appearance().standardAppearance = navigationBarAppearance
        UINavigationBar.appearance().compactAppearance = navigationBarAppearance
        UINavigationBar.appearance().scrollEdgeAppearance = navigationBarAppearance

        // Configure tab bar appearance
        let tabBarAppearance = UITabBarAppearance()
        tabBarAppearance.configureWithDefaultBackground()
        UITabBar.appearance().standardAppearance = tabBarAppearance
        UITabBar.appearance().scrollEdgeAppearance = tabBarAppearance
    }
}
