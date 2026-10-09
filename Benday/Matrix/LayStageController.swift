import PencilKit
import UIKit

/// Twist surface on the home plate. One PencilKit canvas for today's armed cell.
final class LayStageController: UIViewController, PKCanvasViewDelegate {
    let canvas = PKCanvasView()
    private let material = UIVisualEffectView(effect: UIBlurEffect(style: .systemChromeMaterial))
    private let session: PlateSession
    private var suppress = false
    private let haptic = UIImpactFeedbackGenerator(style: .medium)

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
        view.backgroundColor = .clear
        material.layer.cornerRadius = PlateRadius.card
        material.layer.cornerCurve = .continuous
        material.clipsToBounds = true
        material.translatesAutoresizingMaskIntoConstraints = false
        canvas.translatesAutoresizingMaskIntoConstraints = false
        canvas.delegate = self
        canvas.drawingPolicy = .anyInput
        canvas.backgroundColor = PlateColor.surface
        canvas.isOpaque = true
        canvas.tool = PKInkingTool(.pen, color: PlateColor.ink, width: PlateMeasure.nib)
        canvas.drawing = PKDrawing()
        material.contentView.addSubview(canvas)
        view.addSubview(material)
        NSLayoutConstraint.activate([
            material.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            material.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            material.topAnchor.constraint(equalTo: view.topAnchor),
            material.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            canvas.leadingAnchor.constraint(equalTo: material.contentView.leadingAnchor),
            canvas.trailingAnchor.constraint(equalTo: material.contentView.trailingAnchor),
            canvas.topAnchor.constraint(equalTo: material.contentView.topAnchor),
            canvas.bottomAnchor.constraint(equalTo: material.contentView.bottomAnchor)
        ])
        haptic.prepare()
    }

    func sync(now: Date) {
        let matrix = session.matrix
        let key = DayKey.make(now, calendar: matrix.calendar)
        let cell = matrix.plate.cell(dayKey: key)
        let armed = cell?.fold == .armed
        canvas.isUserInteractionEnabled = armed
        let inkID = matrix.plate.bristle.inkID
        let slot = matrix.plate.well.inks.first { $0.id == inkID }?.slot ?? 0
        let color = inkID == nil ? PlateColor.muted : PlateColor.well(slot)
        canvas.tool = PKInkingTool(.pen, color: color, width: PlateMeasure.nib)
        canvas.accessibilityLabel = "Today's cell"
        if armed {
            canvas.accessibilityHint = "Draw one stroke. It commits when you lift."
        } else if cell?.fold == .laid {
            canvas.accessibilityHint = "Today is laid. Peel to draw again."
        } else {
            canvas.accessibilityHint = "Dip an ink before drawing."
        }
        guard !suppress else { return }
        let stored: Data
        if cell?.fold == .laid {
            stored = cell?.entry?.stroke ?? Data()
        } else if armed {
            stored = matrix.plate.bristle.liveStroke
        } else {
            stored = Data()
        }
        if stored.isEmpty {
            if !canvas.drawing.strokes.isEmpty {
                suppress = true
                canvas.drawing = PKDrawing()
                suppress = false
            }
            return
        }
        if let drawing = try? PKDrawing(data: stored), canvas.drawing.dataRepresentation() != stored {
            suppress = true
            canvas.drawing = drawing
            suppress = false
        }
    }

    func canvasViewDrawingDidChange(_ canvasView: PKCanvasView) {
        guard !suppress else { return }
        let data = canvasView.drawing.dataRepresentation()
        guard !data.isEmpty, !canvasView.drawing.strokes.isEmpty else { return }
        session.sketch(stroke: data)
    }

    func canvasViewDidEndUsingTool(_ canvasView: PKCanvasView) {
        guard !suppress else { return }
        var drawing = canvasView.drawing
        if drawing.strokes.count > 1, let last = drawing.strokes.last {
            drawing = PKDrawing(strokes: [last])
            suppress = true
            canvasView.drawing = drawing
            suppress = false
        }
        let data = drawing.dataRepresentation()
        guard !data.isEmpty else { return }
        session.sketch(stroke: data)
        if session.penUp() {
            haptic.impactOccurred()
            haptic.prepare()
        }
    }
}
