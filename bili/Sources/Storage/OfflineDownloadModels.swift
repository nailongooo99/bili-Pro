import Foundation

nonisolated enum OfflineDownloadState: String, Codable, Sendable {
    case queued
    case downloading
    case paused
    case completed
    case failed
}

nonisolated struct OfflineDownloadItem: Codable, Equatable, Identifiable, Sendable {
    let id: UUID
    let bvid: String
    let aid: Int?
    let cid: Int
    let title: String
    let pageIndex: Int
    let videoURL: URL?
    let audioURL: URL?
    let directoryURL: URL
    var state: OfflineDownloadState
    var progress: Double
    var errorMessage: String?
    var createdAt: Date
    var updatedAt: Date

    init(
        id: UUID = UUID(),
        bvid: String,
        aid: Int? = nil,
        cid: Int,
        title: String,
        pageIndex: Int = 0,
        videoURL: URL? = nil,
        audioURL: URL? = nil,
        directoryURL: URL,
        state: OfflineDownloadState = .queued,
        progress: Double = 0,
        errorMessage: String? = nil,
        createdAt: Date = .now,
        updatedAt: Date = .now
    ) {
        self.id = id
        self.bvid = bvid
        self.aid = aid
        self.cid = cid
        self.title = title
        self.pageIndex = pageIndex
        self.videoURL = videoURL
        self.audioURL = audioURL
        self.directoryURL = directoryURL
        self.state = state
        self.progress = min(max(progress, 0), 1)
        self.errorMessage = errorMessage
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}
