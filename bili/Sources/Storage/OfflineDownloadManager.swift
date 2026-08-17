import Foundation
import Combine
import AVFoundation

@MainActor
final class OfflineDownloadManager: ObservableObject {
    @Published private(set) var items: [OfflineDownloadItem] = []

    private let store: OfflineDownloadStore
    private let session: URLSession
    private var tasks: [UUID: Task<Void, Never>] = [:]

    init(store: OfflineDownloadStore = OfflineDownloadStore(), session: URLSession = .shared) {
        self.store = store
        self.session = session
    }

    func refresh() async {
        items = await store.allItems()
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
        try? await store.remove(id: id, removeFiles: true)
        await refresh()
    }

    private func start(_ item: OfflineDownloadItem) {
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
                let (videoTemporaryURL, _) = try await session.download(from: item.videoURL ?? URL(fileURLWithPath: ""))
                try replace(videoTemporaryURL, with: videoDestination)
                if let audioURL = item.audioURL {
                    let audioDestination = item.directoryURL.appendingPathComponent("audio.m4a")
                    let (audioTemporaryURL, _) = try await session.download(from: audioURL)
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
    case missingMediaTrack
    case exportUnavailable

    var errorDescription: String? {
        switch self {
        case .missingMediaTrack: return "The downloaded media did not contain compatible audio and video tracks."
        case .exportUnavailable: return "The device could not create a local media export session."
        }
    }
}
