import XCTest
import LocusCore
@testable import LocusApp

final class NetworkServiceTests: XCTestCase {
    private func fixture(primary: String = "wired", family: String = "IPv4") -> [String: [String: Any]] {
        [
            "State:/Network/Global/\(family)": [
                "PrimaryService": primary,
                "PrimaryInterface": primary == "wired" ? "en9" : "en0",
                "Router": "192.168.61.254"
            ],
            "Setup:/Network/Service/wired/Interface": ["Type": "Ethernet", "DeviceName": "en9"],
            "Setup:/Network/Service/wifi/Interface": ["Type": "IEEE80211", "DeviceName": "en0"],
            "State:/Network/Service/wired/\(family)": [
                "NetworkSignature": "router-signature",
                "Router": "192.168.61.254",
                "Addresses": ["192.168.61.53"], "SubnetMasks": ["255.255.255.0"]
            ]
        ]
    }

    func testWiredPrimaryWinsWhileWiFiIsAlsoConnected() throws {
        let data = fixture()
        let connection = try XCTUnwrap(NetworkService.connection(read: { data[$0] }, ssid: { _ in
            XCTFail("Wired detection must not access Wi-Fi or require location permission")
            return "Studio"
        }))
        XCTAssertEqual(connection.kind, .ethernet)
        XCTAssertEqual(connection.interfaceName, "en9")
        XCTAssertEqual(connection.identifier, "signature:router-signature")
        XCTAssertTrue(connection.detail.contains("192.168.61.254"))
    }

    func testWiFiPrimaryWinsEvenWithWiredServiceConfigured() throws {
        let data = fixture(primary: "wifi")
        let connection = try XCTUnwrap(NetworkService.connection(read: { data[$0] }, ssid: {
            XCTAssertEqual($0, "en0")
            return "Studio"
        }))
        XCTAssertEqual(connection.kind, .wifi)
        XCTAssertEqual(connection.identifier, "Studio")
    }

    func testUnavailableSSIDStillIdentifiesWiFiInsteadOfDisconnect() throws {
        let data = fixture(primary: "wifi")
        let connection = try XCTUnwrap(NetworkService.connection(read: { data[$0] }, ssid: { _ in nil }))
        XCTAssertEqual(connection.kind, .wifi)
        XCTAssertNil(connection.identifier)
    }

    func testUnpluggingWiredAndFallingBackToWiFiChangesIdentity() {
        var data = fixture()
        let wired = NetworkService.connection(read: { data[$0] }, ssid: { _ in "Studio" })
        data = fixture(primary: "wifi")
        let wifi = NetworkService.connection(read: { data[$0] }, ssid: { _ in "Studio" })
        XCTAssertEqual(wired?.kind, .ethernet)
        XCTAssertEqual(wifi?.kind, .wifi)
        XCTAssertNotEqual(wired?.identifier, wifi?.identifier)
        data = [:]
        XCTAssertNil(NetworkService.connection(read: { data[$0] }, ssid: { _ in "Studio" }))
    }

    func testIPv6OnlyWiredPrimaryIsRecognized() {
        let data = fixture(family: "IPv6")
        XCTAssertEqual(NetworkService.connection(read: { data[$0] }, ssid: { _ in nil })?.kind, .ethernet)
    }

    func testUnrelatedInterfaceIsNotMistakenForEthernet() {
        var data = fixture()
        data["Setup:/Network/Service/wired/Interface"] = ["Type": "PPP"]
        XCTAssertNil(NetworkService.connection(read: { data[$0] }, ssid: { _ in nil }))
    }
}
