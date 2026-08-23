// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "AutoQSL",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(name: "AutoQSL", targets: ["AutoQSL"]),
        .executable(name: "AutoQSLInstaller", targets: ["AutoQSLInstaller"])
    ],
    targets: [
        .executableTarget(
            name: "AutoQSL",
            path: "Sources/AutoQSL",
            resources: [
                .process("Resources")
            ]
        ),
        .executableTarget(
            name: "AutoQSLInstaller",
            path: "Sources/AutoQSLInstaller"
        ),
        .testTarget(
            name: "AutoQSLTests",
            dependencies: ["AutoQSL"],
            path: "Tests/AutoQSLTests"
        )
    ]
)
