import UIKit

/// Loads one YearMatrix, then shows the gate or the canvas. Launch keys are read once.
final class PlateHostController: UIViewController, PlateObserving {
    private let session: PlateSession
    private let spinner = UIActivityIndicatorView(style: .large)
    private let status = UILabel()
    private var booted = false
    private var canvas: YearCanvasController?
    private var gate: GateController?

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
        status.text = "Opening the plate."
        status.font = PlateType.body()
        status.textColor = PlateColor.muted
        status.translatesAutoresizingMaskIntoConstraints = false
        spinner.color = PlateColor.accent
        spinner.translatesAutoresizingMaskIntoConstraints = false
        spinner.hidesWhenStopped = true
        view.addSubview(spinner)
        view.addSubview(status)
        NSLayoutConstraint.activate([
            spinner.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            spinner.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            status.topAnchor.constraint(equalTo: spinner.bottomAnchor, constant: PlateMeasure.gap),
            status.centerXAnchor.constraint(equalTo: view.centerXAnchor)
        ])
        session.observe(self)
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(150))
            if !booted {
                spinner.startAnimating()
            }
        }
        Task { @MainActor in
            await session.boot()
            booted = true
            spinner.stopAnimating()
            status.isHidden = true
        }
    }

    func plateDidChange() {
        let complete = session.matrix.plate.onboardingComplete
        if complete {
            guard canvas == nil else { return }
            remove(gate)
            gate = nil
            let canvas = YearCanvasController(session: session)
            install(canvas)
            self.canvas = canvas
            status.isHidden = true
            spinner.stopAnimating()
        } else if gate == nil {
            remove(canvas)
            canvas = nil
            let gate = GateController(session: session)
            install(gate)
            self.gate = gate
            status.isHidden = true
            spinner.stopAnimating()
        }
    }

    private func install(_ controller: UIViewController) {
        addChild(controller)
        controller.view.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(controller.view)
        NSLayoutConstraint.activate([
            controller.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            controller.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            controller.view.topAnchor.constraint(equalTo: view.topAnchor),
            controller.view.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        controller.didMove(toParent: self)
    }

    private func remove(_ controller: UIViewController?) {
        guard let controller else { return }
        controller.willMove(toParent: nil)
        controller.view.removeFromSuperview()
        controller.removeFromParent()
    }
}
