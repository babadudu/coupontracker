// RecommendationSearchView.swift
// CouponTracker
//
// View for searching and discovering card recommendations

import SwiftUI

/// Search view for finding card recommendations
struct RecommendationSearchView: View {

    // MARK: - Properties

    var onSelectCard: ((UUID) -> Void)?

    @Environment(\.dismiss) private var dismiss
    @State private var searchText = ""
    @State private var recommendations: [RecommendedCard] = []

    // MARK: - Body

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if recommendations.isEmpty && searchText.isEmpty {
                    emptyStateView
                } else if recommendations.isEmpty {
                    noResultsView
                } else {
                    resultsList
                }
            }
            .navigationTitle("Find Cards")
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $searchText, prompt: "Search cards...")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .onChange(of: searchText) { _, newValue in
                // Search would be performed here with the recommendation service
                // For now, show placeholder behavior
            }
        }
    }

    // MARK: - Subviews

    private var emptyStateView: some View {
        VStack(spacing: DesignSystem.Spacing.lg) {
            Spacer()

            Image(systemName: "magnifyingglass")
                .font(.system(size: 48))
                .foregroundColor(DesignSystem.Colors.textSecondary)

            Text("Search for Cards")
                .font(DesignSystem.Typography.title2)
                .foregroundColor(DesignSystem.Colors.textPrimary)

            Text("Find credit cards with benefits that match your spending habits.")
                .font(DesignSystem.Typography.body)
                .foregroundColor(DesignSystem.Colors.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, DesignSystem.Spacing.xl)

            Spacer()
        }
    }

    private var noResultsView: some View {
        VStack(spacing: DesignSystem.Spacing.lg) {
            Spacer()

            Image(systemName: "creditcard.trianglebadge.exclamationmark")
                .font(.system(size: 48))
                .foregroundColor(DesignSystem.Colors.textSecondary)

            Text("No Results")
                .font(DesignSystem.Typography.title2)
                .foregroundColor(DesignSystem.Colors.textPrimary)

            Text("No cards match your search. Try different keywords.")
                .font(DesignSystem.Typography.body)
                .foregroundColor(DesignSystem.Colors.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, DesignSystem.Spacing.xl)

            Spacer()
        }
    }

    private var resultsList: some View {
        List(recommendations) { card in
            RecommendationRowView(card: card) {
                onSelectCard?(card.cardTemplateId)
                dismiss()
            }
        }
        .listStyle(.plain)
    }
}

// MARK: - Recommendation Row

struct RecommendationRowView: View {
    let card: RecommendedCard
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: DesignSystem.Spacing.md) {
                // Card icon
                RoundedRectangle(cornerRadius: DesignSystem.Sizing.badgeCornerRadius)
                    .fill(DesignSystem.Colors.primary.opacity(0.1))
                    .frame(width: 44, height: 28)
                    .overlay(
                        Image(systemName: "creditcard.fill")
                            .font(.caption)
                            .foregroundColor(DesignSystem.Colors.primary)
                    )

                VStack(alignment: .leading, spacing: 2) {
                    Text(card.cardName)
                        .font(DesignSystem.Typography.headline)
                        .foregroundColor(DesignSystem.Colors.textPrimary)

                    Text(card.issuer)
                        .font(DesignSystem.Typography.caption)
                        .foregroundColor(DesignSystem.Colors.textSecondary)
                }

                Spacer()

                Text(card.reason)
                    .font(DesignSystem.Typography.caption)
                    .foregroundColor(DesignSystem.Colors.textSecondary)
            }
            .padding(.vertical, DesignSystem.Spacing.xs)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    RecommendationSearchView()
}
