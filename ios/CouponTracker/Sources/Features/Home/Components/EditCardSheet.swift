//
//  EditCardSheet.swift
//  CouponTracker
//
//  Created: January 2026
//  Purpose: Simple edit card sheet for updating card nickname.
//

import SwiftUI
import SwiftData

// MARK: - Edit Card Sheet

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
            // Error loading card
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
            onCancel()
        }
    }
}
