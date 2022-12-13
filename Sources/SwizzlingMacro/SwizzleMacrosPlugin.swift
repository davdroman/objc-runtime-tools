import SwiftCompilerPlugin
import SwiftSyntaxMacros

@main
struct SwizzleMacrosPlugin: CompilerPlugin {
	let providingMacros: [Macro.Type] = [
		SwizzleMacro.self,
	]
}
