import DelegateForwarding
import Foundation
import Testing

@MainActor
struct DelegateProxyTests {
	@Test
	func `calls the proxy doesn't implement reach the replaced delegate`() throws {
		let owner = Owner()
		let original = RecordingListener()
		owner.listener = original
		let proxy = InterceptingProxy()
		proxy.install(on: owner, at: \.listener)
		let listener = try #require(owner.listener)

		#expect(listener !== original)
		#expect(listener.responds(to: didFinish))
		listener.didFinish?()

		#expect(original.calls == ["didFinish"])
	}

	@Test
	func `calls the proxy implements reach the proxy, which can forward them`() throws {
		let owner = Owner()
		let original = RecordingListener()
		owner.listener = original
		let proxy = InterceptingProxy()
		proxy.install(on: owner, at: \.listener)
		let listener = try #require(owner.listener)

		#expect(listener.shouldStart?() == true)
		proxy.isBlocking = true
		#expect(listener.shouldStart?() == false)

		#expect(proxy.calls == ["shouldStart", "shouldStart"])
		#expect(original.calls == ["shouldStart"])
	}

	@Test
	func `the owner sees the replaced delegate's methods as soon as the proxy is assigned`() {
		let owner = Owner()
		let original = RecordingListener()
		owner.listener = original
		let proxy = InterceptingProxy()
		proxy.install(on: owner, at: \.listener)

		#expect(owner.listenerRespondedToDidFinishOnAssignment == true)
	}

	@Test
	func `a call for a replaced delegate that's gone is dropped`() {
		let owner = Owner()
		var original: RecordingListener? = RecordingListener()
		owner.listener = original
		let proxy = InterceptingProxy()
		proxy.install(on: owner, at: \.listener)
		#expect(owner.listenerRespondedToDidFinishOnAssignment == true)

		original = nil

		// UIKit keeps calling what the delegate responded to when it was assigned.
		#expect(proxy.perform(didFinish) == nil)
		#expect(proxy.responds(to: didFinish) == false)
	}

	@Test
	func `a method neither delegate implements isn't reported`() throws {
		let owner = Owner()
		let original = SilentListener()
		owner.listener = original
		let proxy = InterceptingProxy()
		proxy.install(on: owner, at: \.listener)

		#expect(try #require(owner.listener).responds(to: didFinish) == false)
	}

	@Test
	func `the replaced delegate is held weakly`() {
		let owner = Owner()
		var original: RecordingListener? = RecordingListener()
		owner.listener = original
		let proxy = InterceptingProxy()
		proxy.install(on: owner, at: \.listener)
		#expect(proxy.forwardee === original)

		original = nil

		#expect(proxy.forwardee == nil)
	}

	@Test
	func `installing again on the slot it holds changes nothing`() {
		let owner = Owner()
		let original = RecordingListener()
		owner.listener = original
		let proxy = InterceptingProxy()
		proxy.install(on: owner, at: \.listener)
		proxy.install(on: owner, at: \.listener)

		#expect(owner.listener === proxy)
		#expect(proxy.forwardee === original)
	}

	@Test
	func `installing after the slot is given another delegate forwards to that one`() {
		let owner = Owner()
		let original = RecordingListener()
		owner.listener = original
		let proxy = InterceptingProxy()
		proxy.install(on: owner, at: \.listener)
		let replacement = RecordingListener()
		owner.listener = replacement

		proxy.install(on: owner, at: \.listener)

		#expect(owner.listener === proxy)
		#expect(proxy.forwardee === replacement)
		proxy.uninstall()
		#expect(owner.listener === replacement)
	}

	@Test
	func `installing on another owner gives the first one back its delegate`() {
		let first = Owner()
		let firstListener = RecordingListener()
		first.listener = firstListener
		let second = Owner()
		let secondListener = RecordingListener()
		second.listener = secondListener
		let proxy = InterceptingProxy()
		proxy.install(on: first, at: \.listener)

		proxy.install(on: second, at: \.listener)

		#expect(first.listener === firstListener)
		#expect(second.listener === proxy)
		#expect(proxy.forwardee === secondListener)
	}

	@Test
	func `uninstalling gives the slot back to the replaced delegate`() {
		let owner = Owner()
		let original = RecordingListener()
		owner.listener = original
		let proxy = InterceptingProxy()
		proxy.install(on: owner, at: \.listener)

		proxy.uninstall()

		#expect(owner.listener === original)
		#expect(proxy.forwardee == nil)
	}

