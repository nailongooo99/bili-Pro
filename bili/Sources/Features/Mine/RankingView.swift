import SwiftUI

struct RankingView: View {
    let api: BiliAPIClient
    @State private var videos: [VideoItem] = []
    @State private var isLoading = true
    @State private var errorMessage: String?

    var body: some View {
        Group {
            if isLoading {
                ProgressView()
            } else if let errorMessage {
                ContentUnavailableView("排行榜加载失败", systemImage: "chart.bar.xaxis", description: Text(errorMessage))
            } else if videos.isEmpty {
                ContentUnavailableView("暂无排行榜内容", systemImage: "chart.bar.xaxis")
            } else {
                List {
                    ForEach(Array(videos.enumerated()), id: \.element.id) { index, video in
                        NavigationLink {
                            VideoDetailView(seedVideo: video, hidesRootTabBar: false, onRequestClose: {}, onPopOne: {})
                        } label: {
                            HStack(spacing: 12) {
                                Text("\(index + 1)")
                                    .font(.headline.monospacedDigit())
                                    .foregroundStyle(index < 3 ? .orange : .secondary)
                                    .frame(width: 28)
                                AsyncImage(url: video.pic.flatMap(URL.init(string:))) { phase in
                                    if case .success(let image) = phase {
                                        image.resizable().scaledToFill()
                                    } else {
                                        Color.secondary.opacity(0.12)
                                    }
                                }
                                .frame(width: 112, height: 64)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(video.title.removingHTMLTags())
                                        .font(.subheadline.weight(.medium))
                                        .lineLimit(2)
                                    Text(video.owner?.name ?? "哔哩哔哩")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }
                .listStyle(.insetGrouped)
            }
        }
        .navigationTitle("排行榜")
        .task { await load() }
        .refreshable { await load() }
    }

    private func load() async {
        isLoading = true
        errorMessage = nil
        do { videos = try await api.fetchRankingVideos() }
        catch { errorMessage = error.localizedDescription }
        isLoading = false
    }
}
