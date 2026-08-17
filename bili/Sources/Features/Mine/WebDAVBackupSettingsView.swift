import SwiftUI

struct WebDAVBackupSettingsView: View {
    @EnvironmentObject private var libraryStore: LibraryStore
    @State private var endpoint = UserDefaults.standard.string(forKey: "bili-Pro.webdav.endpoint") ?? ""
    @State private var username = UserDefaults.standard.string(forKey: "bili-Pro.webdav.username") ?? ""
    @State private var password = ""
    @State private var status: String?
    @State private var isWorking = false
    private let service = WebDAVBackupService()

    var body: some View {
        Form {
            Section {
                TextField("WebDAV 地址", text: $endpoint)
                    .textInputAutocapitalization(.never)
                    .keyboardType(.URL)
                TextField("用户名", text: $username)
                    .textInputAutocapitalization(.never)
                SecureField("密码", text: $password)
            } header: {
                Text("连接")
            } footer: {
                Text("密码只保存到系统 Keychain，不写入 UserDefaults 或备份文件。")
            }

            Section {
                Button {
                    Task { await saveAndTest() }
                } label: {
                    HStack {
                        Text("保存并测试连接")
                        Spacer()
                        if isWorking { ProgressView() }
                    }
                }
                .disabled(isWorking || endpoint.isEmpty || username.isEmpty || password.isEmpty)

                if let status {
                    Text(status)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            } header: {
                Text("备份")
            }
        }
        .navigationTitle("WebDAV 备份")
    }

    private func saveAndTest() async {
        guard let url = URL(string: endpoint) else {
            status = "地址格式无效"
            return
        }
        isWorking = true
        defer { isWorking = false }
        let configuration = WebDAVConfiguration(baseURL: url, username: username)
        do {
            try await service.savePassword(password, for: configuration)
            UserDefaults.standard.set(endpoint, forKey: "bili-Pro.webdav.endpoint")
            UserDefaults.standard.set(username, forKey: "bili-Pro.webdav.username")
            try await service.testConnection(configuration: configuration)
            status = "连接成功"
        } catch {
            status = error.localizedDescription
        }
    }
}
