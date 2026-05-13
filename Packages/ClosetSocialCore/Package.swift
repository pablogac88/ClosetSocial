// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "ClosetSocialCore",
    platforms: [
        .iOS(.v17)
    ],
    products: [
        .library(name: "Domain", targets: ["Domain"]),
        .library(name: "Networking", targets: ["Networking"]),
        .library(name: "Data", targets: ["Data"]),
        .library(name: "DesignSystem", targets: ["DesignSystem"]),
        .library(name: "AuthFeature", targets: ["AuthFeature"]),
        .library(name: "TimelineFeature", targets: ["TimelineFeature"]),
        .library(name: "ClosetFeature", targets: ["ClosetFeature"]),
        .library(name: "OutfitsFeature", targets: ["OutfitsFeature"]),
        .library(name: "ProfileFeature", targets: ["ProfileFeature"]),
        .library(name: "AppShell", targets: ["AppShell"])
    ],
    targets: [
        .target(name: "Domain", path: "Sources/Domain"),
        .target(name: "Networking", path: "Sources/Networking"),
        .target(
            name: "Data",
            dependencies: ["Domain", "Networking"],
            path: "Sources/Data"
        ),
        .target(
            name: "DesignSystem",
            dependencies: ["Domain"],
            path: "Sources/DesignSystem"
        ),
        .target(
            name: "AuthFeature",
            dependencies: ["Domain", "DesignSystem"],
            path: "Sources/AuthFeature"
        ),
        .target(
            name: "TimelineFeature",
            dependencies: ["Domain", "DesignSystem"],
            path: "Sources/TimelineFeature"
        ),
        .target(
            name: "ClosetFeature",
            dependencies: ["Domain", "DesignSystem"],
            path: "Sources/ClosetFeature"
        ),
        .target(
            name: "OutfitsFeature",
            dependencies: ["Domain", "DesignSystem"],
            path: "Sources/OutfitsFeature"
        ),
        .target(
            name: "ProfileFeature",
            dependencies: ["Domain", "DesignSystem"],
            path: "Sources/ProfileFeature"
        ),
        .target(
            name: "AppShell",
            dependencies: [
                "Domain",
                "Data",
                "Networking",
                "DesignSystem",
                "AuthFeature",
                "TimelineFeature",
                "ClosetFeature",
                "OutfitsFeature",
                "ProfileFeature"
            ],
            path: "Sources/AppShell"
        ),
        .testTarget(
            name: "DomainTests",
            dependencies: ["Domain"],
            path: "Tests/DomainTests"
        ),
        .testTarget(
            name: "DataTests",
            dependencies: ["Data", "Domain", "Networking"],
            path: "Tests/DataTests"
        )
    ]
)
