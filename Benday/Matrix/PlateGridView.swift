import PencilKit
import UIKit

/// The one custom-rendered surface. Halftone thumbnails for laid cells live only here.
final class PlateGridView: UIView {
    private var days: [Date] = []
    private var cells: [Int: Cell] = [:]
    private var inks: [UUID: Ink] = [:]
    private var calendar = Calendar.current
    private var todayKey = 0
    private var notedKey: Int?

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = PlateColor.background
        isOpaque = true
        isUserInteractionEnabled = false
        contentMode = .redraw
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        nil
    }

    func render(matrix: YearMatrix, now: Date) {
        calendar = matrix.calendar
        todayKey = DayKey.make(now, calendar: calendar)
        let year = calendar.component(.year, from: calendar.startOfDay(for: now))
        days = dates(in: year)
        cells = Dictionary(uniqueKeysWithValues: matrix.plate.cells.map { ($0.dayKey, $0) })
        inks = Dictionary(uniqueKeysWithValues: matrix.plate.well.inks.map { ($0.id, $0) })
        setNeedsDisplay()
    }

    func note(dayKey: Int) {
        notedKey = dayKey
        setNeedsDisplay()
    }

    func preferredHeight(for width: CGFloat) -> CGFloat {
        let side = cellSide(for: width)
        let rows = rowCount()
        return side * CGFloat(rows)
    }

    func frameForDay(at index: Int, width: CGFloat) -> CGRect {
        let side = cellSide(for: width)
        let column = (leadingBlanks() + index) % 7
        let row = (leadingBlanks() + index) / 7
        return CGRect(x: CGFloat(column) * side, y: CGFloat(row) * side, width: side, height: side)
    }

    func dayCount() -> Int { days.count }

    func date(at index: Int) -> Date? {
        guard days.indices.contains(index) else { return nil }
        return days[index]
    }

    override func draw(_ rect: CGRect) {
        guard let context = UIGraphicsGetCurrentContext() else { return }
        PlateColor.background.setFill()
        context.fill(rect)
        let width = bounds.width
        for index in days.indices {
            let frame = frameForDay(at: index, width: width).insetBy(dx: PlateMeasure.unit / 4, dy: PlateMeasure.unit / 4)
            let key = DayKey.make(days[index], calendar: calendar)
            let cell = cells[key]
            let fold = cell?.fold ?? .open
            let path = UIBezierPath(roundedRect: frame, cornerRadius: min(PlateRadius.chip, frame.width / 2))
            PlateColor.surface.setFill()
            path.fill()
            if fold == .laid, let entry = cell?.entry {
                let slot = inks[entry.inkID]?.slot ?? 0
                drawHalftone(entry.stroke, color: PlateColor.well(slot), in: frame, context: context)
            } else if fold == .armed {
                PlateColor.accent.withAlphaComponent(0.18).setFill()
                path.fill()
            }
            if key == todayKey {
                PlateColor.accent.setStroke()
                path.lineWidth = PlateMeasure.line
                path.stroke()
            } else if key == notedKey {
                PlateColor.ink.setStroke()
                path.lineWidth = PlateMeasure.line
                path.stroke()
            }
        }
    }

    private func drawHalftone(_ stroke: Data, color: UIColor, in frame: CGRect, context: CGContext) {
        let drawing = try? PKDrawing(data: stroke)
        context.saveGState()
        let clip = UIBezierPath(roundedRect: frame, cornerRadius: min(PlateRadius.chip, frame.width / 2))
        clip.addClip()
        if let drawing, !drawing.bounds.isEmpty {
            let image = drawing.image(from: drawing.bounds.insetBy(dx: -8, dy: -8), scale: 2)
            image.draw(in: frame)
            context.setBlendMode(.destinationIn)
            color.setFill()
            dotField(in: frame, context: context, step: max(3, frame.width / 8))
        } else {
            color.setFill()
            let step = max(3, frame.width / 7)
            var x = frame.minX + step
            var y = frame.maxY - step
            while x < frame.maxX - 2 && y > frame.minY + 2 {
                context.fillEllipse(in: CGRect(x: x, y: y, width: step * 0.45, height: step * 0.45))
                x += step * 0.7
                y -= step * 0.45
            }
        }
        context.restoreGState()
    }

    private func dotField(in frame: CGRect, context: CGContext, step: CGFloat) {
        var y = frame.minY
        var row = 0
        while y < frame.maxY {
            var x = frame.minX + (row.isMultiple(of: 2) ? 0 : step / 2)
            while x < frame.maxX {
                context.fillEllipse(in: CGRect(x: x, y: y, width: step * 0.42, height: step * 0.42))
                x += step
            }
            y += step
            row += 1
        }
    }

    private func dates(in year: Int) -> [Date] {
        var parts = DateComponents()
        parts.calendar = calendar
        parts.year = year
        parts.month = 1
        parts.day = 1
        guard let start = calendar.date(from: parts) else { return [] }
        guard let range = calendar.range(of: .day, in: .year, for: start) else { return [] }
        return range.compactMap { offset in
            calendar.date(byAdding: .day, value: offset - 1, to: start)
        }
    }

    private func leadingBlanks() -> Int {
        guard let first = days.first else { return 0 }
        let weekday = calendar.component(.weekday, from: first)
        let firstWeekday = calendar.firstWeekday
        return (weekday - firstWeekday + 7) % 7
    }

    private func rowCount() -> Int {
        let count = leadingBlanks() + days.count
        return max(1, Int(ceil(Double(count) / 7)))
    }

    private func cellSide(for width: CGFloat) -> CGFloat {
        max(PlateMeasure.hit, width / 7)
    }
}
