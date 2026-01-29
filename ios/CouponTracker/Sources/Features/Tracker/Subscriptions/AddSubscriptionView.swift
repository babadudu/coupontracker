// AddSubscriptionView.swift
// CouponTracker
//
// Created: January 2026
// Purpose: Sheet for adding subscriptions from templates or custom entry.

import SwiftUI

/// Add subscription sheet view.
///
/// Allows adding subscriptions from pre-defined templates
/// or creating custom subscriptions with manual entry.
struct AddSubscriptionView: View {

    // MARK: - Environment

    @Environment(\.dismiss) private var dismiss

    // MARK: - State

    @Bindable var viewModel: AddSubscriptionViewModel
    var onComplete: (() -> Void)?

    @State private var showingCustomForm = false

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ZStack {
                if viewModel.isLoading && viewModel.templates.isEmpty {
                    LoadingView()
                } else if showingCustomForm || viewModel.selectedTemplate != nil {
                    customFormContent
                } else {
                    templateSelectionContent
                }
            }
            .background(DesignSystem.Colors.backgroundPrimary)
            .navigationTitle(showingCustomForm ? "Custom Subscription" : "Add Subscription")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }

                if showingCustomForm || viewModel.selectedTemplate != nil {
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Add") {
                            addSubscription()
                        }
                        .disabled(!viewModel.isCustomFormValid)
                    }
                }
            }
            .alert("Error", isPresented: $viewModel.showingError) {
                Button("OK") { viewModel.dismissError() }
            } message: {
                Text(viewModel.errorMessage ?? "An error occurred")
            }
            .onAppear {
                viewModel.loadTemplates()
            }
        }
    }

    // MARK: - Template Selection Content

    @ViewBuilder
    private var templateSelectionContent: some View {
        VStack(spacing: 0) {
            // Search Bar
            searchBar
                .padding(.horizontal, DesignSystem.Spacing.lg)
                .padding(.vertical, DesignSystem.Spacing.md)

            // Custom Entry Button
            Button(action: { showingCustomForm = true }) {
                HStack {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: DesignSystem.Sizing.iconMedium))
                        .foregroundStyle(DesignSystem.Colors.primaryFallback)

                    Text("Create Custom Subscription")
                        .font(DesignSystem.Typography.headline)
                        .foregroundStyle(DesignSystem.Colors.primaryFallback)

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(DesignSystem.Colors.textTertiary)
                }
                .padding(DesignSystem.Spacing.lg)
                .background(DesignSystem.Colors.backgroundSecondary)
                .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Sizing.cardCornerRadius))
            }
            .buttonStyle(.plain)
            .padding(.horizontal, DesignSystem.Spacing.lg)
            .padding(.bottom, DesignSystem.Spacing.md)

            // Templates List
            if viewModel.filteredTemplates.isEmpty {
                emptySearchState
            } else {
                templatesList
            }
        }
    }

    // MARK: - Search Bar

    @ViewBuilder
    private var searchBar: some View {
        HStack(spacing: DesignSystem.Spacing.md) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(DesignSystem.Colors.textTertiary)
                .font(.system(size: DesignSystem.Sizing.iconSmall))

            TextField("Search services...", text: $viewModel.searchQuery)
                .font(DesignSystem.Typography.body)
                .textFieldStyle(.plain)
                .autocorrectionDisabled()

            if !viewModel.searchQuery.isEmpty {
                Button(action: { viewModel.searchQuery = "" }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(DesignSystem.Colors.textTertiary)
                }
            }
        }
        .padding(DesignSystem.Spacing.md)
        .background(DesignSystem.Colors.backgroundSecondary)
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    // MARK: - Templates List

    @ViewBuilder
    private var templatesList: some View {
        ScrollView {
            LazyVStack(spacing: DesignSystem.Spacing.sm, pinnedViews: .sectionHeaders) {
                ForEach(SubscriptionCategory.allCases) { category in
                    if let templates = viewModel.templatesByCategory[category], !templates.isEmpty {
                        Section {
                            ForEach(templates) { template in
                                TemplateRowView(template: template) {
                                    viewModel.selectTemplate(template)
                                }
                            }
                        } header: {
                            HStack {
                                Label(category.displayName, systemImage: category.iconName)
                                    .font(DesignSystem.Typography.subhead)
                                    .foregroundStyle(DesignSystem.Colors.textSecondary)
                                Spacer()
                            }
                            .padding(.horizontal, DesignSystem.Spacing.lg)
                            .padding(.vertical, DesignSystem.Spacing.sm)
                            .background(DesignSystem.Colors.backgroundPrimary)
                        }
                    }
                }
            }
            .padding(.bottom, DesignSystem.Spacing.xxl)
        }
    }

    // MARK: - Empty Search State

    @ViewBuilder
    private var emptySearchState: some View {
        VStack(spacing: DesignSystem.Spacing.lg) {
            Spacer()

            Image(systemName: "magnifyingglass")
                .font(.system(size: 48))
                .foregroundStyle(DesignSystem.Colors.textTertiary)

            Text("No services found")
                .font(DesignSystem.Typography.headline)
                .foregroundStyle(DesignSystem.Colors.textPrimary)

            Text("Try a different search or create a custom subscription")
                .font(DesignSystem.Typography.subhead)
                .foregroundStyle(DesignSystem.Colors.textSecondary)
                .multilineTextAlignment(.center)

            Spacer()
        }
        .padding(DesignSystem.Spacing.lg)
    }

    // MARK: - Custom Form Content

    @ViewBuilder
    private var customFormContent: some View {
        Form {
            // Template Info (if selected)
            if let template = viewModel.selectedTemplate {
                Section {
                    HStack {
                        Image(systemName: template.displayIconName)
                            .font(.system(size: DesignSystem.Sizing.iconMedium))
                            .foregroundStyle(template.category.color)

                        Text("Based on \(template.name)")
                            .font(DesignSystem.Typography.body)
                            .foregroundStyle(DesignSystem.Colors.textSecondary)

                        Spacer()

                        Button("Change") {
                            viewModel.clearSelection()
                            showingCustomForm = false
                        }
                        .font(DesignSystem.Typography.subhead)
                    }
                }
            }

            // Basic Info
            Section("Basic Info") {
                TextField("Name", text: $viewModel.customName)

                HStack {
                    Text("$")
                    TextField("Price", text: $viewModel.customPrice)
                        .keyboardType(.decimalPad)
                }

                Picker("Frequency", selection: $viewModel.customFrequency) {
                    ForEach(SubscriptionFrequency.allCases) { frequency in
                        Text(frequency.displayName).tag(frequency)
                    }
                }

                Picker("Category", selection: $viewModel.customCategory) {
                    ForEach(SubscriptionCategory.allCases) { category in
                        Label(category.displayName, systemImage: category.iconName)
                            .tag(category)
                    }
                }
            }

            // Start Date
            Section("Renewal Date") {
                DatePicker(
                    "Start Date",
                    selection: $viewModel.customStartDate,
                    displayedComponents: .date
                )
            }

            // Reminders
            Section("Reminders") {
                Toggle("Enable Reminders", isOn: $viewModel.reminderEnabled)

                if viewModel.reminderEnabled {
                    Picker("Remind me", selection: $viewModel.reminderDaysBefore) {
                        Text("1 day before").tag(1)
                        Text("3 days before").tag(3)
                        Text("7 days before").tag(7)
                        Text("14 days before").tag(14)
                    }
                }
            }

            // Notes
            Section("Notes (Optional)") {
                TextField("Notes", text: $viewModel.customNotes, axis: .vertical)
                    .lineLimit(3...6)
            }
        }
    }

    // MARK: - Actions

    private func addSubscription() {
        if let _ = viewModel.createSubscription() {
            onComplete?()
            dismiss()
        }
    }
}

