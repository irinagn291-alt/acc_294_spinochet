import Foundation

/// The twelve inks docked under today's cell. Dip reads this well and writes the chosen ink onto the bristle.
struct Well: Codable, Equatable, Sendable {
    static let capacity = 12

    var inks: [Ink]

    static func stock() -> Well {
        let labels = [
            "Chalk", "Clay", "Ember", "Moss", "Tide", "Dusk",
            "Linen", "Copper", "Sage", "Plum", "Sand", "Soot"
        ]
        let inks = labels.enumerated().map { index, label in
            Ink(id: Self.stableID(index), trayLabel: label, slot: index)
        }
        return Well(inks: inks)
    }

    func ink(id: UUID) -> Ink? {
        inks.first { $0.id == id }
    }

    private static func stableID(_ slot: Int) -> UUID {
        let tail = String(format: "%012d", slot + 1)
        return UUID(uuidString: "B3D4A100-0000-4000-8000-\(tail)") ?? UUID()
    }
}
