import Foundation

struct WebDAVBackupDocument: Codable, Sendable {
    let formatVersion: Int
    let createdAt: Date
    let settings: [String: String]
    let downloadManifest: Data
}

enum WebDAVBackupDocumentCodec {
    private static let excludedFragments = [
        "password", "cookie", "sessdata", "token", "csrf", "credential", "keychain", "accesskey", "refresh"
    ]

    static func makeDocument(downloadManifest: Data, defaults: UserDefaults = .standard) -> WebDAVBackupDocument {
        var settings: [String: String] = [:]
        for (key, value) in defaults.dictionaryRepresentation() {
            let lowered = key.lowercased()
            guard !excludedFragments.contains(where: lowered.contains) else { continue }
            switch value {
            case let value as String: settings[key] = value
            case let value as NSNumber: settings[key] = value.stringValue
            default: continue
            }
        }
        return WebDAVBackupDocument(formatVersion: 1, createdAt: Date(), settings: settings, downloadManifest: downloadManifest)
    }

    static func restore(_ document: WebDAVBackupDocument, defaults: UserDefaults = .standard) throws {
        guard document.formatVersion == 1 else { throw WebDAVBackupError.unsupportedBackupVersion }
        for (key, value) in document.settings {
            let lowered = key.lowercased()
            guard !excludedFragments.contains(where: lowered.contains) else { continue }
            defaults.set(value, forKey: key)
        }
    }
}

struct WebDAVConfiguration: Codable, Equatable, Sendable {
    let baseURL: URL
    let username: String
    let remotePath: String

    init(baseURL: URL, username: String, remotePath: String = "bili-Pro-backup.json") {
        self.baseURL = baseURL
        self.username = username
        self.remotePath = remotePath.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
    }
}

enum WebDAVBackupError: LocalizedError, Equatable {
    case invalidResponse
    case unauthorized
    case server(statusCode: Int)
    case unsupportedBackupVersion

    var errorDescription: String? {
        switch self {
        case .invalidResponse: return "WebDAV returned an invalid response."
        case .unauthorized: return "WebDAV authentication failed."
        case .server(let statusCode): return "WebDAV server returned HTTP \(statusCode)."
        case .unsupportedBackupVersion: return "This backup was created by an unsupported version of bili-Pro."
        }
    }
}

actor WebDAVBackupService {
    private let session: URLSession
    private let keychain: KeychainStore

    init(session: URLSession = .shared, keychain: KeychainStore = KeychainStore(service: "bili-Pro.WebDAV")) {
        self.session = session
        self.keychain = keychain
    }

    func savePassword(_ password: String, for configuration: WebDAVConfiguration) throws {
        try keychain.save(password, for: credentialKey(for: configuration))
    }

    func deletePassword(for configuration: WebDAVConfiguration) throws {
        try keychain.delete(credentialKey(for: configuration))
    }

    func upload(_ data: Data, configuration: WebDAVConfiguration) async throws {
        let request = try makeRequest(method: "PUT", configuration: configuration)
        var requestWithBody = request
        requestWithBody.httpBody = data
        requestWithBody.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let (_, response) = try await session.data(for: requestWithBody)
        try validate(response)
    }

    func download(configuration: WebDAVConfiguration) async throws -> Data {
        let request = try makeRequest(method: "GET", configuration: configuration)
        let (data, response) = try await session.data(for: request)
        try validate(response)
        return data
    }

    func testConnection(configuration: WebDAVConfiguration) async throws {
        let request = try makeRequest(method: "OPTIONS", configuration: configuration)
        let (_, response) = try await session.data(for: request)
        try validate(response)
    }

    private func makeRequest(method: String, configuration: WebDAVConfiguration) throws -> URLRequest {
        let url = configuration.baseURL
            .appendingPathComponent(configuration.remotePath, isDirectory: false)
        var request = URLRequest(url: url)
        request.httpMethod = method
        guard let password = try keychain.read(credentialKey(for: configuration)) else {
            throw WebDAVBackupError.unauthorized
        }
        let token = Data("\(configuration.username):\(password)".utf8).base64EncodedString()
        request.setValue("Basic \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("bili-Pro", forHTTPHeaderField: "User-Agent")
        return request
    }

    private func validate(_ response: URLResponse) throws {
        guard let http = response as? HTTPURLResponse else { throw WebDAVBackupError.invalidResponse }
        switch http.statusCode {
        case 200..<300: return
        case 401, 403: throw WebDAVBackupError.unauthorized
        default: throw WebDAVBackupError.server(statusCode: http.statusCode)
        }
    }

    private func credentialKey(for configuration: WebDAVConfiguration) -> String {
        "password.\(configuration.baseURL.absoluteString).\(configuration.username)"
    }
}
