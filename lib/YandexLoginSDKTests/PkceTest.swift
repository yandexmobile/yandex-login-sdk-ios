import XCTest

@objc protocol YXLPkceTest {
    func decryptPkce(_ pkce: String) -> String
}

extension YXLPkce {
    func testDecryptPkce(_ pkce: String) -> String {
        return perform(#selector(YXLPkceTest.decryptPkce), with: pkce).takeUnretainedValue() as! String
    }
}

final class PkceTest: XCTestCase {
    func testGeneratePkce() {
        let pkce = YXLPkce()
        XCTAssertNotNil(pkce.codeVerifier)
        XCTAssertNotEqual(pkce.codeVerifier, YXLPkce().codeVerifier)
        XCTAssertGreaterThanOrEqual(pkce.codeVerifier.characters.count, 43)
        XCTAssertLessThanOrEqual(pkce.codeVerifier.characters.count, 128)
    }
    func testDecryptPkce() {
        let pkce = YXLPkce()
        XCTAssertEqual(pkce.testDecryptPkce("hello"), "LPJNul-wow4m6DsqxbninhsWHlwfp0JecwQzYpOLmCQ=")
        XCTAssertEqual(pkce.testDecryptPkce("test"), "n4bQgYhMfWWaL-qgxVrQFaO_TxsrC4Is0V1sFbDwCgg=")
    }
}
