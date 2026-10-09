import Foundation

/// One mark for a calendar day. YearMatrix stores at most one of these per YYYYMMDD key.
struct MoodEntry: Codable, Equatable, Sendable, Identifiable {
    var id: Int { dayKey }
    var dayKey: Int
    var inkID: UUID
    /// `PKDrawing.dataRepresentation()` captured at pen-up. Kept as bytes so the plate stays Sendable.
    var stroke: Data
}
