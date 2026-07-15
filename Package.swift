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
          url: "https://github.com/ghostpass-ai/ghostpass-sdk-distribution-dev/releases/download/1.1.0/GoPassSDK.xcframework.zip",
          checksum: "5ac32b5dba0bec57f6dacb2c18ead88085885cb5c70eff8c492c7745beb4e239"
      )
  ]
)
