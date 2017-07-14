import XCTest

class StatesManagerTest: XCTestCase {
    func testGenerateNewState() {
        let manager = statesManager
        let state = manager.generateNewState()
        XCTAssertNotNil(state)
        XCTAssertTrue(manager.isValidState(state))
    }
    func testGenerateStates() {
        let manager = statesManager
        let states: [String] = Array(repeating: 0.0, count: 30).map{ _ in manager.generateNewState() }
        XCTAssertEqual(states.count, Set(states).count)
    }
    func testDeleteState() {
        let manager = statesManager
        let state = manager.generateNewState()
        manager.deleteState(state)
        XCTAssertFalse(manager.isValidState(state))
    }
    func testDeleteOldestState() {
        let manager = statesManager
        let states: [String] = Array(repeating: 0.0, count: 50).map{ _ in manager.generateNewState() }
        let oldestState = states.first!
        XCTAssertTrue(manager.isValidState(oldestState))
        let _ = manager.generateNewState()
        XCTAssertFalse(manager.isValidState(oldestState))
    }

    private var statesManager: YXLStatesManager {
        class TestStorage : NSObject, YXLStorage {
            var storedObject: [AnyHashable : Any]? = nil
        }
        return YXLStatesManager(storage: TestStorage())
    }
}

