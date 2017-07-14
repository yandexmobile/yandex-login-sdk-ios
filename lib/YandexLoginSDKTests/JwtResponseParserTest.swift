import XCTest

class JwtResponseParserTest: XCTestCase {
    private let parser = YXLJwtResponseParser()
    private let errorData = Data(bytes: [0xFF])

    func testSuccessResult() {
        let string = "test.jwt"
        let parseResult = try? parser.parseData(string.data(using: .utf8))
        XCTAssertEqual(parseResult, string)
    }
    func testErrorThrown() {
        do {
            try parser.parseData(errorData)
            XCTFail()
        } catch {
        }
    }
    func testErrorDomain() {
        do {
            try parser.parseData(errorData)
        } catch {
            XCTAssertEqual((error as NSError).domain, kYXLErrorDomain)
        }
    }
    func testErrorCode() {
        do {
            try parser.parseData(errorData)
        } catch {
            XCTAssertEqual((error as NSError).code, YXLErrorCode.requestJwtError.rawValue)
        }
    }
}
