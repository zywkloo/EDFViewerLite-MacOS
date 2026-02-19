// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "EDFViewer-MacOS",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(name: "EDFViewerMac", targets: ["EDFViewerMac"])
    ],
    targets: [
        .executableTarget(
            name: "EDFViewerMac",
            path: "Sources/EDFViewerMac"
        )
    ]
)
