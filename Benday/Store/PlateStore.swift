import Foundation

/// Seam between the year matrix and storage. The UI never touches this type.
/// The in-memory plate is the source of truth. UserDefaults and the Application Support file are projections.
actor PlateStore {
    static let plateKey = "bdy.plate.v1"
    static let backupKey = "bdy.plate.backup.v1"
    static let demoKey = "bdy.demo.v1"

    private let defaults: UserDefaults
    private let directory: URL
    private let debounce: Duration
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder

    private var pending: Plate?
    private var generation = 0
    private var acceptedRevision = 0
    private var debounceTask: Task<Void, Never>?
    private var lastSaveError: String?

    init(suiteName: String, directory: URL, debounce: Duration = .milliseconds(350)) {
        self.defaults = UserDefaults(suiteName: suiteName) ?? .standard
        self.directory = directory
        self.debounce = debounce
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .useDefaultKeys
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.sortedKeys]
        self.encoder = encoder
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .useDefaultKeys
        decoder.dateDecodingStrategy = .iso8601
        self.decoder = decoder
    }

    static func applicationSupportDirectory() -> URL {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? URL(fileURLWithPath: NSTemporaryDirectory())
        return base.appendingPathComponent("BendayPlate", isDirectory: true)
    }

    func load() -> PlateLoad {
        if let data = defaults.data(forKey: Self.plateKey), let plate = decode(data) {
            return .ready(plate)
        }
        if let data = defaults.data(forKey: Self.backupKey), let plate = decode(data) {
            return .restored(plate)
        }
        if let data = readFile(primaryFile), let plate = decode(data) {
            return .restored(plate)
        }
        if let data = readFile(backupFile), let plate = decode(data) {
            return .restored(plate)
        }
        let hadBlob = defaults.data(forKey: Self.plateKey) != nil
            || defaults.data(forKey: Self.backupKey) != nil
            || fileExists(primaryFile)
            || fileExists(backupFile)
        if hadBlob {
            return .unreadable(Plate.fresh())
        }
        return .ready(Plate.fresh())
    }

    func accept(_ plate: Plate, revision: Int, immediate: Bool) async {
        guard revision >= acceptedRevision else { return }
        acceptedRevision = revision
        generation += 1
        let token = generation
        pending = plate
        debounceTask?.cancel()
        debounceTask = nil
        if immediate {
            await writeIfCurrent(token)
            return
        }
        let wait = debounce
        debounceTask = Task { [wait] in
            do {
                try await Task.sleep(for: wait)
            } catch {
                return
            }
            guard !Task.isCancelled else { return }
            await self.writeIfCurrent(token)
        }
    }

    func flush() async {
        guard let plate = pending else { return }
        generation += 1
        let token = generation
        debounceTask?.cancel()
        debounceTask = nil
        await writeIfCurrent(token, plate: plate)
    }

    /// Removes the plate key, the backup, and the files. Does not clear the one-shot demo key.
    func resetAllData() {
        generation += 1
        debounceTask?.cancel()
        debounceTask = nil
        pending = nil
        defaults.removeObject(forKey: Self.plateKey)
        defaults.removeObject(forKey: Self.backupKey)
        removeFile(primaryFile)
        removeFile(backupFile)
    }

    func demoAlreadyApplied() -> Bool {
        defaults.bool(forKey: Self.demoKey)
    }

    func markDemoApplied() {
        defaults.set(true, forKey: Self.demoKey)
    }

    func lastErrorDescription() -> String? {
        lastSaveError
    }

    private func writeIfCurrent(_ token: Int, plate explicit: Plate? = nil) async {
        guard token == generation else { return }
        guard let plate = explicit ?? pending else { return }
        let data: Data
        do {
            data = try encoder.encode(plate)
        } catch {
            lastSaveError = "The plate could not be saved."
            return
        }
        guard token == generation else { return }
        if let previous = defaults.data(forKey: Self.plateKey) {
            defaults.set(previous, forKey: Self.backupKey)
        }
        guard token == generation else { return }
        defaults.set(data, forKey: Self.plateKey)
        writeFiles(data)
        if token == generation {
            pending = nil
        }
    }

    private func writeFiles(_ data: Data) {
        do {
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        } catch {
            lastSaveError = "The plate folder could not be created."
            return
        }
        if fileExists(primaryFile), let existing = readFile(primaryFile) {
            do {
                try existing.write(to: backupFile, options: .atomic)
            } catch {
                lastSaveError = "The plate backup could not be written."
            }
        }
        do {
            try data.write(to: primaryFile, options: .atomic)
            var values = URLResourceValues()
            values.isExcludedFromBackup = false
            var mutable = primaryFile
            try mutable.setResourceValues(values)
        } catch {
            lastSaveError = "The plate could not be written."
        }
    }

    private func decode(_ data: Data) -> Plate? {
        do {
            return try decoder.decode(Plate.self, from: data)
        } catch {
            return nil
        }
    }

    private var primaryFile: URL {
        directory.appendingPathComponent("plate.json")
    }

    private var backupFile: URL {
        directory.appendingPathComponent("plate.json.backup")
    }

    private func readFile(_ url: URL) -> Data? {
        do {
            return try Data(contentsOf: url)
        } catch {
            return nil
        }
    }

    private func fileExists(_ url: URL) -> Bool {
        FileManager.default.fileExists(atPath: url.path)
    }

    private func removeFile(_ url: URL) {
        do {
            try FileManager.default.removeItem(at: url)
        } catch let error as CocoaError where error.code == .fileNoSuchFile {
            return
        } catch {
            lastSaveError = "The plate file could not be removed."
        }
    }
}

enum PlateLoad: Equatable, Sendable {
    case ready(Plate)
    case restored(Plate)
    case unreadable(Plate)
}
