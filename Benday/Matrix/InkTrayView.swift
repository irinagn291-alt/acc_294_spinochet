import UIKit

/// Docked tray under today's cell. Each well is a dip.
final class InkTrayView: UIView {
    var onDip: ((UUID) -> Void)?
    private let scroll = UIScrollView()
    private var buttons: [UIButton] = []

    override init(frame: CGRect) {
        super.init(frame: frame)
        scroll.showsHorizontalScrollIndicator = false
        scroll.translatesAutoresizingMaskIntoConstraints = false
        addSubview(scroll)
        NSLayoutConstraint.activate([
            scroll.leadingAnchor.constraint(equalTo: leadingAnchor),
            scroll.trailingAnchor.constraint(equalTo: trailingAnchor),
            scroll.topAnchor.constraint(equalTo: topAnchor),
            scroll.bottomAnchor.constraint(equalTo: bottomAnchor),
            heightAnchor.constraint(greaterThanOrEqualToConstant: PlateMeasure.hit)
        ])
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        nil
    }

    func render(well: Well, dipped: UUID?, dipsEnabled: Bool) {
        buttons.forEach { $0.removeFromSuperview() }
        buttons = []
        var x = PlateMeasure.gap
        let ordered = well.inks.sorted { $0.slot < $1.slot }
        for ink in ordered {
            let button = UIButton(type: .system)
            button.setTitle(ink.trayLabel, for: .normal)
            button.titleLabel?.font = PlateType.caption()
            button.titleLabel?.adjustsFontForContentSizeCategory = true
            button.titleLabel?.adjustsFontSizeToFitWidth = true
            button.titleLabel?.minimumScaleFactor = 0.7
            button.setTitleColor(PlateColor.onWell(ink.slot), for: .normal)
            button.backgroundColor = PlateColor.well(ink.slot)
            button.layer.cornerRadius = PlateRadius.chip
            button.layer.cornerCurve = .continuous
            button.clipsToBounds = true
            let selected = ink.id == dipped
            button.layer.borderWidth = selected ? PlateMeasure.line : 0
            button.layer.borderColor = PlateColor.ink.cgColor
            button.accessibilityLabel = ink.trayLabel
            button.accessibilityValue = selected ? "Dipped" : nil
            button.isEnabled = dipsEnabled
            button.alpha = dipsEnabled ? 1 : 0.45
            button.tag = ink.slot
            button.accessibilityIdentifier = ink.id.uuidString
            button.frame = CGRect(x: x, y: 0, width: PlateMeasure.unit * 11, height: PlateMeasure.hit)
            button.addAction(UIAction { [weak self] _ in
                self?.onDip?(ink.id)
            }, for: .touchUpInside)
            scroll.addSubview(button)
            buttons.append(button)
            x += button.frame.width + PlateMeasure.unit
        }
        scroll.contentSize = CGSize(width: x + PlateMeasure.gap, height: PlateMeasure.hit)
    }
}
