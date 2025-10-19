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

#if canImport(AssociationMacro)
import MacroTesting
import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import Testing

@testable import Association
@testable import AssociationMacro

@Suite(
	.macros(
		["Associated": AssociatedMacro.self],
		indentationWidth: .tab,
		record: .never
	)
)
struct AssociatedTests {
	@Test
	func testString() throws {
		assertMacro {
			"""
			@Associated(.retain(.atomic))
			var string: String = "text"
			"""
		} expansion: {
			"""
			var string: String {
				get {
					if let value = objc_getAssociatedObject(
						self,
						Self.__associated_stringKey
					) as? String {
						return value
					} else {
						let value: String = "text"
						objc_setAssociatedObject(
							self,
							Self.__associated_stringKey,
							value,
							.retain(.atomic)
						)
						return value
					}
				}
				set {
					objc_setAssociatedObject(
						self,
						Self.__associated_stringKey,
						newValue,
						.retain(.atomic)
					)
				}
			}

			@inline(never) private static var __associated_stringKey: UnsafeRawPointer {
				let f: @convention(c) () -> Void = {
				}
				return unsafeBitCast(f, to: UnsafeRawPointer.self)
			}
			"""
		}
	}

	@Test
	func testInt() throws {
		assertMacro {
			"""
			@Associated(.retain(.nonatomic))
			var int: Int = 5
			"""
		} expansion: {
			"""
			var int: Int {
				get {
					if let value = objc_getAssociatedObject(
						self,
						Self.__associated_intKey
					) as? Int {
						return value
					} else {
						let value: Int = 5
						objc_setAssociatedObject(
							self,
							Self.__associated_intKey,
							value,
							.retain(.nonatomic)
						)
						return value
					}
				}
				set {
					objc_setAssociatedObject(
						self,
						Self.__associated_intKey,
						newValue,
						.retain(.nonatomic)
					)
				}
			}

			@inline(never) private static var __associated_intKey: UnsafeRawPointer {
				let f: @convention(c) () -> Void = {
				}
				return unsafeBitCast(f, to: UnsafeRawPointer.self)
			}
			"""
		}
	}

	@Test
	func testFloat() throws {
		assertMacro {
			"""
			@Associated(.retain(.nonatomic))
			var float: Float = 5.0
			"""
		} expansion: {
			"""
			var float: Float {
				get {
					if let value = objc_getAssociatedObject(
						self,
						Self.__associated_floatKey
					) as? Float {
						return value
					} else {
						let value: Float = 5.0
						objc_setAssociatedObject(
							self,
							Self.__associated_floatKey,
							value,
							.retain(.nonatomic)
						)
						return value
					}
				}
				set {
					objc_setAssociatedObject(
						self,
						Self.__associated_floatKey,
						newValue,
						.retain(.nonatomic)
					)
				}
			}

			@inline(never) private static var __associated_floatKey: UnsafeRawPointer {
				let f: @convention(c) () -> Void = {
				}
				return unsafeBitCast(f, to: UnsafeRawPointer.self)
			}
			"""
		}
	}

	@Test
	func testDouble() throws {
		assertMacro {
			"""
			@Associated(.retain(.nonatomic))
			var double: Double = 5.0
			"""
		} expansion: {
			"""
			var double: Double {
				get {
					if let value = objc_getAssociatedObject(
						self,
						Self.__associated_doubleKey
					) as? Double {
						return value
					} else {
						let value: Double = 5.0
						objc_setAssociatedObject(
							self,
							Self.__associated_doubleKey,
							value,
							.retain(.nonatomic)
						)
						return value
					}
				}
				set {
					objc_setAssociatedObject(
						self,
						Self.__associated_doubleKey,
						newValue,
						.retain(.nonatomic)
					)
				}
			}

			@inline(never) private static var __associated_doubleKey: UnsafeRawPointer {
				let f: @convention(c) () -> Void = {
				}
				return unsafeBitCast(f, to: UnsafeRawPointer.self)
			}
			"""
		}
	}

