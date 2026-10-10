// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "MoveB",
    platforms: [.macOS(.v13)],
    targets: [
        .executableTarget(name: "MoveB", path: "Sources/MoveB")
    ]
)
