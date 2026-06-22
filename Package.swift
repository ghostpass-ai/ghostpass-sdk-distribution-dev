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
          url: "https://github.com/ghostpass-ai/ghostpass-sdk-distribution-dev/releases/download/1.0.7/GoPassSDK.xcframework.zip",
          checksum: "621600c3f82f87174884a7e9d31c6f90fb78d87c741cac95d2b5041fa31c6ce7"
      )
  ]
)
