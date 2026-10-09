import CoreText
import SwiftUI
import UIKit

/// Spacing, radii, and motion. Views read these accessors and do not invent a second kit.
enum PlateMeasure {
    static var unit: CGFloat { 8 }
    static var gap: CGFloat { unit * 2 }
    static var pad: CGFloat { unit * 3 }
    static var hit: CGFloat { unit * 6 }
    static var control: CGFloat { unit * 6 }
    static var stage: CGFloat { unit * 20 }
    static var gridFloor: CGFloat { unit * 22 }
    static var line: CGFloat { 2 }
    static var nib: CGFloat { unit }
}

enum PlateRadius {
    static var card: CGFloat { 32 }
    static var chip: CGFloat { 16 }
}

@MainActor
enum PlateMotion {
    static var fade: TimeInterval {
        UIAccessibility.isReduceMotionEnabled ? 0 : 0.18
    }

    static var playfulScale: CGFloat { 0.96 }
}

/// Colour from DesignTokens only. Ink slots are blends of those tokens.
enum PlateColor {
    static var background: UIColor { UIColor(DesignTokens.bg) }
    static var surface: UIColor { UIColor(DesignTokens.surface) }
    static var ink: UIColor { UIColor(DesignTokens.ink) }
    static var accent: UIColor { UIColor(DesignTokens.accent) }
    static var muted: UIColor { UIColor(DesignTokens.muted) }

    /// Ink or surface, whichever stays readable on a well swatch.
    static func onWell(_ slot: Int) -> UIColor {
        let fill = well(slot)
        return contrast(surface, fill) >= contrast(ink, fill) ? surface : ink
    }

    static func well(_ slot: Int) -> UIColor {
        let index = ((slot % Well.capacity) + Well.capacity) % Well.capacity
        switch index {
        case 0: return accent
        case 1: return ink
        case 2: return muted
        case 3: return blend(accent, ink, 0.45)
        case 4: return blend(accent, muted, 0.5)
        case 5: return blend(ink, surface, 0.28)
        case 6: return blend(accent, surface, 0.42)
        case 7: return blend(muted, ink, 0.35)
        case 8: return blend(accent, background, 0.3)
        case 9: return blend(ink, background, 0.22)
        case 10: return blend(muted, surface, 0.4)
        default: return blend(accent, ink, 0.22)
        }
    }

    private static func contrast(_ leading: UIColor, _ trailing: UIColor) -> CGFloat {
        let left = luminance(leading)
        let right = luminance(trailing)
        let lighter = max(left, right)
        let darker = min(left, right)
        return (lighter + 0.05) / (darker + 0.05)
    }

    private static func luminance(_ color: UIColor) -> CGFloat {
        var red: CGFloat = 0, green: CGFloat = 0, blue: CGFloat = 0, alpha: CGFloat = 0
        color.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        func channel(_ value: CGFloat) -> CGFloat {
            value <= 0.04045 ? value / 12.92 : pow((value + 0.055) / 1.055, 2.4)
        }
        return 0.2126 * channel(red) + 0.7152 * channel(green) + 0.0722 * channel(blue)
    }

    private static func blend(_ leading: UIColor, _ trailing: UIColor, _ amount: CGFloat) -> UIColor {
        var lr: CGFloat = 0, lg: CGFloat = 0, lb: CGFloat = 0, la: CGFloat = 0
        var rr: CGFloat = 0, rg: CGFloat = 0, rb: CGFloat = 0, ra: CGFloat = 0
        leading.getRed(&lr, green: &lg, blue: &lb, alpha: &la)
        trailing.getRed(&rr, green: &rg, blue: &rb, alpha: &ra)
        let t = min(1, max(0, amount))
        return UIColor(
            red: lr + (rr - lr) * t,
            green: lg + (rg - lg) * t,
            blue: lb + (rb - lb) * t,
            alpha: la + (ra - la) * t
        )
    }
}

