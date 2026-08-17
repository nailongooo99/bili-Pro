import SwiftUI

struct DLNADevicesView: View {
    private let service = DLNAService()
    @State private var devices: [DLNADevice] = []
    @State private var isLoading = false
    @State private var errorMessage: String?

    var body: some View {
        Group {
            if isLoading {
                ProgressView("正在搜索设备")
            } else if devices.isEmpty {
                ContentUnavailableView("暂无 DLNA 设备", systemImage: "tv", description: Text("请确认手机与电视位于同一 Wi‑Fi。"))
            } else {
                List(devices) { device in
                    Label(device.name, systemImage: "tv")
                }
            }
        }
        .navigationTitle("DLNA 投屏")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("搜索") { Task { await discover() } }
                    .disabled(isLoading)
            }
        }
        .task { await discover() }
        .alert("DLNA", isPresented: Binding(get: { errorMessage != nil }, set: { if !$0 { errorMessage = nil } })) {
            Button("好", role: .cancel) { errorMessage = nil }
        } message: {
            Text(errorMessage ?? "")
        }
    }

    private func discover() async {
        isLoading = true
        defer { isLoading = false }
        do {
            let discovered = try await service.discover()
            devices = try await withThrowingTaskGroup(of: DLNADevice.self, returning: [DLNADevice].self) { group in
                for device in discovered { group.addTask { try await service.resolve(device) } }
                var resolved = [DLNADevice]()
                for try await device in group { resolved.append(device) }
                return resolved
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
