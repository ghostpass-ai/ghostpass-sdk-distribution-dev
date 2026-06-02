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
          url: "https://github.com/ghostpass-ai/ghostpass-sdk-distribution-dev/releases/download/1.0.4/GoPassSDK.xcframework.zip",
          checksum: "8f3e0f594467450222062d3af921517ca5a52ab8a0444b323bceac2228f6ea08"
      )
  ]
)
