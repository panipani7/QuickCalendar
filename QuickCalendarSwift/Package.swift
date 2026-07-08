// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "QuickCalendar",
    platforms: [.macOS(.v13)],
    targets: [
        .executableTarget(
            name: "QuickCalendar",
            path: "Sources/QuickCalendar"
        )
    ]
)
