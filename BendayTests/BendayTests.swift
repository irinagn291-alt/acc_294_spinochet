import XCTest
@testable import Benday

@MainActor
final class BendayTests: XCTestCase {
    private var suiteName: String?
    private var directory: URL?

    override func tearDown() async throws {
        if let suiteName, let defaults = UserDefaults(suiteName: suiteName) {
            defaults.removePersistentDomain(forName: suiteName)
        }
        if let directory {
            try? FileManager.default.removeItem(at: directory)
        }
        suiteName = nil
        directory = nil
    }

    func testReviewLaunchParsesScreenArgument() {
        XCTAssertEqual(ReviewLaunch.screen(from: ["Benday", "-ReviewScreen", "today"]), "today")
        XCTAssertEqual(ReviewLaunch.screen(from: ["Benday", "-ReviewScreen", "log"]), "log")
        XCTAssertEqual(ReviewLaunch.screen(from: ["Benday", "-ReviewScreen", "goals"]), "goals")
        XCTAssertNil(ReviewLaunch.screen(from: ["Benday"]))
        XCTAssertNil(ReviewLaunch.screen(from: ["Benday", "-ReviewScreen"]))
    }

    func testOneMoodEntryPerDay() async throws {
        let matrix = makeMatrix()
        let now = sampleNow()
        let ink = try XCTUnwrap(matrix.plate.well.inks.first).id
        try matrix.dip(inkID: ink, now: now)
        try matrix.sketch(stroke: Data([1, 2, 3]), now: now)
        try matrix.penUp(now: now)
        XCTAssertThrowsError(try matrix.penUp(now: now))
        let key = DayKey.make(now, calendar: matrix.calendar)
        let start = matrix.calendar.startOfDay(for: now)
        XCTAssertEqual(key, DayKey.make(start, calendar: matrix.calendar))
        let matches = matrix.plate.cells.filter { $0.dayKey == key && $0.entry != nil }
        XCTAssertEqual(matches.count, 1)
        XCTAssertEqual(matrix.plate.layMarks.filter { $0.dayKey == key }.count, 1)
    }

    func testQuietStreakEndsTodayOrYesterdayAndGapRestarts() async throws {
        let matrix = makeMatrix()
        let now = sampleNow()
        let ink = try XCTUnwrap(matrix.plate.well.inks.first).id
        try lay(daysAgo: 1, matrix: matrix, now: now, ink: ink)
        try lay(daysAgo: 2, matrix: matrix, now: now, ink: ink)
        XCTAssertEqual(matrix.quietStreak(endingAt: now), 2)
        try lay(daysAgo: 0, matrix: matrix, now: now, ink: ink)
        XCTAssertEqual(matrix.quietStreak(endingAt: now), 3)

        let gapped = makeMatrix()
        try lay(daysAgo: 0, matrix: gapped, now: now, ink: ink)
        try lay(daysAgo: 2, matrix: gapped, now: now, ink: ink)
        XCTAssertEqual(gapped.quietStreak(endingAt: now), 1)
        XCTAssertEqual(makeMatrix().quietStreak(endingAt: now), 0)
    }

    func testSketchOnLaidAndDipOverLiveStrokeAreRefused() async throws {
        let matrix = makeMatrix()
        let now = sampleNow()
        let inks = matrix.plate.well.inks
        let first = try XCTUnwrap(inks.first).id
        let second = try XCTUnwrap(inks.dropFirst().first).id
        try matrix.dip(inkID: first, now: now)
        try matrix.sketch(stroke: Data([4, 5]), now: now)
        XCTAssertThrowsError(try matrix.dip(inkID: second, now: now)) { error in
            XCTAssertEqual(error as? BristleRefusal, .dipOverLiveStroke)
        }
        try matrix.penUp(now: now)
        XCTAssertThrowsError(try matrix.sketch(stroke: Data([6]), now: now)) { error in
            XCTAssertEqual(error as? BristleRefusal, .sketchOnLaid)
        }
    }

