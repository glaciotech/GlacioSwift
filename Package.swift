// swift-tools-version: 5.7
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "GlacioSwift",
    platforms: [.macOS(.v11), .iOS(.v14)],
    products: [
        .library(name: "GlacioSwift", targets: ["GlacioSwift"]),
    ],
    dependencies: [
        .package(url: "https://github.com/realm/realm-swift", "10.0.0" ..< "11.0.0"),
        
        .package(url: "https://github.com/glaciotech/GlacioCore", branch: "pre-alpha-v0.14.31-rc1"),
//        .package(name: "GlacioCore", path: "../../MacOS&iOS/Glacio"),
//        .package(url: "peter-dev@raptor.local:/volume1/Git/glacio.git", branch: "master"),
//        .package(name: "GlacioCore", path: "../../Glacio/GlacioCore-Deploy"),

//        .package(name: "GlacioCore", path: "../GlacioCore-Deploy/Local"),
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.
        .target(
            name: "GlacioSwift",
            dependencies: ["GlacioCore",
                // .product(name: "GlacioCore", package: "glacio"), //Only needed with local repo as it's named "glacip" not "GlacioCore"
                .product(name: "RealmSwift", package: "realm-swift")]),
        .testTarget(
            name: "GlacioSwiftTests",
            dependencies: ["GlacioSwift"]),
    ]
)
