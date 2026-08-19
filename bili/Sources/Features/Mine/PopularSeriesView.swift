import SwiftUI

struct PopularSeriesView: View {
    let api: BiliAPIClient
    @State private var series: [PopularSeriesItem] = []
    @State private var selected: PopularSeriesDetail?
    @State private var isLoading = true
    @State private var errorMessage: String?

    var body: some View {
        List {
            if isLoading {
                ProgressView()
            } else if let errorMessage {
                ContentUnavailableView("Weekly picks unavailable", systemImage: "calendar.badge.exclamationmark", description: Text(errorMessage))
            } else {
                ForEach(series) { item in
                    Button {
                        Task { await loadDetail(number: item.number) }
                    } label: {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(item.name).font(.headline)
                            Text(item.subject).foregroundStyle(.secondary).lineLimit(2)
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .navigationTitle("Weekly Picks")
        .task { await load() }
        .refreshable { await load() }
        .sheet(item: $selected) { detail in
            NavigationStack {
                List(detail.list) { video in
                    NavigationLink {
                        VideoDetailView(seedVideo: video, hidesRootTabBar: false, onRequestClose: {}, onPopOne: {})
                    } label: {
                        Text(video.title.removingHTMLTags()).lineLimit(2)
                    }
                }
                .navigationTitle(detail.config.name)
            }
        }
    }

    private func load() async {
        isLoading = true
        errorMessage = nil
        do { series = try await api.fetchPopularSeries() }
        catch { errorMessage = error.localizedDescription }
        isLoading = false
    }

    private func loadDetail(number: Int) async {
        do { selected = try await api.fetchPopularSeriesDetail(number: number) }
        catch { errorMessage = error.localizedDescription }
    }
}
