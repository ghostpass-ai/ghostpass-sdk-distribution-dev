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
          url: "https://github.com/ghostpass-ai/ghostpass-sdk-distribution-dev/releases/download/1.0.5/GoPassSDK.xcframework.zip",
          checksum: "9b80e04d58bed2c18058da5ac29643f0e987253731e4ae15476a6829cdf89bab"
      )
  ]
)