/// Verdana scale. Six steps, capped, with monospaced digits.
@MainActor
enum PlateType {
    static func display() -> UIFont { face(28, .largeTitle, bold: true) }
    static func title() -> UIFont { face(22, .title2, bold: true) }
    static func headline() -> UIFont { face(20, .headline, bold: true) }
    static func body() -> UIFont { face(17, .body, bold: false) }
    static func caption() -> UIFont { face(14, .footnote, bold: false) }
    static func micro() -> UIFont { face(12, .caption2, bold: false) }

    private static func face(_ size: CGFloat, _ style: UIFont.TextStyle, bold: Bool) -> UIFont {
        let baseSize = min(34, max(12, size))
        let name = bold ? "Verdana-Bold" : "Verdana"
        let base = UIFont(name: name, size: baseSize) ?? UIFont.systemFont(ofSize: baseSize, weight: bold ? .bold : .regular)
        let featured = base.fontDescriptor.addingAttributes([
            UIFontDescriptor.AttributeName.featureSettings: [
                [
                    UIFontDescriptor.FeatureKey.type: kNumberSpacingType,
                    UIFontDescriptor.FeatureKey.selector: kMonospacedNumbersSelector
                ]
            ]
        ])
        let seeded = UIFont(descriptor: featured, size: baseSize)
        let scaled = UIFontMetrics(forTextStyle: style).scaledFont(for: seeded)
        let resolved = min(34, max(12, scaled.pointSize))
        return UIFont(descriptor: scaled.fontDescriptor, size: resolved)
    }
}

@MainActor
enum PlateCount {
    private static let formatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter
    }()

    static func string(_ value: Int) -> String {
        formatter.string(from: NSNumber(value: value)) ?? "0"
    }
}

/// Filled primary action and a separate destructive action. Default, pressed, disabled, loading.
final class PlateButton: UIButton {
    enum Kind {
        case primary
        case destructive
    }

    private let kind: Kind
    private let spinner = UIActivityIndicatorView(style: .medium)

    var isLoading = false {
        didSet { apply() }
    }

    init(kind: Kind) {
        self.kind = kind
        super.init(frame: .zero)
        configuration = kind == .primary ? .filled() : .gray()
        spinner.hidesWhenStopped = true
        addSubview(spinner)
        spinner.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            spinner.centerXAnchor.constraint(equalTo: centerXAnchor),
            spinner.centerYAnchor.constraint(equalTo: centerYAnchor),
            heightAnchor.constraint(greaterThanOrEqualToConstant: PlateMeasure.hit)
        ])
        layer.cornerCurve = .continuous
        clipsToBounds = true
        apply()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        nil
    }

    override var isHighlighted: Bool {
        didSet { apply() }
    }

    override var isEnabled: Bool {
        didSet { apply() }
    }

    func setTitle(_ title: String) {
        accessibilityLabel = title
        var updated = configuration ?? .filled()
        updated.title = title
        configuration = updated
        apply()
    }

    func applyFont() {
        apply()
    }

    private func apply() {
        var updated = configuration ?? .filled()
        updated.cornerStyle = .fixed
        updated.background.cornerRadius = PlateRadius.card
        updated.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
            var copy = incoming
            copy.font = PlateType.headline()
            return copy
        }
        updated.contentInsets = NSDirectionalEdgeInsets(
            top: PlateMeasure.unit,
            leading: PlateMeasure.gap,
            bottom: PlateMeasure.unit,
            trailing: PlateMeasure.gap
        )
        switch kind {
        case .primary:
            updated.baseForegroundColor = PlateColor.surface
            updated.baseBackgroundColor = PlateColor.accent
            spinner.color = PlateColor.surface
        case .destructive:
            updated.baseForegroundColor = PlateColor.ink
            updated.baseBackgroundColor = PlateColor.surface
            updated.background.strokeColor = PlateColor.ink
            updated.background.strokeWidth = PlateMeasure.line
            spinner.color = PlateColor.ink
        }
        if isLoading {
            updated.title = " "
            spinner.startAnimating()
        } else {
            spinner.stopAnimating()
        }
        configuration = updated
        let inactive = !isEnabled || isLoading
        alpha = inactive ? 0.45 : (isHighlighted ? 0.82 : 1)
        isUserInteractionEnabled = !isLoading
        layer.cornerRadius = PlateRadius.card
    }
}