	@Test
	func testStringWithOtherPolicy() throws {
		assertMacro {
			"""
			@Associated(.retain(.nonatomic))
			var string: String = "text"
			"""
		} expansion: {
			"""
			var string: String {
				get {
					if let value = objc_getAssociatedObject(
						self,
						Self.__associated_stringKey
					) as? String {
						return value
					} else {
						let value: String = "text"
						objc_setAssociatedObject(
							self,
							Self.__associated_stringKey,
							value,
							.retain(.nonatomic)
						)
						return value
					}
				}
				set {
					objc_setAssociatedObject(
						self,
						Self.__associated_stringKey,
						newValue,
						.retain(.nonatomic)
					)
				}
			}

			@inline(never) private static var __associated_stringKey: UnsafeRawPointer {
				let f: @convention(c) () -> Void = {
				}
				return unsafeBitCast(f, to: UnsafeRawPointer.self)
			}
			"""
		}
	}

	@Test
	func testOptionalString() throws {
		assertMacro {
			"""
			@Associated(.retain(.nonatomic))
			var string: String?
			"""
		} expansion: {
			"""
			var string: String? {
				get {
					objc_getAssociatedObject(
						self,
						Self.__associated_stringKey
					) as? String
					?? nil
				}
				set {
					objc_setAssociatedObject(
						self,
						Self.__associated_stringKey,
						newValue,
						.retain(.nonatomic)
					)
				}
			}

			@inline(never) private static var __associated_stringKey: UnsafeRawPointer {
				let f: @convention(c) () -> Void = {
				}
				return unsafeBitCast(f, to: UnsafeRawPointer.self)
			}
			"""
		}
	}

	@Test
	func testOptionalGenericsString() throws {
		assertMacro {
			"""
			@Associated(.retain(.nonatomic))
			var string: Optional<String>
			"""
		} expansion: {
			"""
			var string: Optional<String> {
				get {
					objc_getAssociatedObject(
						self,
						Self.__associated_stringKey
					) as? Optional<String>
					?? nil
				}
				set {
					objc_setAssociatedObject(
						self,
						Self.__associated_stringKey,
						newValue,
						.retain(.nonatomic)
					)
				}
			}

			@inline(never) private static var __associated_stringKey: UnsafeRawPointer {
				let f: @convention(c) () -> Void = {
				}
				return unsafeBitCast(f, to: UnsafeRawPointer.self)
			}
			"""
		}
	}

	@Test
	func testImplicitlyUnwrappedOptionalString() throws {
		assertMacro {
			"""
			@Associated(.retain(.nonatomic))
			var string: String!
			"""
		} expansion: {
			"""
			var string: String! {
				get {
					objc_getAssociatedObject(
						self,
						Self.__associated_stringKey
					) as? String
					?? nil
				}
				set {
					objc_setAssociatedObject(
						self,
						Self.__associated_stringKey,
						newValue,
						.retain(.nonatomic)
					)
				}
			}

			@inline(never) private static var __associated_stringKey: UnsafeRawPointer {
				let f: @convention(c) () -> Void = {
				}
				return unsafeBitCast(f, to: UnsafeRawPointer.self)
			}
			"""
		}
	}

	@Test
	func testOptionalStringWithInitialValue() throws {
		assertMacro {
			"""
			@Associated(.retain(.nonatomic))
			var string: String? = "hello"
			"""
		} expansion: {
			"""
			var string: String? {
				get {
					if !self.__associated_stringIsSet {
						let value: String? = "hello"
						objc_setAssociatedObject(
							self,
							Self.__associated_stringKey,
							value,
							.retain(.nonatomic)
						)
						self.__associated_stringIsSet = true
						return value
					} else {
						return objc_getAssociatedObject(
							self,
							Self.__associated_stringKey
						) as? String
					}
				}
				set {
					objc_setAssociatedObject(
						self,
						Self.__associated_stringKey,
						newValue,
						.retain(.nonatomic)
					)
					self.__associated_stringIsSet = true
				}
			}

			@inline(never) private static var __associated_stringKey: UnsafeRawPointer {
				let f: @convention(c) () -> Void = {
				}
				return unsafeBitCast(f, to: UnsafeRawPointer.self)
			}

			@_Associated(.retain(.nonatomic)) private var __associated_stringIsSet: Bool = false

			@inline(never) private static var __associated___associated_stringIsSetKey: UnsafeRawPointer {
				let f: @convention(c) () -> Void = {
				}
				return unsafeBitCast(f, to: UnsafeRawPointer.self)
			}
			"""
		}
	}

