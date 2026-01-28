//
//  WalletTabView.swift
//  CouponTracker
//
//  Created: January 2026
//  Purpose: Wallet tab showing user's cards and benefits.
//

import SwiftUI
import SwiftData

// MARK: - Wallet Tab View

/// Wallet tab showing user's cards and benefits
struct WalletTabView: View {
    @Environment(AppContainer.self) private var container
    @Binding var viewModel: HomeViewModel?
    @State private var selectedCardId: UUID?
    @State private var highlightedBenefitId: UUID?
    @State private var showAddCard = false
    @State private var showEditCard = false
    @State private var showExpiringList = false
    @State private var showRecommendationSearch = false

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
                        categoryRecommendations: viewModel.categoryRecommendations,
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
                        },
                        onSearchRecommendations: {
                            showRecommendationSearch = true
                        },
                        onSelectRecommendedCard: { cardId in
                            selectedCardId = cardId
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
                set: { if !$0 { selectedCardId = nil; highlightedBenefitId = nil } }
            )) {
                if let card = selectedCard {
                    CardDetailView(
                        card: card,
                        highlightBenefitId: highlightedBenefitId,
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
                        templateLoader: container.templateLoader,
                        notificationService: container.notificationService,
                        modelContext: container.modelContext
                    )
                )
            }
            .sheet(isPresented: $showEditCard) {
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
            .sheet(isPresented: $showRecommendationSearch) {
                RecommendationSearchView(
                    onSelectCard: { cardId in
                        showRecommendationSearch = false
                        selectedCardId = cardId
                    }
                )
            }
            // Listen for deep link navigation from notifications
            .onReceive(NotificationCenter.default.publisher(for: Notification.Name("CouponTracker.selectCard"))) { notification in
                if let cardId = notification.userInfo?["cardId"] as? UUID {
                    selectedCardId = cardId
                    if let benefitId = notification.userInfo?["benefitId"] as? UUID {
                        highlightedBenefitId = benefitId
                    }
                }
            }
        }
    }
}

// MARK: - Wallet Tab View Actions

extension WalletTabView {

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

    func deleteCard(_ card: PreviewCard) {
        let cardIdToDelete = card.id
        viewModel?.removeCardFromState(cardIdToDelete)
        selectedCardId = nil

        Task {
            do {
                let allCards = try container.cardRepository.getAllCards()
                if let matchingCard = allCards.first(where: { $0.id == cardIdToDelete }) {
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
