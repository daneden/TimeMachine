// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
	name: "TimeMachine",
	platforms: [
		.macOS(.v14),
		.iOS(.v17),
		.watchOS(.v10),
		.visionOS(.v1),
	],
	products: [
		// Products define the executables and libraries a package produces, making them visible to other packages.
		.library(
			name: "TimeMachine",
			targets: ["TimeMachine"]
		),
	],
	targets: [
		// Targets are the basic building blocks of a package, defining a module or a test suite.
		// Targets can depend on other targets in this package and products from dependencies.
		.target(
			name: "TimeMachine"
		),
		// Preview-only target. It is not part of any product, so package
		// consumers never build it. Xcode builds it when this package is
		// opened directly, which keeps previews working here.
		.target(
			name: "TimeMachinePreviews",
			dependencies: ["TimeMachine"]
		),
		.testTarget(
			name: "TimeMachineTests",
			dependencies: ["TimeMachine"]
		),
	]
)
