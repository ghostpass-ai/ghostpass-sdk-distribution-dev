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
          url: "https://github.com/ghostpass-ai/ghostpass-sdk-distribution-dev/releases/download/1.0.1/GoPassSDK.xcframework.zip",
          checksum: "f0ac8a7b092f66ee3ce269be440d0082eb577552e16a716812c3c7546697fe52"
      )
  ]
)
