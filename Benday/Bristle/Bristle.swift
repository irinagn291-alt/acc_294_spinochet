import Foundation

/// The dipped brush. Ink sits here until pen-up commits it. A nonempty live stroke blocks another dip.
struct Bristle: Codable, Equatable, Sendable {
    var inkID: UUID?
    var liveStroke: Data

    var isDipped: Bool { inkID != nil }
    var pathIsEmpty: Bool { liveStroke.isEmpty }

    static let dry = Bristle(inkID: nil, liveStroke: Data())
}
