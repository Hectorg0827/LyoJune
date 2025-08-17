// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "LyoAppNewUI",
    platforms: [
        .iOS(.v17)
    ],
    products: [
        .executable(
            name: "LyoApp",
            targets: ["LyoApp"]
        )
    ],
    dependencies: [
        // Future dependencies can be added here. For example:
        // .package(url: "https://github.com/facebook/facebook-ios-sdk.git", from: "17.0.0"),
        // .package(url: "https://github.com/google/GoogleSignIn-iOS.git", from: "7.1.0"),
    ],
    targets: [
        .executableTarget(
            name: "LyoApp",
            dependencies: [
                // When dependencies are added above, link them here. e.g.:
                // .product(name: "FacebookLogin", package: "facebook-ios-sdk"),
                // .product(name: "GoogleSignIn", package: "GoogleSignIn-iOS"),
            ],
            path: "Lyo",
            // Exclude directories that are not source code or are handled separately.
            exclude: [
                "Tests",
                "UITests"
            ],
            resources: [
                // This makes Config.plist available to the app's bundle.
                .process("Config/Config.plist"),
                // This copies the MLModels directory into the app's bundle.
                .copy("Resources/MLModels")
            ]
        ),
        .testTarget(
            name: "Tests",
            dependencies: ["LyoApp"],
            path: "Tests"
        ),
        // Note: SPM does not have direct support for UI Test targets for iOS apps yet.
        // The UITests target needs to be created and configured manually within Xcode after
        // opening the Swift Package. This will be documented in the README.
    ]
)
