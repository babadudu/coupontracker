//
//  BenefitRowButtonStyle.swift
//  CouponTracker
//
//  Created: January 2026
//  Purpose: Custom button style for benefit rows with subtle press feedback.
//

import SwiftUI

// MARK: - Benefit Row Button Style

/// Custom button style for benefit rows with subtle press feedback
struct BenefitRowButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background(
                configuration.isPressed ?
                    DesignSystem.Colors.backgroundSecondary :
                    Color.clear
            )
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}
