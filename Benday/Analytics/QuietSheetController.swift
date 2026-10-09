import UIKit

/// Quiet streak and the year's ink mix. Stock rows, no second canvas.
final class QuietSheetController: UIViewController, UITableViewDataSource, UITableViewDelegate, PlateObserving {
    private let session: PlateSession
    private let table = UITableView(frame: .zero, style: .insetGrouped)
    private let empty = UIView()
    private let error = UIView()
    private let emptyTitle = UILabel()
    private let emptyLine = UILabel()
    private let errorTitle = UILabel()
    private let errorLine = UILabel()
    private let retry = PlateButton(kind: .primary)
    private let lay = PlateButton(kind: .primary)
    private var rows: [(name: String, count: Int)] = []
    private var streak = 0

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
        table.dataSource = self
        table.delegate = self
        table.backgroundColor = PlateColor.background
        table.translatesAutoresizingMaskIntoConstraints = false
        table.rowHeight = UITableView.automaticDimension
        table.estimatedRowHeight = PlateMeasure.hit
        view.addSubview(table)
        configureEmpty()
        configureError()
        NSLayoutConstraint.activate([
            table.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            table.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            table.topAnchor.constraint(equalTo: view.topAnchor),
            table.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            empty.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            empty.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            empty.topAnchor.constraint(equalTo: view.topAnchor),
            empty.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            error.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            error.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            error.topAnchor.constraint(equalTo: view.topAnchor),
            error.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        retry.addAction(UIAction { [weak self] _ in
            guard let self else { return }
            self.retry.isLoading = true
            Task { @MainActor in
                await self.session.reload()
                self.retry.isLoading = false
            }
        }, for: .touchUpInside)
        plateDidChange()
    }

    func plateDidChange() {
        let now = Date()
        streak = session.matrix.quietStreak(endingAt: now)
        rows = session.matrix.inkMix().map { ($0.ink.trayLabel, $0.count) }
        let laid = session.matrix.plate.cells.contains { $0.fold == .laid }
        let failed = session.matrix.notice != nil && session.matrix.plate.cells.isEmpty
        error.isHidden = !failed
        empty.isHidden = failed || laid
        table.isHidden = failed || !laid
        if let notice = session.matrix.notice, failed {
            errorLine.text = notice
        }
        table.reloadData()
    }

    func numberOfSections(in tableView: UITableView) -> Int { 2 }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        section == 0 ? 1 : rows.count
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        section == 0 ? "Quiet streak" : "Ink mix"
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .value1, reuseIdentifier: nil)
        cell.backgroundColor = PlateColor.surface
        cell.textLabel?.font = PlateType.body()
        cell.textLabel?.textColor = PlateColor.ink
        cell.textLabel?.numberOfLines = 2
        cell.detailTextLabel?.font = PlateType.headline()
        cell.detailTextLabel?.textColor = PlateColor.accent
        if indexPath.section == 0 {
            cell.textLabel?.text = "Consecutive laid days"
            cell.detailTextLabel?.text = PlateCount.string(streak)
            cell.selectionStyle = .none
        } else {
            let row = rows[indexPath.row]
            cell.textLabel?.text = row.name
            cell.detailTextLabel?.text = PlateCount.string(row.count)
            cell.selectionStyle = .none
        }
        return cell
    }

    private func configureEmpty() {
        empty.backgroundColor = PlateColor.background
        empty.translatesAutoresizingMaskIntoConstraints = false
        let art = UIImageView(image: UIImage(named: "bdy_EmptyList"))
        art.contentMode = .scaleAspectFit
        art.isAccessibilityElement = false
        emptyTitle.text = "No ink has been laid."
        emptyTitle.textColor = PlateColor.ink
        emptyTitle.numberOfLines = 2
        emptyTitle.font = PlateType.title()
        emptyLine.text = "Dip an ink and lay today's stroke."
        emptyLine.textColor = PlateColor.muted
        emptyLine.numberOfLines = 0
        emptyLine.font = PlateType.body()
        lay.setTitle("Lay today's stroke")
        lay.addAction(UIAction { [weak self] _ in
            self?.dismiss(animated: PlateMotion.fade > 0)
        }, for: .touchUpInside)
        let stack = UIStackView(arrangedSubviews: [art, emptyTitle, emptyLine, UIView(), lay])
        stack.axis = .vertical
        stack.spacing = PlateMeasure.gap
        stack.translatesAutoresizingMaskIntoConstraints = false
        empty.addSubview(stack)
        view.addSubview(empty)
        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: empty.safeAreaLayoutGuide.leadingAnchor, constant: PlateMeasure.gap),
            stack.trailingAnchor.constraint(equalTo: empty.safeAreaLayoutGuide.trailingAnchor, constant: -PlateMeasure.gap),
            stack.topAnchor.constraint(equalTo: empty.safeAreaLayoutGuide.topAnchor, constant: PlateMeasure.pad),
            stack.bottomAnchor.constraint(equalTo: empty.safeAreaLayoutGuide.bottomAnchor, constant: -PlateMeasure.gap),
            art.heightAnchor.constraint(equalTo: empty.heightAnchor, multiplier: 0.36),
            lay.heightAnchor.constraint(greaterThanOrEqualToConstant: PlateMeasure.hit)
        ])
    }

    private func configureError() {
        error.backgroundColor = PlateColor.background
        error.translatesAutoresizingMaskIntoConstraints = false
        errorTitle.text = "The plate could not be read."
        errorTitle.textColor = PlateColor.ink
        errorTitle.numberOfLines = 2
        errorTitle.font = PlateType.title()
        errorLine.textColor = PlateColor.muted
        errorLine.numberOfLines = 0
        errorLine.font = PlateType.body()
        retry.setTitle("Try again")
        let stack = UIStackView(arrangedSubviews: [errorTitle, errorLine, retry])
        stack.axis = .vertical
        stack.spacing = PlateMeasure.gap
        stack.translatesAutoresizingMaskIntoConstraints = false
        error.addSubview(stack)
        view.addSubview(error)
        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: error.safeAreaLayoutGuide.leadingAnchor, constant: PlateMeasure.gap),
            stack.trailingAnchor.constraint(equalTo: error.safeAreaLayoutGuide.trailingAnchor, constant: -PlateMeasure.gap),
            stack.bottomAnchor.constraint(equalTo: error.safeAreaLayoutGuide.bottomAnchor, constant: -PlateMeasure.gap),
            stack.topAnchor.constraint(greaterThanOrEqualTo: error.safeAreaLayoutGuide.topAnchor, constant: PlateMeasure.pad)
        ])
    }
}
