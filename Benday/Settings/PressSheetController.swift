import UIKit

/// Tray ink names, export, a confirmed plate reset, and the contact link.
final class PressSheetController: UIViewController, PlateObserving {
    private let session: PlateSession
    private let scroll = UIScrollView()
    private let stack = UIStackView()
    private let empty = UIView()
    private let error = UILabel()
    private let retry = PlateButton(kind: .primary)
    private var retryExport = false
    private var inks: [Ink] = []

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
        session.observe(self)
        scroll.translatesAutoresizingMaskIntoConstraints = false
        scroll.alwaysBounceVertical = true
        scroll.keyboardDismissMode = .onDrag
        stack.axis = .vertical
        stack.spacing = PlateMeasure.gap
        stack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scroll)
        scroll.addSubview(stack)
        configureEmpty()
        error.numberOfLines = 0
        error.textColor = PlateColor.ink
        error.font = PlateType.body()
        error.translatesAutoresizingMaskIntoConstraints = false
        retry.setTitle("Try again")
        retry.translatesAutoresizingMaskIntoConstraints = false
        retry.addAction(UIAction { [weak self] _ in
            self?.retryFailure()
        }, for: .touchUpInside)
        view.addSubview(error)
        view.addSubview(retry)
        NSLayoutConstraint.activate([
            scroll.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scroll.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scroll.topAnchor.constraint(equalTo: view.topAnchor),
            scroll.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            stack.leadingAnchor.constraint(equalTo: scroll.contentLayoutGuide.leadingAnchor, constant: PlateMeasure.gap),
            stack.trailingAnchor.constraint(equalTo: scroll.contentLayoutGuide.trailingAnchor, constant: -PlateMeasure.gap),
            stack.topAnchor.constraint(equalTo: scroll.contentLayoutGuide.topAnchor, constant: PlateMeasure.pad),
            stack.bottomAnchor.constraint(equalTo: scroll.contentLayoutGuide.bottomAnchor, constant: -PlateMeasure.gap),
            stack.widthAnchor.constraint(equalTo: scroll.frameLayoutGuide.widthAnchor, constant: -PlateMeasure.gap * 2),
            empty.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            empty.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            empty.topAnchor.constraint(equalTo: view.topAnchor),
            empty.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            error.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: PlateMeasure.gap),
            error.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -PlateMeasure.gap),
            error.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: PlateMeasure.gap),
            retry.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: PlateMeasure.gap),
            retry.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -PlateMeasure.gap),
            retry.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -PlateMeasure.gap)
        ])
        plateDidChange()
    }

    func plateDidChange() {
        inks = session.matrix.plate.well.inks.sorted { $0.slot < $1.slot }
        let failed = session.matrix.notice != nil && session.matrix.plate.cells.isEmpty && !session.matrix.plate.onboardingComplete
        if !retryExport {
            error.text = session.matrix.notice
            error.isHidden = !failed
            retry.isHidden = !failed
        }
        empty.isHidden = failed || !inks.isEmpty || retryExport
        scroll.isHidden = failed || inks.isEmpty || retryExport
        rebuild()
    }

    private func rebuild() {
        stack.arrangedSubviews.forEach { view in
            stack.removeArrangedSubview(view)
            view.removeFromSuperview()
        }
        let title = UILabel()
        title.text = "Tray ink names"
        title.font = PlateType.title()
        title.textColor = PlateColor.ink
        title.numberOfLines = 0
        let line = UILabel()
        line.text = "These names sit on the ink tray under the year. Tap one to rename it."
        line.font = PlateType.body()
        line.textColor = PlateColor.muted
        line.numberOfLines = 0
        stack.addArrangedSubview(title)
        stack.addArrangedSubview(line)

        for ink in inks {
            stack.addArrangedSubview(inkButton(ink))
        }

        let export = PlateButton(kind: .primary)
        export.setTitle("Export plate")
        export.addAction(UIAction { [weak self] _ in
            self?.exportPlate()
        }, for: .touchUpInside)
        let reset = PlateButton(kind: .destructive)
        reset.setTitle("Reset plate")
        reset.addAction(UIAction { [weak self] _ in
            self?.confirmReset()
        }, for: .touchUpInside)
        let contact = PlateButton(kind: .primary)
        contact.setTitle("Contact Benday")
        contact.addAction(UIAction { [weak self] _ in
            self?.openContact()
        }, for: .touchUpInside)
        stack.addArrangedSubview(export)
        stack.addArrangedSubview(reset)
        stack.addArrangedSubview(contact)
    }

    private func inkButton(_ ink: Ink) -> UIButton {
        let button = UIButton(type: .custom)
        button.backgroundColor = PlateColor.surface
        button.layer.cornerRadius = PlateRadius.card
        button.layer.cornerCurve = .continuous
        button.clipsToBounds = true
        button.accessibilityLabel = "Rename tray ink \(ink.trayLabel)"
        button.addAction(UIAction { [weak self] _ in
            self?.rename(ink)
        }, for: .touchUpInside)

        let swatch = UIView()
        swatch.backgroundColor = PlateColor.well(ink.slot)
        swatch.layer.cornerRadius = PlateRadius.chip
        swatch.isUserInteractionEnabled = false
        swatch.translatesAutoresizingMaskIntoConstraints = false

        let name = UILabel()
        name.text = ink.trayLabel
        name.font = PlateType.headline()
        name.textColor = PlateColor.ink
        name.isUserInteractionEnabled = false

        let hint = UILabel()
        hint.text = "Rename this ink"
        hint.font = PlateType.caption()
        hint.textColor = PlateColor.accent
        hint.isUserInteractionEnabled = false

        let words = UIStackView(arrangedSubviews: [name, hint])
        words.axis = .vertical
        words.spacing = 2
        words.isUserInteractionEnabled = false
        words.translatesAutoresizingMaskIntoConstraints = false

        button.addSubview(swatch)
        button.addSubview(words)
        NSLayoutConstraint.activate([
            button.heightAnchor.constraint(greaterThanOrEqualToConstant: PlateMeasure.hit),
            swatch.leadingAnchor.constraint(equalTo: button.leadingAnchor, constant: PlateMeasure.gap),
            swatch.centerYAnchor.constraint(equalTo: button.centerYAnchor),
            swatch.widthAnchor.constraint(equalToConstant: PlateMeasure.hit),
            swatch.heightAnchor.constraint(equalToConstant: PlateMeasure.hit - PlateMeasure.unit),
            words.leadingAnchor.constraint(equalTo: swatch.trailingAnchor, constant: PlateMeasure.gap),
            words.trailingAnchor.constraint(equalTo: button.trailingAnchor, constant: -PlateMeasure.gap),
            words.topAnchor.constraint(equalTo: button.topAnchor, constant: PlateMeasure.unit),
            words.bottomAnchor.constraint(equalTo: button.bottomAnchor, constant: -PlateMeasure.unit)
        ])
        return button
    }

    private func rename(_ ink: Ink) {
        let alert = UIAlertController(
            title: "Rename \(ink.trayLabel)",
            message: "This word is the name on that tray ink.",
            preferredStyle: .alert
        )
        alert.addTextField { field in
            field.text = ink.trayLabel
            field.font = PlateType.body()
            field.clearButtonMode = .whileEditing
            field.autocapitalizationType = .words
        }
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Save name", style: .default) { [weak self] _ in
            guard let self else { return }
            self.session.renameInk(id: ink.id, trayLabel: alert.textFields?.first?.text ?? "")
        })
        present(alert, animated: PlateMotion.fade > 0)
    }

    private func exportPlate() {
        let plate = session.matrix.plate
        Task { @MainActor in
            let result = await Task.detached(priority: .userInitiated) { () -> Result<URL, Error> in
                let encoder = JSONEncoder()
                encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
                encoder.dateEncodingStrategy = .iso8601
                do {
                    let data = try encoder.encode(plate)
                    let url = FileManager.default.temporaryDirectory.appendingPathComponent("benday-plate.json")
                    try data.write(to: url, options: .atomic)
                    return .success(url)
                } catch {
                    return .failure(error)
                }
            }.value
            switch result {
            case .success(let url):
                self.retryExport = false
                self.error.isHidden = true
                self.retry.isHidden = true
                self.scroll.isHidden = false
                let activity = UIActivityViewController(activityItems: [url], applicationActivities: nil)
                activity.popoverPresentationController?.sourceView = self.view
                self.present(activity, animated: PlateMotion.fade > 0)
            case .failure:
                self.retryExport = true
                self.error.text = "The plate could not be exported. Try again."
                self.error.isHidden = false
                self.retry.isHidden = false
                self.scroll.isHidden = true
            }
        }
    }

    private func retryFailure() {
        retry.isLoading = true
        if retryExport {
            retryExport = false
            exportPlate()
            retry.isLoading = false
            return
        }
        Task { @MainActor in
            await session.reload()
            retry.isLoading = false
        }
    }

    private func configureEmpty() {
        empty.backgroundColor = PlateColor.background
        empty.translatesAutoresizingMaskIntoConstraints = false
        let art = UIImageView(image: UIImage(named: "bdy_EmptyList"))
        art.contentMode = .scaleAspectFit
        art.isAccessibilityElement = false
        let title = UILabel()
        title.text = "The tray has no inks."
        title.textColor = PlateColor.ink
        title.font = PlateType.title()
        title.numberOfLines = 2
        let line = UILabel()
        line.text = "Return to the year and dip a well."
        line.textColor = PlateColor.muted
        line.font = PlateType.body()
        line.numberOfLines = 0
        let back = PlateButton(kind: .primary)
        back.setTitle("Back to the year")
        back.addAction(UIAction { [weak self] _ in
            self?.dismiss(animated: PlateMotion.fade > 0)
        }, for: .touchUpInside)
        let column = UIStackView(arrangedSubviews: [art, title, line, UIView(), back])
        column.axis = .vertical
        column.spacing = PlateMeasure.gap
        column.translatesAutoresizingMaskIntoConstraints = false
        empty.addSubview(column)
        view.addSubview(empty)
        NSLayoutConstraint.activate([
            column.leadingAnchor.constraint(equalTo: empty.safeAreaLayoutGuide.leadingAnchor, constant: PlateMeasure.gap),
            column.trailingAnchor.constraint(equalTo: empty.safeAreaLayoutGuide.trailingAnchor, constant: -PlateMeasure.gap),
            column.topAnchor.constraint(equalTo: empty.safeAreaLayoutGuide.topAnchor, constant: PlateMeasure.pad),
            column.bottomAnchor.constraint(equalTo: empty.safeAreaLayoutGuide.bottomAnchor, constant: -PlateMeasure.gap),
            art.heightAnchor.constraint(equalTo: empty.heightAnchor, multiplier: 0.36),
            back.heightAnchor.constraint(greaterThanOrEqualToConstant: PlateMeasure.hit)
        ])
    }

    private func openContact() {
        guard let url = URL(string: "https://benday-matrix.pro/contact-us") else { return }
        UIApplication.shared.open(url)
    }

    private func confirmReset() {
        let alert = UIAlertController(
            title: "Reset the Benday plate?",
            message: "This wipe removes every laid day on the plate.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Reset plate", style: .destructive) { [weak self] _ in
            guard let self else { return }
            Task { @MainActor in
                await self.session.resetAllData()
                self.dismiss(animated: PlateMotion.fade > 0)
            }
        })
        present(alert, animated: PlateMotion.fade > 0)
    }
}
