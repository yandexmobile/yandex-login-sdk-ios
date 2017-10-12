import XCTest

class ObserversControllerTest: XCTestCase {
    override func setUp() {
        super.setUp()
        observers = [TestObserver(), TestObserver()]
        observersController = YXLObserversController()
        observersController.add(observers[0])
        observersController.add(observers[1])
    }

    func testDidFinishWithResult() {
        observersController.notifyLoginDidFinish(with: nil)
        XCTAssertEqual(observers[0].didFinishWithResultTimes, 1)
        XCTAssertEqual(observers[1].didFinishWithResultTimes, 1)
    }
    func testDidFinishWithError() {
        observersController.notifyLoginDidFinishWithError(nil)
        XCTAssertEqual(observers[0].didFinishWithErrorTimes, 1)
        XCTAssertEqual(observers[1].didFinishWithErrorTimes, 1)
    }

    private var observers: [TestObserver] = []
    private var observersController = YXLObserversController()

    private class TestObserver: NSObject, YXLObserver {
        private(set) var didFinishWithResultTimes = 0
        private(set) var didFinishWithErrorTimes = 0

        func loginDidFinish(with result: YXLLoginResult) {
            didFinishWithResultTimes += 1
        }
        func loginDidFinishWithError(_ error: Error) {
            didFinishWithErrorTimes += 1
        }
    }
}
