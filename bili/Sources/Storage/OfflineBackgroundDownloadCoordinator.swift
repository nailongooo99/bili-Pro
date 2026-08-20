import Foundation

/// Owns system-managed download tasks so an offline video can continue while
/// the app is suspended or relaunched. The durable item index remains the
/// source of truth; taskDescription is the bridge back to that index.
final class OfflineBackgroundDownloadCoordinator: NSObject, URLSessionDownloadDelegate, @unchecked Sendable {
    private let store: OfflineDownloadStore
    private var session: URLSession!
    private let fileManager = FileManager.default

    init(store: OfflineDownloadStore) {
        self.store = store
        let configuration = URLSessionConfiguration.background(withIdentifier: "cc.bili.offline-downloads")
        configuration.isDiscretionary = false
        configuration.sessionSendsLaunchEvents = true
        configuration.waitsForConnectivity = true
        super.init()
        self.session = URLSession(configuration: configuration, delegate: self, delegateQueue: nil)
    }

    func start(_ item: OfflineDownloadItem) {
        guard let url = item.videoURL else { return }
        var request = URLRequest(url: url)
        request.setValue("https://www.bilibili.com/", forHTTPHeaderField: "Referer")
        let task = session.downloadTask(with: request)
        task.taskDescription = item.id.uuidString
        task.resume()
        Task { try? await store.update(id: item.id) { $0.state = .downloading; $0.errorMessage = nil } }
    }

    func cancel(id: UUID) {
        session.getAllTasks { tasks in
            tasks.filter { $0.taskDescription == id.uuidString }.forEach { $0.cancel() }
        }
    }

    func urlSessionDidFinishEvents(forBackgroundURLSession session: URLSession) { }

    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        guard let rawID = downloadTask.taskDescription, let id = UUID(uuidString: rawID) else { return }
        Task {
            guard let item = await store.item(id: id) else { return }
            do {
                try fileManager.createDirectory(at: item.directoryURL, withIntermediateDirectories: true)
                let destination = item.directoryURL.appendingPathComponent("video.mp4")
                try? fileManager.removeItem(at: destination)
                try fileManager.moveItem(at: location, to: destination)
                _ = try await store.update(id: id) { item in
                    item.state = item.audioURL == nil ? .completed : .queued
                    item.progress = item.audioURL == nil ? 1 : 0.8
                    item.errorMessage = nil
                }
            } catch {
                _ = try? await store.update(id: id) { item in
                    item.state = .failed
                    item.errorMessage = error.localizedDescription
                }
            }
        }
    }

    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        guard let rawID = task.taskDescription, let id = UUID(uuidString: rawID), let error else { return }
        Task { _ = try? await store.update(id: id) { item in
            guard item.state != .completed else { return }
            item.state = .failed
            item.errorMessage = error.localizedDescription
        } }
    }
}
