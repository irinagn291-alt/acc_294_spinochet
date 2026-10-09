import Foundation

/// Screens observe this one YearMatrix. The session is the only mutation door the UI uses.
@MainActor
protocol PlateObserving: AnyObject {
    func plateDidChange()
}

@MainActor
final class PlateSession {
    let matrix: YearMatrix
    private(set) var refusal: BristleRefusal?
    private(set) var launchScreen: String?
    private var didReadLaunch = false
    private var boxes: [ObserverBox] = []

    init(matrix: YearMatrix) {
        self.matrix = matrix
    }

    static func live() -> PlateSession {
        let store = PlateStore(
            suiteName: "com.benday.matrix",
            directory: PlateStore.applicationSupportDirectory()
        )
        return PlateSession(matrix: YearMatrix(store: store))
    }

    func observe(_ observer: PlateObserving) {
        boxes.removeAll { $0.observer == nil }
        if boxes.contains(where: { $0.observer === observer }) { return }
        boxes.append(ObserverBox(observer))
    }

    func boot() async {
        await matrix.loadFromStore()
        await matrix.applySimulatorSeedIfNeeded(now: Date())
        note()
    }

    func readLaunchOnce() {
        guard !didReadLaunch else { return }
        guard matrix.plate.onboardingComplete else { return }
        didReadLaunch = true
        launchScreen = ReviewLaunch.screen
    }

    func dip(inkID: UUID) {
        do {
            try matrix.dip(inkID: inkID, now: Date())
            refusal = nil
        } catch let error as BristleRefusal {
            refusal = error
        } catch {
            refusal = nil
        }
        note()
    }

    func sketch(stroke: Data) {
        do {
            try matrix.sketch(stroke: stroke, now: Date())
            refusal = nil
        } catch let error as BristleRefusal {
            refusal = error
        } catch {
            refusal = nil
        }
    }

    @discardableResult
    func penUp() -> Bool {
        do {
            try matrix.penUp(now: Date())
            refusal = nil
            note()
            return true
        } catch let error as BristleRefusal {
            refusal = error
            note()
            return false
        } catch {
            note()
            return false
        }
    }

    func peelToday() {
        do {
            try matrix.peelToday(now: Date())
            refusal = nil
        } catch let error as BristleRefusal {
            refusal = error
        } catch {
            refusal = nil
        }
        note()
    }

    func finishOnboarding() async {
        await matrix.finishOnboarding()
        readLaunchOnce()
        note()
    }

    func reopenOnboarding() async {
        await matrix.reopenOnboarding()
        note()
    }

    func renameInk(id: UUID, trayLabel: String) {
        matrix.renameInk(id: id, trayLabel: trayLabel)
        note()
    }

    func resetAllData() async {
        await matrix.resetAllData()
        note()
    }

    func reload() async {
        await matrix.loadFromStore()
        note()
    }

    func refusalLine() -> String? {
        switch refusal {
        case .sketchOnLaid:
            return "Today is laid. Peel today, then dip and draw again."
        case .sketchWhileOpen:
            return "Dip an ink in the tray, then lay the stroke."
        case .dipOverLiveStroke:
            return "Finish this stroke before dipping another ink."
        case .penUpWithoutStroke:
            return "Lay a stroke before you lift."
        case .penUpWhileNotArmed:
            return "Dip an ink so today can take a stroke."
        case .peelWhenNotLaid:
            return "Peel is ready after today is laid."
        case .unknownInk:
            return "That ink is not in the tray."
        case nil:
            return nil
        }
    }

    private func note() {
        readLaunchOnce()
        boxes.removeAll { $0.observer == nil }
        boxes.forEach { $0.observer?.plateDidChange() }
    }
}

@MainActor
private final class ObserverBox {
    weak var observer: PlateObserving?
    init(_ observer: PlateObserving) {
        self.observer = observer
    }
}
