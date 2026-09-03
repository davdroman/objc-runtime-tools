import ObjectiveC.runtime

// MARK: Getter & Setter

@discardableResult
@freestanding(expression)
public macro swizzle<Object, Result>(
	getter: KeyPath<Object, Result>,
	returning: Result.Type,
	implementation: (LocalSelf<Object>) -> Result,
) -> AnyHook = #externalMacro(module: "SwizzlingMacro", type: "SwizzleMacro")

@discardableResult
@freestanding(expression)
public macro swizzle<Object, Param>(
	setter: KeyPath<Object, Param>,
	param: Param.Type,
	implementation: (LocalSelf<Object>, Param) -> Void,
) -> AnyHook = #externalMacro(module: "SwizzlingMacro", type: "SwizzleMacro")

// MARK: Functions - Non Returning

@available(*, deprecated, renamed: "swizzle(_:params:implementation:)")
@discardableResult
@freestanding(expression)
public macro swizzle<Object, Param>(
	_ function: (Object) -> (Param) -> Void,
	param: Param.Type,
	implementation: (LocalSelf<Object>, Param) -> Void,
) -> AnyHook = #externalMacro(module: "SwizzlingMacro", type: "SwizzleMacro")

@discardableResult
@freestanding(expression)
public macro swizzle<Object, each Param>(
	_ function: (Object) -> (repeat each Param) -> Void,
	params: repeat (each Param).Type,
	implementation: (LocalSelf<Object>, repeat each Param) -> Void,
) -> AnyHook = #externalMacro(module: "SwizzlingMacro", type: "SwizzleMacro")

// MARK: Functions - Returning

@available(*, deprecated, renamed: "swizzle(_:params:returning:implementation:)")
@discardableResult
@freestanding(expression)
public macro swizzle<Object, Param, Result>(
	_ function: (Object) -> (Param) -> Result,
	param: Param.Type,
	returning: Result.Type,
	implementation: (LocalSelf<Object>, Param) -> Result,
) -> AnyHook = #externalMacro(module: "SwizzlingMacro", type: "SwizzleMacro")

@discardableResult
@freestanding(expression)
public macro swizzle<Object, each Param, Result>(
	_ function: (Object) -> (repeat each Param) -> Result,
	params: repeat (each Param).Type,
	returning: Result.Type,
	implementation: (LocalSelf<Object>, repeat each Param) -> Result,
) -> AnyHook = #externalMacro(module: "SwizzlingMacro", type: "SwizzleMacro")
