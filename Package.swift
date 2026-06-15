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
          url: "https://github.com/ghostpass-ai/ghostpass-sdk-distribution-dev/releases/download/1.0.6/GoPassSDK.xcframework.zip",
          checksum: "6063fe119216aa99624e0ffdf8512bc7e26af60ef7d5f57500859f0fad3cc477"
      )
  ]
)
