// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "FotMobMenuBar",
    platforms: [.macOS(.v13)],
    products: [
        .executable(name: "FotMobMenuBar", targets: ["FotMobMenuBar"])
    ],
    targets: [
        .executableTarget(name: "FotMobMenuBar")
    ]
)
