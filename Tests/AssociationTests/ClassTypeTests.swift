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

import Association
import Foundation
import Testing

class ClassType {
	@Associated(.retain(.nonatomic))
	@objc var int: Int = 0

	@Associated(.retain(.nonatomic))
	var optionalDouble: Double? = 123.4

	@Associated(.retain(.nonatomic))
	var optionalString: String?

	@Associated(.retain(.nonatomic))
	var optionalBool: Bool? = false

	@Associated(.retain(.nonatomic))
	var implicitlyUnwrappedString: String!

	@Associated(.retain(.nonatomic))
	var classType: ClassType2 = .init()

	@Suite
	struct Tests {
		@Test
		func testKeysUnique() {
			let keys = [
				ClassType.__associated_intKey,
				ClassType.__associated_optionalDoubleKey,
				ClassType.__associated_optionalStringKey,
				ClassType.__associated_optionalBoolKey,
				ClassType.__associated_implicitlyUnwrappedStringKey,
				ClassType.__associated_classTypeKey,
			]
			#expect(Set(keys).count == keys.count)
		}

		@Test
		func testAssignments() {
			let item = ClassType()
			#expect(item.int == 0)
			#expect(item.optionalDouble == 123.4)
			#expect(item.optionalString == nil)
			#expect(item.optionalBool == false)
			#expect(item.implicitlyUnwrappedString == nil)

			item.int = 123
			#expect(item.int == 123)

			item.optionalDouble = 456.7
			#expect(item.optionalDouble == 456.7)

			item.optionalString = "hello"
			#expect(item.optionalString == "hello")

			item.optionalBool = true
			#expect(item.optionalBool == true)

			item.implicitlyUnwrappedString = "world"
			#expect(item.implicitlyUnwrappedString == "world")

			item.int = 0
			#expect(item.int == 0)

			item.optionalDouble = nil
			#expect(item.optionalDouble == nil)

			item.optionalString = nil
			#expect(item.optionalString == nil)

			item.optionalBool = nil
			#expect(item.optionalBool == nil)

			item.implicitlyUnwrappedString = nil
			#expect(item.implicitlyUnwrappedString == nil)
		}

		@Test
		func testOptional() {
			let item = ClassType()
			#expect(item.optionalDouble == 123.4)

			item.optionalDouble = nil
			#expect(item.optionalDouble == nil)

			item.implicitlyUnwrappedString = "hello"
			#expect(item.implicitlyUnwrappedString == "hello")

			item.implicitlyUnwrappedString = nil
			#expect(item.implicitlyUnwrappedString == nil)

			item.implicitlyUnwrappedString = "modified hello"
			#expect(item.implicitlyUnwrappedString == "modified hello")
		}

		@Test
		func testSetDefaultValue() {
			let item = ClassType()
			#expect(item.classType === item.classType)
		}

		@Test
		func testProtocol() {
			let item = ClassType()
			#expect(item.definedInProtocol == "hello")

			item.definedInProtocol = "modified"
			#expect(item.definedInProtocol == "modified")
		}
	}
}

class ClassType2 {}

protocol ProtocolType: AnyObject {}

extension ProtocolType {
	@Associated(.retain(.nonatomic))
	var definedInProtocol: String = "hello"
}

extension ClassType: ProtocolType {}
