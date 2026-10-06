// swift-tools-version: 6.2

import PackageDescription

let swiftSettings: [SwiftSetting] = [
    .unsafeFlags([
        "-Xfrontend", "-internalize-at-link",
        "-Xfrontend", "-lto=llvm-full",
        "-Xfrontend", "-conditional-runtime-records"
    ])
]

let linkerSettings: [LinkerSetting] = [
    .unsafeFlags(["-Xlinker", "-dead_strip"])
]

let runtimeDependency: Target.Dependency = .product(
    name: "SwiftGodotRuntime",
    package: "SwiftGodotBinary"
)

let package = Package(
    name: "GodotAdMob",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [
        .library(name: "GodotAdMob", type: .dynamic, targets: ["GodotAdMob"]),
    ],
    dependencies: [
        .package(url: "https://github.com/migueldeicaza/SwiftGodotBinary", revision: "bf7cd9cb51b30039199c47811c486976923af93e"),
        .package(url: "https://github.com/googleads/swift-package-manager-google-mobile-ads.git", from: "11.0.0"),
    ],
    targets: [
        .target(
            name: "GodotAdMob",
            dependencies: [
                runtimeDependency,
                .product(name: "GoogleMobileAds", package: "swift-package-manager-google-mobile-ads", condition: .when(platforms: [.iOS])),
            ],
            swiftSettings: swiftSettings,
            linkerSettings: linkerSettings
        ),
    ]
)
