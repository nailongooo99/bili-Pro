import SwiftUI

struct VideoDetailOfflineDownloadButton: View {
    @ObservedObject var viewModel: VideoDetailViewModel
    @ObservedObject var manager: OfflineDownloadManager
    @State private var message: String?

    var body: some View {
        Button {
            Task { await enqueue() }
        } label: {
            Label("下载到本机", systemImage: "arrow.down.circle")
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .buttonStyle(.bordered)
        .disabled(viewModel.selectedPlayVariant?.videoURL == nil || isAlreadyQueued)
        .overlay(alignment: .trailing) {
            if isAlreadyQueued {
                Text("已加入")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.trailing, 12)
            }
        }
        .alert("离线下载", isPresented: Binding(
            get: { message != nil },
            set: { if !$0 { message = nil } }
        )) {
            Button("好", role: .cancel) { message = nil }
        } message: {
            Text(message ?? "")
        }
    }

    private var isAlreadyQueued: Bool {
        manager.items.contains {
            $0.bvid == viewModel.detail.bvid && $0.cid == (viewModel.selectedCID ?? viewModel.detail.cid ?? 0)
        }
    }

    private func enqueue() async {
        guard let variant = viewModel.selectedPlayVariant,
              let videoURL = variant.videoURL,
              let cid = viewModel.selectedCID ?? viewModel.detail.cid
        else {
            message = "播放地址尚未准备好，请稍后再试。"
            return
        }
        do {
            _ = try await manager.enqueue(
                bvid: viewModel.detail.bvid,
                aid: viewModel.detail.aid,
                cid: cid,
                title: viewModel.detail.title,
                videoURL: videoURL,
                audioURL: variant.audioURL
            )
            message = "已加入离线下载队列。"
        } catch {
            message = error.localizedDescription
        }
    }
}
