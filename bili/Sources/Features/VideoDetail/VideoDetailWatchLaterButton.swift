import SwiftUI

struct VideoDetailWatchLaterButton: View {
    @ObservedObject var viewModel: VideoDetailViewModel
    @State private var isWorking = false
    @State private var message: String?

    var body: some View {
        Button {
            Task { await save() }
        } label: {
            Label("Watch later", systemImage: "bookmark")
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .buttonStyle(.bordered)
        .disabled(viewModel.detail.aid == nil || isWorking)
        .overlay(alignment: .trailing) {
            if isWorking { ProgressView().padding(.trailing, 12) }
        }
        .alert("Watch later", isPresented: Binding(
            get: { message != nil },
            set: { if !$0 { message = nil } }
        )) {
            Button("OK", role: .cancel) { message = nil }
        } message: {
            Text(message ?? "")
        }
    }

    private func save() async {
        guard let aid = viewModel.detail.aid else { return }
        isWorking = true
        defer { isWorking = false }
        do {
            try await viewModel.serviceDependencies.api.addToWatchLater(aid: aid)
            message = "Added to your watch-later list."
        } catch {
            message = error.localizedDescription
        }
    }
}
