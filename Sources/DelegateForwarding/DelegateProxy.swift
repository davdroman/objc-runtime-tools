public import Foundation

/// A delegate that takes an object's delegate slot and forwards every call it doesn't handle itself to the delegate
/// it replaced.
///
/// Subclass it with the delegate protocol as `Delegate`, conform the subclass to that protocol, and implement only
/// the methods to intercept. Implemented methods replace the original delegate's, so call through ``forwardee`` to
/// keep its behavior:
///
/// ```swift
/// @MainActor
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
/// The proxy itself isn't isolated, so the subclass decides: a delegate called on the main actor, such as UIKit's and
/// AppKit's, gets a `@MainActor` subclass, and a delegate called from the framework's own threads, such as
/// `URLSessionTaskDelegate`, gets a nonisolated one that protects its own state. Delegate protocols that inherit
/// `Sendable` need the subclass to declare `@unchecked Sendable` as well.
///
/// The proxy holds the replaced delegate weakly, like the slot did, so the object that owns it keeps it alive.
/// Releasing the proxy puts the replaced delegate back unless the slot has been given another delegate since.
open class DelegateProxy<Delegate>: NSObject {
	/// Read by the forwarding overrides, which the Objective-C runtime calls from whichever thread calls the delegate.
	/// Written only before the proxy enters a slot and after it leaves it, so the slot's own synchronization publishes
	/// the writes.
	private nonisolated(unsafe) weak var forwardeeObject: AnyObject? = nil
	/// Only touched where the slot is: in ``install(on:at:isolation:)``, ``uninstall(isolation:)`` and `deinit`.
	private nonisolated(unsafe) var installation: Installation? = nil

	override public init() {
		super.init()
	}

	/// The delegate the proxy replaced, which receives every call the proxy doesn't implement.
	public var forwardee: Delegate? {
		forwardeeObject as? Delegate
	}

	/// Takes the delegate slot at `slot` on `owner`, forwarding to the delegate it holds.
	///
	/// The slot is written in the caller's isolation, and the proxy remembers that isolation to write the slot again
	/// when it gives it back. A main-actor slot, such as a UIKit delegate, can only be installed from the main actor,
	/// because that's the only place its key path can be formed.
	///
	/// Installing again on the same slot while the proxy still holds it does nothing, so it's safe to call from
	/// callbacks that repeat, such as view updates. When the slot has been given another delegate since, the proxy
	/// forwards to that one instead. Installing on a different slot first uninstalls the proxy from the current one.
	///
	/// - Precondition: The proxy conforms to `Delegate`.
	public func install<Owner: AnyObject>(
		on owner: Owner,
		at slot: ReferenceWritableKeyPath<Owner, Delegate?>,
		isolation: isolated (any Actor)? = #isolation,
	) {
		guard let delegate = self as? Delegate else {
			preconditionFailure("\(type(of: self)) doesn't conform to \(Delegate.self)")
		}
		let current = owner[keyPath: slot].map { $0 as AnyObject }
		guard current !== self else { return }
		uninstall(isolation: isolation)
		// UIKit and AppKit often ask a delegate which methods it implements once, when it's assigned, so the
		// forwardee has to be in place first.
		forwardeeObject = current
		owner[keyPath: slot] = delegate
		installation = Installation(isolation: isolation, forwardee: current) { [weak owner] proxy, forwardee in
			guard let owner else { return }
			let current = owner[keyPath: slot].map { $0 as AnyObject }
			// Once the proxy is being released, a weak slot that held it reads nil.
			if current == nil || current === proxy {
				owner[keyPath: slot] = forwardee as? Delegate
			}
		}
	}

	/// Gives the slot back to the delegate the proxy replaced, unless the slot has been given another delegate since.
	///
	/// The slot is written in the isolation it was installed from. When called from somewhere else, the write is
	/// scheduled on that isolation instead of happening before this returns.
	public func uninstall(isolation: isolated (any Actor)? = #isolation) {
		guard let installation else { return }
		self.installation = nil
		forwardeeObject = nil
		installation.restore(replacing: self, isReleasing: false, from: isolation)
	}

	override open func responds(to selector: Selector!) -> Bool {
		super.responds(to: selector) || forwardeeObject?.responds(to: selector) == true
	}

	override open func forwardingTarget(for selector: Selector!) -> Any? {
		if let forwardeeObject, forwardeeObject.responds(to: selector) { return forwardeeObject }
		return super.forwardingTarget(for: selector)
	}

	deinit {
		// `deinit` runs wherever the last reference goes away, so the slot may have to be written on its isolation
		// later, like `isolated deinit` does.
		installation?.restore(replacing: self, isReleasing: true, from: nil)
	}
}

/// What ``DelegateProxy`` needs to give a slot back, kept apart from the proxy so the write can outlive it.
private final class Installation: @unchecked Sendable {
	/// Where the slot was written from, and so where it's written again. `nil` for a slot installed outside any actor,
	/// which is one the owner synchronizes itself.
	let isolation: (any Actor)?
	private weak var forwardee: AnyObject? = nil
	private let write: (_ proxy: AnyObject?, _ forwardee: AnyObject?) -> Void

	init(
		isolation: (any Actor)?,
		forwardee: AnyObject?,
		write: @escaping (_ proxy: AnyObject?, _ forwardee: AnyObject?) -> Void,
	) {
		self.isolation = isolation
		self.forwardee = forwardee
		self.write = write
	}

	/// Writes the replaced delegate back on ``isolation``, right away when `current` is that isolation, or the main
	/// thread for the main actor, and otherwise on a task hopping there.
	///
	/// - Parameters:
	///   - proxy: The proxy the slot is expected to hold. A slot that doesn't retain its delegate still holds it while
	///     it's being released.
	///   - isReleasing: Whether `proxy` is being released, so a task scheduled here can't keep it.
	func restore(replacing proxy: AnyObject, isReleasing: Bool, from current: (any Actor)?) {
		guard let isolation else { return write(proxy, forwardee) }
		if current === isolation || (isolation is MainActor && Thread.isMainThread) {
			write(proxy, forwardee)
		} else {
			// A weak slot reads nil by the time the task runs, which the write accepts in place of the proxy.
			nonisolated(unsafe) let proxy: AnyObject? = isReleasing ? nil : proxy
			Task { await restore(replacing: proxy, on: isolation) }
		}
	}

	private func restore(replacing proxy: AnyObject?, on isolation: isolated any Actor) {
		write(proxy, forwardee)
	}
}
