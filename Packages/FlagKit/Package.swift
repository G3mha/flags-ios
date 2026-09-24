// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "FlagKit",
    defaultLocalization: "en",
    platforms: [.iOS(.v17), .watchOS(.v10), .macOS(.v14)],
    products: [
        .library(name: "FlagKit", targets: ["FlagKit"]),
    ],
    targets: [
        .target(name: "FlagKit"),
        .testTarget(name: "FlagKitTests", dependencies: ["FlagKit"]),
    ]
)
