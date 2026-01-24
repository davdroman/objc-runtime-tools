//  MIT License
//
//  Copyright (c) 2023 p-x9
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all
//  copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//  SOFTWARE.

import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

struct AssociatedMacro {}

extension AssociatedMacro: PeerMacro {
	static func expansion(
		of node: AttributeSyntax,
		providingPeersOf declaration: some DeclSyntaxProtocol,
		in context: some MacroExpansionContext
	) throws -> [DeclSyntax] {
		guard
			let varDecl = declaration.as(VariableDeclSyntax.self),
			let binding = varDecl.bindings.first,
			let identifier = binding.pattern.as(IdentifierPatternSyntax.self)?.identifier
		else {
			context.diagnose(AssociatedMacroDiagnostic.requiresVariableDeclaration.diagnose(at: declaration))
			return []
		}

		let defaultValue = binding.initializer?.value
		let type: TypeSyntax? = binding.typeAnnotation?.type

		guard let type else {
			//  Explicit specification of type is required
			context.diagnose(AssociatedMacroDiagnostic.specifyTypeExplicitly.diagnose(at: identifier))
			return []
		}

		let keyAccessor = """
		let f: @convention(c) () -> Void = {}
		return unsafeBitCast(f, to: UnsafeRawPointer.self)
		"""

		let keyDecl = VariableDeclSyntax(
			attributes: [
				.attribute("@inline(never)"),
			],
			bindingSpecifier: .identifier("private static var"),
			bindings: PatternBindingListSyntax {
				PatternBindingSyntax(
					pattern: IdentifierPatternSyntax(identifier: .identifier("__associated_\(identifier.trimmed)Key")),
					typeAnnotation: .init(type: IdentifierTypeSyntax(name: .identifier("UnsafeRawPointer"))),
					accessorBlock: .init(
						accessors: .getter("\(raw: keyAccessor)")
					)
				)
			}
		)

		var decls = [
			DeclSyntax(keyDecl),
		]

		if type.isOptional, defaultValue != nil {
			let flagName = "__associated_\(identifier.trimmed)IsSet"
			let flagDecl = VariableDeclSyntax(
				attributes: [
					.attribute("@_Associated(.retain(.nonatomic))"),
				],
				bindingSpecifier: .identifier("private var"),
				bindings: PatternBindingListSyntax {
					PatternBindingSyntax(
						pattern: IdentifierPatternSyntax(
							identifier: .identifier(flagName)
						),
						typeAnnotation: .init(type: IdentifierTypeSyntax(name: .identifier("Bool"))),
						initializer: InitializerClauseSyntax(value: BooleanLiteralExprSyntax(false))
					)
				}
			)

			// nested peer macro will not expand
			// https://github.com/apple/swift/issues/69073
			let flagKeyDecl = VariableDeclSyntax(
				attributes: [
					.attribute("@inline(never)"),
				],
				bindingSpecifier: .identifier("private static var"),
				bindings: PatternBindingListSyntax {
					PatternBindingSyntax(
						pattern: IdentifierPatternSyntax(
							identifier: .identifier("__associated___associated_\(identifier.trimmed)IsSetKey")
						),
						typeAnnotation: .init(type: IdentifierTypeSyntax(name: .identifier("UnsafeRawPointer"))),
						accessorBlock: .init(
							accessors: .getter("\(raw: keyAccessor)")
						)
					)
				}
			)
			decls.append(DeclSyntax(flagDecl))
			decls.append(DeclSyntax(flagKeyDecl))
		}

		return decls
	}
}

