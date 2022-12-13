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

import ObjectiveC.runtime

// A typealias for `objc_AssociationPolicy`.
public typealias Policy = objc_AssociationPolicy

/// Extension for objc_AssociationPolicy to provide a more Swift-friendly interface.
extension objc_AssociationPolicy {
	/// Represents the atomicity options for associated objects.
	public enum Atomicity {
		/// Indicates that the associated object should be stored atomically.
		case atomic
		/// Indicates that the associated object should be stored non-atomically.
		case nonatomic
	}

	/// A property wrapper that corresponds to `.OBJC_ASSOCIATION_ASSIGN` policy.
	public static var assign: Self { .OBJC_ASSOCIATION_ASSIGN }

	/// Create an association policy for retaining an associated object with the specified atomicity.
	///
	/// - Parameter atomicity: The desired atomicity for the associated object.
	/// - Returns: The appropriate association policy for retaining with the specified atomicity.
	public static func retain(_ atomicity: Atomicity) -> Self {
		switch atomicity {
		case .atomic:
			.OBJC_ASSOCIATION_RETAIN
		case .nonatomic:
			.OBJC_ASSOCIATION_RETAIN_NONATOMIC
		}
	}

	/// Create an association policy for copying an associated object with the specified atomicity.
	///
	/// - Parameter atomicity: The desired atomicity for the associated object.
	/// - Returns: The appropriate association policy for copying with the specified atomicity.
	public static func copy(_ atomicity: Atomicity) -> Self {
		switch atomicity {
		case .atomic:
			.OBJC_ASSOCIATION_COPY
		case .nonatomic:
			.OBJC_ASSOCIATION_COPY_NONATOMIC
		}
	}
}
