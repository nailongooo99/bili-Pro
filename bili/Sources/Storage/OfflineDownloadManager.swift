import Foundation
import Combine
import AVFoundation

@MainActor
final class OfflineDownloadManager: ObservableObject {
    @Published private(set) var items: [OfflineDownloadItem] = []

    private let store: OfflineDownloadStore
    private let session: URLSession
    private let backgroundCoordinator: OfflineBackgroundDownloadCoordinator
    private var tasks: [UUID: Task<Void, Never>] = [:]

    init(store: OfflineDownloadStore = OfflineDownloadStore(), session: URLSession = .shared) {
        self.store = store
        self.session = session
        self.backgroundCoordinator = OfflineBackgroundDownloadCoordinator(store: store)
    }

    func refresh() async {
        items = await store.allItems()
    }

    /// Rehydrates unfinished downloads after a process or background-task restart.
    /// This intentionally only resumes queued/downloading items; paused items remain
    /// user-controlled and failed items are left available for an explicit retry.
    func resumePendingDownloads() async {
        let pending = await store.allItems().filter { $0.state == .queued || $0.state == .downloading }
        items = await store.allItems()
        for item in pending { start(item) }
    }

    @discardableResult
    func enqueue(
        bvid: String,
        aid: Int?,
        cid: Int,
        title: String,
        pageIndex: Int = 0,
        videoURL: URL,
        audioURL: URL? = nil
    ) async throws -> OfflineDownloadItem {
        let directory = try makeDirectory(for: bvid, cid: cid)
        let item = OfflineDownloadItem(
            bvid: bvid,
            aid: aid,
            cid: cid,
            title: title,
            pageIndex: pageIndex,
            videoURL: videoURL,
            audioURL: audioURL,
            directoryURL: directory
        )
        _ = try await store.upsert(item)
        await refresh()
        start(item)
        return item
    }

    func pause(id: UUID) async {
        tasks[id]?.cancel()
        tasks[id] = nil
        backgroundCoordinator.cancel(id: id)
        _ = try? await store.update(id: id) {
            guard $0.state == .downloading || $0.state == .queued else { return }
            $0.state = .paused
        }
        await refresh()
    }

    func retry(id: UUID) async {
        guard let item = await store.item(id: id) else { return }
        start(item)
    }

    func remove(id: UUID) async {
        tasks[id]?.cancel()
        tasks[id] = nil
        backgroundCoordinator.cancel(id: id)
        try? await store.remove(id: id, removeFiles: true)
        await refresh()
    }

    private func start(_ item: OfflineDownloadItem) {
        if item.audioURL == nil {
            backgroundCoordinator.start(item)
            return
        }
        tasks[item.id]?.cancel()
        tasks[item.id] = Task { [weak self] in
            guard let self else { return }
            _ = try? await self.store.update(id: item.id) {
                $0.state = .downloading
                $0.errorMessage = nil
            }
            do {
                try FileManager.default.createDirectory(at: item.directoryURL, withIntermediateDirectories: true)
                let videoDestination = item.directoryURL.appendingPathComponent("video.mp4")
                guard let videoURL = item.videoURL else { throw OfflineDownloadError.missingVideoURL }
                let videoTemporaryURL = item.directoryURL.appendingPathComponent("video.download")
                try await streamDownload(videoURL, to: videoTemporaryURL, id: item.id, baseProgress: 0, weight: item.audioURL == nil ? 1 : 0.8)
                try replace(videoTemporaryURL, with: videoDestination)
                if let audioURL = item.audioURL {
                    let audioDestination = item.directoryURL.appendingPathComponent("audio.m4a")
                    let audioTemporaryURL = item.directoryURL.appendingPathComponent("audio.download")
                    try await streamDownload(audioURL, to: audioTemporaryURL, id: item.id, baseProgress: 0.8, weight: 0.2)
                    try replace(audioTemporaryURL, with: audioDestination)
                    try await mux(videoURL: videoDestination, audioURL: audioDestination, outputURL: videoDestination)
                    try? FileManager.default.removeItem(at: audioDestination)
                }
                _ = try await store.update(id: item.id) {
                    $0.state = .completed
                    $0.progress = 1
                }
            } catch is CancellationError {
                return
            } catch {
                _ = try? await store.update(id: item.id) {
                    $0.state = .failed
                    $0.errorMessage = error.localizedDescription
                }
            }
            await refresh()
        }
    }

