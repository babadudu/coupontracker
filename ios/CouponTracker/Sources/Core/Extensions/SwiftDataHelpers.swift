//
//  SwiftDataHelpers.swift
//  CouponTracker
//
//  Extension to handle SwiftData lazy loading patterns
//

import Foundation

extension Sequence {
    /// Eagerly loads a property on all elements to trigger SwiftData lazy loading.
    ///
    /// SwiftData uses lazy loading for relationships, which can cause issues with
    /// aggregations (sum, count, etc.) that don't automatically trigger property access.
    /// This helper ensures properties are loaded before performing operations on them.
    ///
    /// - Parameter keyPath: The key path to the property to eagerly load
    /// - Returns: Array of elements with the specified property loaded
    ///
    /// Example:
    /// ```swift
    /// let total = cards
    ///     .eagerLoad(\.benefits)
    ///     .flatMap { $0.benefits }
    ///     .reduce(0) { $0 + $1.value }
    /// ```
    func eagerLoad<T>(_ keyPath: KeyPath<Element, T>) -> [Element] {
        map { element in
            _ = element[keyPath: keyPath]
            return element
        }
    }
}
