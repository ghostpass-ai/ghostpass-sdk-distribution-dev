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
          url: "https://github.com/ghostpass-ai/ghostpass-sdk-distribution-dev/releases/download/1.1.2/GoPassSDK.xcframework.zip",
          checksum: "e537d8f994f1090dbd080baca5a785e495f5cd12fbde494caecdab3a2fedff23"
      )
  ]
)