	@Test
	func testBool() throws {
		assertMacro {
			"""
			@Associated(.retain(.nonatomic))
			var bool: Bool = false
			"""
		} expansion: {
			"""
			var bool: Bool {
				get {
					if let value = objc_getAssociatedObject(
						self,
						Self.__associated_boolKey
					) as? Bool {
						return value
					} else {
						let value: Bool = false
						objc_setAssociatedObject(
							self,
							Self.__associated_boolKey,
							value,
							.retain(.nonatomic)
						)
						return value
					}
				}
				set {
					objc_setAssociatedObject(
						self,
						Self.__associated_boolKey,
						newValue,
						.retain(.nonatomic)
					)
				}
			}

			@inline(never) private static var __associated_boolKey: UnsafeRawPointer {
				let f: @convention(c) () -> Void = {
				}
				return unsafeBitCast(f, to: UnsafeRawPointer.self)
			}
			"""
		}
	}

	@Test
	func testIntArray() throws {
		assertMacro {
			"""
			@Associated(.retain(.nonatomic))
			var intArray: [Int] = [1, 2, 3]
			"""
		} expansion: {
			"""
			var intArray: [Int] {
				get {
					if let value = objc_getAssociatedObject(
						self,
						Self.__associated_intArrayKey
					) as? [Int] {
						return value
					} else {
						let value: [Int] = [1, 2, 3]
						objc_setAssociatedObject(
							self,
							Self.__associated_intArrayKey,
							value,
							.retain(.nonatomic)
						)
						return value
					}
				}
				set {
					objc_setAssociatedObject(
						self,
						Self.__associated_intArrayKey,
						newValue,
						.retain(.nonatomic)
					)
				}
			}

			@inline(never) private static var __associated_intArrayKey: UnsafeRawPointer {
				let f: @convention(c) () -> Void = {
				}
				return unsafeBitCast(f, to: UnsafeRawPointer.self)
			}
			"""
		}
	}

	@Test
	func testOptionalBool() throws {
		assertMacro {
			"""
			@Associated(.retain(.nonatomic))
			var bool: Bool?
			"""
		} expansion: {
			"""
			var bool: Bool? {
				get {
					objc_getAssociatedObject(
						self,
						Self.__associated_boolKey
					) as? Bool
					?? nil
				}
				set {
					objc_setAssociatedObject(
						self,
						Self.__associated_boolKey,
						newValue,
						.retain(.nonatomic)
					)
				}
			}

			@inline(never) private static var __associated_boolKey: UnsafeRawPointer {
				let f: @convention(c) () -> Void = {
				}
				return unsafeBitCast(f, to: UnsafeRawPointer.self)
			}
			"""
		}
	}

	@Test
	func testDictionary() throws {
		assertMacro {
			"""
			@Associated(.retain(.nonatomic))
			var dic: [String: String] = ["t": "a"]
			"""
		} expansion: {
			"""
			var dic: [String: String] {
				get {
					if let value = objc_getAssociatedObject(
						self,
						Self.__associated_dicKey
					) as? [String: String] {
						return value
					} else {
						let value: [String: String] = ["t": "a"]
						objc_setAssociatedObject(
							self,
							Self.__associated_dicKey,
							value,
							.retain(.nonatomic)
						)
						return value
					}
				}
				set {
					objc_setAssociatedObject(
						self,
						Self.__associated_dicKey,
						newValue,
						.retain(.nonatomic)
					)
				}
			}

			@inline(never) private static var __associated_dicKey: UnsafeRawPointer {
				let f: @convention(c) () -> Void = {
				}
				return unsafeBitCast(f, to: UnsafeRawPointer.self)
			}
			"""
		}
	}

