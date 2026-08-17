import Foundation
import Network

struct DLNADevice: Codable, Equatable, Identifiable, Sendable {
    let id: String
    let name: String
    let location: URL
    let controlURL: URL?
}

enum DLNAError: LocalizedError {
    case discoveryFailed
    case unsupportedDevice
    case requestFailed

    var errorDescription: String? {
        switch self {
        case .discoveryFailed: return "未发现 DLNA 设备，请确认设备与手机在同一局域网。"
        case .unsupportedDevice: return "该设备不支持视频投屏。"
        case .requestFailed: return "DLNA 投屏请求失败。"
        }
    }
}

actor DLNAService {
    private let session: URLSession

    init(session: URLSession = .shared) {
        self.session = session
    }

    func discover(timeout: TimeInterval = 3) async throws -> [DLNADevice] {
        try await withCheckedThrowingContinuation { continuation in
            let connection = NWConnection(
                host: NWEndpoint.Host("239.255.255.250"),
                port: NWEndpoint.Port(rawValue: 1900)!,
                using: .udp
            )
            let queue = DispatchQueue(label: "bili-Pro.dlna.discovery")
            let request = "M-SEARCH * HTTP/1.1\r\nHOST: 239.255.255.250:1900\r\nMAN: \"ssdp:discover\"\r\nMX: 2\r\nST: urn:schemas-upnp-org:device:MediaRenderer:1\r\n\r\n"
            var responses = [String: DLNADevice]()
            var didFinish = false

            func finish(_ result: Result<[DLNADevice], Error>) {
                guard !didFinish else { return }
                didFinish = true
                connection.cancel()
                continuation.resume(with: result)
            }

            connection.stateUpdateHandler = { state in
                if case .ready = state {
                    connection.send(content: Data(request.utf8), completion: .contentProcessed { error in
                        if let error { finish(.failure(error)) }
                    })
                    receive()
                } else if case .failed(let error) = state {
                    finish(.failure(error))
                }
            }

            func receive() {
                connection.receiveMessage { data, _, _, error in
                    if let data, let response = String(data: data, encoding: .utf8),
                       let device = Self.parseDevice(response),
                       responses[device.id] == nil {
                        responses[device.id] = device
                    }
                    if let error, (error as NSError).code != 57 {
                        finish(.failure(error))
                    } else if !didFinish {
                        receive()
                    }
                }
            }

            connection.start(queue: queue)
            queue.asyncAfter(deadline: .now() + timeout) {
                finish(.success(Array(responses.values).sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }))
            }
        }
    }

    func play(url: URL, on device: DLNADevice) async throws {
        let resolvedDevice = try await resolve(device)
        guard let controlURL = resolvedDevice.controlURL else { throw DLNAError.unsupportedDevice }
        let escapedURL = url.absoluteString.replacingOccurrences(of: "&", with: "&amp;")
        let body = """
        <?xml version="1.0" encoding="utf-8"?>
        <s:Envelope xmlns:s="http://schemas.xmlsoap.org/soap/envelope/" s:encodingStyle="http://schemas.xmlsoap.org/soap/encoding/"><s:Body><u:SetAVTransportURI xmlns:u="urn:schemas-upnp-org:service:AVTransport:1"><InstanceID>0</InstanceID><CurrentURI>\(escapedURL)</CurrentURI><CurrentURIMetaData></CurrentURIMetaData></u:SetAVTransportURI></s:Body></s:Envelope>
        """
        var request = URLRequest(url: controlURL)
        request.httpMethod = "POST"
        request.httpBody = Data(body.utf8)
        request.setValue("text/xml; charset=\"utf-8\"", forHTTPHeaderField: "Content-Type")
        request.setValue("\"urn:schemas-upnp-org:service:AVTransport:1#SetAVTransportURI\"", forHTTPHeaderField: "SOAPAction")
        let (_, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            throw DLNAError.requestFailed
        }
    }

    func resolve(_ device: DLNADevice) async throws -> DLNADevice {
        let (data, response) = try await session.data(from: device.location)
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode),
              let xml = String(data: data, encoding: .utf8)
        else { throw DLNAError.requestFailed }
        let friendlyName = Self.xmlValue("friendlyName", in: xml) ?? device.name
        let serviceBlock = Self.serviceBlock(for: "urn:schemas-upnp-org:service:AVTransport:1", in: xml)
        let controlPath = serviceBlock.flatMap { Self.xmlValue("controlURL", in: $0) }
        let controlURL = controlPath.flatMap { URL(string: $0, relativeTo: device.location)?.absoluteURL }
        return DLNADevice(id: device.id, name: friendlyName, location: device.location, controlURL: controlURL)
    }

    private static func parseDevice(_ response: String) -> DLNADevice? {
        let headers = response.split(separator: "\n").reduce(into: [String: String]()) { result, line in
            let parts = line.split(separator: ":", maxSplits: 1).map(String.init)
            guard parts.count == 2 else { return }
            result[parts[0].trimmingCharacters(in: .whitespacesAndNewlines).lowercased()] = parts[1].trimmingCharacters(in: .whitespacesAndNewlines)
        }
        guard let locationString = headers["location"], let location = URL(string: locationString) else { return nil }
        let id = headers["usn"] ?? location.absoluteString
        let name = headers["server"] ?? location.host ?? "DLNA 设备"
        return DLNADevice(id: id, name: name, location: location, controlURL: nil)
    }

    private static func serviceBlock(for serviceType: String, in xml: String) -> String? {
        let escaped = NSRegularExpression.escapedPattern(for: serviceType)
        let pattern = "<service>(?:(?!</service>).)*<serviceType>\\s*\(escaped)\\s*</serviceType>(?:(?!</service>).)*</service>"
        guard let expression = try? NSRegularExpression(pattern: pattern, options: [.dotMatchesLineSeparators]),
              let match = expression.firstMatch(in: xml, range: NSRange(xml.startIndex..., in: xml)),
              let range = Range(match.range, in: xml)
        else { return nil }
        return String(xml[range])
    }

    private static func xmlValue(_ tag: String, in xml: String) -> String? {
        let pattern = "<\(tag)>\\s*([^<]+?)\\s*</\(tag)>"
        guard let expression = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive, .dotMatchesLineSeparators]),
              let match = expression.firstMatch(in: xml, range: NSRange(xml.startIndex..., in: xml)),
              let range = Range(match.range(at: 1), in: xml)
        else { return nil }
        return String(xml[range]).trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
