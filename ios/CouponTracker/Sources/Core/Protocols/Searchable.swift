//
//  Searchable.swift
//  CouponTracker
//
//  Created on 2026-01-20.
//

import Foundation

/// Protocol for types that support text-based search filtering.
protocol Searchable {
    /// Determines if this item matches the given search query.
    ///
    /// - Parameter query: The search text to match against.
    /// - Returns: True if the item matches the query, false otherwise.
    func matches(query: String) -> Bool
}

extension CardTemplate: Searchable {
    func matches(query: String) -> Bool {
        let q = query.lowercased()
        return name.lowercased().contains(q) ||
               issuer.lowercased().contains(q)
    }
}

extension Sequence where Element: Searchable {
    /// Filters the sequence by the given search query.
    ///
    /// - Parameter query: The search text to filter by. If empty or whitespace-only, returns all elements.
    /// - Returns: Array of elements that match the query.
    func filtered(by query: String) -> [Element] {
        let trimmedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedQuery.isEmpty else {
            return Array(self)
        }
        return filter { $0.matches(query: trimmedQuery) }
    }
}
