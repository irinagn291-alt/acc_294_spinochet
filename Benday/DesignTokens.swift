import SwiftUI

/// SPEC section 7. The only place these hex values live — reach colours
/// and the font family through here. Keep this file and its values.
enum DesignTokens {
    /// #D8DADE
    static let bg = Color(red: 0.847059, green: 0.854902, blue: 0.870588)
    static let bgHex = "#D8DADE"
    /// #ECEDEF
    static let surface = Color(red: 0.925490, green: 0.929412, blue: 0.937255)
    static let surfaceHex = "#ECEDEF"
    /// #15181E
    static let ink = Color(red: 0.082353, green: 0.094118, blue: 0.117647)
    static let inkHex = "#15181E"
    /// #2253B4
    static let accent = Color(red: 0.133333, green: 0.325490, blue: 0.705882)
    static let accentHex = "#2253B4"
    /// #53565A
    static let muted = Color(red: 0.325490, green: 0.337255, blue: 0.352941)
    static let mutedHex = "#53565A"
    static let fontFamily = "Verdana"
}