	@Test
	func testWillSet() throws {
		assertMacro {
			"""
			@Associated(.retain(.nonatomic))
			var string: String = "text" {
				willSet {
					print("willSet: old", string)
					print("willSet: new", newValue)
				}
			}
			"""
		} expansion: {
			"""
			var string: String {
				willSet {
					print("willSet: old", string)
					print("willSet: new", newValue)
				}
				get {
					if let value = objc_getAssociatedObject(
						self,
						Self.__associated_stringKey
					) as? String {
						return value
					} else {
						let value: String = "text"
						objc_setAssociatedObject(
							self,
							Self.__associated_stringKey,
							value,
							.retain(.nonatomic)
						)
						return value
					}
				}

				set {
					let willSet: (String) -> Void = { [self] newValue in
						print("willSet: old", string)
						print("willSet: new", newValue)
					}
					willSet(newValue)

					objc_setAssociatedObject(
						self,
						Self.__associated_stringKey,
						newValue,
						.retain(.nonatomic)
					)
				}
			}

			@inline(never) private static var __associated_stringKey: UnsafeRawPointer {
				let f: @convention(c) () -> Void = {
				}
				return unsafeBitCast(f, to: UnsafeRawPointer.self)
			}
			"""
		}
	}

	@Test
	func testDidSet() throws {
		assertMacro {
			"""
			@Associated(.retain(.nonatomic))
			var string: String = "text" {
				didSet {
					print("didSet: old", oldValue)
				}
			}
			"""
		} expansion: {
			"""
			var string: String {
				didSet {
					print("didSet: old", oldValue)
				}
				get {
					if let value = objc_getAssociatedObject(
						self,
						Self.__associated_stringKey
					) as? String {
						return value
					} else {
						let value: String = "text"
						objc_setAssociatedObject(
							self,
							Self.__associated_stringKey,
							value,
							.retain(.nonatomic)
						)
						return value
					}
				}

				set {
					let oldValue = string
					objc_setAssociatedObject(
						self,
						Self.__associated_stringKey,
						newValue,
						.retain(.nonatomic)
					)

					let didSet: (String) -> Void = { [self] oldValue in
						print("didSet: old", oldValue)
					}
					didSet(oldValue)
				}
			}

			@inline(never) private static var __associated_stringKey: UnsafeRawPointer {
				let f: @convention(c) () -> Void = {
				}
				return unsafeBitCast(f, to: UnsafeRawPointer.self)
			}
			"""
		}
	}

	@Test
	func testWillSetAndDidSet() throws {
		assertMacro {
			"""
			@Associated(.retain(.nonatomic))
			var string: String = "text" {
				willSet {
					print("willSet: old", string)
					print("willSet: new", newValue)
				}
				didSet {
					print("didSet: old", oldValue)
				}
			}
			"""
		} expansion: {
			"""
			var string: String {
				willSet {
					print("willSet: old", string)
					print("willSet: new", newValue)
				}
				didSet {
					print("didSet: old", oldValue)
				}
				get {
					if let value = objc_getAssociatedObject(
						self,
						Self.__associated_stringKey
					) as? String {
						return value
					} else {
						let value: String = "text"
						objc_setAssociatedObject(
							self,
							Self.__associated_stringKey,
							value,
							.retain(.nonatomic)
						)
						return value
					}
				}

				set {
					let willSet: (String) -> Void = { [self] newValue in
						print("willSet: old", string)
						print("willSet: new", newValue)
					}
					willSet(newValue)

					let oldValue = string
					objc_setAssociatedObject(
						self,
						Self.__associated_stringKey,
						newValue,
						.retain(.nonatomic)
					)

					let didSet: (String) -> Void = { [self] oldValue in
						print("didSet: old", oldValue)
					}
					didSet(oldValue)
				}
			}

			@inline(never) private static var __associated_stringKey: UnsafeRawPointer {
				let f: @convention(c) () -> Void = {
				}
				return unsafeBitCast(f, to: UnsafeRawPointer.self)
			}
			"""
		}
	}

	@Test
	func testWillSetWithArgument() throws {
		assertMacro {
			"""
			@Associated(.retain(.nonatomic))
			var string: String = "text" {
				willSet(new) {
					print("willSet: old", string)
					print("willSet: new", new)
				}
			}
			"""
		} expansion: {
			"""
			var string: String {
				willSet(new) {
					print("willSet: old", string)
					print("willSet: new", new)
				}
				get {
					if let value = objc_getAssociatedObject(
						self,
						Self.__associated_stringKey
					) as? String {
						return value
					} else {
						let value: String = "text"
						objc_setAssociatedObject(
							self,
							Self.__associated_stringKey,
							value,
							.retain(.nonatomic)
						)
						return value
					}
				}

				set {
					let willSet: (String) -> Void = { [self] new in
						print("willSet: old", string)
						print("willSet: new", new)
					}
					willSet(newValue)

					objc_setAssociatedObject(
						self,
						Self.__associated_stringKey,
						newValue,
						.retain(.nonatomic)
					)
				}
			}

			@inline(never) private static var __associated_stringKey: UnsafeRawPointer {
				let f: @convention(c) () -> Void = {
				}
				return unsafeBitCast(f, to: UnsafeRawPointer.self)
			}
			"""
		}
	}

