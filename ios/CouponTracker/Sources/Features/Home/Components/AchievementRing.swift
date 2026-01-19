//
//  AchievementRing.swift
//  CouponTracker
//
//  Created: January 2026
//  Purpose: Apple Fitness-inspired progress ring component.
//           Displays progress as an animated arc with gradient colors.

import SwiftUI

/// A single achievement ring displaying progress with gradient colors.
///
/// Usage:
/// ```swift
/// AchievementRing(
///     progress: 0.75,
///     gradientColors: [.green, .blue],
///     lineWidth: 20,
///     size: 200
/// )
/// ```
struct AchievementRing: View {

    // MARK: - Properties

    /// Progress value from 0.0 to 1.0
    let progress: Double

    /// Colors for the gradient arc
    let gradientColors: [Color]

    /// Width of the ring stroke
    var lineWidth: CGFloat = 20

    /// Overall size of the ring
    var size: CGFloat = 200

    /// Whether to show the checkmark on completion
    var showCompletionMark: Bool = true

    // MARK: - State

    @State private var animatedProgress: Double = 0

    // MARK: - Body

    var body: some View {
        ZStack {
            // Background track
            Circle()
                .stroke(
                    trackColor,
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )

            // Progress arc
            Circle()
                .trim(from: 0, to: min(animatedProgress, 1.0))
                .stroke(
                    progressGradient,
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))

            // Completion checkmark
            if showCompletionMark && animatedProgress >= 1.0 {
                completionMark
            }
        }
        .frame(width: size, height: size)
        .onAppear {
            withAnimation(DesignSystem.Animation.spring) {
                animatedProgress = progress
            }
        }
        .onChange(of: progress) { _, newValue in
            withAnimation(DesignSystem.Animation.spring) {
                animatedProgress = newValue
            }
        }
    }

    // MARK: - Subviews

    /// Background track color (faded version of first gradient color)
    private var trackColor: Color {
        gradientColors.first?.opacity(0.2) ?? Color.gray.opacity(0.2)
    }

    /// Angular gradient for the progress arc
    private var progressGradient: AngularGradient {
        AngularGradient(
            colors: gradientColors + [gradientColors.first ?? .green],
            center: .center,
            startAngle: .degrees(0),
            endAngle: .degrees(360 * animatedProgress)
        )
    }

    /// Checkmark shown at 100% completion
    private var completionMark: some View {
        Image(systemName: "checkmark")
            .font(.system(size: size * 0.25, weight: .bold))
            .foregroundStyle(gradientColors.first ?? DesignSystem.Colors.success)
            .transition(.scale.combined(with: .opacity))
    }
}

// MARK: - Ring Styles

extension AchievementRing {

    /// Creates a success-themed ring (green gradient)
    static func success(progress: Double, size: CGFloat = 200) -> AchievementRing {
        AchievementRing(
            progress: progress,
            gradientColors: [
                DesignSystem.Colors.success,
                DesignSystem.Colors.success.opacity(0.7)
            ],
            size: size
        )
    }

    /// Creates a warning-themed ring (orange gradient)
    static func warning(progress: Double, size: CGFloat = 200) -> AchievementRing {
        AchievementRing(
            progress: progress,
            gradientColors: [
                DesignSystem.Colors.warning,
                DesignSystem.Colors.warning.opacity(0.7)
            ],
            size: size
        )
    }

    /// Creates a danger-themed ring (red gradient)
    static func danger(progress: Double, size: CGFloat = 200) -> AchievementRing {
        AchievementRing(
            progress: progress,
            gradientColors: [
                DesignSystem.Colors.danger,
                DesignSystem.Colors.danger.opacity(0.7)
            ],
            size: size
        )
    }
}

// MARK: - Mini Ring

/// A compact version of the achievement ring for list views
struct MiniAchievementRing: View {

    let progress: Double
    let color: Color
    var size: CGFloat = 40
    var lineWidth: CGFloat = 4

    var body: some View {
        AchievementRing(
            progress: progress,
            gradientColors: [color, color.opacity(0.7)],
            lineWidth: lineWidth,
            size: size,
            showCompletionMark: false
        )
    }
}

// MARK: - Category Ring

/// Ring with label for category-based progress display
struct CategoryRing: View {

    let category: BenefitCategory
    let usedCount: Int
    let totalCount: Int
    var size: CGFloat = 60

    private var progress: Double {
        guard totalCount > 0 else { return 0 }
        return Double(usedCount) / Double(totalCount)
    }

    var body: some View {
        VStack(spacing: DesignSystem.Spacing.xs) {
            ZStack {
                AchievementRing(
                    progress: progress,
                    gradientColors: [categoryColor, categoryColor.opacity(0.7)],
                    lineWidth: 6,
                    size: size,
                    showCompletionMark: false
                )

                Text("\(usedCount)/\(totalCount)")
                    .font(DesignSystem.Typography.caption)
                    .fontWeight(.semibold)
            }

            Text(category.displayName)
                .font(DesignSystem.Typography.caption)
                .foregroundStyle(DesignSystem.Colors.textSecondary)
        }
    }

    private var categoryColor: Color {
        DesignSystem.Colors.categoryColor(for: category)
    }
}

// MARK: - Preview

#Preview("Achievement Ring") {
    VStack(spacing: 32) {
        AchievementRing(
            progress: 0.8,
            gradientColors: [.green, .mint]
        )

        HStack(spacing: 24) {
            AchievementRing.success(progress: 0.25, size: 80)
            AchievementRing.warning(progress: 0.5, size: 80)
            AchievementRing.danger(progress: 0.75, size: 80)
        }

        HStack(spacing: 16) {
            MiniAchievementRing(progress: 0.3, color: .blue)
            MiniAchievementRing(progress: 0.6, color: .orange)
            MiniAchievementRing(progress: 1.0, color: .green)
        }
    }
    .padding()
}

#Preview("Category Rings") {
    HStack(spacing: 20) {
        CategoryRing(category: .dining, usedCount: 2, totalCount: 3)
        CategoryRing(category: .travel, usedCount: 1, totalCount: 1)
        CategoryRing(category: .shopping, usedCount: 0, totalCount: 2)
    }
    .padding()
}