    func testPrimaryVerbEmptyPopulatedAndInvalid() async throws {
        let matrix = makeMatrix()
        let now = sampleNow()
        XCTAssertTrue(matrix.showsGesso)
        XCTAssertThrowsError(try matrix.penUp(now: now)) { error in
            XCTAssertEqual(error as? BristleRefusal, .penUpWhileNotArmed)
        }
        XCTAssertThrowsError(try matrix.sketch(stroke: Data([1]), now: now)) { error in
            XCTAssertEqual(error as? BristleRefusal, .sketchWhileOpen)
        }
        let ink = try XCTUnwrap(matrix.plate.well.inks.first).id
        try matrix.dip(inkID: ink, now: now)
        XCTAssertThrowsError(try matrix.penUp(now: now)) { error in
            XCTAssertEqual(error as? BristleRefusal, .penUpWithoutStroke)
        }
        XCTAssertThrowsError(try matrix.sketch(stroke: Data(), now: now)) { error in
            XCTAssertEqual(error as? BristleRefusal, .penUpWithoutStroke)
        }
        XCTAssertThrowsError(try matrix.sketch(stroke: Data(), now: now))
        try matrix.sketch(stroke: Data([8, 8]), now: now)
        try matrix.penUp(now: now)
        let key = DayKey.make(now, calendar: matrix.calendar)
        XCTAssertEqual(matrix.plate.cell(dayKey: key)?.fold, .laid)
        XCTAssertFalse(matrix.showsGesso)
        XCTAssertThrowsError(try matrix.dip(inkID: UUID(), now: now)) { error in
            XCTAssertEqual(error as? BristleRefusal, .unknownInk)
        }
    }

    func testBristleLayFoldArmsSketchesLaysAndPeelsOnlyToday() async throws {
        let matrix = makeMatrix()
        let now = sampleNow()
        let ink = try XCTUnwrap(matrix.plate.well.inks.first).id
        let today = DayKey.make(now, calendar: matrix.calendar)
        let yesterday = try XCTUnwrap(DayKey.byAddingDays(-1, to: today, calendar: matrix.calendar))
        XCTAssertEqual(matrix.plate.cell(dayKey: today)?.fold, nil)
        try matrix.dip(inkID: ink, now: now)
        XCTAssertEqual(matrix.plate.cell(dayKey: today)?.fold, .armed)
        XCTAssertEqual(matrix.plate.bristle.inkID, ink)
        try matrix.sketch(stroke: Data([3]), now: now)
        try matrix.penUp(now: now)
        XCTAssertEqual(matrix.plate.cell(dayKey: today)?.fold, .laid)
        XCTAssertEqual(matrix.plate.cell(dayKey: today)?.entry?.inkID, ink)
        XCTAssertTrue(matrix.plate.bristle.pathIsEmpty)

        try lay(daysAgo: 1, matrix: matrix, now: now, ink: ink)
        try matrix.peelToday(now: now)
        XCTAssertEqual(matrix.plate.cell(dayKey: today)?.fold, .open)
        XCTAssertNil(matrix.plate.cell(dayKey: today)?.entry)
        XCTAssertEqual(matrix.plate.cell(dayKey: yesterday)?.fold, .laid)
        XCTAssertEqual(matrix.plate.peelMarks.map(\.dayKey), [today])
        XCTAssertFalse(matrix.plate.layMarks.contains { $0.dayKey == today })
    }

    func testPersistenceRoundTrip() async throws {
        let matrix = makeMatrix()
        let now = sampleNow()
        let ink = try XCTUnwrap(matrix.plate.well.inks.first).id
        try matrix.dip(inkID: ink, now: now)
        try matrix.sketch(stroke: Data([7, 7, 7]), now: now)
        try matrix.penUp(now: now)
        await matrix.flush()
        let reloaded = YearMatrix(store: matrixStore(), calendar: matrix.calendar)
        await reloaded.loadFromStore()
        let key = DayKey.make(now, calendar: matrix.calendar)
        XCTAssertEqual(reloaded.plate.cell(dayKey: key)?.entry?.stroke, Data([7, 7, 7]))
        XCTAssertEqual(reloaded.plate.cell(dayKey: key)?.fold, .laid)
        XCTAssertEqual(reloaded.plate.schemaVersion, 1)
    }

    func testCorruptPlateFallsBackToBackupThenEmptyNotice() async throws {
        let defaults = makeDefaults()
        let directory = makeDirectory()
        let suite = try XCTUnwrap(suiteName)
        let store = PlateStore(suiteName: suite, directory: directory, debounce: .milliseconds(20))
        let calendar = fixedCalendar()
        var plate = Plate.fresh()
        plate.onboardingComplete = true
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let good = try encoder.encode(plate)
        defaults.set(good, forKey: PlateStore.backupKey)
        defaults.set(Data("not-json".utf8), forKey: PlateStore.plateKey)
        let restored = YearMatrix(store: store, calendar: calendar)
        await restored.loadFromStore()
        XCTAssertEqual(restored.notice, "A backup plate was opened.")
        XCTAssertTrue(restored.plate.onboardingComplete)

        defaults.set(Data("bad".utf8), forKey: PlateStore.plateKey)
        defaults.set(Data("also-bad".utf8), forKey: PlateStore.backupKey)
        let broken = YearMatrix(store: store, calendar: calendar)
        await broken.loadFromStore()
        XCTAssertEqual(broken.notice, "The plate could not be read.")
        XCTAssertTrue(broken.showsGesso)
    }

