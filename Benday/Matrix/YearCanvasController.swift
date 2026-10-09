import UIKit

/// Matrix-locked home. The year stays on screen. Analytics and Settings are sheets.
final class YearCanvasController: UIViewController, UIScrollViewDelegate, PlateObserving {
    private let session: PlateSession
    private let headerTitle = UILabel()
    private let streakValue = UILabel()
    private let streakCaption = UILabel()
    private let analyticsButton = UIButton(type: .system)
    private let settingsButton = UIButton(type: .system)
    private let scroll = UIScrollView()
    private let zoomView = UIView()
    private let grid = PlateGridView()
    private var dayButtons: [UIButton] = []
    private let stage: LayStageController
    private let caption = UILabel()
    private let tray = InkTrayView()
    private let peelButton = PlateButton(kind: .destructive)
    private let gesso = GessoView()
    private let banner = UILabel()
    private let notice = UILabel()
    private lazy var stageWidthConstraint = stage.view.widthAnchor.constraint(equalToConstant: PlateMeasure.stage)
    private lazy var gridFloorConstraint: NSLayoutConstraint = {
        let constraint = scroll.heightAnchor.constraint(greaterThanOrEqualToConstant: PlateMeasure.gridFloor)
        constraint.priority = .defaultHigh
        return constraint
    }()
    private var didPlayStage = false
    private var didPresentLaunch = false
    private var gridWidth: CGFloat = 0
    private var notedDay: String?

