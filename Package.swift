// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "AppleSignin",
    platforms: [
        .iOS(.v10),
    ],
    products: [
        .library(
            name: "AppleSignin",
            targets: ["AppleSignin"]),
    ],
    dependencies: [
    ],
    targets: [
        .target(
            name: "AppleSignin",
            dependencies: []),
        .testTarget(
            name: "AppleSigninTests",
            dependencies: ["AppleSignin"]),
    ]
)
