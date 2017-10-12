import XCTest

class TokenResponseParserTest: XCTestCase {
    private let parser = YXLTokenResponseParser()

    func testSuccessResult() {
        let string = "{\"access_token\": \"test_token\"}"
        let parseResult = try? parser.parseData(string.data(using: .utf8))
        XCTAssertEqual(parseResult, "test_token")
    }
    func testErrorThrown() {
        do {
            try parser.parseData("test".data(using: .utf8))
            XCTFail()
        } catch {
        }
    }
    func testErrorDomain() {
        do {
            try parser.parseData("test".data(using: .utf8))
        } catch {
            XCTAssertEqual((error as NSError).domain, kYXLErrorDomain)
        }
    }
    func testErrorCode() {
        do {
            try parser.parseData("test".data(using: .utf8))
        } catch {
            XCTAssertEqual((error as NSError).code, YXLErrorCode.requestTokenError.rawValue)
        }
    }
}
