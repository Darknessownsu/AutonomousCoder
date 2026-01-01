// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

/*
 MIT License
 
 Copyright (c) 2025 Autonomous Coder Project
 
 Permission is hereby granted, free of charge, to any person obtaining a copy
 of this software and associated documentation files (the "Software"), to deal
 in the Software without restriction, including without limitation the rights
 to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 copies of the Software, and to permit persons to whom the Software is
 furnished to do so, subject to the following conditions:
 
 The above copyright notice and this permission notice shall be included in all
 copies or substantial portions of the Software.
 
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 SOFTWARE.
 */

import PackageDescription

let package = Package(
    name: "AutonomousCoder",
    defaultLocalization: "en",
    platforms: [
        .macOS(.v13),
        .iOS(.v16),
        .macCatalyst(.v16)
    ],
    products: [
        .library(
            name: "AutonomousCoderCore",
            targets: ["AutonomousCoderCore"]
        ),
        .library(
            name: "AutonomousCoderAI",
            targets: ["AutonomousCoderAI"]
        ),
        .library(
            name: "AutonomousCoderData",
            targets: ["AutonomousCoderData"]
        ),
        .library(
            name: "AutonomousCoderSecurity",
            targets: ["AutonomousCoderSecurity"]
        ),
        .library(
            name: "AutonomousCoderMonitoring",
            targets: ["AutonomousCoderMonitoring"]
        ),
        .library(
            name: "AutonomousCoderOrchestration",
            targets: ["AutonomousCoderOrchestration"]
        ),
        .executable(
            name: "AutonomousCoderCLI",
            targets: ["AutonomousCoderCLI"]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-log.git", from: "1.5.0"),
        .package(url: "https://github.com/apple/swift-nio.git", from: "2.62.0"),
        .package(url: "https://github.com/apple/swift-async-algorithms.git", from: "1.0.0"),
        .package(url: "https://github.com/apple/swift-collections.git", from: "1.1.0"),
        .package(url: "https://github.com/apple/swift-system.git", from: "1.3.0"),
        .package(url: "https://github.com/vapor/fluent.git", from: "4.8.0"),
        .package(url: "https://github.com/vapor/sqlite-kit.git", from: "4.0.0"),
        .package(url: "https://github.com/swift-server/swift-service-lifecycle.git", from: "2.4.0")
    ],
    targets: [
        // MARK: - Core Module
        .target(
            name: "AutonomousCoderCore",
            dependencies: [
                .product(name: "Logging", package: "swift-log"),
                .product(name: "System", package: "swift-system")
            ],
            path: "Shared/Sources/Core",
            swiftSettings: [
                .enableExperimentalFeature("StrictConcurrency"),
                .define("SWIFT_CONCURRENCY_COOPERATIVE_QUEUE")
            ]
        ),
        
        // MARK: - AI Module
        .target(
            name: "AutonomousCoderAI",
            dependencies: [
                "AutonomousCoderCore",
                "AutonomousCoderData",
                .product(name: "Logging", package: "swift-log"),
                .product(name: "Collections", package: "swift-collections")
            ],
            path: "Shared/Sources/AI",
            swiftSettings: [
                .enableExperimentalFeature("StrictConcurrency"),
                .define("SWIFT_CONCURRENCY_COOPERATIVE_QUEUE")
            ]
        ),
        
        // MARK: - Data Module
        .target(
            name: "AutonomousCoderData",
            dependencies: [
                "AutonomousCoderCore",
                .product(name: "Logging", package: "swift-log"),
                .product(name: "NIO", package: "swift-nio"),
                .product(name: "Fluent", package: "fluent"),
                .product(name: "SQLiteKit", package: "sqlite-kit")
            ],
            path: "Shared/Sources/Data",
            swiftSettings: [
                .enableExperimentalFeature("StrictConcurrency"),
                .define("SWIFT_CONCURRENCY_COOPERATIVE_QUEUE")
            ]
        ),
        
        // MARK: - Security Module
        .target(
            name: "AutonomousCoderSecurity",
            dependencies: [
                "AutonomousCoderCore",
                .product(name: "Logging", package: "swift-log"),
                .product(name: "System", package: "swift-system")
            ],
            path: "Shared/Sources/Security",
            swiftSettings: [
                .enableExperimentalFeature("StrictConcurrency"),
                .define("SWIFT_CONCURRENCY_COOPERATIVE_QUEUE")
            ]
        ),
        
        // MARK: - Monitoring Module
        .target(
            name: "AutonomousCoderMonitoring",
            dependencies: [
                "AutonomousCoderCore",
                "AutonomousCoderData",
                .product(name: "Logging", package: "swift-log")
            ],
            path: "Shared/Sources/Monitoring",
            swiftSettings: [
                .enableExperimentalFeature("StrictConcurrency"),
                .define("SWIFT_CONCURRENCY_COOPERATIVE_QUEUE")
            ]
        ),
        
        // MARK: - Orchestration Module
        .target(
            name: "AutonomousCoderOrchestration",
            dependencies: [
                "AutonomousCoderCore",
                "AutonomousCoderAI",
                "AutonomousCoderData",
                "AutonomousCoderSecurity",
                "AutonomousCoderMonitoring",
                .product(name: "Logging", package: "swift-log"),
                .product(name: "AsyncAlgorithms", package: "swift-async-algorithms"),
                .product(name: "ServiceLifecycle", package: "swift-service-lifecycle")
            ],
            path: "Shared/Sources/Orchestration",
            swiftSettings: [
                .enableExperimentalFeature("StrictConcurrency"),
                .define("SWIFT_CONCURRENCY_COOPERATIVE_QUEUE")
            ]
        ),
        
        // MARK: - CLI Executable
        .executableTarget(
            name: "AutonomousCoderCLI",
            dependencies: [
                "AutonomousCoderCore",
                "AutonomousCoderAI",
                "AutonomousCoderData",
                "AutonomousCoderSecurity",
                "AutonomousCoderMonitoring",
                "AutonomousCoderOrchestration",
                .product(name: "Logging", package: "swift-log"),
                .product(name: "ServiceLifecycle", package: "swift-service-lifecycle")
            ],
            path: "Shared/Sources/CLI",
            swiftSettings: [
                .enableExperimentalFeature("StrictConcurrency"),
                .define("SWIFT_CONCURRENCY_COOPERATIVE_QUEUE")
            ]
        ),
        
        // MARK: - Test Targets
        .testTarget(
            name: "AutonomousCoderCoreTests",
            dependencies: ["AutonomousCoderCore"],
            path: "Tests/Unit/Core"
        ),
        .testTarget(
            name: "AutonomousCoderAITests",
            dependencies: ["AutonomousCoderAI", "AutonomousCoderCore"],
            path: "Tests/Unit/AI"
        ),
        .testTarget(
            name: "AutonomousCoderDataTests",
            dependencies: ["AutonomousCoderData", "AutonomousCoderCore"],
            path: "Tests/Unit/Data"
        ),
        .testTarget(
            name: "AutonomousCoderSecurityTests",
            dependencies: ["AutonomousCoderSecurity", "AutonomousCoderCore"],
            path: "Tests/Unit/Security"
        ),
        .testTarget(
            name: "AutonomousCoderIntegrationTests",
            dependencies: [
                "AutonomousCoderCore",
                "AutonomousCoderAI",
                "AutonomousCoderData",
                "AutonomousCoderSecurity",
                "AutonomousCoderMonitoring",
                "AutonomousCoderOrchestration"
            ],
            path: "Tests/Integration"
        ),
        .testTarget(
            name: "AutonomousCoderSystemTests",
            dependencies: [
                "AutonomousCoderCore",
                "AutonomousCoderAI",
                "AutonomousCoderData",
                "AutonomousCoderSecurity",
                "AutonomousCoderMonitoring",
                "AutonomousCoderOrchestration"
            ],
            path: "Tests/System"
        )
    ]
)