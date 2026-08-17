import Foundation
import Testing
@testable import bili

@Test("offline download store persists and updates items")
func offlineDownloadStorePersistsAndUpdatesItems() async throws {
    let fileManager = FileManager()
    let store = OfflineDownloadStore(fileManager: fileManager)
    let directory = fileManager.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    let item = OfflineDownloadItem(bvid: "BV1TEST", cid: 7, title: "Test", directoryURL: directory)

    _ = try await store.upsert(item)
    _ = try await store.update(id: item.id) {
        $0.state = .completed
        $0.progress = 1
    }

    let saved = await store.item(id: item.id)
    #expect(saved?.state == .completed)
    #expect(saved?.progress == 1)
}
