import ObjectiveC.runtime

// MARK: Getter & Setter

@discardableResult
@freestanding(expression)
public macro swizzle<Object, Result>(
	getter: KeyPath<Object, Result>,
	returning: Result.Type,
	implementation: (LocalSelf<Object>) -> Result
) -> AnyHook = #externalMacro(module: "SwizzlingMacro", type: "SwizzleMacro")

@discardableResult
@freestanding(expression)
public macro swizzle<Object, Param>(
	setter: KeyPath<Object, Param>,
	param: Param.Type,
	implementation: (LocalSelf<Object>, Param) -> Void
) -> AnyHook = #externalMacro(module: "SwizzlingMacro", type: "SwizzleMacro")

// MARK: Functions - Non Returning

// NOTE: this is only needed because some weird behavior in the compiler causes the variadic
// version below to throw a false positive error when passing a single param under very specific
// conditions. This version is a workaround that can be used in those cases.
//
// Reproducible case:
//	```swift
//	try #swizzle(
//		SUT.functionWithParamsWithoutReturn,
//		params: Int.self
//	) { $self, state in
//		self.functionWithParamsWithoutReturn(state) // 🛑 error: Cannot pass value pack expansion to non-pack parameter of type 'Int'
//	}
//	```
@discardableResult
@freestanding(expression)
public macro swizzle<Object, Param>(
	_ function: (Object) -> (Param) -> Void,
	param: Param.Type,
	implementation: (LocalSelf<Object>, Param) -> Void
) -> AnyHook = #externalMacro(module: "SwizzlingMacro", type: "SwizzleMacro")

@discardableResult
@freestanding(expression)
public macro swizzle<Object, each Param>(
	_ function: (Object) -> (repeat each Param) -> Void,
	params: repeat (each Param).Type,
	implementation: (LocalSelf<Object>, repeat each Param) -> Void
) -> AnyHook = #externalMacro(module: "SwizzlingMacro", type: "SwizzleMacro")

// MARK: Functions - Returning

// NOTE: this is only needed because some weird behavior in the compiler causes the variadic
// version below to throw a false positive error when passing a single param under very specific
// conditions. This version is a workaround that can be used in those cases.
//
// Reproducible case:
//	```swift
//	try #swizzle(
//		SUT.functionWithParamsWithReturn,
//		params: Int.self,
//		returning: Int.self
//	) { $self, state in
//		self.functionWithParamsWithReturn(state) // 🛑 error: Cannot pass value pack expansion to non-pack parameter of type 'Int'
//	}
@discardableResult
@freestanding(expression)
public macro swizzle<Object, Param, Result>(
	_ function: (Object) -> (Param) -> Result,
	param: Param.Type,
	returning: Result.Type,
	implementation: (LocalSelf<Object>, Param) -> Result
) -> AnyHook = #externalMacro(module: "SwizzlingMacro", type: "SwizzleMacro")

@discardableResult
@freestanding(expression)
public macro swizzle<Object, each Param, Result>(
	_ function: (Object) -> (repeat each Param) -> Result,
	params: repeat (each Param).Type,
	returning: Result.Type,
	implementation: (LocalSelf<Object>, repeat each Param) -> Result
) -> AnyHook = #externalMacro(module: "SwizzlingMacro", type: "SwizzleMacro")
