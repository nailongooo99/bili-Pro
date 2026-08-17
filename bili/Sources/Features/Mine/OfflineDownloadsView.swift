import SwiftUI

struct OfflineDownloadsView: View {
    @EnvironmentObject private var manager: OfflineDownloadManager
    @State private var items: [OfflineDownloadItem] = []
    @State private var isLoading = true

    var body: some View {
        Group {
            if isLoading {
                ProgressView()
            } else if items.isEmpty {
                ContentUnavailableView("No Offline Downloads", systemImage: "arrow.down.circle", description: Text("Downloaded videos will appear here."))
            } else {
                List {
                    ForEach(items) { item in OfflineDownloadRow(item: item) }
                        .onDelete { offsets in
                            let ids = offsets.map { items[$0].id }
                            Task { for id in ids { await manager.remove(id: id) }; await reload() }
                        }
                }
                .listStyle(.insetGrouped)
            }
        }
        .navigationTitle("Offline Downloads")
        .task { await reload() }
        .refreshable { await reload() }
    }

    private func reload() async {
        await manager.refresh()
        items = manager.items
        isLoading = false
    }
}

private struct OfflineDownloadRow: View {
    let item: OfflineDownloadItem

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: iconName).font(.title3).foregroundStyle(tint).frame(width: 28)
            VStack(alignment: .leading, spacing: 4) {
                Text(item.title).lineLimit(2)
                Text(statusText).font(.caption).foregroundStyle(.secondary)
                if item.state == .downloading || item.state == .queued { ProgressView(value: item.progress) }
            }
        }
        .padding(.vertical, 4)
    }

    private var iconName: String {
        switch item.state {
        case .completed: return "checkmark.circle.fill"
        case .failed: return "exclamationmark.triangle.fill"
        case .paused: return "pause.circle.fill"
        case .queued, .downloading: return "arrow.down.circle.fill"
        }
    }

    private var tint: Color { item.state == .failed ? .orange : .accentColor }

    private var statusText: String {
        switch item.state {
        case .queued: return "Queued"
        case .downloading: return "Downloading \(Int(item.progress * 100))%"
        case .paused: return "Paused"
        case .completed: return "Completed"
        case .failed: return item.errorMessage ?? "Download failed"
        }
    }
}
