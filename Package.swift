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
          url: "https://github.com/ghostpass-ai/ghostpass-sdk-distribution-dev/releases/download/1.0.8/GoPassSDK.xcframework.zip",
          checksum: "0389b4a701071c65621541ca8f3a7c5fa92fd5ede3e9d91b90de21144f4ac6a0"
      )
  ]
)
