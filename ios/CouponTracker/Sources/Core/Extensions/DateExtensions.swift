//
//  DateExtensions.swift
//  CouponTracker
//
//  Centralized date period calculations to eliminate scattered calendar logic.
//

import Foundation

extension Date {
    /// Adds the specified number of days to this date.
    /// - Parameter days: The number of days to add (can be negative)
    /// - Returns: A new date with the days added, or the original date if calculation fails
    func adding(days: Int) -> Date {
        Calendar.current.date(byAdding: .day, value: days, to: self) ?? self
    }

    /// Returns the start of the month for this date (midnight of the 1st).
    /// - Returns: The first moment of the month, or the original date if calculation fails
    func startOfMonth() -> Date {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month], from: self)
        return calendar.date(from: components) ?? self
    }

    /// Returns the end of the month for this date (last moment of the last day).
    /// - Returns: The last moment of the month, or the original date if calculation fails
    func endOfMonth() -> Date {
        let calendar = Calendar.current
        guard let nextMonth = calendar.date(byAdding: .month, value: 1, to: startOfMonth()),
              let endOfMonth = calendar.date(byAdding: .day, value: -1, to: nextMonth) else {
            return self
        }
        return endOfMonth
    }

    /// Calculates the number of days between this date and the specified date.
    /// - Parameter date: The target date
    /// - Returns: The number of days until the target date (negative if target is in the past)
    func days(until date: Date) -> Int {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.day], from: self, to: date)
        return components.day ?? 0
    }

    /// Checks if this date represents today.
    /// - Returns: true if the date is today, false otherwise
    var isToday: Bool {
        Calendar.current.isDateInToday(self)
    }
}