    init(session: PlateSession) {
        self.session = session
        self.stage = LayStageController(session: session)
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        nil
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = PlateColor.background
        session.observe(self)
        headerTitle.text = "Lay today's stroke"
        headerTitle.textColor = PlateColor.ink
        headerTitle.numberOfLines = 2
        headerTitle.adjustsFontForContentSizeCategory = true
        headerTitle.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        streakCaption.text = "Quiet streak"
        streakCaption.textColor = PlateColor.muted
        streakValue.textColor = PlateColor.accent
        streakValue.adjustsFontForContentSizeCategory = true
        configureChrome(analyticsButton, title: "Analytics", symbol: "chart.bar")
        configureChrome(settingsButton, title: "Settings", symbol: "slider.horizontal.3")
        analyticsButton.addAction(UIAction { [weak self] _ in self?.presentQuiet() }, for: .touchUpInside)
        settingsButton.addAction(UIAction { [weak self] _ in self?.presentPress() }, for: .touchUpInside)
        caption.textColor = PlateColor.ink
        caption.numberOfLines = 0
        caption.adjustsFontForContentSizeCategory = true
        notice.textColor = PlateColor.muted
        notice.numberOfLines = 0
        notice.adjustsFontForContentSizeCategory = true
        banner.textColor = PlateColor.ink
        banner.numberOfLines = 0
        banner.backgroundColor = PlateColor.surface
        banner.layer.cornerRadius = PlateRadius.chip
        banner.layer.cornerCurve = .continuous
        banner.clipsToBounds = true
        banner.isHidden = true
        peelButton.setTitle("Peel today")
        peelButton.addAction(UIAction { [weak self] _ in self?.session.peelToday() }, for: .touchUpInside)
        gesso.dipButton.addAction(UIAction { [weak self] _ in self?.dipFirstInk() }, for: .touchUpInside)
        scroll.delegate = self
        scroll.minimumZoomScale = 1
        scroll.maximumZoomScale = 3
        scroll.bouncesZoom = true
        scroll.backgroundColor = PlateColor.background
        zoomView.backgroundColor = PlateColor.background
        scroll.addSubview(zoomView)
        zoomView.addSubview(grid)
        tray.onDip = { [weak self] id in
            self?.session.dip(inkID: id)
        }
        addChild(stage)
        stage.view.translatesAutoresizingMaskIntoConstraints = false
        [headerTitle, streakValue, streakCaption, analyticsButton, settingsButton, scroll, stage.view, caption, tray, peelButton, notice, banner, gesso].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview($0)
        }
        stage.didMove(toParent: self)
        let guide = view.safeAreaLayoutGuide
        NSLayoutConstraint.activate([
            headerTitle.leadingAnchor.constraint(equalTo: guide.leadingAnchor, constant: PlateMeasure.gap),
            headerTitle.topAnchor.constraint(equalTo: guide.topAnchor, constant: PlateMeasure.unit),
            headerTitle.trailingAnchor.constraint(lessThanOrEqualTo: analyticsButton.leadingAnchor, constant: -PlateMeasure.unit),
            analyticsButton.trailingAnchor.constraint(equalTo: settingsButton.leadingAnchor, constant: -PlateMeasure.unit),
            analyticsButton.centerYAnchor.constraint(equalTo: headerTitle.centerYAnchor),
            analyticsButton.heightAnchor.constraint(greaterThanOrEqualToConstant: PlateMeasure.hit),
            analyticsButton.widthAnchor.constraint(greaterThanOrEqualToConstant: PlateMeasure.hit),
            settingsButton.trailingAnchor.constraint(equalTo: guide.trailingAnchor, constant: -PlateMeasure.gap),
            settingsButton.centerYAnchor.constraint(equalTo: headerTitle.centerYAnchor),
            settingsButton.heightAnchor.constraint(greaterThanOrEqualToConstant: PlateMeasure.hit),
            settingsButton.widthAnchor.constraint(greaterThanOrEqualToConstant: PlateMeasure.hit),
            streakValue.leadingAnchor.constraint(equalTo: headerTitle.leadingAnchor),
            streakValue.topAnchor.constraint(equalTo: headerTitle.bottomAnchor),
            streakCaption.leadingAnchor.constraint(equalTo: streakValue.trailingAnchor, constant: PlateMeasure.unit),
            streakCaption.centerYAnchor.constraint(equalTo: streakValue.centerYAnchor),
            streakCaption.trailingAnchor.constraint(lessThanOrEqualTo: guide.trailingAnchor, constant: -PlateMeasure.gap),
            banner.leadingAnchor.constraint(equalTo: guide.leadingAnchor, constant: PlateMeasure.gap),
            banner.trailingAnchor.constraint(equalTo: guide.trailingAnchor, constant: -PlateMeasure.gap),
            banner.topAnchor.constraint(equalTo: streakValue.bottomAnchor, constant: PlateMeasure.unit),
            scroll.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scroll.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scroll.topAnchor.constraint(equalTo: banner.bottomAnchor, constant: PlateMeasure.unit),
            stage.view.topAnchor.constraint(equalTo: scroll.bottomAnchor, constant: PlateMeasure.gap),
            stage.view.centerXAnchor.constraint(equalTo: guide.centerXAnchor),
            stageWidthConstraint,
            stage.view.heightAnchor.constraint(equalTo: stage.view.widthAnchor),
            caption.leadingAnchor.constraint(equalTo: guide.leadingAnchor, constant: PlateMeasure.gap),
            caption.trailingAnchor.constraint(equalTo: guide.trailingAnchor, constant: -PlateMeasure.gap),
            caption.topAnchor.constraint(equalTo: stage.view.bottomAnchor, constant: PlateMeasure.unit),
            tray.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tray.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tray.topAnchor.constraint(equalTo: caption.bottomAnchor, constant: PlateMeasure.unit),
            tray.heightAnchor.constraint(equalToConstant: PlateMeasure.hit),
            notice.leadingAnchor.constraint(equalTo: guide.leadingAnchor, constant: PlateMeasure.gap),
            notice.trailingAnchor.constraint(equalTo: guide.trailingAnchor, constant: -PlateMeasure.gap),
            notice.topAnchor.constraint(equalTo: tray.bottomAnchor, constant: PlateMeasure.unit),
            peelButton.leadingAnchor.constraint(equalTo: guide.leadingAnchor, constant: PlateMeasure.gap),
            peelButton.trailingAnchor.constraint(equalTo: guide.trailingAnchor, constant: -PlateMeasure.gap),
            peelButton.topAnchor.constraint(equalTo: notice.bottomAnchor, constant: PlateMeasure.unit),
            peelButton.bottomAnchor.constraint(equalTo: guide.bottomAnchor, constant: -PlateMeasure.unit),
            gridFloorConstraint,
            gesso.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            gesso.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            gesso.topAnchor.constraint(equalTo: view.topAnchor),
            gesso.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        streakValue.setContentCompressionResistancePriority(.required, for: .horizontal)
        streakCaption.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        applyFonts()
        plateDidChange()
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(dayChanged),
            name: UIApplication.significantTimeChangeNotification,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(dayChanged),
            name: UIScene.didActivateNotification,
            object: nil
        )
        registerForTraitChanges([UITraitPreferredContentSizeCategory.self]) { (self: Self, _: UITraitCollection) in
            self.applyFonts()
        }
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    @objc private func dayChanged() {
        plateDidChange()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if !didPlayStage && !gesso.isHidden {
            didPlayStage = true
        }
        if !didPlayStage {
            didPlayStage = true
            if PlateMotion.fade > 0 {
                stage.view.transform = CGAffineTransform(scaleX: PlateMotion.playfulScale, y: PlateMotion.playfulScale)
                UIView.animate(withDuration: PlateMotion.fade, delay: 0, options: [.curveEaseOut]) {
                    self.stage.view.transform = .identity
                }
            }
        }
        presentLaunchIfNeeded()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        let width = scroll.bounds.width
        guard width > 0, abs(width - gridWidth) > 0.5 else {
            layoutGrid(width: width)
            return
        }
        gridWidth = width
        layoutGrid(width: width)
        scrollToToday()
    }

    func plateDidChange() {
        let now = Date()
        let matrix = session.matrix
        streakValue.text = PlateCount.string(matrix.quietStreak(endingAt: now))
        grid.render(matrix: matrix, now: now)
        rebuildDayButtons()
        layoutGrid(width: scroll.bounds.width)
        stage.sync(now: now)
        let key = DayKey.make(now, calendar: matrix.calendar)
        let fold = matrix.plate.cell(dayKey: key)?.fold ?? .open
        let pathBlocked = fold == .armed && !matrix.plate.bristle.pathIsEmpty
        tray.render(well: matrix.plate.well, dipped: matrix.plate.bristle.inkID, dipsEnabled: !pathBlocked)
        peelButton.isEnabled = fold == .laid
        peelButton.applyFont()
        caption.text = composedCaption(fold: fold)
        if let refusal = session.refusalLine() {
            notice.text = refusal
            notice.isHidden = false
        } else {
            notice.text = nil
            notice.isHidden = true
        }
        if let text = matrix.notice {
            banner.text = "  \(text)  "
            banner.isHidden = false
        } else {
            banner.text = nil
            banner.isHidden = true
        }
        let showGesso = matrix.showsGesso && (fold == .open)
        if gesso.isHidden == showGesso {
            UIView.transition(with: view, duration: PlateMotion.fade, options: [.transitionCrossDissolve]) {
                self.gesso.isHidden = !showGesso
            }
        }
        gesso.isHidden = !showGesso
        view.bringSubviewToFront(gesso)
    }

    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        zoomView
    }