	@Test
	func testDidSetWithArgument() throws {
		assertMacro {
			"""
			@Associated(.retain(.nonatomic))
			var string: String = "text" {
				didSet(old) {
					print("didSet: old", old)
				}
			}
			"""
		} expansion: {
			"""
			var string: String {
				didSet(old) {
					print("didSet: old", old)
				}
				get {
					if let value = objc_getAssociatedObject(
						self,
						Self.__associated_stringKey
					) as? String {
						return value
					} else {
						let value: String = "text"
						objc_setAssociatedObject(
							self,
							Self.__associated_stringKey,
							value,
							.retain(.nonatomic)
						)
						return value
					}
				}

				set {
					let oldValue = string
					objc_setAssociatedObject(
						self,
						Self.__associated_stringKey,
						newValue,
						.retain(.nonatomic)
					)

					let didSet: (String) -> Void = { [self] old in
						print("didSet: old", old)
					}
					didSet(oldValue)
				}
			}

			@inline(never) private static var __associated_stringKey: UnsafeRawPointer {
				let f: @convention(c) () -> Void = {
				}
				return unsafeBitCast(f, to: UnsafeRawPointer.self)
			}
			"""
		}
	}

	@Test
	func testModernWritingStyle() throws {
		assertMacro {
			"""
			@Associated(.copy(.nonatomic))
			var string: String = "text"
			"""
		} expansion: {
			"""
			var string: String {
				get {
					if let value = objc_getAssociatedObject(
						self,
						Self.__associated_stringKey
					) as? String {
						return value
					} else {
						let value: String = "text"
						objc_setAssociatedObject(
							self,
							Self.__associated_stringKey,
							value,
							.copy(.nonatomic)
						)
						return value
					}
				}
				set {
					objc_setAssociatedObject(
						self,
						Self.__associated_stringKey,
						newValue,
						.copy(.nonatomic)
					)
				}
			}

			@inline(never) private static var __associated_stringKey: UnsafeRawPointer {
				let f: @convention(c) () -> Void = {
				}
				return unsafeBitCast(f, to: UnsafeRawPointer.self)
			}
			"""
		}
	}

	// MARK: Diagnostics test

	@Test
	func testDiagnosticsDeclarationType() throws {
		assertMacro {
			"""
			@Associated(.retain(.nonatomic))
			struct Item {}
			"""
		} diagnostics: {
			"""
			@Associated(.retain(.nonatomic))
			╰─ 🛑 `@Associated` must be attached to the property declaration.
			struct Item {}
			"""
		}
	}

	@Test
	func testDiagnosticsGetterAndSetter() throws {
		assertMacro {
			"""
			@Associated(.retain(.nonatomic))
			var string: String? {
				get { "" }
				set {}
			}
			"""
		} diagnostics: {
			"""
			@Associated(.retain(.nonatomic))
			var string: String? {
				get { "" }
				set {}
			 ┬─────
			 ╰─ 🛑 getter and setter must not be implemented when using `@Associated`.
			}
			"""
		}
	}

	@Test
	func testDiagnosticsInitialValue() throws {
		assertMacro {
			"""
			@Associated(.retain(.nonatomic))
			var string: String
			"""
		} diagnostics: {
			"""
			@Associated(.retain(.nonatomic))
			╰─ 🛑 Initial values must be specified when using `@Associated`.
			var string: String
			"""
		}
	}

	@Test
	func testDiagnosticsSpecifyType() throws {
		assertMacro {
			"""
			@Associated(.retain(.nonatomic))
			var string = ["text", 123]
			"""
		} diagnostics: {
			"""
			@Associated(.retain(.nonatomic))
			var string = ["text", 123]
			    ┬─────
			    ├─ 🛑 Specify a type explicitly when using `@Associated`.
			    ╰─ 🛑 Specify a type explicitly when using `@Associated`.
			"""
		}
	}
}
#endif
