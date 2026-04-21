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
          checksum: "20a593f7db886ba194250185f85ae552959c0bb48cbce397ba6dba6b2bd506a4"
      )
  ]
)