    private func layoutGrid(width: CGFloat) {
        guard width > 0 else { return }
        let height = grid.preferredHeight(for: width)
        zoomView.frame = CGRect(x: 0, y: 0, width: width, height: height)
        grid.frame = zoomView.bounds
        scroll.contentSize = zoomView.frame.size
        for (index, button) in dayButtons.enumerated() {
            button.frame = grid.frameForDay(at: index, width: width)
        }
    }

    private func rebuildDayButtons() {
        dayButtons.forEach { $0.removeFromSuperview() }
        dayButtons = []
        let matrix = session.matrix
        for index in 0..<grid.dayCount() {
            guard let date = grid.date(at: index) else { continue }
            let key = DayKey.make(date, calendar: matrix.calendar)
            let button = UIButton(type: .custom)
            button.backgroundColor = .clear
            button.accessibilityLabel = dayLabel(date: date, key: key)
            button.addAction(UIAction { [weak self] _ in
                self?.focus(dayAt: index, date: date, key: key)
            }, for: .touchUpInside)
            zoomView.addSubview(button)
            dayButtons.append(button)
        }
    }

    private func focus(dayAt index: Int, date: Date, key: Int) {
        let width = scroll.bounds.width
        let frame = grid.frameForDay(at: index, width: width)
        scroll.scrollRectToVisible(frame.insetBy(dx: 0, dy: -PlateMeasure.gap), animated: PlateMotion.fade > 0)
        notedDay = dayLabel(date: date, key: key)
        grid.note(dayKey: key)
        let fold = session.matrix.plate.cell(dayKey: DayKey.make(Date(), calendar: session.matrix.calendar))?.fold ?? .open
        caption.text = composedCaption(fold: fold)
    }

