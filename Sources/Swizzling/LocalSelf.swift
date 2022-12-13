/// A property wrapper that exists purely for the sake of the `swizzle` macro.
///
/// Normally the `self` keyword is reserved and cannot normally be used as a closure parameter.
///
/// `LocalSelf` allows the swizzled implementation block to have a `self` different from the outer
/// scope's `self`.
///
/// This is achieved by declaring `$self` as a closure parameter, which shadows the outer scope's `self`.
///
/// It's unclear whether this is a bug or a feature, but it's a nifty trick for now.
@dynamicMemberLookup
@propertyWrapper
public struct LocalSelf<Object: AnyObject> {
	// this isn't meant to be accessed directly anyway as it's purely cosmetic — the macro
	// overrides any usage of $self as `self`, so no danger of memory leaks here
	public var wrappedValue: Object

	public init(wrappedValue: Object) {
		self.wrappedValue = wrappedValue
	}

	public init(projectedValue: Self) {
		self = projectedValue
	}

	public var projectedValue: Self {
		self
	}

	// this is not used in the final code but the compiler needs this for expressions
	// like $self.isDragging to type check before macro expansion
	public subscript<Value>(dynamicMember keyPath: KeyPath<Object, Value>) -> Value {
		wrappedValue[keyPath: keyPath]
	}

	// this is not used in the final code but the compiler needs this for expressions
	// like $self.isHidden to type check before macro expansion
	public subscript<Value>(dynamicMember keyPath: ReferenceWritableKeyPath<Object, Value>) -> Value {
		get { wrappedValue[keyPath: keyPath] }
		nonmutating set { wrappedValue[keyPath: keyPath] = newValue }
	}
}
