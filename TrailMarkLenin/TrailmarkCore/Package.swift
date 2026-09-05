// swift-tools-version: 6.3
import PackageDescription

let package = Package(
    name: "TrailmarkCore",
    platforms: [
        .iOS(.v17),
        .watchOS(.v10)
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
