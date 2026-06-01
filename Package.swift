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
          url: "https://github.com/ghostpass-ai/ghostpass-sdk-distribution-dev/releases/download/1.0.3/GoPassSDK.xcframework.zip",
          checksum: "3da54286f6e22422b80c7f203e4f48c090c80ed8f4f3e8eb8ef8b61eaecb3a26"
      )
  ]
)
