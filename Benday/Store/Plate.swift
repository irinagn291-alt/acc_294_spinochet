import Foundation

/// Single root record. The matrix reads this in memory. The store projects it to one UserDefaults blob.
struct Plate: Equatable, Sendable {
    static let currentSchema = 1

    var schemaVersion: Int
    var cells: [Cell]
    var well: Well
    var bristle: Bristle
    var layMarks: [LayMark]
    var peelMarks: [PeelMark]
    var onboardingComplete: Bool

    static func fresh() -> Plate {
        Plate(
            schemaVersion: currentSchema,
            cells: [],
            well: Well.stock(),
            bristle: .dry,
            layMarks: [],
            peelMarks: [],
            onboardingComplete: false
        )
    }

    func cell(dayKey: Int) -> Cell? {
        cells.first { $0.dayKey == dayKey }
    }

    var showsGesso: Bool {
        !cells.contains { $0.fold == .laid }
    }
}

enum PlateCodingError: Error, Equatable {
    case unsupportedSchema(Int)
}

extension Plate: Codable {
    private enum CodingKeys: String, CodingKey {
        case schemaVersion
        case cells
        case well
        case bristle
        case layMarks
        case peelMarks
        case onboardingComplete
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let version = try container.decode(Int.self, forKey: .schemaVersion)
        switch version {
        case 1:
            schemaVersion = 1
            cells = try container.decode([Cell].self, forKey: .cells)
            well = try container.decode(Well.self, forKey: .well)
            bristle = try container.decode(Bristle.self, forKey: .bristle)
            layMarks = try container.decode([LayMark].self, forKey: .layMarks)
            peelMarks = try container.decode([PeelMark].self, forKey: .peelMarks)
            onboardingComplete = try container.decode(Bool.self, forKey: .onboardingComplete)
        default:
            throw PlateCodingError.unsupportedSchema(version)
        }
    }
}
