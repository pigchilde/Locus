// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "Locus",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .library(name: "LocusCore", targets: ["LocusCore"]),
        .executable(name: "Locus", targets: ["LocusApp"])
    ],
    targets: [
        .target(
            name: "LocusCore"
        ),
        .executableTarget(
            name: "LocusApp",
            dependencies: ["LocusCore"],
            linkerSettings: [
                .linkedFramework("AppKit"),
                .linkedFramework("AudioToolbox"),
                .linkedFramework("CoreAudio"),
                .linkedFramework("CoreLocation"),
                .linkedFramework("CoreWLAN"),
                .linkedFramework("ServiceManagement"),
                .linkedFramework("UserNotifications")
            ]
        ),
        .testTarget(
            name: "LocusCoreTests",
            dependencies: ["LocusCore"]
        )
    ],
    swiftLanguageModes: [.v5]
)