// MARK: - Template Row View

struct TemplateRowView: View {
    let template: SubscriptionTemplate
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: DesignSystem.Spacing.md) {
                Image(systemName: template.displayIconName)
                    .font(.system(size: DesignSystem.Sizing.iconMedium))
                    .foregroundStyle(template.category.color)
                    .frame(width: 40, height: 40)
                    .background(template.category.color.opacity(0.15))
                    .clipShape(RoundedRectangle(cornerRadius: 8))

                VStack(alignment: .leading, spacing: 2) {
                    Text(template.name)
                        .font(DesignSystem.Typography.headline)
                        .foregroundStyle(DesignSystem.Colors.textPrimary)

                    Text(template.category.displayName)
                        .font(DesignSystem.Typography.caption)
                        .foregroundStyle(DesignSystem.Colors.textSecondary)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 2) {
                    Text(Formatters.formatCurrency(template.defaultPrice))
                        .font(DesignSystem.Typography.headline)
                        .foregroundStyle(DesignSystem.Colors.textPrimary)

                    Text(template.frequency.shortLabel)
                        .font(DesignSystem.Typography.caption)
                        .foregroundStyle(DesignSystem.Colors.textSecondary)
                }
            }
            .padding(DesignSystem.Spacing.md)
            .background(DesignSystem.Colors.backgroundSecondary)
            .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Sizing.cardCornerRadius))
        }
        .buttonStyle(.plain)
        .padding(.horizontal, DesignSystem.Spacing.lg)
    }
}

// MARK: - Preview

#Preview("Add Subscription") {
    AddSubscriptionView(viewModel: AddSubscriptionViewModel.preview)
        .environment(AppContainer.preview)
        .modelContainer(AppContainer.previewModelContainer)
}
