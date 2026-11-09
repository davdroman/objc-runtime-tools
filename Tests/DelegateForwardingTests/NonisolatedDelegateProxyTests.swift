import DelegateForwarding
import Foundation
import Testing

/// A proxy for a delegate the framework calls on its own threads, like `URLSessionDelegate`, installed and released
/// outside any actor.
struct NonisolatedDelegateProxyTests {
	@Test
	func `calls the proxy doesn't implement reach the replaced delegate`() throws {
		let owner = Owner()
		let original = RecordingWorker()
		owner.worker = original
		let proxy = InterceptingProxy()
		proxy.install(on: owner, at: \.worker)
		let worker = try #require(owner.worker)

		#expect(worker !== original)
		#expect(worker.responds(to: didFinish))
		worker.didFinish?()

		#expect(original.calls == ["didFinish"])
	}

	@Test
	func `calls the proxy implements reach the proxy, which can forward them`() throws {
		let owner = Owner()
		let original = RecordingWorker()
		owner.worker = original
		let proxy = InterceptingProxy()
		proxy.install(on: owner, at: \.worker)
		let worker = try #require(owner.worker)

		#expect(worker.shouldStart?() == true)
		proxy.isBlocking.withLock { $0 = true }
		#expect(worker.shouldStart?() == false)

		#expect(proxy.calls == ["shouldStart", "shouldStart"])
		#expect(original.calls == ["shouldStart"])
	}

	@Test
	func `calls for a replaced delegate that's gone are dropped, including inherited protocol methods`() {
		let owner = Owner()
		var original: RecordingWorker? = RecordingWorker()
		owner.worker = original
		let proxy = InterceptingProxy()
		proxy.install(on: owner, at: \.worker)
		// Forwarding autoreleases the forwardee, which would keep it alive past the release below.
		autoreleasepool { #expect(proxy.perform(canStart) != nil) }

		original = nil

		#expect(proxy.perform(willStart) == nil)
		#expect(proxy.perform(didFinish) == nil)
		// `perform` hands back the raw return value, so a dropped `Bool` method reads as nil.
		#expect(proxy.perform(canStart) == nil)
	}

	@Test
	func `installing again on the slot it holds changes nothing`() {
		let owner = Owner()
		let original = RecordingWorker()
		owner.worker = original
		let proxy = InterceptingProxy()
		proxy.install(on: owner, at: \.worker)
		proxy.install(on: owner, at: \.worker)

		#expect(owner.worker === proxy)
		#expect(proxy.forwardee === original)
	}

	@Test
	func `installing after the slot is given another delegate forwards to that one`() {
		let owner = Owner()
		let original = RecordingWorker()
		owner.worker = original
		let proxy = InterceptingProxy()
		proxy.install(on: owner, at: \.worker)
		let replacement = RecordingWorker()
		owner.worker = replacement

		proxy.install(on: owner, at: \.worker)

		#expect(owner.worker === proxy)
		#expect(proxy.forwardee === replacement)
		proxy.uninstall()
		#expect(owner.worker === replacement)
	}

	@Test
	func `installing on another owner gives the first one back its delegate`() {
		let first = Owner()
		let firstWorker = RecordingWorker()
		first.worker = firstWorker
		let second = Owner()
		let secondWorker = RecordingWorker()
		second.worker = secondWorker
		let proxy = InterceptingProxy()
		proxy.install(on: first, at: \.worker)

		proxy.install(on: second, at: \.worker)

		#expect(first.worker === firstWorker)
		#expect(second.worker === proxy)
		#expect(proxy.forwardee === secondWorker)
	}

	@Test
	func `uninstalling keeps a delegate the slot was given since`() {
		let owner = Owner()
		let original = RecordingWorker()
		owner.worker = original
		let proxy = InterceptingProxy()
		proxy.install(on: owner, at: \.worker)
		let replacement = RecordingWorker()
		owner.worker = replacement

		proxy.uninstall()

		#expect(owner.worker === replacement)
	}

	@Test
	func `uninstalling gives the slot back to the replaced delegate`() {
		let owner = Owner()
		let original = RecordingWorker()
		owner.worker = original
		let proxy = InterceptingProxy()
		proxy.install(on: owner, at: \.worker)

		proxy.uninstall()

		#expect(owner.worker === original)
		#expect(proxy.forwardee == nil)
	}

	@Test
	func `releasing the proxy gives the slot back to the replaced delegate right away`() {
		let owner = Owner()
		let original = RecordingWorker()
		owner.worker = original
		var proxy: InterceptingProxy? = InterceptingProxy()
		proxy?.install(on: owner, at: \.worker)
		#expect(owner.worker !== original)

		proxy = nil

		#expect(owner.worker === original)
	}

	@Test
	func `releasing the proxy gives back a slot that doesn't retain its delegate`() {
		let owner = UnretainingOwner()
		let original = RecordingWorker()
		owner.worker = original
		var proxy: InterceptingProxy? = InterceptingProxy()
		proxy?.install(on: owner, at: \.worker)
		#expect(owner.worker !== original)

		proxy = nil

		#expect(owner.worker === original)
	}

	/// `XMLParser` calls its delegate on the thread that parses, and holds it without retaining it.
	@Test
	func `a Foundation delegate called off the main thread is proxied`() async {
		let original = RecordingParserDelegate()
		let proxy = ParserProxy()

		let restored = await Task.detached {
			let parser = XMLParser(data: Data("<a><b/></a>".utf8))
			parser.delegate = original
			proxy.install(on: parser, at: \.delegate)
			#expect(parser.parse())
			proxy.uninstall()
			return parser.delegate === original
		}
		.value

		#expect(restored)
		#expect(proxy.startedDocumentOnMainThread.withLock { $0 } == false)
		#expect(original.events.withLock { $0 } == ["start", "a", "b"])
	}
}

/// `didFinish` lives on a parent protocol, like `UITableViewDelegate` inherits `UIScrollViewDelegate`'s methods.
@objc
private protocol WorkerBase: NSObjectProtocol {
	@objc optional func didFinish()
}

@objc
private protocol Worker: WorkerBase, Sendable {
	@objc optional func shouldStart() -> Bool
	@objc optional func canStart() -> Bool
	@objc optional func willStart()
}

private final class Owner: NSObject {
	weak var worker: (any Worker)? = nil
}

/// An owner with an `assign` delegate, like `XMLParser` and some AppKit classes.
private final class UnretainingOwner: NSObject {
	unowned(unsafe) var worker: (any Worker)? = nil
}

private final class InterceptingProxy: DelegateProxy<any Worker>, Worker, @unchecked Sendable {
	let isBlocking = Locked(false)
	private let recordedCalls = Locked<[String]>([])

