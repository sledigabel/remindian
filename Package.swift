// swift-tools-version: 6.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "remindian",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .library(name: "RemindianCore", targets: ["RemindianCore"]),
        .executable(name: "remindian", targets: ["remindian"])
    ],
    targets: [
        .target(
            name: "RemindianCore",
            path: "Sources/RemindianCore"
        ),
        .executableTarget(
            name: "remindian",
            dependencies: ["RemindianCore"],
            path: "Sources/CLI"
        ),
        .testTarget(
            name: "RemindianCoreTests",
            dependencies: ["RemindianCore"],
            path: "Tests/RemindianCoreTests",
            resources: [
                .process("Fixtures")
            ]
        )
    ]
)
