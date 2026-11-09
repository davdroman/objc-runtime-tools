public import Foundation

/// A delegate that takes an object's delegate slot and forwards every call it doesn't handle itself to the delegate
/// it replaced.
///
/// Subclass it with the delegate protocol as `Delegate`, conform the subclass to that protocol, and implement only
/// the methods to intercept. Implemented methods replace the original delegate's, so call through ``forwardee`` to
/// keep its behavior:
///
/// ```swift
/// final class DismissInterceptor: DelegateProxy<any UIAdaptivePresentationControllerDelegate>,
/// 	UIAdaptivePresentationControllerDelegate
/// {
/// 	var isDismissible = true
///
/// 	func presentationControllerShouldDismiss(_ controller: UIPresentationController) -> Bool {
/// 		isDismissible && forwardee?.presentationControllerShouldDismiss?(controller) ?? true
/// 	}
/// }
///
/// interceptor.install(on: presentationController, at: \.delegate)
/// ```
///
/// The proxy holds the replaced delegate weakly, like the slot did, so the object that owns it keeps it alive.
/// Releasing the proxy puts the replaced delegate back unless the slot has been given another delegate since.
@MainActor
open class DelegateProxy<Delegate>: NSObject {
	/// Read by the forwarding overrides, which the Objective-C runtime calls without isolation. Only written on the
	/// main actor, and delegates are called on the thread that owns them.
	private nonisolated(unsafe) weak var forwardeeObject: AnyObject? = nil
	private var uninstallation: ((DelegateProxy<Delegate>) -> Void)? = nil

	override public init() {
		super.init()
	}

	/// The delegate the proxy replaced, which receives every call the proxy doesn't implement.
	public var forwardee: Delegate? {
		forwardeeObject as? Delegate
	}

	/// Takes the delegate slot at `slot` on `owner`, forwarding to the delegate it holds.
	///
	/// Installing again on the same slot while the proxy still holds it does nothing, so it's safe to call from
	/// callbacks that repeat, such as view updates. When the slot has been given another delegate since, the proxy
	/// forwards to that one instead. Installing on a different slot first uninstalls the proxy from the current one.
	///
	/// - Precondition: The proxy conforms to `Delegate`.
	public func install<Owner: AnyObject>(on owner: Owner, at slot: ReferenceWritableKeyPath<Owner, Delegate?>) {
		guard let delegate = self as? Delegate else {
			preconditionFailure("\(type(of: self)) doesn't conform to \(Delegate.self)")
		}
		let current = owner[keyPath: slot].map { $0 as AnyObject }
		guard current !== self else { return }
		uninstall()
		// UIKit and AppKit often ask a delegate which methods it implements once, when it's assigned, so the
		// forwardee has to be in place first.
		forwardeeObject = current
		owner[keyPath: slot] = delegate
		uninstallation = { [weak owner] proxy in
			guard let owner else { return }
			// While the proxy deallocates, a weak slot that held it already reads nil.
			let current = owner[keyPath: slot].map { $0 as AnyObject }
			if current == nil || current === proxy {
				owner[keyPath: slot] = proxy.forwardee
			}
		}
	}

	/// Gives the slot back to the delegate the proxy replaced, unless the slot has been given another delegate since.
	public func uninstall() {
		uninstallation?(self)
		uninstallation = nil
		forwardeeObject = nil
	}

	override open nonisolated func responds(to selector: Selector!) -> Bool {
		super.responds(to: selector) || forwardeeObject?.responds(to: selector) == true
	}

	override open nonisolated func forwardingTarget(for selector: Selector!) -> Any? {
		if let forwardeeObject, forwardeeObject.responds(to: selector) { return forwardeeObject }
		return super.forwardingTarget(for: selector)
	}

	isolated deinit {
		uninstall()
	}
}
