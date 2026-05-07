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
          url: "https://github.com/ghostpass-ai/ghostpass-sdk-distribution-dev/releases/download/1.0.0/GoPassSDK.xcframework.zip",
          checksum: "ef19736894fd463d35ed3c5c0c7a458371b5a67e82a8daa9157d5d419350f2ef"
      )
  ]
)
