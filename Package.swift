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
          url: "https://github.com/ghostpass-ai/ghostpass-sdk-distribution-dev/releases/download/1.1.1/GoPassSDK.xcframework.zip",
          checksum: "c34cb8e254ee96de52666539a64105fd36b060573842eb3c78c09ab43ca969b6"
      )
  ]
)