	@Test
	func `uninstalling keeps a delegate the slot was given since`() {
		let owner = Owner()
		let original = RecordingListener()
		owner.listener = original
		let proxy = InterceptingProxy()
		proxy.install(on: owner, at: \.listener)
		let replacement = RecordingListener()
		owner.listener = replacement

		proxy.uninstall()

		#expect(owner.listener === replacement)
	}

	@Test
	func `releasing the proxy gives the slot back to the replaced delegate`() {
		let owner = Owner()
		let original = RecordingListener()
		owner.listener = original
		var proxy: InterceptingProxy? = InterceptingProxy()
		proxy?.install(on: owner, at: \.listener)
		#expect(owner.listener !== original)

		proxy = nil

		#expect(owner.listener === original)
	}

	@Test
	func `releasing the proxy off the main actor gives the slot back on the main actor`() async {
		let owner = Owner()
		let original = RecordingListener()
		owner.listener = original
		let holder = Holder(InterceptingProxy())
		holder.proxy?.install(on: owner, at: \.listener)
		#expect(owner.listener !== original)

		await Task.detached { holder.proxy = nil }.value

		await waitUntil { owner.listener === original }
		#expect(owner.listener === original)
	}

	@Test
	func `releasing off the main actor gives back a slot that doesn't retain its delegate right away`() async {
		let owner = UnretainingOwner()
		let original = RecordingListener()
		owner.listener = original
		let holder = Holder(InterceptingProxy())
		holder.proxy?.install(on: owner, at: \.listener)
		#expect(owner.listener !== original)

		await Task.detached { holder.proxy = nil }.value

		#expect(owner.listener === original)
		#expect(owner.wroteOnMainThread == false)
	}

	#if os(macOS)
	@Test
	func `uninstalling off the main actor is a programmer error`() async {
		await #expect(processExitsWith: .failure) {
			let (owner, holder) = await MainActor.run {
				let owner = Owner()
				let original = RecordingListener()
				owner.listener = original
				let holder = Holder(InterceptingProxy())
				holder.proxy?.install(on: owner, at: \.listener)
				return (owner, holder)
			}
			await Task.detached { holder.proxy?.uninstall() }.value
			_ = owner
		}
	}
	#endif

	/// Waits up to a second for a write scheduled from another thread to reach the main actor.
	private func waitUntil(_ condition: () -> Bool) async {
		for _ in 0..<200 where !condition() {
			try? await Task.sleep(nanoseconds: 5_000_000)
		}
	}
}

@MainActor
private final class UnretainingOwner: NSObject {
	private(set) var wroteOnMainThread: Bool? = nil

	unowned(unsafe) var listener: (any Listener)? = nil {
		didSet { wroteOnMainThread = Thread.isMainThread }
	}
}

/// Hands a main-actor proxy to another thread so it can be released or uninstalled there.
private final class Holder: @unchecked Sendable {
	var proxy: InterceptingProxy? = nil

	init(_ proxy: InterceptingProxy) {
		self.proxy = proxy
	}
}

@MainActor
@objc
private protocol Listener: NSObjectProtocol {
	@objc optional func shouldStart() -> Bool
	@objc optional func didFinish()
}

@MainActor
private final class Owner: NSObject {
	private(set) var listenerRespondedToDidFinishOnAssignment: Bool? = nil

	weak var listener: (any Listener)? = nil {
		didSet { listenerRespondedToDidFinishOnAssignment = listener?.responds(to: didFinish) }
	}
}

@MainActor
private final class InterceptingProxy: DelegateProxy<any Listener>, Listener {
	var isBlocking = false
	private(set) var calls: [String] = []

	func shouldStart() -> Bool {
		calls.append("shouldStart")
		return !isBlocking && forwardee?.shouldStart?() ?? true
	}
}

@MainActor
private final class RecordingListener: NSObject, Listener {
	private(set) var calls: [String] = []

	func shouldStart() -> Bool {
		calls.append("shouldStart")
		return true
	}

	func didFinish() {
		calls.append("didFinish")
	}
}

private final class SilentListener: NSObject, Listener {}

private let didFinish = NSSelectorFromString("didFinish")
