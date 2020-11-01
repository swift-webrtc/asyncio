// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
  name: "webrtc-asyncio",
  products: [
    .library(name: "AsyncIO", targets: ["AsyncIO"])
  ],
  dependencies: [
    .package(name: "webrtc-core", url: "https://github.com/swift-webrtc/core.git", .branch("master"))
  ],
  targets: [
    .systemLibrary(name: "CLibuv", pkgConfig: "libuv", providers: [
      .apt(["libuv"]),
      .brew(["libuv"])
    ]),
    .target(name: "AsyncIO", dependencies: [
      "CLibuv",
      .product(name: "Core", package: "webrtc-core")
    ]),
    .target(name: "TCPServer", dependencies: ["AsyncIO"]),
    .target(name: "TCPClient", dependencies: ["AsyncIO"]),
    .target(name: "UDPServer", dependencies: ["AsyncIO"]),
    .target(name: "UDPClient", dependencies: ["AsyncIO"]),
    .target(name: "Timer", dependencies: ["AsyncIO"]),
    .target(name: "Idle", dependencies: ["AsyncIO"]),
    .target(name: "DNS", dependencies: ["AsyncIO"]),
    .testTarget(name: "AsyncIOTests", dependencies: ["AsyncIO"])
  ]
)
