import Foundation

/// The single model every screen observes.
/// Dip arms today, pen-up lays one MoodEntry, Peel returns today to Open.
@MainActor
final class YearMatrix {
    private(set) var plate: Plate
    private(set) var notice: String?
    private let store: PlateStore
    private nonisolated(unsafe) var saveTask: Task<Void, Never>?
    private var revision = 0
    let calendar: Calendar

    init(plate: Plate = .fresh(), store: PlateStore, calendar: Calendar = .current) {
        self.plate = plate
        self.store = store
        self.calendar = calendar
    }

    deinit {
        saveTask?.cancel()
    }

    var showsGesso: Bool { plate.showsGesso }

    func cell(on date: Date) -> Cell? {
        plate.cell(dayKey: DayKey.make(date, calendar: calendar))
    }

    func loadFromStore() async {
        let loaded = await store.load()
        switch loaded {
        case .ready(let plate):
            self.plate = plate
            notice = nil
        case .restored(let plate):
            self.plate = plate
            notice = "A backup plate was opened."
        case .unreadable:
            self.plate = Plate.fresh()
            notice = "The plate could not be read."
        }
    }

    /// Simulator only, once, behind `bdy.demo.v1`. Yesterday is laid. Today is armed with the bristle dipped.
    func applySimulatorSeedIfNeeded(now: Date) async {
        #if targetEnvironment(simulator)
        let already = await store.demoAlreadyApplied()
        guard !already else { return }
        guard notice == nil else { return }
        guard plate.cells.isEmpty else { return }
        let laid = layYesterdayForDemo(now: now)
        guard laid else { return }
        await store.markDemoApplied()
        await persist(immediate: true)
        #else
        _ = now
        #endif
    }

    func dip(inkID: UUID, now: Date) throws {
        guard plate.well.ink(id: inkID) != nil else { throw BristleRefusal.unknownInk }
        let key = DayKey.make(now, calendar: calendar)
        var cell = plate.cell(dayKey: key) ?? Cell.open(dayKey: key)
        if cell.fold == .armed, !plate.bristle.pathIsEmpty {
            throw BristleRefusal.dipOverLiveStroke
        }
        plate.bristle.inkID = inkID
        if cell.entry == nil, cell.fold == .open {
            cell.fold = .armed
            upsert(cell)
        }
        scheduleSave(immediate: false)
    }

    func sketch(stroke: Data, now: Date) throws {
        if stroke.isEmpty { throw BristleRefusal.penUpWithoutStroke }
        let key = DayKey.make(now, calendar: calendar)
        guard let cell = plate.cell(dayKey: key) else { throw BristleRefusal.sketchWhileOpen }
        switch cell.fold {
        case .laid:
            throw BristleRefusal.sketchOnLaid
        case .open:
            throw BristleRefusal.sketchWhileOpen
        case .armed:
            guard plate.bristle.isDipped else { throw BristleRefusal.sketchWhileOpen }
            plate.bristle.liveStroke = stroke
            scheduleSave(immediate: false)
        }
    }

    /// Pen-up is the persisted verb. It writes one LayMark and one MoodEntry, then folds Armed to Laid.
    func penUp(now: Date) throws {
        let key = DayKey.make(now, calendar: calendar)
        guard var cell = plate.cell(dayKey: key), cell.fold == .armed else {
            throw BristleRefusal.penUpWhileNotArmed
        }
        guard let inkID = plate.bristle.inkID else { throw BristleRefusal.penUpWhileNotArmed }
        guard !plate.bristle.liveStroke.isEmpty else { throw BristleRefusal.penUpWithoutStroke }
        if plate.cell(dayKey: key)?.entry != nil {
            throw BristleRefusal.sketchOnLaid
        }
        let entry = MoodEntry(dayKey: key, inkID: inkID, stroke: plate.bristle.liveStroke)
        cell.entry = entry
        cell.fold = .laid
        upsert(entryReplacing: cell)
        plate.layMarks.removeAll { $0.dayKey == key }
        plate.layMarks.append(LayMark(id: UUID(), dayKey: key, inkID: inkID, laidAt: now))
        plate.bristle.liveStroke = Data()
        scheduleSave(immediate: false)
    }

