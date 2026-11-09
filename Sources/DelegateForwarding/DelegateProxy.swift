public import DelegateForwardingObjC
import Foundation

/// A delegate that takes an object's delegate slot and forwards every call it doesn't handle itself to the delegate
/// it replaced.
///
/// Subclass it with the delegate protocol as `Delegate`, conform the subclass to that protocol, and implement only
/// the methods to intercept. Implemented methods replace the original delegate's, so call through ``forwardee`` to
/// keep its behavior:
///
/// ```swift
/// final class CompletionLogger: DelegateProxy<any XMLParserDelegate>, XMLParserDelegate {
/// 	func parserDidEndDocument(_ parser: XMLParser) {
/// 		print("Finished parsing")
/// 		forwardee?.parserDidEndDocument?(parser)
/// 	}
/// }
///
/// logger.install(on: parser, at: \.delegate)
/// ```
///
/// The subclass takes the isolation of the delegate protocol. A delegate a framework calls on its own threads, like
/// `XMLParserDelegate`, gets a nonisolated subclass that protects any state it keeps, declared `@unchecked Sendable`
/// when the protocol inherits `Sendable`. A delegate called on the main actor, such as UIKit's and AppKit's, gets a
/// `@MainActor` subclass.
///
/// The proxy holds the replaced delegate weakly, like the slot did, so the object that owns it keeps it alive.
/// Releasing the proxy puts the replaced delegate back unless the slot has been given another delegate since. The
/// slot is written in the isolation the proxy was installed from. Released anywhere else, the proxy schedules the
/// write there, except on a slot that doesn't retain its delegate, such as `XMLParser`'s, which is written straight
/// away so it isn't left pointing at freed memory. A proxy installed from an actor other than the main actor always
/// counts as released elsewhere, because it can't tell which actor it's released on.
///
/// If the replaced delegate goes away while the proxy is installed, calls the owner still makes to methods only that
/// delegate implemented are dropped and return `nil`, `false` or `0`, because UIKit and AppKit decide which methods a
/// delegate implements once, when it's assigned.
open class DelegateProxy<Delegate>: DelegateProxyBase {
	/// Read by the forwarding overrides, which the Objective-C runtime calls from whichever thread calls the delegate.
	/// Written only before the proxy enters a slot and after it leaves it, so the slot's own synchronization publishes
	/// the writes.
	private nonisolated(unsafe) weak var forwardeeObject: AnyObject? = nil
	/// The slot the proxy holds. Only touched where the slot is: in ``install(on:at:isolation:)``,
	/// ``uninstall(isolation:)`` and `deinit`.
	private nonisolated(unsafe) var installation: Installation? = nil

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
	/// forwards to that one instead. Installing on a different slot first uninstalls the proxy from the current one,
	/// which has to happen in that slot's isolation like ``uninstall(isolation:)``.
	///
	/// Some owners stop accepting delegates at some point, such as a `URLSessionTask` once resumed, so a proxy
	/// installed on one of those has to outlive that owner.
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
		let installation = Installation(isolation: isolation, owner: owner, slot: slot)
		let current = installation.currentDelegate()
		guard current !== self else { return }
		uninstall(isolation: isolation)
		// UIKit and AppKit often ask a delegate which methods it implements once, when it's assigned, so the
		// forwardee has to be in place first.
		forwardeeObject = current
		owner[keyPath: slot] = delegate
		self.installation = installation
	}

	/// Gives the slot back to the delegate the proxy replaced, unless the slot has been given another delegate since.
	///
	/// - Precondition: Called in the isolation the proxy was installed from, or on the main thread for a slot
	///   installed from the main actor.
	public func uninstall(isolation: isolated (any Actor)? = #isolation) {
		guard let installation else { return }
		precondition(
			installation.canWrite(from: isolation),
			"\(type(of: self)) must be uninstalled in the isolation it was installed from",
		)
		self.installation = nil
		installation.write(forwardeeObject, replacing: self)
		forwardeeObject = nil
	}

	override open func responds(to selector: Selector!) -> Bool {
		super.responds(to: selector) || forwardeeObject?.responds(to: selector) == true
	}

	override open func forwardingTarget(for selector: Selector!) -> Any? {
		if let forwardeeObject, forwardeeObject.responds(to: selector) { return forwardeeObject }
		return super.forwardingTarget(for: selector)
	}

	deinit {
		guard let installation else { return }
		// Away from the slot's isolation, the slot can still be read here, while the proxy is valid. A weak slot
		// already reads nil, so the write can wait for its isolation.
		if !installation.canWrite(from: nil), installation.currentDelegate() == nil {
			nonisolated(unsafe) let forwardee = forwardeeObject
			Task { await installation.perform { installation.write(forwardee, replacing: nil) } }
			return
		}
		// On the slot's isolation, or on a slot that doesn't retain its delegate, which still holds the proxy and
		// would point at freed memory once this returns.
		installation.write(forwardeeObject, replacing: self)
	}
}

/// A slot a ``DelegateProxy`` holds, and how to write the replaced delegate back into it. Kept apart from the proxy so
/// the write can outlive it.
private final class Installation: @unchecked Sendable {
	/// Where the slot was written from, and so where it's written again. `nil` for a slot installed outside any actor,
	/// which is one the owner synchronizes itself.
	private let isolation: (any Actor)?
	/// What the slot holds, or `nil` when it's empty or its owner is gone.
	let currentDelegate: () -> AnyObject?
	private let assign: (_ forwardee: AnyObject?) -> Void

	init<Owner: AnyObject, Delegate>(
		isolation: (any Actor)?,
		owner: Owner,
		slot: ReferenceWritableKeyPath<Owner, Delegate?>,
	) {
		self.isolation = isolation
		currentDelegate = { [weak owner] in owner?[keyPath: slot].map { $0 as AnyObject } }
		assign = { [weak owner] forwardee in owner?[keyPath: slot] = forwardee as? Delegate }
	}

	/// Whether code running in `caller` can write the slot right away: the isolation matches, or the slot belongs to
	/// the main actor and this is the main thread.
	func canWrite(from caller: (any Actor)?) -> Bool {
		guard let isolation else { return true }
		return caller === isolation || (isolation is MainActor && Thread.isMainThread)
	}

	/// Writes `forwardee` when the slot holds nothing or `proxy`.
	func write(_ forwardee: AnyObject?, replacing proxy: AnyObject?) {
		let current = currentDelegate()
		guard current == nil || current === proxy else { return }
		assign(forwardee)
	}

	/// Runs `body` on ``isolation``.
	func perform(_ body: @Sendable () -> Void) async {
		guard let isolation else { return body() }
		await perform(body, on: isolation)
	}

	private func perform(_ body: @Sendable () -> Void, on isolation: isolated any Actor) {
		body()
	}
}
