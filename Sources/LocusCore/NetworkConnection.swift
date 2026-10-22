import Foundation

public enum NetworkKind: String, Codable, CaseIterable, Identifiable, Sendable {
    case wifi
    case ethernet

    public var id: String { rawValue }
    public var displayName: String { self == .wifi ? "Wi‑Fi" : "有线网络" }
    public var symbol: String { self == .wifi ? "wifi" : "network" }
}

/// The physical network selected by macOS, independently of Internet reachability.
public struct NetworkConnection: Equatable, Sendable {
    public let kind: NetworkKind
    public let identifier: String?
    public let name: String
    public let interfaceName: String
    public let detail: String

    public init(kind: NetworkKind, identifier: String?, name: String,
                interfaceName: String, detail: String = "") {
        self.kind = kind
        self.identifier = identifier
        self.name = name
        self.interfaceName = interfaceName
        self.detail = detail
    }

    /// Prefer macOS's router signature (includes the router hardware address).
    /// The fallback uses the gateway and subnet, never the DHCP host address or adapter name.
    public static func ethernetIdentifier(signature: String?, router: String?,
                                          address: String?, subnetMask: String?) -> String? {
        if let signature, !signature.isEmpty { return "signature:\(signature)" }
        guard let router, !router.isEmpty else { return nil }
        if let address, let subnetMask,
           let host = ipv4Octets(address), let mask = ipv4Octets(subnetMask) {
            let subnet = zip(host, mask).map { String($0 & $1) }.joined(separator: ".")
            return "ipv4:\(router);subnet=\(subnet)/\(subnetMask)"
        }
        return "router:\(router)"
    }

    private static func ipv4Octets(_ value: String) -> [UInt8]? {
        let parts = value.split(separator: ".", omittingEmptySubsequences: false)
        let octets = parts.compactMap { UInt8($0) }
        return parts.count == 4 && octets.count == 4 ? octets : nil
    }
}