    private func scrollToToday() {
        let now = Date()
        let key = DayKey.make(now, calendar: session.matrix.calendar)
        guard let index = (0..<grid.dayCount()).first(where: { idx in
            guard let date = grid.date(at: idx) else { return false }
            return DayKey.make(date, calendar: session.matrix.calendar) == key
        }) else { return }
        let frame = grid.frameForDay(at: index, width: scroll.bounds.width)
        scroll.scrollRectToVisible(frame, animated: false)
    }

    private func dayLabel(date: Date, key: Int) -> String {
        let day = PlateCount.string(session.matrix.calendar.component(.day, from: date))
        let month = session.matrix.calendar.monthSymbols[max(0, session.matrix.calendar.component(.month, from: date) - 1)]
        let fold = session.matrix.plate.cell(dayKey: key)?.fold ?? .open
        let state: String
        switch fold {
        case .open: state = "open"
        case .armed: state = "armed"
        case .laid: state = "laid"
        }
        return "\(month) \(day), \(state)"
    }

    private func captionLine(fold: CellFold) -> String {
        switch fold {
        case .armed:
            return "Draw in today's cell. The stroke commits when you lift."
        case .laid:
            return "Today's stroke is kept. Peel today if it went wrong."
        case .open:
            return "Dip an ink from the tray, then draw in today's cell."
        }
    }

    private func composedCaption(fold: CellFold) -> String {
        guard let notedDay else { return captionLine(fold: fold) }
        return "\(notedDay). \(captionLine(fold: fold))"
    }

    private func dipFirstInk() {
        guard let ink = session.matrix.plate.well.inks.sorted(by: { $0.slot < $1.slot }).first else { return }
        gesso.dipButton.isLoading = true
        session.dip(inkID: ink.id)
        gesso.dipButton.isLoading = false
    }

    private func presentLaunchIfNeeded() {
        guard !didPresentLaunch else { return }
        didPresentLaunch = true
        switch session.launchScreen {
        case "log", "analytics":
            presentQuiet()
        case "goals", "settings":
            presentPress()
        default:
            break
        }
    }

    private func presentQuiet() {
        let sheet = QuietSheetController(session: session)
        sheet.modalPresentationStyle = .pageSheet
        present(sheet, animated: PlateMotion.fade > 0)
    }

    private func presentPress() {
        let sheet = PressSheetController(session: session)
        sheet.modalPresentationStyle = .pageSheet
        present(sheet, animated: PlateMotion.fade > 0)
    }

    private func configureChrome(_ button: UIButton, title: String, symbol: String) {
        var config = UIButton.Configuration.plain()
        config.image = UIImage(systemName: symbol)
        config.baseForegroundColor = PlateColor.ink
        config.background.backgroundColor = PlateColor.surface
        config.background.cornerRadius = PlateRadius.chip
        config.contentInsets = NSDirectionalEdgeInsets(
            top: PlateMeasure.unit,
            leading: PlateMeasure.unit,
            bottom: PlateMeasure.unit,
            trailing: PlateMeasure.unit
        )
        button.configuration = config
        button.accessibilityLabel = title
        button.tintColor = PlateColor.ink
    }

    private func applyFonts() {
        headerTitle.font = PlateType.title()
        streakValue.font = PlateType.headline()
        streakCaption.font = PlateType.caption()
        caption.font = PlateType.body()
        notice.font = PlateType.caption()
        banner.font = PlateType.caption()
        analyticsButton.titleLabel?.font = PlateType.caption()
        settingsButton.titleLabel?.font = PlateType.caption()
        gesso.applyFonts()
        peelButton.applyFont()
    }
}
