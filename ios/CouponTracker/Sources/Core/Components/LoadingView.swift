//
//  LoadingView.swift
//  CouponTracker
//
//  Created: January 2026
//  Purpose: Simple loading view shown during initial data load.
//

import SwiftUI

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

// MARK: - Preview

#Preview("Loading View") {
    LoadingView()
}