    private func makeDirectory(for bvid: String, cid: Int) throws -> URL {
        let root = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
            .appendingPathComponent("bili-Pro/Offline", isDirectory: true)
        let directory = root.appendingPathComponent("\(bvid)-\(cid)", isDirectory: true)
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        return directory
    }

    private func replace(_ source: URL, with destination: URL) throws {
        try? FileManager.default.removeItem(at: destination)
        try FileManager.default.moveItem(at: source, to: destination)
    }

    private func streamDownload(_ url: URL, to destination: URL, id: UUID, baseProgress: Double, weight: Double) async throws {
        try? FileManager.default.removeItem(at: destination)
        FileManager.default.createFile(atPath: destination.path, contents: nil)
        let handle = try FileHandle(forWritingTo: destination)
        defer { try? handle.close() }
        let (bytes, response) = try await session.bytes(from: url)
        let expected = response.expectedContentLength > 0 ? Double(response.expectedContentLength) : nil
        var received = 0
        var buffer = Data()
        buffer.reserveCapacity(64 * 1024)
        for try await byte in bytes {
            try Task.checkCancellation()
            buffer.append(byte)
            received += 1
            if buffer.count >= 64 * 1024 {
                try handle.write(contentsOf: buffer)
                buffer.removeAll(keepingCapacity: true)
            }
            if received % (256 * 1024) == 0, let expected {
                let progress = baseProgress + min(1, Double(received) / expected) * weight
                _ = try? await store.update(id: id) { $0.progress = progress }
                await refresh()
            }
        }
        if !buffer.isEmpty { try handle.write(contentsOf: buffer) }
        _ = try? await store.update(id: id) { $0.progress = baseProgress + weight }
        await refresh()
    }

    private func mux(videoURL: URL, audioURL: URL, outputURL: URL) async throws {
        let videoAsset = AVURLAsset(url: videoURL)
        let audioAsset = AVURLAsset(url: audioURL)
        let composition = AVMutableComposition()
        guard let videoTrack = try await videoAsset.loadTracks(withMediaType: .video).first,
              let audioTrack = try await audioAsset.loadTracks(withMediaType: .audio).first else {
            throw OfflineDownloadError.missingMediaTrack
        }
        let duration = try await videoAsset.load(.duration)
        let videoCompositionTrack = composition.addMutableTrack(withMediaType: .video, preferredTrackID: kCMPersistentTrackID_Invalid)
        let audioCompositionTrack = composition.addMutableTrack(withMediaType: .audio, preferredTrackID: kCMPersistentTrackID_Invalid)
        try videoCompositionTrack?.insertTimeRange(CMTimeRange(start: .zero, duration: duration), of: videoTrack, at: .zero)
        let audioDuration = try await audioAsset.load(.duration)
        let outputDuration = min(duration.seconds, audioDuration.seconds)
        try audioCompositionTrack?.insertTimeRange(CMTimeRange(start: .zero, duration: CMTime(seconds: outputDuration, preferredTimescale: 600)), of: audioTrack, at: .zero)

        let temporaryURL = outputURL.deletingLastPathComponent().appendingPathComponent("muxed.mp4")
        try? FileManager.default.removeItem(at: temporaryURL)
        guard let exporter = AVAssetExportSession(asset: composition, presetName: AVAssetExportPresetHighestQuality) else {
            throw OfflineDownloadError.exportUnavailable
        }
        exporter.outputURL = temporaryURL
        exporter.outputFileType = .mp4
        try await exporter.export()
        try replace(temporaryURL, with: outputURL)
    }
}

private enum OfflineDownloadError: LocalizedError {
    case missingVideoURL
    case missingMediaTrack
    case exportUnavailable

    var errorDescription: String? {
        switch self {
        case .missingVideoURL: return "The download did not contain a video URL."
        case .missingMediaTrack: return "The downloaded media did not contain compatible audio and video tracks."
        case .exportUnavailable: return "The device could not create a local media export session."
        }
    }
}
