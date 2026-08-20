import AVKit
import SwiftUI

struct AudioDetailView: View {
    @EnvironmentObject private var dependencies: AppDependencies
    let audio: SearchAudioItem
    @State private var detail: AudioDetail?
    @State private var player: AVPlayer?
    @State private var isLoading = true
    @State private var errorMessage: String?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                SearchPosterCover(sourceURLString: detail?.cover?.normalizedBiliURL() ?? audio.cover?.normalizedBiliURL(), thumbnailWidth: 720, thumbnailHeight: 720, targetPixelSize: 720, size: CGSize(width: 220, height: 220), placeholderSystemImage: "waveform")
                    .frame(maxWidth: .infinity)
                    .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                Text(detail?.title ?? audio.title).font(.title2.bold())
                if let author = detail?.author ?? audio.author, !author.isEmpty { Label(author, systemImage: "person").foregroundStyle(.secondary) }
                if let player { VideoPlayer(player: player).frame(height: 80).clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous)) }
                else if isLoading { ProgressView("正在加载音频…").frame(maxWidth: .infinity) }
                if let errorMessage { Text(errorMessage).foregroundStyle(.secondary) }
                if let intro = detail?.intro, !intro.isEmpty { Text(intro.removingHTMLTags()).foregroundStyle(.secondary) }
            }
            .padding(16)
        }
        .navigationTitle("音频")
        .navigationBarTitleDisplayMode(.inline)
        .task { await load() }
        .onDisappear { player?.pause() }
    }

    private func load() async {
        do {
            async let detailRequest = dependencies.api.fetchAudioDetail(sid: audio.id)
            async let urlRequest = dependencies.api.fetchAudioPlayURL(sid: audio.id)
            let (loadedDetail, url) = try await (detailRequest, urlRequest)
            detail = loadedDetail
            player = AVPlayer(url: url)
            isLoading = false
        } catch {
            errorMessage = error.localizedDescription
            isLoading = false
        }
    }
}
