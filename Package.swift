// swift-tools-version: 5.9
import PackageDescription

let package = Package(
  name: "GoPassSDK-Dev",
  platforms: [.iOS(.v15)],
  products: [
      .library(name: "GoPassSDK", targets: ["GoPassSDK"])
  ],
  targets: [
      .binaryTarget(
          name: "GoPassSDK",
          url: "https://github.com/ghostpass-ai/ghostpass-sdk-distribution-dev/releases/download/1.0.2/GoPassSDK.xcframework.zip",
          checksum: "28fa48573ca1955510398f82bd3fe1b5967890b984fc7eba246457810086139b"
      )
  ]
)
