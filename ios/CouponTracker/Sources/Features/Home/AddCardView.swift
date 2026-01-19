//
//  AddCardView.swift
//  CouponTracker
//
//  Created by Junior Engineer 3 on 2026-01-17.
//

import SwiftUI

/// Sheet/modal view for adding new cards from card templates.
///
/// This view provides:
/// - Search bar for filtering card templates
/// - Grid display of available templates grouped by issuer
/// - Card selection with visual highlight
/// - Nickname input field after selection
/// - Add button to create the card
/// - Loading and empty states
/// - Cancel button to dismiss
struct AddCardView: View {
    // MARK: - Properties

    @Environment(\.dismiss) private var dismiss
    @Bindable var viewModel: AddCardViewModel

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ZStack {
                if viewModel.isLoading {
                    loadingState
                } else {
                    mainContent
                }
            }
            .navigationTitle("Add Card")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                // Reset and load fresh templates each time
                viewModel.reset()
                viewModel.loadTemplates()
            }
        }
    }

    // MARK: - Main Content

    @ViewBuilder
    private var mainContent: some View {
        VStack(spacing: 0) {
            // Search bar
            searchBar
                .padding(.horizontal, DesignSystem.Spacing.lg)
                .padding(.vertical, DesignSystem.Spacing.md)

            if viewModel.filteredTemplates.isEmpty {
                // Empty search state
                emptySearchState
            } else {
                // Card template grid
                ScrollView {
                    templateGrid
                        .padding(.horizontal, DesignSystem.Spacing.lg)
                        .padding(.bottom, DesignSystem.Spacing.xxl)
                }
            }

            // Bottom section with nickname field and add button
            if viewModel.selectedTemplate != nil {
                bottomSection
            }
        }
        .background(DesignSystem.Colors.backgroundPrimary)
    }

    // MARK: - Search Bar

    @ViewBuilder
    private var searchBar: some View {
        HStack(spacing: DesignSystem.Spacing.md) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(DesignSystem.Colors.textTertiary)
                .font(.system(size: DesignSystem.Sizing.iconSmall))

            TextField("Search cards...", text: $viewModel.searchQuery)
                .font(DesignSystem.Typography.body)
                .textFieldStyle(.plain)
                .autocorrectionDisabled()

            if !viewModel.searchQuery.isEmpty {
                Button(action: {
                    viewModel.searchQuery = ""
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(DesignSystem.Colors.textTertiary)
                        .font(.system(size: DesignSystem.Sizing.iconSmall))
                }
            }
        }
        .padding(.horizontal, DesignSystem.Spacing.md)
        .padding(.vertical, DesignSystem.Spacing.sm)
        .background(
            RoundedRectangle(cornerRadius: DesignSystem.Sizing.buttonCornerRadius)
                .fill(DesignSystem.Colors.backgroundSecondary)
        )
    }

    // MARK: - Template Grid

    @ViewBuilder
    private var templateGrid: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.xl) {
            // Group templates by issuer
            ForEach(sortedIssuers, id: \.self) { issuer in
                issuerSection(issuer: issuer)
            }
        }
        .padding(.top, DesignSystem.Spacing.md)
    }

    // MARK: - Issuer Section

    @ViewBuilder
    private func issuerSection(issuer: String) -> some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
            // Issuer name header
            Text(issuer)
                .font(DesignSystem.Typography.title3)
                .foregroundStyle(DesignSystem.Colors.textPrimary)

            // Template grid for this issuer
            LazyVGrid(
                columns: [
                    GridItem(.flexible(), spacing: DesignSystem.Spacing.md),
                    GridItem(.flexible(), spacing: DesignSystem.Spacing.md),
                    GridItem(.flexible(), spacing: DesignSystem.Spacing.md)
                ],
                spacing: DesignSystem.Spacing.md
            ) {
                if let templates = viewModel.templatesByIssuer[issuer] {
                    ForEach(templates, id: \.id) { template in
                        templateCard(template)
                    }
                }
            }
        }
    }

    // MARK: - Template Card

    @ViewBuilder
    private func templateCard(_ template: CardTemplate) -> some View {
        Button(action: {
            viewModel.selectTemplate(template)
        }) {
            TemplateCardView(
                template: template,
                isSelected: viewModel.selectedTemplate?.id == template.id
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(template.name) from \(template.issuer)")
        .accessibilityHint(viewModel.selectedTemplate?.id == template.id ? "Selected" : "Double tap to select")
    }

    // MARK: - Bottom Section

    @ViewBuilder
    private var bottomSection: some View {
        VStack(spacing: DesignSystem.Spacing.md) {
            Divider()

            VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
                // Nickname label
                Text("Card Nickname (Optional)")
                    .font(DesignSystem.Typography.subhead)
                    .foregroundStyle(DesignSystem.Colors.textSecondary)

                // Nickname text field
                TextField("e.g., Personal, Business", text: $viewModel.nickname)
                    .font(DesignSystem.Typography.body)
                    .textFieldStyle(.plain)
                    .padding(.horizontal, DesignSystem.Spacing.md)
                    .padding(.vertical, DesignSystem.Spacing.sm)
                    .background(
                        RoundedRectangle(cornerRadius: DesignSystem.Sizing.buttonCornerRadius)
                            .fill(DesignSystem.Colors.backgroundSecondary)
                    )
            }
            .padding(.horizontal, DesignSystem.Spacing.lg)

            // Add button
            Button(action: addCard) {
                HStack {
                    Spacer()
                    Text("Add to Wallet")
                        .font(DesignSystem.Typography.headline)
                    Spacer()
                }
                .padding(.vertical, DesignSystem.Spacing.md)
                .background(
                    RoundedRectangle(cornerRadius: DesignSystem.Sizing.buttonCornerRadius)
                        .fill(viewModel.canAddCard ? DesignSystem.Colors.primaryFallback : DesignSystem.Colors.neutral)
                )
                .foregroundStyle(.white)
            }
            .disabled(!viewModel.canAddCard)
            .padding(.horizontal, DesignSystem.Spacing.lg)
            .accessibilityLabel("Add to Wallet")
            .accessibilityHint(viewModel.canAddCard ? "Double tap to add this card" : "Select a card first")
        }
        .padding(.vertical, DesignSystem.Spacing.md)
        .background(DesignSystem.Colors.backgroundPrimary)
        .shadow(
            color: Color.black.opacity(0.1),
            radius: 8,
            x: 0,
            y: -2
        )
    }

    // MARK: - Loading State

    @ViewBuilder
    private var loadingState: some View {
        VStack(spacing: DesignSystem.Spacing.lg) {
            ProgressView()
                .scaleEffect(1.2)

            Text("Loading cards...")
                .font(DesignSystem.Typography.subhead)
                .foregroundStyle(DesignSystem.Colors.textSecondary)
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

            Text("No cards found")
                .font(DesignSystem.Typography.title3)
                .foregroundStyle(DesignSystem.Colors.textPrimary)

            Text("Try a different search term")
                .font(DesignSystem.Typography.subhead)
                .foregroundStyle(DesignSystem.Colors.textSecondary)

            Spacer()
        }
    }

    // MARK: - Helper Properties

    /// Sorted list of issuer names for consistent display order
    private var sortedIssuers: [String] {
        Array(viewModel.templatesByIssuer.keys).sorted()
    }

    // MARK: - Actions

    /// Add the selected card and dismiss the view
    private func addCard() {
        if let newCard = viewModel.addCard() {
            // Successfully added card - dismiss the sheet
            dismiss()
        } else {
            // Handle error - in production, might show an error alert
            if let error = viewModel.error {
                print("Error adding card: \(error)")
                // Could show an alert here
            }
        }
    }
}

