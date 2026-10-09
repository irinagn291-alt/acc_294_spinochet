import Foundation

/// Records that today's laid stroke was peeled. The cell returns to Open. Earlier days stay laid.
struct PeelMark: Codable, Equatable, Sendable, Identifiable {
    var id: UUID
    var dayKey: Int
    var peeledAt: Date
}
