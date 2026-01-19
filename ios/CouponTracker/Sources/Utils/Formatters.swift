import Foundation

/// Centralized formatters to avoid repeated instantiation (DRY compliance).
/// Usage: `Formatters.currency.string(from: value)`
enum Formatters {

    // MARK: - Currency

    /// Formats Decimal values as currency (e.g., "$100.00")
    static let currency: NumberFormatter = {
        let f = NumberFormatter()
        f.numberStyle = .currency
        f.currencyCode = "USD"
        return f
    }()

    /// Formats whole dollar amounts without cents (e.g., "$100")
    static let currencyWhole: NumberFormatter = {
        let f = NumberFormatter()
        f.numberStyle = .currency
        f.currencyCode = "USD"
        f.maximumFractionDigits = 0
        return f
    }()

    // MARK: - Dates

    /// Short date format (e.g., "1/15/26")
    static let shortDate: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .short
        f.timeStyle = .none
        return f
    }()

    /// Medium date format (e.g., "Jan 15, 2026")
    static let mediumDate: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .medium
        f.timeStyle = .none
        return f
    }()

    /// Time only (e.g., "9:00 AM")
    static let time: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .none
        f.timeStyle = .short
        return f
    }()

    /// Month and year (e.g., "January 2026")
    static let monthYear: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "MMMM yyyy"
        return f
    }()

    // MARK: - Helpers

    /// Formats a Decimal as currency string, returns "$0" on failure
    static func formatCurrency(_ value: Decimal) -> String {
        currency.string(from: value as NSDecimalNumber) ?? "$0"
    }

    /// Formats a Decimal as whole currency string, returns "$0" on failure
    static func formatCurrencyWhole(_ value: Decimal) -> String {
        currencyWhole.string(from: value as NSDecimalNumber) ?? "$0"
    }
}

// MARK: - CurrencyFormatter Convenience

/// Convenience wrapper for currency formatting (singleton pattern)
enum CurrencyFormatter {
    static let shared = CurrencyFormatterInstance()

    struct CurrencyFormatterInstance {
        func format(_ value: Decimal) -> String {
            Formatters.formatCurrency(value)
        }
    }
}
