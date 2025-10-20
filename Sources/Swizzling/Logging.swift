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

private final class Atomic<Value> {
	private let lock = NSLock()
	private var value: Value

	init(_ value: Value) {
		self.value = value
	}

	func withLock<R>(_ body: (inout Value) throws -> R) rethrows -> R {
		lock.lock()
		defer { lock.unlock() }
		return try body(&value)
	}
}

extension Atomic: @unchecked Sendable where Value: Sendable {}

// MARK: Logging

public enum Swizzling {
	private static let loggingState = Atomic(false)

	/// Logging uses print and is minimal. Stored in a lock to keep writes concurrency-safe.
	public static var isLoggingEnabled: Bool {
		get { loggingState.withLock { $0 } }
		set { loggingState.withLock { $0 = newValue } }
	}

	/// Simple log wrapper for print.
	static func log(_ object: Any) {
		if isLoggingEnabled {
			print("[Swizzling] \(object)")
		}
	}
}
