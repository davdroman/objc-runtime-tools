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

public import Foundation

extension Swizzling {
	/// Hook an `@objc dynamic` instance method via selector on the specified class..
	@discardableResult
	public static func __swizzle<MethodSignature, HookSignature>(
		_ class: NSObject.Type,
		_ selector: Selector,
		methodSignature: MethodSignature.Type,
		hookSignature: HookSignature.Type,
		_ implementation: (TypedHook<MethodSignature, HookSignature>) -> HookSignature?
	) throws(SwizzlingError) -> AnyHook {
		do {
			return try SwizzlingHook(class: `class` as AnyClass, selector: selector, implementation: implementation).apply()
		} catch let error as SwizzlingError {
			throw error
		} catch let error {
			throw SwizzlingError.unknownError(error.localizedDescription)
		}
	}
}
