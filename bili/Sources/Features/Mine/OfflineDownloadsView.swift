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
                ContentUnavailableView(
                    "暂无离线内容",
                    systemImage: "arrow.down.circle",
                    description: Text("在视频详情页选择下载后，内容会显示在这里。")
                )
            } else {
                List {
                    ForEach(items) { item in
                        OfflineDownloadRow(item: item)
                    }
                    .onDelete { offsets in
                        let ids = offsets.map { items[$0].id }
                        Task {
                            for id in ids { await manager.remove(id: id) }
                        }
                    }
                }
                .listStyle(.insetGrouped)
            }
        }
        .navigationTitle("离线下载")
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
            Image(systemName: iconName)
                .font(.title3)
                .foregroundStyle(tint)
                .frame(width: 28)
            VStack(alignment: .leading, spacing: 4) {
                Text(item.title)
                    .lineLimit(2)
                Text(statusText)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                if item.state == .downloading || item.state == .queued {
                    ProgressView(value: item.progress)
                }
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

    private var tint: Color {
        item.state == .failed ? .orange : .accentColor
    }

    private var statusText: String {
        switch item.state {
        case .queued: return "等待下载"
        case .downloading: return "下载中 (Int(item.progress * 100))%"
        case .paused: return "已暂停"
        case .completed: return "已完成"
        case .failed: return item.errorMessage ?? "下载失败"
        }
    }
}