extension AssociatedMacro: AccessorMacro {
	static func expansion(
		of node: AttributeSyntax,
		providingAccessorsOf declaration: some DeclSyntaxProtocol,
		in context: some MacroExpansionContext
	) throws -> [AccessorDeclSyntax] {
		guard
			let varDecl = declaration.as(VariableDeclSyntax.self),
			let binding = varDecl.bindings.first,
			let identifier = binding.pattern.as(IdentifierPatternSyntax.self)?.identifier
		else {
			// Probably can't add a diagnose here, since this is an Accessor macro
			context.diagnose(AssociatedMacroDiagnostic.requiresVariableDeclaration.diagnose(at: declaration))
			return []
		}

		if varDecl.bindings.count > 1 {
			context.diagnose(AssociatedMacroDiagnostic.multipleVariableDeclarationIsNotSupported.diagnose(at: binding))
			return []
		}

		let defaultValue = binding.initializer?.value
		let type: TypeSyntax

		if let specifiedType = binding.typeAnnotation?.type {
			//  TypeAnnotation
			type = specifiedType
		} else {
			//  Explicit specification of type is required
			context.diagnose(AssociatedMacroDiagnostic.specifyTypeExplicitly.diagnose(at: identifier))
			return []
		}

		// Error if setter already exists
		if let setter = binding.setter {
			context.diagnose(AssociatedMacroDiagnostic.getterAndSetterShouldBeNil.diagnose(at: setter))
			return []
		}

		// Error if getter already exists
		if let getter = binding.getter {
			context.diagnose(AssociatedMacroDiagnostic.getterAndSetterShouldBeNil.diagnose(at: getter))
			return []
		}

		// Initial value required if type is optional
		if defaultValue == nil, !type.isOptional {
			context.diagnose(AssociatedMacroDiagnostic.requiresInitialValue.diagnose(at: declaration))
			return []
		}

		guard case let .argumentList(arguments) = node.arguments else {
			return []
		}

		var policy: ExprSyntax = ".retain(.nonatomic)"
		if
			let firstElement = arguments.first?.expression,
			let specifiedPolicy = ExprSyntax(firstElement)
		{
			policy = specifiedPolicy
		}

		let associatedKey: ExprSyntax = "Self.__associated_\(identifier.trimmed)Key"

		return [
			Self.getter(
				identifier: identifier,
				type: type,
				associatedKey: associatedKey,
				policy: policy,
				defaultValue: defaultValue
			),

			Self.setter(
				identifier: identifier,
				type: type,
				policy: policy,
				associatedKey: associatedKey,
				hasDefaultValue: defaultValue != nil,
				willSet: binding.willSet,
				didSet: binding.didSet
			),
		]
	}
}

extension AssociatedMacro {
	/// Create the syntax for the `get` accessor after expansion.
	/// - Parameters:
	///   - identifier: Type of Associated object.
	///   - type: Type of Associated object.
	///   - defaultValue: Syntax of default value
	/// - Returns: Syntax of `get` accessor after expansion.
	static func getter(
		identifier: TokenSyntax,
		type: TypeSyntax,
		associatedKey: ExprSyntax,
		policy: ExprSyntax,
		defaultValue: ExprSyntax?
	) -> AccessorDeclSyntax {
		let typeWithoutOptional = if let type = type.as(ImplicitlyUnwrappedOptionalTypeSyntax.self) {
			type.wrappedType
		} else if let type = type.as(OptionalTypeSyntax.self) {
			type.wrappedType
		} else {
			type
		}

		return AccessorDeclSyntax(
			accessorSpecifier: .keyword(.get),
			body: CodeBlockSyntax {
				if let defaultValue, type.isOptional {
					"""
					if !self.__associated_\(identifier.trimmed)IsSet {
						let value: \(type.trimmed) = \(defaultValue.trimmed)
						objc_setAssociatedObject(
							self,
							\(associatedKey),
							value,
							\(policy.trimmed)
						)
						self.__associated_\(identifier.trimmed)IsSet = true
						return value
					} else {
						return objc_getAssociatedObject(
							self,
							\(associatedKey)
						) as? \(typeWithoutOptional.trimmed)
					}
					"""
				} else if let defaultValue {
					"""
					if let value = objc_getAssociatedObject(
						self,
						\(associatedKey)
					) as? \(typeWithoutOptional.trimmed) {
						return value
					} else {
						let value: \(type.trimmed) = \(defaultValue.trimmed)
						objc_setAssociatedObject(
							self,
							\(associatedKey),
							value,
							\(policy.trimmed)
						)
						return value
					}
					"""
				} else {
					"""
					objc_getAssociatedObject(
						self,
						\(associatedKey)
					) as? \(typeWithoutOptional.trimmed)
					?? \(defaultValue ?? "nil")
					"""
				}
			}
		)
	}
}

extension AssociatedMacro {
	/// Create the syntax for the `set` accessor after expansion.
	/// - Parameters:
	///   - identifier: Name of associated object.
	///   - type: Type of Associated object.
	///   - policy: Syntax of `objc_AssociationPolicy`
	///   - `willSet`: `willSet` accessor of the original variable definition.
	///   - `didSet`: `didSet` accessor of the original variable definition.
	/// - Returns: Syntax of `set` accessor after expansion.
	static func setter(
		identifier: TokenSyntax,
		type: TypeSyntax,
		policy: ExprSyntax,
		associatedKey: ExprSyntax,
		hasDefaultValue: Bool,
		`willSet`: AccessorDeclSyntax?,
		`didSet`: AccessorDeclSyntax?
	) -> AccessorDeclSyntax {
		AccessorDeclSyntax(
			accessorSpecifier: .keyword(.set),
			body: CodeBlockSyntax {
				if
					let willSet = `willSet`,
					let body = willSet.body
				{
					Self.willSet(
						type: type,
						accessor: willSet,
						body: body
					)

					Self.callWillSet()
						.with(\.trailingTrivia, .newlines(2))
				}

				if `didSet` != nil {
					"let oldValue = \(identifier)"
				}

				"""
				objc_setAssociatedObject(
					self,
					\(associatedKey),
					newValue,
					\(policy)
				)
				"""

				if type.isOptional, hasDefaultValue {
					"""
					self.__associated_\(identifier.trimmed)IsSet = true
					"""
				}

				if
					let didSet = `didSet`,
					let body = didSet.body
				{
					Self.didSet(
						type: type,
						accessor: didSet,
						body: body
					).with(\.leadingTrivia, .newlines(2))

					Self.callDidSet()
				}
			}
		)
	}