    func testResetRemovesStoredPlate() async throws {
        let matrix = makeMatrix()
        let now = sampleNow()
        let ink = try XCTUnwrap(matrix.plate.well.inks.first).id
        try matrix.dip(inkID: ink, now: now)
        try matrix.sketch(stroke: Data([1]), now: now)
        try matrix.penUp(now: now)
        await matrix.flush()
        await matrix.resetAllData()
        let reloaded = YearMatrix(store: matrixStore(), calendar: matrix.calendar)
        await reloaded.loadFromStore()
        XCTAssertTrue(reloaded.plate.cells.isEmpty)
        XCTAssertNil(reloaded.notice)
    }

    func testSimulatorSeedLaysYesterdayAndArmsToday() async throws {
        let matrix = makeMatrix()
        let now = sampleNow()
        await matrix.applySimulatorSeedIfNeeded(now: now)
        #if targetEnvironment(simulator)
        let today = DayKey.make(now, calendar: matrix.calendar)
        let yesterday = try XCTUnwrap(DayKey.byAddingDays(-1, to: today, calendar: matrix.calendar))
        XCTAssertEqual(matrix.plate.cell(dayKey: yesterday)?.fold, .laid)
        XCTAssertEqual(matrix.plate.cell(dayKey: today)?.fold, .armed)
        XCTAssertTrue(matrix.plate.bristle.isDipped)
        XCTAssertTrue(matrix.plate.bristle.pathIsEmpty)
        XCTAssertTrue(matrix.plate.onboardingComplete)
        XCTAssertEqual(matrix.quietStreak(endingAt: now), 1)
        await matrix.applySimulatorSeedIfNeeded(now: now)
        XCTAssertEqual(matrix.plate.cells.count, 2)
        #else
        XCTAssertTrue(matrix.plate.cells.isEmpty)
        #endif
    }

    func testSchemaRejectsUnknownVersion() throws {
        let payload = """
        {"schemaVersion":9,"cells":[],"well":{"inks":[]},"bristle":{"liveStroke":""},"layMarks":[],"peelMarks":[],"onboardingComplete":false}
        """.data(using: .utf8)
        let data = try XCTUnwrap(payload)
        XCTAssertThrowsError(try JSONDecoder().decode(Plate.self, from: data)) { error in
            XCTAssertEqual(error as? PlateCodingError, .unsupportedSchema(9))
        }
    }

    private var heldStore: PlateStore?

    private func makeMatrix() -> YearMatrix {
        let store = matrixStore()
        return YearMatrix(store: store, calendar: fixedCalendar())
    }

    private func matrixStore() -> PlateStore {
        if let heldStore { return heldStore }
        let name = suiteName ?? "bdy.tests.\(UUID().uuidString)"
        suiteName = name
        let store = PlateStore(suiteName: name, directory: makeDirectory(), debounce: .milliseconds(20))
        heldStore = store
        return store
    }

    private func makeDefaults() -> UserDefaults {
        let name = suiteName ?? "bdy.tests.\(UUID().uuidString)"
        suiteName = name
        return UserDefaults(suiteName: name) ?? .standard
    }

    private func makeDirectory() -> URL {
        if let directory { return directory }
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("bdy-\(UUID().uuidString)", isDirectory: true)
        directory = url
        return url
    }

    private func fixedCalendar() -> Calendar {
        var calendar = Calendar(identifier: .gregorian)
        if let zone = TimeZone(secondsFromGMT: 0) {
            calendar.timeZone = zone
        }
        return calendar
    }

    private func sampleNow() -> Date {
        var parts = DateComponents()
        parts.calendar = fixedCalendar()
        parts.timeZone = TimeZone(secondsFromGMT: 0)
        parts.year = 2026
        parts.month = 9
        parts.day = 27
        parts.hour = 15
        return parts.date ?? Date(timeIntervalSince1970: 1_758_985_200)
    }

    private func lay(daysAgo: Int, matrix: YearMatrix, now: Date, ink: UUID) throws {
        let day = try XCTUnwrap(matrix.calendar.date(byAdding: .day, value: -daysAgo, to: now))
        try matrix.dip(inkID: ink, now: day)
        try matrix.sketch(stroke: Data([9, UInt8(daysAgo)]), now: day)
        try matrix.penUp(now: day)
    }
}
