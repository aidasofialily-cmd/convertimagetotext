// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "mac-ocr",
    platforms: [.macOS(.v11)],
    targets: [
        .executableTarget(name: "mac-ocr", path: "Sources")
    ]
)
