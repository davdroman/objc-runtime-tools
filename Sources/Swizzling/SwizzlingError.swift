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

/// The list of errors while hooking a method.
public enum SwizzlingError: LocalizedError {
	/// The method couldn't be found. Usually happens for when you use stringified selectors that do not exist.
	case methodNotFound(AnyClass, Selector)

	/// The implementation could not be found. Class must be in a weird state for this to happen.
	case nonExistingImplementation(AnyClass, Selector)

	/// Someone else changed the implementation; reverting removed this implementation.
	/// This is bad, likely someone else also hooked this method. If you are in such a codebase, do not use revert.
	case unexpectedImplementation(AnyClass, Selector, IMP?)

	/// Unable to register subclass for object-based interposing.
	case failedToAllocateClassPair(class: AnyClass, subclassName: String)

	/// Unable to add method  for object-based interposing.
	case unableToAddMethod(AnyClass, Selector)

	/// Object-based hooking does not work if an object is using KVO.
	/// The KVO mechanism also uses subclasses created at runtime but doesn't check for additional overrides.
	/// Adding a hook eventually crashes the KVO management code so we reject hooking altogether in this case.
	case keyValueObservationDetected(AnyObject)

	/// Object is lying about it's actual class metadata.
	/// This usually happens when other swizzling libraries (like Aspects) also interfere with a class.
	/// While this might just work, it's not worth risking a crash, so similar to KVO this case is rejected.
	///
	/// @note Printing classes in Swift uses the class posing mechanism.
	/// Use `NSClassFromString` to get the correct name.
	case objectPosingAsDifferentClass(AnyObject, actualClass: AnyClass)

	/// Can't revert or apply if already done so.
	case invalidState(expectedState: AnyHook.State)

	/// Unable to remove hook.
	case resetUnsupported(_ reason: String)

	/// Generic failure
	case unknownError(_ reason: String)
}

extension SwizzlingError: Equatable {
	// Lazy equating via string compare
	public static func == (lhs: SwizzlingError, rhs: SwizzlingError) -> Bool {
		lhs.errorDescription == rhs.errorDescription
	}

	public var errorDescription: String? {
		switch self {
		case let .methodNotFound(klass, selector):
			"Method not found: -[\(klass) \(selector)]"
		case let .nonExistingImplementation(klass, selector):
			"Implementation not found: -[\(klass) \(selector)]"
		case let .unexpectedImplementation(klass, selector, IMP):
			"Unexpected Implementation in -[\(klass) \(selector)]: \(String(describing: IMP))"
		case let .failedToAllocateClassPair(klass, subclassName):
			"Failed to allocate class pair: \(klass), \(subclassName)"
		case let .unableToAddMethod(klass, selector):
			"Unable to add method: -[\(klass) \(selector)]"
		case let .keyValueObservationDetected(obj):
			"Unable to hook object that uses Key Value Observing: \(obj)"
		case let .objectPosingAsDifferentClass(obj, actualClass):
			"Unable to hook \(type(of: obj)) posing as \(NSStringFromClass(actualClass))/"
		case let .invalidState(expectedState):
			"Invalid State. Expected: \(expectedState)"
		case let .resetUnsupported(reason):
			"Reset Unsupported: \(reason)"
		case let .unknownError(reason):
			reason
		}
	}

	@discardableResult func log() -> SwizzlingError {
		Swizzling.log(self.errorDescription!)
		return self
	}
}

extension SwizzlingError: @unchecked Sendable {}
