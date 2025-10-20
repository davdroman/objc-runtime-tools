import Foundation
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

struct SwizzleMacro: ExpressionMacro {
	static func expansion(
		of node: some FreestandingMacroExpansionSyntax,
		in context: some MacroExpansionContext
	) throws -> ExprSyntax {
		guard
			let firstArgument = node.arguments.first,
			let kind = FunctionKind(from: firstArgument.label?.text)
		else {
			throw MacroError.unexpectedFunctionSignature
		}

		let className: String
		let functionName: String

		if
			let memberAccess = firstArgument.expression.as(MemberAccessExprSyntax.self),
			let base = memberAccess.base
		{
			className = base.trimmedDescription
			functionName = memberAccess.declName.baseName.trimmedDescription
		} else if
			let keyPath = firstArgument.expression.as(KeyPathExprSyntax.self),
			let root = keyPath.root
		{
			className = root.trimmedDescription
			functionName = keyPath.components.trimmedDescription.replacingOccurrences(of: ".", with: "")
		} else {
			throw MacroError.unexpectedFunctionSignature
		}

		let selector = firstArgument.with(\.trailingComma, nil).trimmedDescription.replacingOccurrences(of: #"\"#, with: "")

		let params = node.arguments.dropFirst().prefix(while: { $0.label?.text != "returning" && $0.label?.text != "implementation" })
		let paramTypes = if !params.isEmpty {
			", " + params.map { $0.expression.trimmedDescription.replacingOccurrences(of: ".self", with: "") }.joined(separator: ", ")
		} else {
			""
		}

		let returning = node.arguments.first(where: { $0.label?.text == "returning" })
		let returnType = returning?.expression.trimmedDescription.replacingOccurrences(of: ".self", with: "") ?? "Void"

		guard
			let block = node.arguments.last?.expression.as(ClosureExprSyntax.self) ?? node.trailingClosure
		else {
			throw MacroError.missingClosure
		}

		let firstClosureParamFinder = FirstClosureParameterFinder()
		firstClosureParamFinder.walk(block)
		guard let rawFirstParamName = firstClosureParamFinder.paramName else {
			throw MacroError.missingClosureParams
		}

		let firstClosureParamRenamer = FirstClosureParameterRenamer(rawParamName: rawFirstParamName)
		var newBlock = firstClosureParamRenamer.rewrite(block)
		let firstParamName = firstClosureParamRenamer.paramName!
		newBlock = FunctionCallRewriter(kind: kind, baseName: firstParamName, functionName: functionName).rewrite(newBlock)

		return """
		Swizzling.__swizzle(
			\(raw: className).self,
			#selector(\(raw: selector)),
			methodSignature: (@convention(c) (\(raw: className), Selector\(raw: paramTypes)) -> \(raw: returnType)).self,
			hookSignature: (@convention(block) (\(raw: className)\(raw: paramTypes)) -> \(raw: returnType)).self
		) { hook in return \(newBlock) }
		"""
	}
}

final class FirstClosureParameterFinder: SyntaxVisitor {
	private(set) var paramName: String?

	init() {
		super.init(viewMode: .sourceAccurate)
	}

	override func visit(_ node: ClosureShorthandParameterListSyntax) -> SyntaxVisitorContinueKind {
		paramName = node.first?.name.text
		return .skipChildren
	}

	override func visit(_ node: ClosureParameterListSyntax) -> SyntaxVisitorContinueKind {
		paramName = node.first?.secondName?.text ?? node.first?.firstName.text
		return .skipChildren
	}
}

final class FirstClosureParameterRenamer: SyntaxRewriter {
	private var rawParamName: String

	init(rawParamName: String) {
		self.rawParamName = rawParamName
	}

	private(set) var paramName: String? = nil

	override func visit(_ token: TokenSyntax) -> TokenSyntax {
		guard token.text == rawParamName || token.text == rawParamName.replacingOccurrences(of: "$", with: "") else {
			return super.visit(token)
		}

		var paramName = token.text.replacingOccurrences(of: "$", with: "")

		if paramName == "self" {
			paramName = "`self`"
		}

		self.paramName = paramName

		return TokenSyntax.identifier(paramName)
			.with(\.leadingTrivia, token.leadingTrivia)
			.with(\.trailingTrivia, token.trailingTrivia)
	}
}

enum FunctionKind {
	case getter
	case setter
	case function

	init?(from label: String?) {
		switch label {
		case "getter": self = .getter
		case "setter": self = .setter
		case .none: self = .function
		default: return nil
		}
	}
}

final class FunctionCallRewriter: SyntaxRewriter {
	let kind: FunctionKind
	var baseName: String
	let functionName: String

	init(
		kind: FunctionKind,
		baseName: String,
		functionName: String
	) {
		self.kind = kind
		self.baseName = baseName
		self.functionName = functionName
	}

	override func visit(_ node: MemberAccessExprSyntax) -> ExprSyntax {
		guard kind == .getter else {
			return super.visit(node)
		}

		guard
			node.base?.trimmedDescription == baseName,
			node.declName.trimmedDescription == functionName
		else {
			return super.visit(node)
		}

		return ExprSyntax("hook.original(\(raw: baseName), hook.selector)")
			.with(\.leadingTrivia, node.leadingTrivia)
			.with(\.trailingTrivia, node.trailingTrivia)
	}

	override func visit(_ node: InfixOperatorExprSyntax) -> ExprSyntax {
		guard kind == .setter else {
			return super.visit(node)
		}

		guard
			let leftOperand = node.leftOperand.as(MemberAccessExprSyntax.self),
			leftOperand.base?.trimmedDescription == baseName,
			leftOperand.declName.trimmedDescription == functionName,
			node.operator.trimmedDescription == "="
		else {
			return super.visit(node)
		}

		let rightOperand = node.rightOperand

		return ExprSyntax("hook.original(\(raw: baseName), hook.selector, \(rightOperand))")
			.with(\.leadingTrivia, node.leadingTrivia)
			.with(\.trailingTrivia, node.trailingTrivia)
	}

	override func visit(_ node: FunctionCallExprSyntax) -> ExprSyntax {
		guard kind == .function else {
			return super.visit(node)
		}

		guard
			let call = node.calledExpression.as(MemberAccessExprSyntax.self),
			call.base?.trimmedDescription == baseName,
			call.declName.trimmedDescription == functionName
		else {
			return super.visit(node)
		}

		// remove all labels
		var newArguments = node.arguments.map { $0.with(\.label, nil).with(\.colon, nil) }

		// insert baseName as the first argument
		newArguments.insert(
			LabeledExprSyntax(
				expression: ExprSyntax(DeclReferenceExprSyntax(baseName: .identifier(baseName))),
				trailingComma: .commaToken(trailingTrivia: .space)
			),
			at: 0
		)

		// insert hook.selector as the second argument
		newArguments.insert(
			LabeledExprSyntax(
				expression: ExprSyntax("hook.selector"),
				trailingComma: newArguments.count > 1 ? .commaToken(trailingTrivia: .space) : nil
			),
			at: 1
		)

		return ExprSyntax(
			node
				.with(\.calledExpression, ExprSyntax("hook.original"))
				.with(\.arguments, LabeledExprListSyntax(newArguments))
				.with(\.leadingTrivia, node.leadingTrivia)
				.with(\.trailingTrivia, node.trailingTrivia)
		)
	}
}

enum MacroError: Error {
	case unexpectedFunctionSignature
	case missingClosure
	case missingClosureParams
}
