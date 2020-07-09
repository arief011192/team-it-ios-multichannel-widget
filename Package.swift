// swift-tools-version:5.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "MultichannelWidget",
    platforms: [
        .iOS(.v10)
    ],
    products: [
        // Products define the executables and libraries produced by a package, and make them visible to other packages.
        .library(
            name: "MultichannelWidget",
            targets: ["MultichannelWidget"]),
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        .package(url: "https://github.com/SwiftyJSON/SwiftyJSON", from: "5.0.0"),
        .package(url: "https://github.com/Alamofire/Alamofire.git", .upToNextMajor(from: "4.9.0")),
        .package(url: "https://github.com/Alamofire/AlamofireImage.git", .upToNextMajor(from: "3.6.0")),
        .package(url: "https://github.com/SDWebImage/SDWebImage.git", from: "5.1.0"),
        .package(url: "https://github.com/Qiscus-Integration/QiscusCoreApi.git", .branch ("spm"))
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages which this package depends on.
        .target(
            name: "MultichannelWidget",
            dependencies: ["SwiftyJSON", "Alamofire", "AlamofireImage", "SDWebImage", "QiscusCoreAPI"],
            resources: [
                .bundle(name: "MultichannelWidget", content: [
                    "Sources/MultichannelWidget/**/*.{h,m,swift,xib}": .resource
                ]),
                .include(content: [
                    "Sources/MultichannelWidget/**/*.png": .xcassets
                ])
            ]
        ),
        .testTarget(
            name: "MultichannelWidgetTests",
            dependencies: ["MultichannelWidget"]),
    ]
)
