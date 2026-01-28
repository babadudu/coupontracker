// OnboardingView.swift
// CouponTracker
//
// Simple onboarding view for new users

import SwiftUI

/// Main onboarding flow view that guides new users through setup
struct OnboardingFlowView: View {
    let onComplete: () -> Void

    @State private var currentPage = 0

    private let pages = [
        OnboardingPage(
            title: "Track Your Card Benefits",
            description: "Never miss a credit card perk again. Track all your benefits in one place.",
            systemImage: "creditcard.fill"
        ),
        OnboardingPage(
            title: "Get Timely Reminders",
            description: "Receive notifications before your benefits expire so you can use them.",
            systemImage: "bell.badge.fill"
        ),
        OnboardingPage(
            title: "Maximize Your Value",
            description: "See how much value you're getting from your cards and find opportunities.",
            systemImage: "chart.bar.fill"
        )
    ]

    var body: some View {
        VStack(spacing: 0) {
            TabView(selection: $currentPage) {
                ForEach(0..<pages.count, id: \.self) { index in
                    OnboardingPageView(page: pages[index])
                        .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .always))

            // Bottom button area
            VStack(spacing: DesignSystem.Spacing.md) {
                if currentPage == pages.count - 1 {
                    Button(action: onComplete) {
                        Text("Get Started")
                            .font(DesignSystem.Typography.headline)
                            .foregroundColor(DesignSystem.Colors.onColor)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(DesignSystem.Colors.primary)
                            .cornerRadius(DesignSystem.Sizing.buttonCornerRadius)
                    }
                } else {
                    Button(action: { currentPage += 1 }) {
                        Text("Continue")
                            .font(DesignSystem.Typography.headline)
                            .foregroundColor(DesignSystem.Colors.onColor)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(DesignSystem.Colors.primary)
                            .cornerRadius(DesignSystem.Sizing.buttonCornerRadius)
                    }
                }

                Button(action: onComplete) {
                    Text("Skip")
                        .font(DesignSystem.Typography.body)
                        .foregroundColor(DesignSystem.Colors.textSecondary)
                }
            }
            .padding(.horizontal, DesignSystem.Spacing.lg)
            .padding(.bottom, DesignSystem.Spacing.xl)
        }
        .background(DesignSystem.Colors.backgroundPrimary)
    }
}

/// Simple onboarding view (alias for backward compatibility)
struct OnboardingView: View {
    let onComplete: () -> Void

    var body: some View {
        OnboardingFlowView(onComplete: onComplete)
    }
}

// MARK: - Supporting Types

struct OnboardingPage {
    let title: String
    let description: String
    let systemImage: String
}

struct OnboardingPageView: View {
    let page: OnboardingPage

    var body: some View {
        VStack(spacing: DesignSystem.Spacing.xl) {
            Spacer()

            Image(systemName: page.systemImage)
                .font(.system(size: 80))
                .foregroundColor(DesignSystem.Colors.primary)

            VStack(spacing: DesignSystem.Spacing.sm) {
                Text(page.title)
                    .font(DesignSystem.Typography.title1)
                    .foregroundColor(DesignSystem.Colors.textPrimary)
                    .multilineTextAlignment(.center)

                Text(page.description)
                    .font(DesignSystem.Typography.body)
                    .foregroundColor(DesignSystem.Colors.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, DesignSystem.Spacing.lg)
            }

            Spacer()
            Spacer()
        }
        .padding()
    }
}

#Preview {
    OnboardingFlowView(onComplete: {})
}
