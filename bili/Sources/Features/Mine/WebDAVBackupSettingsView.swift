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
                Button("Back up settings and downloads") { Task { await backupDownloads() } }
                Button("Restore settings and downloads") { Task { await restoreDownloads() } }
                    .disabled(isWorking)
            } footer: {
                Text("Safe app settings and the offline download manifest are backed up. Cookies, tokens, passwords, and Keychain credentials are never exported.")
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
            let document = WebDAVBackupDocumentCodec.makeDocument(downloadManifest: try await downloadStore.exportData())
            let data = try JSONEncoder.webDAV.encode(document)
            try await service.upload(data, configuration: configuration)
            status = "Settings and download manifest backed up"
        } catch { status = error.localizedDescription }
    }

    private func restoreDownloads() async {
        guard let configuration = configuration() else { status = "Save a valid WebDAV connection first"; return }
        isWorking = true
        defer { isWorking = false }
        do {
            let data = try await service.download(configuration: configuration)
            let document = try JSONDecoder.webDAV.decode(WebDAVBackupDocument.self, from: data)
            try WebDAVBackupDocumentCodec.restore(document)
            try await downloadStore.importData(document.downloadManifest)
            status = "Settings and download manifest restored"
        } catch { status = error.localizedDescription }
    }
}

private extension JSONEncoder {
    static var webDAV: JSONEncoder {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }
}

private extension JSONDecoder {
    static var webDAV: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }
}