    /// Clears today's MoodEntry and LayMark. Flush is immediate.
    func peelToday(now: Date) throws {
        let key = DayKey.make(now, calendar: calendar)
        guard var cell = plate.cell(dayKey: key), cell.fold == .laid, cell.entry != nil else {
            throw BristleRefusal.peelWhenNotLaid
        }
        cell.entry = nil
        cell.fold = .open
        upsert(entryReplacing: cell)
        plate.layMarks.removeAll { $0.dayKey == key }
        plate.peelMarks.append(PeelMark(id: UUID(), dayKey: key, peeledAt: now))
        plate.bristle.liveStroke = Data()
        scheduleSave(immediate: true)
    }

    func quietStreak(endingAt now: Date) -> Int {
        let today = DayKey.make(now, calendar: calendar)
        guard let yesterday = DayKey.byAddingDays(-1, to: today, calendar: calendar) else { return 0 }
        let anchor: Int
        if plate.cell(dayKey: today)?.fold == .laid {
            anchor = today
        } else if plate.cell(dayKey: yesterday)?.fold == .laid {
            anchor = yesterday
        } else {
            return 0
        }
        var count = 0
        var cursor: Int? = anchor
        while let key = cursor, plate.cell(dayKey: key)?.fold == .laid {
            count += 1
            cursor = DayKey.byAddingDays(-1, to: key, calendar: calendar)
        }
        return count
    }

    /// Counts laid cells per ink. Computed, never stored.
    func inkMix() -> [(ink: Ink, count: Int)] {
        plate.well.inks.map { ink in
            let count = plate.cells.filter { $0.fold == .laid && $0.entry?.inkID == ink.id }.count
            return (ink, count)
        }
    }

    func finishOnboarding() async {
        plate.onboardingComplete = true
        await persist(immediate: true)
    }

    func reopenOnboarding() async {
        plate.onboardingComplete = false
        await persist(immediate: true)
    }

    func renameInk(id: UUID, trayLabel: String) {
        let trimmed = trayLabel.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        guard let index = plate.well.inks.firstIndex(where: { $0.id == id }) else { return }
        plate.well.inks[index].trayLabel = String(trimmed.prefix(32))
        scheduleSave(immediate: false)
    }

    func resetAllData() async {
        saveTask?.cancel()
        saveTask = nil
        plate = Plate.fresh()
        notice = nil
        await store.resetAllData()
    }

    func flushForSceneExit() async {
        await persist(immediate: true)
    }

    func flush() async {
        await persist(immediate: true)
    }

    private func layYesterdayForDemo(now: Date) -> Bool {
        let today = DayKey.make(now, calendar: calendar)
        guard let yesterday = DayKey.byAddingDays(-1, to: today, calendar: calendar) else { return false }
        guard let ink = plate.well.inks.first else { return false }
        let stroke = Data([0x42, 0x44, 0x59, 0x01])
        let entry = MoodEntry(dayKey: yesterday, inkID: ink.id, stroke: stroke)
        let laid = Cell(dayKey: yesterday, fold: .laid, entry: entry)
        let armed = Cell(dayKey: today, fold: .armed, entry: nil)
        plate.cells = [laid, armed]
        plate.bristle = Bristle(inkID: ink.id, liveStroke: Data())
        plate.layMarks = [LayMark(id: UUID(), dayKey: yesterday, inkID: ink.id, laidAt: now)]
        plate.onboardingComplete = true
        return true
    }

    private func upsert(_ cell: Cell) {
        if let index = plate.cells.firstIndex(where: { $0.dayKey == cell.dayKey }) {
            plate.cells[index] = cell
        } else {
            plate.cells.append(cell)
        }
    }

    private func upsert(entryReplacing cell: Cell) {
        plate.cells.removeAll { $0.dayKey == cell.dayKey }
        plate.cells.append(cell)
    }

    private func scheduleSave(immediate: Bool) {
        revision += 1
        let revision = revision
        let snapshot = plate
        saveTask?.cancel()
        saveTask = Task { [store] in
            await store.accept(snapshot, revision: revision, immediate: immediate)
        }
    }

    private func persist(immediate: Bool) async {
        revision += 1
        let revision = revision
        let snapshot = plate
        saveTask?.cancel()
        saveTask = nil
        await store.accept(snapshot, revision: revision, immediate: immediate)
        await store.flush()
    }
}
