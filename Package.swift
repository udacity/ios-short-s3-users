// swift-tools-version:3.1
import Foundation
import PackageDescription

let package = Package(
    name: "UsersService",

    targets: [
        Target(name: "UsersService"),
        Target(name: "UsersServer", dependencies: ["UsersService"]),
    ],

    dependencies: [
        .Package(url: "https://github.com/IBM-Swift/Kitura.git", majorVersion: 1, minor: 7),
        .Package(url: "https://github.com/IBM-Swift/HeliumLogger.git", majorVersion: 1, minor: 7),
        //.Package(url: "https://github.com/nicholasjackson/swift-mysql.git", majorVersion: 1, minor: 7)
        .Package(url: "https://github.com/jarrodparkes/swift-mysql", majorVersion: 1, minor: 7),
        .Package(url: "https://github.com/PerfectlySoft/Perfect-Crypto.git", majorVersion: 1)
    ]
)

if ProcessInfo.processInfo.environment["TEST"] != nil {
    package.targets.append(Target(name: "UsersTests", dependencies: ["UsersService"]))
    package.targets.append(Target(name: "FunctionalTests"))
    package.dependencies.append(.Package(
        url: "https://github.com/nicholasjackson/kitura-http-test.git",
        majorVersion: 0,
        minor: 2)
    )
}
