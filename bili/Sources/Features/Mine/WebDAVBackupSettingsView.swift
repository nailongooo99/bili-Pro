import SwiftUI

struct WebDAVBackupSettingsView: View {
    @State private var endpoint = UserDefaults.standard.string(forKey: "bili-Pro.webdav.endpoint") ?? ""
    @State private var username = UserDefaults.standard.string(forKey: "bili-Pro.webdav.username") ?? ""
    @State private var remotePath = UserDefaults.standard.string(forKey: "bili-Pro.webdav.remotePath") ?? "bili-Pro-backup.json"
    @State private var password = ""
    @State private var status: String?
    @State private var isWorking = false

    private let service = WebDAVBackupService()
    private let downloadStore = OfflineDownloadStore()

    var body: some View {
        Form {
            Section {
                TextField("WebDAV URL", text: $endpoint)
                    .textInputAutocapitalization(.never)
                    .keyboardType(.URL)
                TextField("Username", text: $username)
                    .textInputAutocapitalization(.never)
                SecureField("Password", text: $password)
                TextField("Remote file path", text: $remotePath)
                    .textInputAutocapitalization(.never)
            } header: {
                Text("Connection")
            } footer: {
                Text("The password is stored only in Keychain and is never written to UserDefaults or backup files.")
            }

            Section {
                Button {
                    Task { await saveAndTest() }
                } label: {
                    HStack {
                        Text("Save and test connection")
                        Spacer()
                        if isWorking { ProgressView() }
                    }
                }
                .disabled(isWorking || endpoint.isEmpty || username.isEmpty || password.isEmpty)

                if let status {
                    Text(status).font(.footnote).foregroundStyle(.secondary)
                }
            } header: {
                Text("Backup")
            }

            Section {
                Button("Back up offline download manifest") { Task { await backupDownloads() } }
                Button("Restore offline download manifest") { Task { await restoreDownloads() } }
                    .disabled(isWorking)
            } footer: {
                Text("Only the offline download manifest is backed up. Playback URLs may need to be refreshed after restore.")
            }
        }
        .navigationTitle("WebDAV Backup")
    }

    private func configuration() -> WebDAVConfiguration? {
        guard let url = URL(string: endpoint), !username.isEmpty else { return nil }
        return WebDAVConfiguration(baseURL: url, username: username, remotePath: remotePath)
    }

    private func saveAndTest() async {
        guard let configuration = configuration() else { status = "Invalid WebDAV URL"; return }
        isWorking = true
        defer { isWorking = false }
        do {
            try await service.savePassword(password, for: configuration)
            UserDefaults.standard.set(endpoint, forKey: "bili-Pro.webdav.endpoint")
            UserDefaults.standard.set(username, forKey: "bili-Pro.webdav.username")
            UserDefaults.standard.set(remotePath, forKey: "bili-Pro.webdav.remotePath")
            try await service.testConnection(configuration: configuration)
            status = "Connection succeeded"
        } catch { status = error.localizedDescription }
    }

    private func backupDownloads() async {
        guard let configuration = configuration() else { status = "Save a valid WebDAV connection first"; return }
        isWorking = true
        defer { isWorking = false }
        do {
            try await service.upload(try await downloadStore.exportData(), configuration: configuration)
            status = "Offline download manifest backed up"
        } catch { status = error.localizedDescription }
    }

    private func restoreDownloads() async {
        guard let configuration = configuration() else { status = "Save a valid WebDAV connection first"; return }
        isWorking = true
        defer { isWorking = false }
        do {
            try await downloadStore.importData(try await service.download(configuration: configuration))
            status = "Offline download manifest restored"
        } catch { status = error.localizedDescription }
    }
}
