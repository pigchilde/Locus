import XCTest
@testable import LocusCore

final class VolumeInterpolatorTests: XCTestCase {
    func testImmediateTransitionReturnsOnlyTarget() {
        XCTAssertEqual(
            VolumeInterpolator.values(from: 0.1, to: 0.8, duration: 0),
            [0.8]
        )
    }

    func testSmoothTransitionEndsExactlyAtTarget() throws {
        let values = VolumeInterpolator.values(
            from: 0.2,
            to: 0.7,
            duration: 1,
            framesPerSecond: 10
        )

        XCTAssertEqual(values.count, 10)
        XCTAssertEqual(try XCTUnwrap(values.last), 0.7, accuracy: 0.000_001)
        XCTAssertTrue(zip(values, values.dropFirst()).allSatisfy { $0 <= $1 })
    }

    func testValuesAreClampedToSystemRange() throws {
        let values = VolumeInterpolator.values(
            from: -1,
            to: 2,
            duration: 1,
            framesPerSecond: 5
        )

        XCTAssertTrue(values.allSatisfy { (0...1).contains($0) })
        XCTAssertEqual(try XCTUnwrap(values.last), 1, accuracy: 0.000_001)
    }
}
