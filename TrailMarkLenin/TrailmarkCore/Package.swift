// swift-tools-version: 6.3
import PackageDescription

let package = Package(
    name: "TrailmarkCore",
    platforms: [
        .iOS(.v17),
        .macOS(.v14)
    ],
    products: [
        .library(
            name: "TrailmarkCore",
            targets: ["TrailmarkCore"]),
    ],
    targets: [
        .target(
            name: "TrailmarkCore"),
    ]
)
