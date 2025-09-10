import Testing

@testable import Router

// MARK: - Test Types

enum TestDestination: RoutableDestination {
	case home
	case profile
	case settings
	case detail(String)
}

enum TestSheet: RoutableSheet {
	case login
	case settings

	var id: String {
		switch self {
		case .login: return "login"
		case .settings: return "settings"
		}
	}
}

enum TestError: RoutableError {
	case networkError
	case validationError(String)

	var id: String {
		switch self {
		case .networkError: return "network"
		case .validationError(let message): return "validation_\(message)"
		}
	}
}

// MARK: - Test Router Implementation

@MainActor
final class TestRouter: RouterProtocol {
	var path: [TestDestination] = []
	var presentedSheet: TestSheet?
	var presentedError: TestError?
	let parent: (any RouterProtocol)?

	init(_ parent: (any RouterProtocol)? = nil) {
		self.parent = parent
	}
}

// MARK: - Router Tests
@Suite("Router Tests")
@MainActor
struct RouterTests {
	@Test func testPushDestination() async throws {
		let router = TestRouter()

		#expect(router.path.isEmpty)

		router.push(.home)
		#expect(router.path.count == 1)
		#expect(router.path.last == .home)

		router.push(.profile)
		#expect(router.path.count == 2)
		#expect(router.path.last == .profile)

		router.push(.detail("test"))
		#expect(router.path.count == 3)
		#expect(router.path.last == .detail("test"))
	}

	@Test func testPopDestination() async throws {
		let router: TestRouter = TestRouter()

		router.push(.home)
		router.push(.profile)
		router.push(.settings)

		#expect(router.path.count == 3)

		let popped = router.pop()
		#expect(popped == .settings)
		#expect(router.path.count == 2)
		#expect(router.path.last == .profile)

		let popped2 = router.pop()
		#expect(popped2 == .profile)
		#expect(router.path.count == 1)
		#expect(router.path.last == .home)

		let popped3 = router.pop()
		#expect(popped3 == .home)
		#expect(router.path.isEmpty)

		// Test popping from empty path
		let popped4 = router.pop()
		#expect(popped4 == nil)
		#expect(router.path.isEmpty)
	}

	@Test func testPopToRoot() async throws {
		let router = TestRouter()

		router.push(.home)
		router.push(.profile)
		router.push(.settings)
		router.push(.detail("test"))

		#expect(router.path.count == 4)

		router.popToRoot()
		#expect(router.path.isEmpty)
	}

	// MARK: - Sheet Presentation Tests

	@Test func testPresentSheet() async throws {
		let router = TestRouter()

		#expect(router.presentedSheet == nil)

		router.presentSheet(.login)
		#expect(router.presentedSheet == .login)

		router.presentSheet(.settings)
		#expect(router.presentedSheet == .settings)
	}

	@Test func testDismissSheet() async throws {
		let router = TestRouter()

		router.presentSheet(.login)
		#expect(router.presentedSheet == .login)

		router.dismissSheet()
		#expect(router.presentedSheet == nil)

		// Test dismissing when no sheet is presented
		router.dismissSheet()
		#expect(router.presentedSheet == nil)
	}

	@Test func testDismissSheetWithParent() async throws {
		let parentRouter = TestRouter()
		let childRouter = TestRouter(parentRouter)

		parentRouter.presentSheet(.login)
		childRouter.presentSheet(.settings)

		#expect(parentRouter.presentedSheet == .login)
		#expect(childRouter.presentedSheet == .settings)

		childRouter.dismissSheet(withParent: true)
		#expect(childRouter.presentedSheet == nil)
		#expect(parentRouter.presentedSheet == nil)
	}

	// MARK: - Error Presentation Tests

	@Test func testPresentError() async throws {
		let router = TestRouter()

		#expect(router.presentedError == nil)

		router.presentError(.networkError)
		#expect(router.presentedError == .networkError)

		router.presentError(.validationError("Invalid input"))
		#expect(router.presentedError == .validationError("Invalid input"))
	}

