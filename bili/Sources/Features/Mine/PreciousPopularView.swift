import SwiftUI

struct PreciousPopularView: View {
    let api: BiliAPIClient
    @State private var videos: [VideoItem] = []
    @State private var isLoading = true
    @State private var errorMessage: String?

    var body: some View {
        List {
            if isLoading {
                ProgressView()
            } else if let errorMessage {
                ContentUnavailableView("Precious popular unavailable", systemImage: "sparkles.tv", description: Text(errorMessage))
            } else {
                ForEach(videos) { video in
                    NavigationLink {
                        VideoDetailView(seedVideo: video, hidesRootTabBar: false, onRequestClose: {}, onPopOne: {})
                    } label: {
                        HStack(spacing: 12) {
                            AsyncImage(url: video.pic.flatMap(URL.init(string:))) { phase in
                                if case .success(let image) = phase { image.resizable().scaledToFill() }
                                else { Color.secondary.opacity(0.12) }
                            }
                            .frame(width: 112, height: 64)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                            Text(video.title.removingHTMLTags())
                                .font(.subheadline.weight(.medium))
                                .lineLimit(2)
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
        }
        .navigationTitle("Precious Popular")
        .task { await load() }
        .refreshable { await load() }
    }

    private func load() async {
        isLoading = true
        errorMessage = nil
        do { videos = try await api.fetchPreciousPopularVideos() }
        catch { errorMessage = error.localizedDescription }
        isLoading = false
    }
}
