import Foundation

/// Written at pen-up together with the day's MoodEntry. Streak and ink mix are computed from cells, not stored here.
struct LayMark: Codable, Equatable, Sendable, Identifiable {
    var id: UUID
    var dayKey: Int
    var inkID: UUID
    var laidAt: Date
}
