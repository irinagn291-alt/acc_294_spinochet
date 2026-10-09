import Foundation

/// A day cell on the plate. Folds Open, then Armed after Dip, then Laid after pen-up.
struct Cell: Codable, Equatable, Sendable, Identifiable {
    var id: Int { dayKey }
    var dayKey: Int
    var fold: CellFold
    var entry: MoodEntry?

    static func open(dayKey: Int) -> Cell {
        Cell(dayKey: dayKey, fold: .open, entry: nil)
    }
}

enum CellFold: String, Codable, Equatable, Sendable {
    case open
    case armed
    case laid
}
