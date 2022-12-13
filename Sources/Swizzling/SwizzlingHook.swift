/// MIT License
///
/// Copyright (c) 2020 Peter Steinberger
///
/// Permission is hereby granted, free of charge, to any person obtaining a copy
/// of this software and associated documentation files (the "Software"), to deal
/// in the Software without restriction, including without limitation the rights
/// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
/// copies of the Software, and to permit persons to whom the Software is
/// furnished to do so, subject to the following conditions:
///
/// The above copyright notice and this permission notice shall be included in all
/// copies or substantial portions of the Software.
///
/// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
/// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
/// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
/// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
/// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
/// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
/// SOFTWARE.

import Foundation

/// A hook to an instance method and stores both the original and new implementation.
final class SwizzlingHook<MethodSignature, HookSignature>: TypedHook<MethodSignature, HookSignature> {
	/// Initialize a new hook to swizzle an instance method.
	init(
		`class`: AnyClass,
		selector: Selector,
		implementation: (SwizzlingHook<MethodSignature, HookSignature>) -> HookSignature? // this must be optional or swift runtime will crash. Or swiftc may segfault. Compiler bug?
	) throws {
		try super.init(class: `class`, selector: selector)
		replacementIMP = imp_implementationWithBlock(implementation(self) as Any)
	}

	override func replaceImplementation() throws {
		let method = try validate()
		origIMP = class_replaceMethod(`class`, selector, replacementIMP, method_getTypeEncoding(method))
		guard origIMP != nil else { throw SwizzlingError.nonExistingImplementation(`class`, selector) }
		Swizzling.log("Swizzled -[\(`class`).\(selector)] IMP: \(origIMP!) -> \(replacementIMP!)")
	}

	override func resetImplementation() throws {
		let method = try validate(expectedState: .swizzled)
		precondition(origIMP != nil)
		let previousIMP = class_replaceMethod(`class`, selector, origIMP!, method_getTypeEncoding(method))
		guard previousIMP == replacementIMP else { throw SwizzlingError.unexpectedImplementation(`class`, selector, previousIMP) }
		Swizzling.log("Restored -[\(`class`).\(selector)] IMP: \(origIMP!)")
	}

	/// The original implementation is cached at hook time.
	override var original: MethodSignature {
		unsafeBitCast(origIMP, to: MethodSignature.self)
	}
}

#if DEBUG
extension SwizzlingHook: CustomDebugStringConvertible {
	var debugDescription: String {
		"\(selector) -> \(String(describing: origIMP))"
	}
}
#endif