	var calls: [String] { recordedCalls.withLock { $0 } }

	func shouldStart() -> Bool {
		recordedCalls.withLock { $0.append("shouldStart") }
		return !isBlocking.withLock { $0 } && forwardee?.shouldStart?() ?? true
	}
}

private final class RecordingWorker: NSObject, Worker, @unchecked Sendable {
	private let recordedCalls = Locked<[String]>([])

	var calls: [String] { recordedCalls.withLock { $0 } }

	func shouldStart() -> Bool {
		recordedCalls.withLock { $0.append("shouldStart") }
		return true
	}

	func canStart() -> Bool {
		true
	}

	func willStart() {
		recordedCalls.withLock { $0.append("willStart") }
	}

	func didFinish() {
		recordedCalls.withLock { $0.append("didFinish") }
	}
}

private final class ParserProxy: DelegateProxy<any XMLParserDelegate>, XMLParserDelegate, @unchecked Sendable {
	let startedDocumentOnMainThread = Locked<Bool?>(nil)

	func parserDidStartDocument(_ parser: XMLParser) {
		startedDocumentOnMainThread.withLock { $0 = Thread.isMainThread }
		forwardee?.parserDidStartDocument?(parser)
	}
}

private final class RecordingParserDelegate: NSObject, XMLParserDelegate, @unchecked Sendable {
	let events = Locked<[String]>([])

	func parserDidStartDocument(_ parser: XMLParser) {
		events.withLock { $0.append("start") }
	}

	func parser(
		_ parser: XMLParser,
		didStartElement elementName: String,
		namespaceURI: String?,
		qualifiedName qName: String?,
		attributes attributeDict: [String: String] = [:],
	) {
		events.withLock { $0.append(elementName) }
	}
}

/// A lock-protected value, since `Mutex` needs a newer deployment target than the package has.
private final class Locked<Value>: @unchecked Sendable {
	private let lock = NSLock()
	private var value: Value

	init(_ value: Value) {
		self.value = value
	}

	func withLock<Result>(_ body: (inout Value) throws -> Result) rethrows -> Result {
		lock.lock()
		defer { lock.unlock() }
		return try body(&value)
	}
}

private let canStart = NSSelectorFromString("canStart")
private let willStart = NSSelectorFromString("willStart")
private let didFinish = NSSelectorFromString("didFinish")
