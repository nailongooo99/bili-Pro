import SwiftUI

struct VideoDetailDLNAButton: View {
    @ObservedObject var viewModel: VideoDetailViewModel
    @State private var devices: [DLNADevice] = []
    @State private var isPresented = false
    @State private var isLoading = false
    @State private var message: String?
    private let service = DLNAService()

    var body: some View {
        Button {
            Task { await discover() }
        } label: {
            Label("Play on TV", systemImage: "tv")
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .buttonStyle(.bordered)
        .disabled(viewModel.selectedPlayVariant?.videoURL == nil || isLoading)
        .sheet(isPresented: $isPresented) {
            NavigationStack {
                List(devices) { device in
                    Button(device.name) {
                        Task { await play(on: device) }
                    }
                }
                .navigationTitle("Choose Device")
                .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Cancel") { isPresented = false } } }
            }
            .presentationDetents([.medium])
        }
        .alert("DLNA", isPresented: Binding(get: { message != nil }, set: { if !$0 { message = nil } })) {
            Button("OK", role: .cancel) { message = nil }
        } message: { Text(message ?? "") }
    }

    private func discover() async {
        isLoading = true
        defer { isLoading = false }
        do {
            devices = try await service.discover()
            if devices.isEmpty { message = "No compatible devices found on the local network." }
            else { isPresented = true }
        } catch { message = error.localizedDescription }
    }

    private func play(on device: DLNADevice) async {
        guard let url = viewModel.selectedPlayVariant?.videoURL else { return }
        do {
            try await service.play(url: url, on: device)
            isPresented = false
            message = "Playback request sent to \(device.name)."
        } catch { message = error.localizedDescription }
    }
}
