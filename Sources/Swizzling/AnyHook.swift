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

/// Base class, represents a hook to exactly one method.
public class AnyHook {
	/// The class this hook is based on.
	public let `class`: AnyClass

	/// The selector this hook swizzles.
	public let selector: Selector

	/// The current state of the hook.
	public internal(set) var state = State.prepared

	// else we validate init order
	var replacementIMP: IMP! = nil

	// fetched at apply time, changes late, thus class requirement
	var origIMP: IMP? = nil

	/// The possible task states
	public enum State: Equatable, Sendable {
		/// The task is prepared to be swizzled.
		case prepared

		/// The method has been successfully swizzled.
		case swizzled

		/// An error happened while interposing a method.
		indirect case error(SwizzlingError)
	}

	init(`class`: AnyClass, selector: Selector) throws {
		self.selector = selector
		self.class = `class`

		// Check if method exists
		try validate()
	}

	func replaceImplementation() throws {
		preconditionFailure("Not implemented")
	}

	func resetImplementation() throws {
		preconditionFailure("Not implemented")
	}

	/// Apply the swizzle hook.
	@discardableResult public func apply() throws -> AnyHook {
		try execute(newState: .swizzled) { try replaceImplementation() }
		return self
	}

	/// Revert the swizzle hook.
	@discardableResult public func revert() throws -> AnyHook {
		try execute(newState: .prepared) { try resetImplementation() }
		return self
	}

	/// Validate that the selector exists on the active class.
	@discardableResult func validate(expectedState: State = .prepared) throws -> Method {
		guard let method = class_getInstanceMethod(`class`, selector) else { throw SwizzlingError.methodNotFound(`class`, selector) }
		guard state == expectedState else { throw SwizzlingError.invalidState(expectedState: expectedState) }
		return method
	}

	private func execute(newState: State, task: () throws -> Void) throws {
		do {
			try task()
			state = newState
		} catch let error as SwizzlingError {
			state = .error(error)
			throw error
		}
	}

	/// Release the hook block if possible.
	public func cleanup() {
		switch state {
		case .prepared:
			Swizzling.log("Releasing -[\(`class`).\(selector)] IMP: \(replacementIMP!)")
			imp_removeBlock(replacementIMP)
		case .swizzled:
			Swizzling.log("Keeping -[\(`class`).\(selector)] IMP: \(replacementIMP!)")
		case let .error(error):
			Swizzling.log("Leaking -[\(`class`).\(selector)] IMP: \(replacementIMP!) due to error: \(error)")
		}
	}
}

/// Hook baseclass with generic signatures.
public class TypedHook<MethodSignature, HookSignature>: AnyHook {
	/// The original implementation of the hook. Might be looked up at runtime. Do not cache this.
	public var original: MethodSignature {
		preconditionFailure("Always override")
	}
}
