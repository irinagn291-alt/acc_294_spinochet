import Foundation

/// Refusals from the bristle-lay fold. A refusal names the next tap that still works.
enum BristleRefusal: Error, Equatable, Sendable {
    /// Sketch on a laid cell. Peel today, then dip and draw again.
    case sketchOnLaid
    /// Sketch before dip. Dip an ink first.
    case sketchWhileOpen
    /// Dip while the armed path already holds a stroke. Peel, then dip.
    case dipOverLiveStroke
    /// Pen-up with nothing drawn.
    case penUpWithoutStroke
    /// Pen-up when today is not armed.
    case penUpWhileNotArmed
    /// Peel when today has no laid stroke.
    case peelWhenNotLaid
    /// The ink is not in the well.
    case unknownInk
}
