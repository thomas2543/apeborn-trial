// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "AppAccess",
    platforms: [.macOS(.v14), .iOS(.v17)],
    targets: [
        .target(name: "AppAccess"),
        .testTarget(name: "AppAccessTests", dependencies: ["AppAccess"]),
    ]
)
