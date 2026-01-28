// AppearanceMode.swift
// CouponTracker
//
// Created: January 2026
// Purpose: User preference for app appearance (system, light, dark).

import SwiftUI

/// Appearance mode preference for the app.
///
/// Maps to ColorScheme for application to the environment.
/// Provides display metadata (name, icon) for settings UI.
enum AppearanceMode: String, Codable, CaseIterable, Identifiable {
    case system
    case light
    case dark

    var id: String { rawValue }

    /// Corresponding ColorScheme for SwiftUI environment.
    /// Returns nil for .system to use device settings.
    var scheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }

    /// User-facing display name
    var displayName: String {
        switch self {
        case .system: return "System"
        case .light: return "Light"
        case .dark: return "Dark"
        }
    }

    /// SF Symbol icon name for settings UI
    var iconName: String {
        switch self {
        case .system: return "circle.lefthalf.filled"
        case .light: return "sun.max.fill"
        case .dark: return "moon.fill"
        }
    }
}
