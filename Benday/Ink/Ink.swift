import Foundation

/// One well in the docked tray. Colour is chosen later from the slot, never stored as a hex.
struct Ink: Codable, Equatable, Sendable, Identifiable {
    var id: UUID
    var trayLabel: String
    var slot: Int
}
