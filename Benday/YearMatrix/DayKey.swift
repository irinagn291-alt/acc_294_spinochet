import Foundation

/// YYYYMMDD taken from `Calendar.startOfDay` in the reader's time zone.
enum DayKey {
    static func make(_ date: Date, calendar: Calendar) -> Int {
        let day = calendar.startOfDay(for: date)
        let parts = calendar.dateComponents([.year, .month, .day], from: day)
        let year = parts.year ?? 0
        let month = parts.month ?? 0
        let dayOfMonth = parts.day ?? 0
        return year * 10_000 + month * 100 + dayOfMonth
    }

    static func date(from key: Int, calendar: Calendar) -> Date? {
        var parts = DateComponents()
        parts.year = key / 10_000
        parts.month = (key / 100) % 100
        parts.day = key % 100
        parts.calendar = calendar
        guard let resolved = calendar.date(from: parts) else { return nil }
        return calendar.startOfDay(for: resolved)
    }

    static func byAddingDays(_ days: Int, to key: Int, calendar: Calendar) -> Int? {
        guard let date = date(from: key, calendar: calendar),
              let shifted = calendar.date(byAdding: .day, value: days, to: date) else {
            return nil
        }
        return make(shifted, calendar: calendar)
    }
}
