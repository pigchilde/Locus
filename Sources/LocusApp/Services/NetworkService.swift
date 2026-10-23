import CoreWLAN
import Foundation
import LocusCore
import SystemConfiguration

/// All reads and callbacks run on the main queue. CoreWLAN supplies SSIDs only;
/// SystemConfiguration supplies the selected service and wired network identity.
final class NetworkService: NSObject, CWEventDelegate {
    private let client = CWWiFiClient.shared()
    private var store: SCDynamicStore?
    private var onChange: ((NetworkConnection?) -> Void)?

    var currentConnection: NetworkConnection? {
        guard let store else { return nil }
        return Self.connection(
            read: { SCDynamicStoreCopyValue(store, $0 as CFString) as? [String: Any] },
            ssid: { self.client.interface(withName: $0)?.ssid() })
    }

    static func connection(read: (String) -> [String: Any]?, ssid: (String) -> String?) -> NetworkConnection? {
        // Prefer the system IPv4 primary service; IPv6-only networks use IPv6.
        for family in ["IPv4", "IPv6"] {
            guard let global = read("State:/Network/Global/\(family)"),
                  let serviceID = global["PrimaryService"] as? String,
                  let interfaceName = global["PrimaryInterface"] as? String,
                  let interface = read("Setup:/Network/Service/\(serviceID)/Interface")
            else { continue }

            let type = interface["Type"] as? String
            let hardware = interface["Hardware"] as? String
            // The dynamic store uses Type=Ethernet for Wi-Fi too; Hardware=AirPort
            // distinguishes it. Check this before the wired branch, independently of
            // SSID access, interface numbering, and the user-editable service name.
            if hardware == (kSCEntNetAirPort as String)
                || type == (kSCNetworkInterfaceTypeIEEE80211 as String) {
                let ssid = ssid(interfaceName)
                return NetworkConnection(kind: .wifi, identifier: ssid,
                    name: ssid ?? "无法读取 Wi‑Fi 名称", interfaceName: interfaceName)
            }
            guard type == (kSCNetworkInterfaceTypeEthernet as String) else { continue }
            let state = read("State:/Network/Service/\(serviceID)/\(family)") ?? [:]
            let router = state["Router"] as? String ?? global["Router"] as? String
            let identifier = NetworkConnection.ethernetIdentifier(
                signature: state["NetworkSignature"] as? String,
                router: router,
                address: (state["Addresses"] as? [String])?.first,
                subnetMask: (state["SubnetMasks"] as? [String])?.first
            )
            return NetworkConnection(kind: .ethernet, identifier: identifier,
                name: "有线网络", interfaceName: interfaceName,
                detail: router.map { "网关 \($0) · \(interfaceName)" } ?? interfaceName)
        }
        return nil
    }

    func startMonitoring(onChange: @escaping (NetworkConnection?) -> Void) throws {
        stopMonitoring()
        self.onChange = onChange
        var context = SCDynamicStoreContext(version: 0,
            info: Unmanaged.passUnretained(self).toOpaque(),
            retain: nil, release: nil, copyDescription: nil)
        guard let store = SCDynamicStoreCreate(nil, "Locus.Network" as CFString, { _, _, info in
            guard let info else { return }
            Unmanaged<NetworkService>.fromOpaque(info).takeUnretainedValue().publish()
        }, &context) else { throw NetworkError.monitorUnavailable }
        self.store = store
        let keys = ["State:/Network/Global/IPv4", "State:/Network/Global/IPv6"]
        let patterns = ["State:/Network/Service/.*/IPv4", "State:/Network/Service/.*/IPv6",
                        "State:/Network/Interface/.*/Link", "Setup:/Network/Service/.*"]
        guard SCDynamicStoreSetNotificationKeys(store, keys as CFArray, patterns as CFArray),
              SCDynamicStoreSetDispatchQueue(store, DispatchQueue.main) else {
            stopMonitoring()
            throw NetworkError.monitorUnavailable
        }
        client.delegate = self
        // Missing/disabled Wi-Fi must not prevent wired monitoring.
        try? client.startMonitoringEvent(with: .ssidDidChange)
        publish()
    }

    func stopMonitoring() {
        if let store { SCDynamicStoreSetDispatchQueue(store, nil) }
        store = nil
        try? client.stopMonitoringAllEvents()
        client.delegate = nil
        onChange = nil
    }

    func ssidDidChangeForWiFiInterface(withName interfaceName: String) {
        DispatchQueue.main.async { [weak self] in self?.publish() }
    }

    func clientConnectionInterrupted() {
        DispatchQueue.main.async { [weak self] in self?.publish() }
    }

    private func publish() { onChange?(currentConnection) }

    deinit { stopMonitoring() }

    private enum NetworkError: LocalizedError {
        case monitorUnavailable
        var errorDescription: String? { "无法启动系统网络监听，请重新打开 Locus。" }
    }
}