// MARK: - Template Card View Component

/// Compact card representation for template selection
private struct TemplateCardView: View {
    let template: CardTemplate
    let isSelected: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
            // Card visual with gradient
            cardVisual

            // Card name
            Text(template.name)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(DesignSystem.Colors.textPrimary)
                .lineLimit(2)
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    @ViewBuilder
    private var cardVisual: some View {
        ZStack {
            // Background gradient based on card colors
            LinearGradient(
                colors: [
                    Color(hex: template.primaryColorHex),
                    Color(hex: template.secondaryColorHex)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            // Issuer name overlay
            VStack(alignment: .leading) {
                Text(template.issuer.uppercased())
                    .font(.system(size: 8, weight: .semibold))
                    .tracking(1.0)
                    .foregroundStyle(.white.opacity(0.8))

                Spacer()
            }
            .padding(DesignSystem.Spacing.xs)

            // Selection indicator
            if isSelected {
                VStack {
                    HStack {
                        Spacer()
                        ZStack {
                            Circle()
                                .fill(DesignSystem.Colors.primaryFallback)
                                .frame(width: 20, height: 20)

                            Image(systemName: "checkmark")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundStyle(.white)
                        }
                    }
                    Spacer()
                }
                .padding(DesignSystem.Spacing.xs)
            }
        }
        .aspectRatio(DesignSystem.Sizing.cardAspectRatio, contentMode: .fit)
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .strokeBorder(
                    isSelected ? DesignSystem.Colors.primaryFallback : Color.clear,
                    lineWidth: 2
                )
        )
        .shadow(
            color: Color.black.opacity(0.12),
            radius: 4,
            x: 0,
            y: 2
        )
    }
}

// MARK: - Previews

#Preview("Add Card View - Default") {
    AddCardView(viewModel: AddCardViewModel.preview())
}

#Preview("Add Card View - With Selection") {
    let viewModel = AddCardViewModel.preview()
    viewModel.selectTemplate(viewModel.filteredTemplates.first!)
    return AddCardView(viewModel: viewModel)
}

#Preview("Add Card View - With Search") {
    let viewModel = AddCardViewModel.preview()
    viewModel.searchQuery = "Platinum"
    return AddCardView(viewModel: viewModel)
}

#Preview("Add Card View - Empty Search") {
    let viewModel = AddCardViewModel.preview()
    viewModel.searchQuery = "XYZ123"
    return AddCardView(viewModel: viewModel)
}

#Preview("Add Card View - With Nickname") {
    let viewModel = AddCardViewModel.preview()
    viewModel.selectTemplate(viewModel.filteredTemplates.first!)
    viewModel.nickname = "Personal"
    return AddCardView(viewModel: viewModel)
}

#Preview("Template Card - Normal") {
    let template = CardTemplate(
        id: UUID(),
        name: "Platinum Card",
        issuer: "American Express",
        artworkAsset: "amex_platinum",
        annualFee: 695,
        primaryColorHex: "#8B8B8B",
        secondaryColorHex: "#D4D4D4",
        isActive: true,
        lastUpdated: Date(),
        benefits: []
    )
    return TemplateCardView(template: template, isSelected: false)
        .frame(width: 100)
        .padding()
}

#Preview("Template Card - Selected") {
    let template = CardTemplate(
        id: UUID(),
        name: "Gold Card",
        issuer: "American Express",
        artworkAsset: "amex_gold",
        annualFee: 250,
        primaryColorHex: "#B8860B",
        secondaryColorHex: "#FFD700",
        isActive: true,
        lastUpdated: Date(),
        benefits: []
    )
    return TemplateCardView(template: template, isSelected: true)
        .frame(width: 100)
        .padding()
}
