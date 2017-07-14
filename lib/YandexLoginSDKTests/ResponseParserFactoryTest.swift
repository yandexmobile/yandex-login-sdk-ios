import XCTest

class ResponseParserFactoryTest: XCTestCase {
    private let paramsClasses = SetOfClasses(prefix: "YXL", postfix: "RequestParams")

    func testThatRequestParamsExist() {
        XCTAssertFalse(paramsClasses.isEmpty)
    }
    func testThatRequestParamsAreCorrect() {
        for paramsClass in paramsClasses {
            XCTAssertTrue(Object(by: paramsClass) is YXLRequestParams)
        }
    }
    func testThatFactoryCreatesParsers() {
        for paramsClass in paramsClasses {
            XCTAssertNotNil(YXLResponseParserFactory.parser(for: Object(by: paramsClass) as! YXLRequestParams))
        }
    }

    class TestParams: NSObject, YXLRequestParams {
        let path = ""
        let params: [String: String] = [:]
    }
    func testThatFactoryReturnsNilForBadParser() {
         XCTAssertNil(YXLResponseParserFactory.parser(for: TestParams()))
    }
}
