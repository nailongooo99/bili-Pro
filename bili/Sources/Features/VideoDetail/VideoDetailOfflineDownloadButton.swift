import SwiftUI

struct VideoDetailOfflineDownloadButton: View {
    @ObservedObject var viewModel: VideoDetailViewModel
    @ObservedObject var manager: OfflineDownloadManager
    @State private var message: String?

    var body: some View {
        Button { Task { await enqueue() } } label: {
            Label("Download", systemImage: "arrow.down.circle")
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .buttonStyle(.bordered)
        .disabled(viewModel.selectedPlayVariant?.videoURL == nil || isAlreadyQueued)
        .overlay(alignment: .trailing) {
            if isAlreadyQueued {
                Text("Added").font(.caption).foregroundStyle(.secondary).padding(.trailing, 12)
            }
        }
        .alert("Offline Download", isPresented: Binding(
            get: { message != nil },
            set: { if !$0 { message = nil } }
        )) {
            Button("OK", role: .cancel) { message = nil }
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
              let cid = viewModel.selectedCID ?? viewModel.detail.cid else {
            message = "The playback stream is not ready. Try again shortly."
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
            message = "Added to the offline download queue."
        } catch {
            message = error.localizedDescription
        }
    }
}
