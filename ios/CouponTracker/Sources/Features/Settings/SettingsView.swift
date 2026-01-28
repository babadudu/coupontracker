//
//  SettingsView.swift
//  CouponTracker
//
//  Created: January 2026
//  Purpose: Settings screen with notification preferences and app configuration.

import SwiftUI
import SwiftData

/// Main settings view with notification configuration.
///
/// Displays:
/// - Notification toggle and time picker
/// - Reminder timing toggles (1 day, 3 days, 1 week before)
/// - App info section
struct SettingsView: View {

    // MARK: - Environment

    @Environment(AppContainer.self) private var container
    @State private var viewModel: SettingsViewModel?

    // MARK: - Body

    var body: some View {
        NavigationStack {
            Group {
                if let viewModel = viewModel {
                    SettingsContentView(viewModel: viewModel)
                } else {
                    ProgressView()
                }
            }
            .navigationTitle("Settings")
            .onAppear {
                if viewModel == nil {
                    let vm = SettingsViewModel(modelContext: container.modelContext)
                    vm.loadPreferences()
                    viewModel = vm
                }
            }
        }
    }
}

// MARK: - Settings Content

/// Internal view with actual settings content
private struct SettingsContentView: View {

    @Bindable var viewModel: SettingsViewModel

    var body: some View {
        List {
            appearanceSection
            notificationSection
            reminderTimingSection
            appInfoSection
        }
        .onChange(of: viewModel.appearanceMode) { _, _ in
            viewModel.savePreferences()
        }
        .onChange(of: viewModel.notificationsEnabled) { _, newValue in
            if newValue {
                Task {
                    let granted = await viewModel.requestNotificationPermission()
                    if !granted {
                        viewModel.notificationsEnabled = false
                    }
                }
            }
            viewModel.savePreferences()
        }
        .onChange(of: viewModel.notify1DayBefore) { _, _ in
            viewModel.savePreferences()
        }
        .onChange(of: viewModel.notify3DaysBefore) { _, _ in
            viewModel.savePreferences()
        }
        .onChange(of: viewModel.notify1WeekBefore) { _, _ in
            viewModel.savePreferences()
        }
        .onChange(of: viewModel.preferredReminderTime) { _, _ in
            viewModel.savePreferences()
        }
    }

    // MARK: - Appearance Section

    private var appearanceSection: some View {
        Section {
            Picker(selection: $viewModel.appearanceMode) {
                ForEach(AppearanceMode.allCases) { mode in
                    Label(mode.displayName, systemImage: mode.iconName)
                        .tag(mode)
                }
            } label: {
                Label("Appearance", systemImage: "circle.lefthalf.filled")
            }
        } header: {
            Text("Appearance")
        }
    }

    // MARK: - Notification Section

    private var notificationSection: some View {
        Section {
            Toggle(isOn: $viewModel.notificationsEnabled) {
                Label {
                    Text("Enable Notifications")
                } icon: {
                    Image(systemName: "bell.fill")
                        .foregroundStyle(DesignSystem.Colors.primaryFallback)
                }
            }

            if viewModel.notificationsEnabled {
                DatePicker(
                    selection: $viewModel.preferredReminderTime,
                    displayedComponents: .hourAndMinute
                ) {
                    Label {
                        Text("Notification Time")
                    } icon: {
                        Image(systemName: "clock.fill")
                            .foregroundStyle(DesignSystem.Colors.primaryFallback)
                    }
                }
            }
        } header: {
            Text("Notifications")
        } footer: {
            Text("Receive reminders before your benefits expire.")
        }
    }

    // MARK: - Reminder Timing Section

    private var reminderTimingSection: some View {
        Section {
            // Same day - Always on, non-disableable
            HStack {
                Label {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Same day")
                        Text("8:00 AM")
                            .font(DesignSystem.Typography.caption)
                            .foregroundStyle(DesignSystem.Colors.textSecondary)
                    }
                } icon: {
                    Image(systemName: "exclamationmark.circle.fill")
                        .foregroundStyle(DesignSystem.Colors.danger)
                }

                Spacer()

                Text("Always On")
                    .font(DesignSystem.Typography.footnote)
                    .foregroundStyle(DesignSystem.Colors.textSecondary)
            }

            Toggle(isOn: $viewModel.notify1DayBefore) {
                Label {
                    Text("1 day before")
                } icon: {
                    Image(systemName: "clock.badge.exclamationmark.fill")
                        .foregroundStyle(DesignSystem.Colors.warning)
                }
            }
            .disabled(!viewModel.notificationsEnabled)

            Toggle(isOn: $viewModel.notify3DaysBefore) {
                Label {
                    Text("3 days before")
                } icon: {
                    Image(systemName: "clock.fill")
                        .foregroundStyle(DesignSystem.Colors.warning.opacity(0.7))
                }
            }
            .disabled(!viewModel.notificationsEnabled)

            Toggle(isOn: $viewModel.notify1WeekBefore) {
                Label {
                    Text("1 week before")
                } icon: {
                    Image(systemName: "calendar.badge.clock")
                        .foregroundStyle(DesignSystem.Colors.neutral)
                }
            }
            .disabled(!viewModel.notificationsEnabled)
        } header: {
            Text("Remind Me Before Expiration")
        } footer: {
            Text("Choose when to receive reminders for expiring benefits.")
        }
    }

    // MARK: - App Info Section

    private var appInfoSection: some View {
        Section {
            HStack {
                Text("Version")
                Spacer()
                Text("\(viewModel.appVersion) (\(viewModel.buildNumber))")
                    .foregroundStyle(DesignSystem.Colors.textSecondary)
            }

            Button(action: {
                viewModel.resetToDefaults()
            }) {
                Label {
                    Text("Reset to Defaults")
                        .foregroundStyle(DesignSystem.Colors.danger)
                } icon: {
                    Image(systemName: "arrow.counterclockwise")
                        .foregroundStyle(DesignSystem.Colors.danger)
                }
            }
        } header: {
            Text("About")
        }
    }
}

// MARK: - Preview

#Preview {
    SettingsView()
        .environment(AppContainer.preview)
        .modelContainer(AppContainer.previewModelContainer)
}
