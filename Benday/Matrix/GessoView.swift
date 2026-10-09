import UIKit

/// Full-page empty plate. Headline, one line, generated art, and a bottom Dip.
final class GessoView: UIView {
    let dipButton = PlateButton(kind: .primary)
    private let art = UIImageView()
    private let headline = UILabel()
    private let line = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = PlateColor.background
        art.contentMode = .scaleAspectFit
        art.image = UIImage(named: "bdy_EmptyHome")
        art.isAccessibilityElement = false
        art.accessibilityIgnoresInvertColors = true
        headline.text = "The year is empty."
        headline.textColor = PlateColor.ink
        headline.numberOfLines = 2
        headline.adjustsFontForContentSizeCategory = true
        line.text = "The first stroke is yours."
        line.textColor = PlateColor.muted
        line.numberOfLines = 0
        line.adjustsFontForContentSizeCategory = true
        dipButton.setTitle("Dip")
        let stack = UIStackView(arrangedSubviews: [art, headline, line, UIView(), dipButton])
        stack.axis = .vertical
        stack.spacing = PlateMeasure.gap
        stack.translatesAutoresizingMaskIntoConstraints = false
        art.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stack)
        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: safeAreaLayoutGuide.leadingAnchor, constant: PlateMeasure.gap),
            stack.trailingAnchor.constraint(equalTo: safeAreaLayoutGuide.trailingAnchor, constant: -PlateMeasure.gap),
            stack.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor, constant: PlateMeasure.pad),
            stack.bottomAnchor.constraint(equalTo: safeAreaLayoutGuide.bottomAnchor, constant: -PlateMeasure.gap),
            art.heightAnchor.constraint(equalTo: heightAnchor, multiplier: 0.36),
            dipButton.heightAnchor.constraint(greaterThanOrEqualToConstant: PlateMeasure.hit)
        ])
        applyFonts()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        nil
    }

    func applyFonts() {
        headline.font = PlateType.display()
        line.font = PlateType.body()
        dipButton.applyFont()
    }
}
