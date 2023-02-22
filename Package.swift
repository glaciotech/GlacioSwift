// swift-tools-version: 5.7
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "GlacioSwift",
    platforms: [.macOS("10.15"), .iOS(.v13)],
    products: [
        .library(name: "GlacioSwift", targets: ["GlacioSwift"]),
    ],
    dependencies: [
//        .package(url: "https://github.com/glaciotech/GlacioCore", branch: "master"),
        .package(name: "GlacioCore", path: "../../MacOS&iOS/Glacio"),
        .package(url: "https://github.com/realm/realm-swift", "10.0.0" ..< "11.0.0"),
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.
        .target(
            name: "GlacioSwift",
            dependencies: ["GlacioCore", .product(name: "RealmSwift", package: "realm-swift")]),
        .testTarget(
            name: "GlacioSwiftTests",
            dependencies: ["GlacioSwift"]),
    ]
)