	/// `willSet` closure
	///
	/// Convert a willSet accessor to a closure variable in the following format.
	/// ```swift
	/// let `willSet`: (\(type.trimmed)) -> Void = { [self] \(newValue) in
	///     \(body.statements.trimmed)
	/// }
	/// ```
	/// - Parameters:
	///   - type: Type of Associated object.
	///   - body: Contents of willSet
	/// - Returns: Variable that converts the contents of willSet to a closure
	static func `willSet`(
		type: TypeSyntax,
		accessor: AccessorDeclSyntax,
		body: CodeBlockSyntax
	) -> VariableDeclSyntax {
		let newValue = accessor.parameters?.name.trimmed ?? .identifier("newValue")

		return VariableDeclSyntax(
			bindingSpecifier: .keyword(.let),
			bindings: .init {
				.init(
					pattern: IdentifierPatternSyntax(identifier: .identifier("willSet")),
					typeAnnotation: .init(
						type: FunctionTypeSyntax(
							parameters: .init {
								TupleTypeElementSyntax(
									type: type.trimmed
								)
							},
							returnClause: ReturnClauseSyntax(
								type: IdentifierTypeSyntax(name: .identifier("Void"))
							)
						)
					),
					initializer: .init(
						value: ClosureExprSyntax(
							signature: .init(
								capture: .init {
									ClosureCaptureSyntax(
										name: .keyword(.`self`),
										expression: DeclReferenceExprSyntax(baseName: .keyword(.`self`))
									)
								},
								parameterClause: .init(ClosureShorthandParameterListSyntax {
									ClosureShorthandParameterSyntax(name: newValue)
								})
							),
							statements: .init(body.statements.map(\.trimmed))
						)
					)
				)
			}
		)
	}

	/// `didSet` closure
	///
	/// Convert a didSet accessor to a closure variable in the following format.
	/// ```swift
	/// let `didSet`: (\(type.trimmed)) -> Void = { [self] \(oldValue) in
	///     \(body.statements.trimmed)
	/// }
	/// ```
	/// - Parameters:
	///   - type: Type of Associated object.
	///   - body: Contents of didSet
	/// - Returns: Variable that converts the contents of didSet to a closure
	static func `didSet`(
		type: TypeSyntax,
		accessor: AccessorDeclSyntax,
		body: CodeBlockSyntax
	) -> VariableDeclSyntax {
		let oldValue = accessor.parameters?.name.trimmed ?? .identifier("oldValue")

		return VariableDeclSyntax(
			bindingSpecifier: .keyword(.let),
			bindings: .init {
				.init(
					pattern: IdentifierPatternSyntax(identifier: .identifier("didSet")),
					typeAnnotation: .init(
						type: FunctionTypeSyntax(
							parameters: .init {
								TupleTypeElementSyntax(
									type: type.trimmed
								)
							},
							returnClause: ReturnClauseSyntax(
								type: IdentifierTypeSyntax(name: .identifier("Void"))
							)
						)
					),
					initializer: .init(
						value: ClosureExprSyntax(
							signature: .init(
								capture: .init {
									ClosureCaptureSyntax(
										name: .keyword(.`self`),
										expression: DeclReferenceExprSyntax(baseName: .keyword(.`self`))
									)
								},
								parameterClause: .init(ClosureShorthandParameterListSyntax {
									ClosureShorthandParameterSyntax(name: oldValue)
								})
							),
							statements: .init(body.statements.map(\.trimmed))
						)
					)
				)
			}
		)
	}

	/// Execute willSet closure
	///
	/// ```swift
	/// willSet(newValue)
	/// ```
	/// - Returns: Syntax for executing willSet closure
	static func callWillSet() -> FunctionCallExprSyntax {
		FunctionCallExprSyntax(
			callee: DeclReferenceExprSyntax(baseName: .identifier("willSet")),
			argumentList: {
				.init(
					expression: DeclReferenceExprSyntax(
						baseName: .identifier("newValue")
					)
				)
			}
		)
	}

	/// Execute didSet closure
	///
	/// ```swift
	/// didSet(oldValue)
	/// ```
	/// - Returns: Syntax for executing didSet closure
	static func callDidSet() -> FunctionCallExprSyntax {
		FunctionCallExprSyntax(
			callee: DeclReferenceExprSyntax(baseName: .identifier("didSet")),
			argumentList: {
				.init(
					expression: DeclReferenceExprSyntax(
						baseName: .identifier("oldValue")
					)
				)
			}
		)
	}
}
