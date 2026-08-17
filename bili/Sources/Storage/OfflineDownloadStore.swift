import Foundation

actor OfflineDownloadStore {
    private let fileManager: FileManager
    private let indexURL: URL
    private var items: [UUID: OfflineDownloadItem] = [:]

    init(fileManager: FileManager = .default) {
        self.fileManager = fileManager
        let supportDirectory = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? fileManager.temporaryDirectory
        let directory = supportDirectory.appendingPathComponent("bili-Pro", isDirectory: true)
        self.indexURL = directory.appendingPathComponent("offline-downloads.json")
        try? fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
        if let data = try? Data(contentsOf: indexURL),
           let decoded = try? JSONDecoder().decode([OfflineDownloadItem].self, from: data) {
            self.items = Dictionary(uniqueKeysWithValues: decoded.map { ($0.id, $0) })
        }
    }

    func allItems() -> [OfflineDownloadItem] {
        items.values.sorted { $0.createdAt > $1.createdAt }
    }

    func exportData() throws -> Data {
        try JSONEncoder().encode(allItems())
    }

    func importData(_ data: Data) throws {
        let decoded = try JSONDecoder().decode([OfflineDownloadItem].self, from: data)
        for item in decoded { items[item.id] = item }
        try persist()
    }

    func item(id: UUID) -> OfflineDownloadItem? {
        items[id]
    }

    @discardableResult
    func upsert(_ item: OfflineDownloadItem) throws -> OfflineDownloadItem {
        items[item.id] = item
        try persist()
        return item
    }

    func update(id: UUID, _ mutate: @Sendable (inout OfflineDownloadItem) -> Void) throws -> OfflineDownloadItem? {
        guard var item = items[id] else { return nil }
        mutate(&item)
        item.updatedAt = .now
        items[id] = item
        try persist()
        return item
    }

    func remove(id: UUID, removeFiles: Bool = false) throws {
        guard let item = items.removeValue(forKey: id) else { return }
        if removeFiles { try? fileManager.removeItem(at: item.directoryURL) }
        try persist()
    }

    private func persist() throws {
        let data = try JSONEncoder().encode(allItems())
        try data.write(to: indexURL, options: .atomic)
    }
}
