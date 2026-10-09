import UIKit

/// Three plates before the matrix. Skip still writes the plate defaults.
final class GateController: UIViewController {
    private let session: PlateSession
    private let art = UIImageView()
    private let headline = UILabel()
    private let line = UILabel()
    private let skip = UIButton(type: .system)
    private let proceed = PlateButton(kind: .primary)
    private let pages = UIPageControl()
    private var index = 0

    init(session: PlateSession) {
        self.session = session
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        nil
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = PlateColor.background
        art.contentMode = .scaleAspectFit
        art.isAccessibilityElement = false
        headline.textColor = PlateColor.ink
        headline.numberOfLines = 3
        headline.adjustsFontForContentSizeCategory = true
        line.textColor = PlateColor.muted
        line.numberOfLines = 0
        line.adjustsFontForContentSizeCategory = true
        pages.numberOfPages = 3
        pages.currentPageIndicatorTintColor = PlateColor.accent
        pages.pageIndicatorTintColor = PlateColor.muted
        pages.isUserInteractionEnabled = false
        var skipConfig = UIButton.Configuration.plain()
        skipConfig.title = "Skip"
        skipConfig.baseForegroundColor = PlateColor.ink
        skip.configuration = skipConfig
        skip.accessibilityLabel = "Skip"
        skip.addAction(UIAction { [weak self] _ in self?.complete() }, for: .touchUpInside)
        proceed.addAction(UIAction { [weak self] _ in self?.advance() }, for: .touchUpInside)
        let stack = UIStackView(arrangedSubviews: [art, headline, line, pages, UIView(), skip, proceed])
        stack.axis = .vertical
        stack.spacing = PlateMeasure.gap
        stack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stack)
        let guide = view.safeAreaLayoutGuide
        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: guide.leadingAnchor, constant: PlateMeasure.gap),
            stack.trailingAnchor.constraint(equalTo: guide.trailingAnchor, constant: -PlateMeasure.gap),
            stack.topAnchor.constraint(equalTo: guide.topAnchor, constant: PlateMeasure.pad),
            stack.bottomAnchor.constraint(equalTo: guide.bottomAnchor, constant: -PlateMeasure.gap),
            art.heightAnchor.constraint(equalTo: view.heightAnchor, multiplier: 0.34),
            proceed.heightAnchor.constraint(greaterThanOrEqualToConstant: PlateMeasure.hit),
            skip.heightAnchor.constraint(greaterThanOrEqualToConstant: PlateMeasure.hit)
        ])
        showPage()
        registerForTraitChanges([UITraitPreferredContentSizeCategory.self]) { (self: Self, _: UITraitCollection) in
            self.showPage()
        }
    }

    private func advance() {
        if index >= 2 {
            complete()
            return
        }
        index += 1
        UIView.transition(with: view, duration: PlateMotion.fade, options: [.transitionCrossDissolve, .curveEaseOut]) {
            self.showPage()
        }
    }

    private func complete() {
        proceed.isLoading = true
        skip.isEnabled = false
        Task { @MainActor in
            await session.finishOnboarding()
        }
    }

    private func showPage() {
        let copy: [(String, String, String, String)] = [
            ("bdy_Onboarding1", "One stroke for each day.", "The year matrix keeps a single mark so you can see how the days felt.", "Next"),
            ("bdy_Onboarding2", "Dip, then lay the stroke.", "Choose an ink from the tray. The stroke commits when you lift.", "Next"),
            ("bdy_Onboarding3", "Peel only today.", "A wrong lay clears the same day. Quiet streak counts the laid days you kept.", "Continue")
        ]
        let page = copy[index]
        art.image = UIImage(named: page.0)
        headline.text = page.1
        headline.font = PlateType.display()
        line.text = page.2
        line.font = PlateType.body()
        proceed.setTitle(page.3)
        pages.currentPage = index
        skip.titleLabel?.font = PlateType.body()
    }
}