	@Test func testDismissError() async throws {
		let router = TestRouter()

		router.presentError(.networkError)
		#expect(router.presentedError == .networkError)

		router.dismissError()
		#expect(router.presentedError == nil)

		// Test dismissing when no error is presented
		router.dismissError()
		#expect(router.presentedError == nil)
	}

	// MARK: - Reset Tests

	@Test func testReset() async throws {
		let router = TestRouter()

		// Set up state
		router.push(.home)
		router.push(.profile)
		router.presentSheet(.login)
		router.presentError(.networkError)

		#expect(router.path.count == 2)
		#expect(router.presentedSheet == .login)
		#expect(router.presentedError == .networkError)

		router.reset()

		#expect(router.path.isEmpty)
		#expect(router.presentedSheet == nil)
		#expect(router.presentedError == nil)
	}

	@Test func testResetWithParent() async throws {
		let parentRouter = TestRouter()
		let childRouter = TestRouter(parentRouter)

		// Set up parent state
		parentRouter.push(.home)
		parentRouter.presentSheet(.login)
		parentRouter.presentError(.networkError)

		// Set up child state
		childRouter.push(.profile)
		childRouter.presentSheet(.settings)
		childRouter.presentError(.validationError("test"))

		#expect(parentRouter.path.count == 1)
		#expect(parentRouter.presentedSheet == .login)
		#expect(parentRouter.presentedError == .networkError)
		#expect(childRouter.path.count == 1)
		#expect(childRouter.presentedSheet == .settings)
		#expect(childRouter.presentedError == .validationError("test"))

		childRouter.reset(withParent: true)

		// Child should be reset
		#expect(childRouter.path.isEmpty)
		#expect(childRouter.presentedSheet == nil)
		#expect(childRouter.presentedError == nil)

		// Parent should also be reset
		#expect(parentRouter.path.isEmpty)
		#expect(parentRouter.presentedSheet == nil)
		#expect(parentRouter.presentedError == nil)
	}

	// MARK: - Parent-Child Relationship Tests

	@Test func testParentChildRelationship() async throws {
		let parentRouter = TestRouter()
		let childRouter = TestRouter(parentRouter)

		#expect(childRouter.parent === parentRouter)
		#expect(parentRouter.parent == nil)
	}

	@Test func testIndependentChildOperations() async throws {
		let parentRouter = TestRouter()
		let childRouter = TestRouter(parentRouter)

		// Set up parent state
		parentRouter.push(.home)
		parentRouter.presentSheet(.login)

		// Child operations should not affect parent
		childRouter.push(.profile)
		childRouter.presentSheet(.settings)

		#expect(parentRouter.path.count == 1)
		#expect(parentRouter.path.last == .home)
		#expect(parentRouter.presentedSheet == .login)

		#expect(childRouter.path.count == 1)
		#expect(childRouter.path.last == .profile)
		#expect(childRouter.presentedSheet == .settings)
	}

	// MARK: - Edge Cases and Error Conditions

	@Test func testMultipleOperationsSequence() async throws {
		let router = TestRouter()

		// Complex sequence of operations
		router.push(.home)
		router.presentSheet(.login)
		router.push(.profile)
		router.presentError(.networkError)
		router.pop()
		router.dismissSheet()
		router.push(.settings)
		router.dismissError()

		#expect(router.path.count == 2)
		#expect(router.path == [.home, .settings])
		#expect(router.presentedSheet == nil)
		#expect(router.presentedError == nil)
	}

	@Test func testEmptyPathOperations() async throws {
		let router = TestRouter()

		// Operations on empty path
		let popped = router.pop()
		#expect(popped == nil)

		router.popToRoot()
		#expect(router.path.isEmpty)

		router.push(.home)
		router.popToRoot()
		#expect(router.path.isEmpty)
	}

	@Test func testSheetAndErrorIndependence() async throws {
		let router = TestRouter()

		// Sheet and error should be independent
		router.presentSheet(.login)
		router.presentError(.networkError)

		#expect(router.presentedSheet == .login)
		#expect(router.presentedError == .networkError)

		router.dismissSheet()
		#expect(router.presentedSheet == nil)
		#expect(router.presentedError == .networkError)

		router.dismissError()
		#expect(router.presentedSheet == nil)
		#expect(router.presentedError == nil)
	}
}
