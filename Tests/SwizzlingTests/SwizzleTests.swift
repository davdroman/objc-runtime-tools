import Foundation
import Swizzling
import Testing

@Suite(.serialized)
struct SwizzleTests {
	final class SUT: NSObject {
		@objc dynamic var state: Int = 0

		@objc dynamic func functionWithoutParamsWithoutReturn() {
			state += 1
		}

		@objc dynamic func functionWithoutParamsWithReturn() -> Int {
			state
		}

		@objc dynamic func functionWithParamsWithoutReturn(_ state: Int) {
			self.state = state
		}

		@objc dynamic func functionWithParamsWithReturn(_ state: Int) -> Int {
			self.state = state
			return self.state
		}
	}
}

extension SwizzleTests {
	@Test
	func swizzleGetter() throws {
		let sut = SUT()
		#expect(sut.state == 0)

		let hook = try #swizzle(getter: \SUT.state, returning: Int.self) { $self in
			return self.state + 1
		}
		#expect(sut.state == 1)
		#expect(sut.state == 1)
		#expect(sut.state == 1)

		try hook.revert()
		#expect(sut.state == 0)
	}
}

extension SwizzleTests {
	@Test
	func swizzleSetter() throws {
		let sut = SUT()
		#expect(sut.state == 0)

		let hook = try #swizzle(setter: \SUT.state, param: Int.self) { $self, newValue in
			self.state = newValue + 1
		}
		#expect(sut.state == 0)
		sut.state = 1
		#expect(sut.state == 2)

		try hook.revert()
		sut.state = 3
		#expect(sut.state == 3)
	}
}

extension SwizzleTests {
	@Test
	func swizzleFunctionWithoutParametersWithoutReturn() throws {
		let sut = SUT()

		let hook = try #swizzle(SUT.functionWithoutParamsWithoutReturn) { $self in
			self.functionWithoutParamsWithoutReturn()
			self.functionWithoutParamsWithoutReturn()
			self.state += 1
		}
		#expect(sut.state == 0)
		sut.functionWithoutParamsWithoutReturn()
		#expect(sut.state == 3)
		sut.functionWithoutParamsWithoutReturn()
		#expect(sut.state == 6)

		try hook.revert()
		#expect(sut.state == 6)
		sut.functionWithoutParamsWithoutReturn()
		#expect(sut.state == 7)
	}

	@Test
	func swizzleFunctionWithoutParametersWithReturn() throws {
		let hook = try #swizzle(
			SUT.functionWithoutParamsWithReturn,
			returning: Int.self
		) { $self in
			self.state += 1
			return self.functionWithoutParamsWithReturn()
		}

		let sut = SUT()
		#expect(sut.state == 0)
		#expect(sut.functionWithoutParamsWithReturn() == 1)
		#expect(sut.state == 1)
		#expect(sut.functionWithoutParamsWithReturn() == 2)
		#expect(sut.state == 2)

		try hook.revert()
		#expect(sut.functionWithoutParamsWithReturn() == 2)
		#expect(sut.state == 2)
	}

	@Test
	func swizzleFunctionWithParametersWithoutReturn() throws {
		let hook = try #swizzle(
			SUT.functionWithParamsWithoutReturn,
			param: Int.self
		) { $self, state in
			self.functionWithParamsWithoutReturn(state + 1)
		}

		let sut = SUT()
		#expect(sut.state == 0)
		sut.functionWithParamsWithoutReturn(1)
		#expect(sut.state == 2)

		try hook.revert()
		sut.functionWithParamsWithoutReturn(5)
		#expect(sut.state == 5)
	}

	@Test
	func swizzleFunctionWithParametersWithReturn() throws {
		let hook = try #swizzle(
			SUT.functionWithParamsWithReturn,
			param: Int.self,
			returning: Int.self
		) { $sut, value in
			sut.functionWithParamsWithReturn(value + 1)
		}

		let sut = SUT()
		#expect(sut.state == 0)
		#expect(sut.functionWithParamsWithReturn(1) == 2)
		#expect(sut.state == 2)

		try hook.revert()
		#expect(sut.functionWithParamsWithReturn(5) == 5)
		#expect(sut.state == 5)
	}
}

@MainActor
@Suite(.serialized)
struct SwizzleLifetimeTests {
	final class SUT: NSObject {
		@objc dynamic var state: Int = 0
	}

	weak static var hook: AnyHook? = nil

	@Test
	func swizzlePersistsAcrossScopes_entryPoint() throws {
		let sut = SUT()
		#expect(sut.state == 0)

		Self.hook = try #swizzle(getter: \SUT.state, returning: Int.self) { $sut in
			return sut.state + 1
		}
		#expect(sut.state == 1)
		#expect(sut.state == 1)
		#expect(sut.state == 1)
	}

	@Test
	func swizzlePersistsAcrossScopes_exitPoint() throws {
		let sut = SUT()
		#expect(sut.state == 1)

		let hook = try #require(Self.hook)

		try hook.revert()
		hook.cleanup()
		Self.hook = nil
	}
}
