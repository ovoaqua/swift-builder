// swift-tools-version:5.1

import PackageDescription

let package = Package(
  name: "TealiumSwift",
  platforms: [ .iOS(.v9), .macOS(.v10_11), .tvOS(.v9), .watchOS(.v3) ],
  products: [
    .library(
      name: "TealiumAppData",
      targets: ["TealiumAppData"]),
    .library(
      name: "TealiumAttribution",
      targets: ["TealiumAttribution"]),
    // not supported - SPM limitation
    // .library(
    //   name: "TealiumAutotracking",
    //   targets: ["TealiumAutotracking"]),
    .library(
      name: "TealiumCore",
      targets: ["TealiumCore"]),
    .library(
      name: "TealiumCollect",
      targets: ["TealiumCollect"]),
    .library(
      name: "TealiumConnectivity",
      targets: ["TealiumConnectivity"]),
    .library(
      name: "TealiumConsentManager",
      targets: ["TealiumConsentManager"]),
    .library(
      name: "TealiumCrash",
      targets: ["TealiumCrash"]),
    .library(
      name: "TealiumDelegate",
      targets: ["TealiumDelegate"]),
    .library(
      name: "TealiumDeviceData",
      targets: ["TealiumDeviceData"]),
    .library(
      name: "TealiumDispatchQueue",
      targets: ["TealiumDispatchQueue"]),
    .library(
      name: "TealiumLifecycle",
      targets: ["TealiumLifecycle"]),
    .library(
      name: "TealiumLogger",
      targets: ["TealiumLogger"]),
    .library(
      name: "TealiumPersistentData",
      targets: ["TealiumPersistentData"]),
    .library(
      name: "TealiumRemoteCommands",
      targets: ["TealiumRemoteCommands"]),
    .library(
      name: "TealiumTagManagement",
      targets: ["TealiumTagManagement"]),
    .library(
      name: "TealiumVisitorService",
      targets: ["TealiumVisitorService"]),
    .library(
      name: "TealiumVolatileData",
      targets: ["TealiumVolatileData"]),
  ],
  dependencies: [
  ],
  targets: [
    .target(
      name: "TealiumCore",
      path: "tealium/core/"
    ),
    .target(
      name: "TealiumAppData",
      dependencies: ["TealiumCore"],
      path: "tealium/appdata/"
    ),
    // .target(
    //   name: "TealiumAutotracking",
    //   dependencies: ["TealiumCore"],
    //   path: "tealium/autotracking/"
    // ),
    .target(
      name: "TealiumAttribution",
      dependencies: ["TealiumCore"],
      path: "tealium/attribution/"
    // .linkedFramework("AdSupport", .when(platforms: [.iOS])),
    ),
    .target(
      name: "TealiumCollect",
      dependencies: ["TealiumCore"],
      path: "tealium/collect/"
    ),
    .target(
      name: "TealiumConnectivity",
      dependencies: ["TealiumCore"],
      path: "tealium/connectivity/"
    ),
    .target(
      name: "TealiumConsentManager",
      dependencies: ["TealiumCore"],
      path: "tealium/consentmanager/"
    ),
    .target(
      name: "TealiumCrash",
      dependencies: ["TealiumCore"],
      path: "tealium/crash/"
    ),
    .target(
      name: "TealiumDelegate",
      dependencies: ["TealiumCore"],
      path: "tealium/delegate/"
    ),
    .target(
      name: "TealiumDeviceData",
      dependencies: ["TealiumCore"],
      path: "tealium/devicedata/"
    ),
    .target(
      name: "TealiumDispatchQueue",
      dependencies: ["TealiumCore"],
      path: "tealium/dispatchqueue/"
    ),
    .target(
      name: "TealiumLifecycle",
      dependencies: ["TealiumCore"],
      path: "tealium/lifecycle/"
    ),
    .target(
      name: "TealiumLogger",
      dependencies: ["TealiumCore"],
      path: "tealium/logger/"
    ),
    .target(
      name: "TealiumPersistentData",
      dependencies: ["TealiumCore"],
      path: "tealium/persistentdata/"
    ),
  .target(
      name: "TealiumRemoteCommands",
      dependencies: ["TealiumCore"],
      path: "tealium/remotecommands/"
    ),
  .target(
      name: "TealiumTagManagement",
      dependencies: ["TealiumCore"],
      path: "tealium/tagmanagement/"
    ),
  .target(
      name: "TealiumVisitorService",
      dependencies: ["TealiumCore"],
      path: "tealium/visitorservice/"
    ),    
  .target(
      name: "TealiumVolatileData",
      dependencies: ["TealiumCore"],
      path: "tealium/volatiledata/"
    ),
  ]
)