import SwiftCompilerPlugin
import SwiftSyntaxMacros

@main
struct SwizzleMacrosPlugin: CompilerPlugin {
	let providingMacros: [any Macro.Type] = [
		SwizzleMacro.self,
	]
}
