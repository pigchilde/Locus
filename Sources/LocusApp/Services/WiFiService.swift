import CoreWLAN
import Foundation

final class WiFiService: NSObject, CWEventDelegate {
    private let client = CWWiFiClient.shared()
    private var onChange: ((String?) -> Void)?

    var currentSSID: String? {
        client.interface()?.ssid()
    }

    func startMonitoring(onChange: @escaping (String?) -> Void) throws {
        self.onChange = onChange
        client.delegate = self
        try client.startMonitoringEvent(with: .ssidDidChange)
        onChange(currentSSID)
    }

    func stopMonitoring() {
        try? client.stopMonitoringAllEvents()
        client.delegate = nil
        onChange = nil
    }

    func ssidDidChangeForWiFiInterface(withName interfaceName: String) {
        onChange?(currentSSID)
    }

    func clientConnectionInterrupted() {
        onChange?(currentSSID)
    }

    deinit {
        stopMonitoring()
    }
}
