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

#if os(macOS) // NB: can only test macros on macOS
import SwiftSyntax
import SwiftSyntaxBuilder
import Testing

@testable import AssociationMacro

@Suite
struct PatternBindingSyntaxTests {
	@Test
	func testSetter() {
		let setter = AccessorDeclSyntax(accessorSpecifier: .keyword(.set), body: .init(statements: CodeBlockItemListSyntax {}))

		let binding: PatternBindingSyntax = .init(
			pattern: IdentifierPatternSyntax(identifier: .identifier("value")),
			accessorBlock: .init(
				accessors: .accessors(.init {
					setter
				})
			)
		)

		#expect(setter.description == binding.setter?.description)
	}

	@Test
	func testGetter() throws {
		let getter = AccessorDeclSyntax(accessorSpecifier: .keyword(.get), body: .init(statements: CodeBlockItemListSyntax {}))

		var binding: PatternBindingSyntax = .init(
			pattern: IdentifierPatternSyntax(identifier: .identifier("value")),
			accessorBlock: .init(
				accessors: .accessors(.init {
					getter
				})
			)
		)

		#expect(getter.description == binding.getter?.description)

		/* getter only */
		let body = try #require(getter.body, "body must not be nil")

		binding = .init(
			pattern: IdentifierPatternSyntax(identifier: .identifier("value")),
			accessorBlock: .init(
				accessors: .getter(body.statements)
			)
		)

		#expect(getter.description == binding.getter?.description)
	}

	@Test
	func testSetSetter() {
		let setter = AccessorDeclSyntax(accessorSpecifier: .keyword(.set), body: .init(statements: CodeBlockItemListSyntax {}))
		var binding: PatternBindingSyntax = .init(
			pattern: IdentifierPatternSyntax(identifier: .identifier("value")),
			accessorBlock: .init(
				accessors: .accessors(.init {
					setter
				})
			)
		)
		let newSetter = AccessorDeclSyntax(
			accessorSpecifier: .keyword(.set),
			body: .init(statements: CodeBlockItemListSyntax {
				.init(item: .expr("print(\"hello\")"))
			})
		)

		binding.setter = newSetter
		#expect(newSetter.description == binding.setter?.description)

		/* getter only */
		binding = .init(
			pattern: IdentifierPatternSyntax(identifier: .identifier("value")),
			accessorBlock: .init(
				accessors: .getter(.init {
					DeclSyntax("\"hello\"")
				})
			)
		)

		binding.setter = newSetter
		#expect(newSetter.description == binding.setter?.description)
	}

	@Test
	func testSetGetter() {
		let getter = AccessorDeclSyntax(accessorSpecifier: .keyword(.get), body: .init(statements: CodeBlockItemListSyntax {}))
		var binding: PatternBindingSyntax = .init(
			pattern: IdentifierPatternSyntax(identifier: .identifier("value")),
			accessorBlock: .init(
				accessors: .accessors(.init {
					getter
				})
			)
		)

		let newGetter = AccessorDeclSyntax(
			accessorSpecifier: .keyword(.get),
			body: .init(statements: CodeBlockItemListSyntax {
				.init(item: .decl("\"hello\""))
			})
		)

		binding.getter = newGetter
		#expect(newGetter.description == binding.getter?.description)

		/* getter only */
		binding = .init(
			pattern: IdentifierPatternSyntax(identifier: .identifier("value")),
			accessorBlock: .init(
				accessors: .getter(.init {
					DeclSyntax("\"hello\"")
				})
			)
		)

		binding.getter = newGetter
		#expect(newGetter.description == binding.getter?.description)

		/* setter only */
		binding = .init(
			pattern: IdentifierPatternSyntax(identifier: .identifier("value")),
			accessorBlock: .init(
				accessors: .accessors(.init {
					AccessorDeclSyntax(accessorSpecifier: .keyword(.set), body: .init(statements: CodeBlockItemListSyntax {}))
				})
			)
		)

		binding.getter = newGetter
		#expect(newGetter.description == binding.getter?.description)
	}

	@Test
	func testWillSet() {
		let `willSet` = AccessorDeclSyntax(accessorSpecifier: .keyword(.willSet), body: .init(statements: CodeBlockItemListSyntax {}))

		let binding: PatternBindingSyntax = .init(
			pattern: IdentifierPatternSyntax(identifier: .identifier("value")),
			accessorBlock: .init(
				accessors: .accessors(.init {
					`willSet`
				})
			)
		)

		#expect(`willSet`.description == binding.willSet?.description)
	}

	@Test
	func testDidSet() {
		let `didSet` = AccessorDeclSyntax(accessorSpecifier: .keyword(.didSet), body: .init(statements: CodeBlockItemListSyntax {}))

		let binding: PatternBindingSyntax = .init(
			pattern: IdentifierPatternSyntax(identifier: .identifier("value")),
			accessorBlock: .init(
				accessors: .accessors(.init {
					`didSet`
				})
			)
		)

		#expect(`didSet`.description == binding.didSet?.description)
	}

	@Test
	func testSetWillSet() {
		let `willSet` = AccessorDeclSyntax(accessorSpecifier: .keyword(.willSet), body: .init(statements: CodeBlockItemListSyntax {}))

		var binding: PatternBindingSyntax = .init(
			pattern: IdentifierPatternSyntax(identifier: .identifier("value")),
			accessorBlock: .init(
				accessors: .accessors(.init {
					`willSet`
				})
			)
		)

		let newWillSet = AccessorDeclSyntax(
			accessorSpecifier: .keyword(.willSet),
			body: .init(statements: CodeBlockItemListSyntax {
				.init(item: .decl("\"hello\""))
			})
		)

		binding.willSet = newWillSet
		#expect(newWillSet.description == binding.willSet?.description)
	}
}
#endif
