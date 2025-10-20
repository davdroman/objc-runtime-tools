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

import SwiftDiagnostics
import SwiftSyntax

enum AssociatedMacroDiagnostic {
	case requiresVariableDeclaration
	case multipleVariableDeclarationIsNotSupported
	case getterAndSetterShouldBeNil
	case requiresInitialValue
	case specifyTypeExplicitly
	case invalidCustomKeySpecification
}

extension AssociatedMacroDiagnostic: DiagnosticMessage {
	func diagnose(at node: some SyntaxProtocol) -> Diagnostic {
		Diagnostic(node: Syntax(node), message: self)
	}

	public var message: String {
		switch self {
		case .requiresVariableDeclaration:
			"`@Associated` must be attached to the property declaration."
		case .multipleVariableDeclarationIsNotSupported:
			"""
			Multiple variable declaration in one statement is not supported when using `@Associated`.
			"""
		case .getterAndSetterShouldBeNil:
			"getter and setter must not be implemented when using `@Associated`."
		case .requiresInitialValue:
			"Initial values must be specified when using `@Associated`."
		case .specifyTypeExplicitly:
			"Specify a type explicitly when using `@Associated`."
		case .invalidCustomKeySpecification:
			"customKey specification is invalid."
		}
	}

	public var severity: DiagnosticSeverity { .error }

	public var diagnosticID: MessageID {
		MessageID(domain: "Swift", id: "Associated.\(self)")
	}
}
