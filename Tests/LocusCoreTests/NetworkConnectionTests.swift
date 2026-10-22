import XCTest
@testable import LocusCore

final class NetworkConnectionTests: XCTestCase {
    func testRouterSignatureDistinguishesNetworksWithTheSamePrivateGateway() {
        let office = NetworkConnection.ethernetIdentifier(
            signature: "IPv4.Router=192.168.1.1;IPv4.RouterHardwareAddress=00:11:22:33:44:55",
            router: "192.168.1.1", address: "192.168.1.2", subnetMask: "255.255.255.0")
        let home = NetworkConnection.ethernetIdentifier(
            signature: "IPv4.Router=192.168.1.1;IPv4.RouterHardwareAddress=00:11:22:33:44:66",
            router: "192.168.1.1", address: "192.168.1.2", subnetMask: "255.255.255.0")
        XCTAssertNotEqual(office, home)
    }

    func testFallbackIdentitySurvivesDHCPAddressChanges() {
        let first = NetworkConnection.ethernetIdentifier(signature: nil,
            router: "192.168.61.254", address: "192.168.61.53", subnetMask: "255.255.255.0")
        let renewed = NetworkConnection.ethernetIdentifier(signature: nil,
            router: "192.168.61.254", address: "192.168.61.99", subnetMask: "255.255.255.0")
        XCTAssertNotNil(first)
        XCTAssertEqual(first, renewed)
    }

    func testMissingNetworkInformationDoesNotInventAnIdentity() {
        XCTAssertNil(NetworkConnection.ethernetIdentifier(signature: "", router: nil,
            address: "169.254.1.2", subnetMask: "255.255.0.0"))
    }

    func testIPv6OnlyGatewayCanBeIdentified() {
        XCTAssertEqual(NetworkConnection.ethernetIdentifier(signature: nil,
            router: "fe80::1", address: "2001:db8::2", subnetMask: nil), "router:fe80::1")
    }
}
