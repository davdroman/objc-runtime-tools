// swift-tools-version: 6.0

import CompilerPluginSupport
import PackageDescription

let package = Package(
	name: "objc-runtime-tools",
	platforms: [
		.iOS(.v13),
		.macOS(.v10_15),
		.tvOS(.v13),
		.watchOS(.v6),
	],
	products: [
		.library(name: "ObjCRuntimeTools", targets: ["ObjCRuntimeTools"]),
	],
	targets: [
		.target(
			name: "ObjCRuntimeTools",
			dependencies: [
				"Association",
				"Swizzling",
			]
		),
	]
)

// MARK: Association

package.products += [
	.library(name: "Association", targets: ["Association"]),
]

package.targets += [
	.target(name: "Association", dependencies: ["AssociationMacro"]),
	.testTarget(
		name: "AssociationTests",
		dependencies: [
			"Association",
		]
	),

	.macro(
		name: "AssociationMacro",
		dependencies: [
			.product(name: "SwiftSyntax", package: "swift-syntax"),
			.product(name: "SwiftSyntaxBuilder", package: "swift-syntax"),
			.product(name: "SwiftSyntaxMacros", package: "swift-syntax"),
			.product(name: "SwiftCompilerPlugin", package: "swift-syntax"),
		]
	),
	.testTarget(
		name: "AssociationMacroTests",
		dependencies: [
			"AssociationMacro",
			.product(name: "MacroTesting", package: "swift-macro-testing"),
		]
	)
]

// MARK: Swizzling

package.products += [
	.library(name: "Swizzling", targets: ["Swizzling"]),
]

package.targets += [
	.target(name: "Swizzling", dependencies: ["SwizzlingMacro"]),
	.macro(
		name: "SwizzlingMacro",
		dependencies: [
			.product(name: "SwiftSyntax", package: "swift-syntax"),
			.product(name: "SwiftSyntaxBuilder", package: "swift-syntax"),
			.product(name: "SwiftSyntaxMacros", package: "swift-syntax"),
			.product(name: "SwiftCompilerPlugin", package: "swift-syntax"),
		]
	),

	.testTarget(
		name: "SwizzlingTests",
		dependencies: [
			"Swizzling",
			"SwizzlingMacro",
			.product(name: "MacroTesting", package: "swift-macro-testing"),
			.product(name: "SwiftCompilerPlugin", package: "swift-syntax"),
		]
	),
]

package.dependencies += [
	.package(url: "https://github.com/pointfreeco/swift-macro-testing", from: "0.6.0"),
	.package(url: "https://github.com/swiftlang/swift-syntax", "600.0.0"..<"603.0.0"),
]
