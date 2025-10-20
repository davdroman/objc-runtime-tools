#if canImport(SwizzlingMacro)
import MacroTesting
import Swizzling
import Testing

@testable import SwizzlingMacro

@Suite(
	.macros(
		["swizzle": SwizzleMacro.self],
		indentationWidth: .tab,
		record: .missing
	)
)
struct SwizzleMacroTests {}

// TODO: add additional assertions with fully spelled out closure parameters in each test case

/// Test property swizzling
extension SwizzleMacroTests {
	@Test(arguments: ["self", "$self", "`self`"])
	func swizzleGetter(selfLabel: String) {
		assertMacro {
			"""
			#swizzle(
				getter: \\UIView.isHidden,
				returning: Bool.self
			) { $self in
				print("Before")
				let hidden = \(selfLabel).isHidden
				print("After")
				return hidden
			}
			"""
		} expansion: {
			"""
			Swizzling.__swizzle(
				UIView.self,
				#selector(getter: UIView.isHidden),
				methodSignature: (@convention(c) (UIView, Selector) -> Bool).self,
				hookSignature: (@convention(block) (UIView) -> Bool).self
			) { hook in
				return { `self` in
					print("Before")
					let hidden = hook.original(`self`, hook.selector)
					print("After")
					return hidden
				}
			}
			"""
		}
	}

	@Test(arguments: ["self", "$self", "`self`"])
	func swizzleSetter(selfLabel: String) {
		assertMacro {
			"""
			#swizzle(
				setter: \\UIView.isHidden,
				param: Bool.self
			) { $self, newValue in
				print("Before")
				\(selfLabel).isHidden = newValue
				print("After")
			}
			"""
		} expansion: {
			"""
			Swizzling.__swizzle(
				UIView.self,
				#selector(setter: UIView.isHidden),
				methodSignature: (@convention(c) (UIView, Selector, Bool) -> Void).self,
				hookSignature: (@convention(block) (UIView, Bool) -> Void).self
			) { hook in
				return { `self`, newValue in
					print("Before")
					hook.original(`self`, hook.selector, newValue)
					print("After")
				}
			}
			"""
		}
	}
}

/// Test function swizzling
extension SwizzleMacroTests {
	@Test(arguments: ["self", "$self", "`self`"])
	func swizzleFunctionWithoutParametersWithoutReturn(selfLabel: String) {
		assertMacro {
			"""
			#swizzle(
				UIView.layoutSubviews
			) { $self in
				print("Before")
				\(selfLabel).layoutSubviews()
				print("After")
			}
			"""
		} expansion: {
			"""
			Swizzling.__swizzle(
				UIView.self,
				#selector(UIView.layoutSubviews),
				methodSignature: (@convention(c) (UIView, Selector) -> Void).self,
				hookSignature: (@convention(block) (UIView) -> Void).self
			) { hook in
				return { `self` in
					print("Before")
					hook.original(`self`, hook.selector)
					print("After")
				}
			}
			"""
		}
	}

	@Test(arguments: ["self", "$self", "`self`"])
	func swizzleFunctionWithoutParametersWithReturn(selfLabel: String) {
		assertMacro {
			"""
			#swizzle(
				UITextField.resignFirstResponder,
				returning: Bool.self
			) { $self in
				print("Before")
				let resigned = \(selfLabel).resignFirstResponder()
				print("After")
				return resigned
			}
			"""
		} expansion: {
			"""
			Swizzling.__swizzle(
				UITextField.self,
				#selector(UITextField.resignFirstResponder),
				methodSignature: (@convention(c) (UITextField, Selector) -> Bool).self,
				hookSignature: (@convention(block) (UITextField) -> Bool).self
			) { hook in
				return { `self` in
					print("Before")
					let resigned = hook.original(`self`, hook.selector)
					print("After")
					return resigned
				}
			}
			"""
		}
	}

	@Test(arguments: ["param", "params"], ["self", "$self", "`self`"])
	func swizzleFunctionWithParametersWithoutReturn(paramOrParams: String, selfLabel: String) {
		assertMacro {
			"""
			#swizzle(
				UIViewController.viewWillAppear(_:),
				\(paramOrParams): Bool.self
			) { $self, animated in
				print("Before")
				\(selfLabel).viewWillAppear(animated)
				print("After")
			}
			"""
		} expansion: {
			"""
			Swizzling.__swizzle(
				UIViewController.self,
				#selector(UIViewController.viewWillAppear(_:)),
				methodSignature: (@convention(c) (UIViewController, Selector, Bool) -> Void).self,
				hookSignature: (@convention(block) (UIViewController, Bool) -> Void).self
			) { hook in
				return { `self`, animated in
					print("Before")
					hook.original(`self`, hook.selector, animated)
					print("After")
				}
			}
			"""
		}
	}

	@Test(arguments: ["self", "$self", "`self`"])
	func swizzleFunctionWithParametersWithReturn(selfLabel: String) {
		assertMacro {
			"""
			#swizzle(
				UIScrollView.touchesShouldBegin(_:with:in:),
				params: Set<UITouch>.self, UIEvent?.self, UIView.self,
				returning: Bool.self
			) { $self, touches, event, view in
				print("Before")
				let should = \(selfLabel).touchesShouldBegin(touches, with: event, in: view)
				print("After")
				return should
			}
			"""
		} expansion: {
			"""
			Swizzling.__swizzle(
				UIScrollView.self,
				#selector(UIScrollView.touchesShouldBegin(_:with:in:)),
				methodSignature: (@convention(c) (UIScrollView, Selector, Set<UITouch>, UIEvent?, UIView) -> Bool).self,
				hookSignature: (@convention(block) (UIScrollView, Set<UITouch>, UIEvent?, UIView) -> Bool).self
			) { hook in
				return { `self`, touches, event, view in
					print("Before")
					let should = hook.original(`self`, hook.selector, touches, event, view)
					print("After")
					return should
				}
			}
			"""
		}
	}
}
#endif
