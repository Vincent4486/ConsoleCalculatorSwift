// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "ConsoleCalculatorSwift",
    products: [
        // Provide an executable product so `swift run` can run the calculator.
        .executable(
            name: "ConsoleCalculatorSwift",
            targets: ["ConsoleCalculatorSwift"]
        ),
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .executableTarget(
            name: "ConsoleCalculatorSwift"
        ),
        .testTarget(
            name: "ConsoleCalculatorSwiftTests",
            dependencies: ["ConsoleCalculatorSwift"]
        ),
    ]
)
