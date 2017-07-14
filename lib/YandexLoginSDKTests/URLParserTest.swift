import XCTest

class URLParserTest: XCTestCase {
    private let appId = "test.app"
    private let state = "test.state"

    func testAuthorizationURL() {
        let url = YXLURLParser.authorizationURL(withAppId: appId, state: state)!
        XCTAssertEqual(url.scheme, "https")
        XCTAssertEqual(url.host, "oauth.yandex.ru")
        XCTAssertEqual(url.path, "/authorize")
        if #available(iOS 8.0, *) {
            let queryItems = NSURLComponents(url: url, resolvingAgainstBaseURL: false)!.queryItems!
            XCTAssertTrue(queryItems.contains(URLQueryItem(name: "client_id", value: appId)))
            XCTAssertTrue(queryItems.contains(URLQueryItem(name: "response_type", value: "token")))
            XCTAssertTrue(queryItems.contains(URLQueryItem(name: "redirect_uri", value: redirectUri)))
            XCTAssertTrue(queryItems.contains(URLQueryItem(name: "state", value: state)))
            XCTAssertTrue(queryItems.contains(URLQueryItem(name: "force_confirm", value: "yes")))
            XCTAssertTrue(queryItems.contains(URLQueryItem(name: "origin", value: "yandex_auth_sdk_ios")))
        }
    }
    func testAddStatistics() {
        let parameters = YXLStatisticsDataProvider.statisticsParameters!
        XCTAssertGreaterThan(parameters.count, 0)
        if #available(iOS 8.0, *) {
            let url = YXLURLParser.authorizationURL(withAppId: appId, state: state)!
            let queryItems = NSURLComponents(url: url, resolvingAgainstBaseURL: false)!.queryItems!
            for parameter in parameters {
                XCTAssertTrue(queryItems.contains(URLQueryItem(name: parameter.key, value: parameter.value)))
            }
        }
    }
    func testOpenURL() {
        let url = YXLURLParser.openURL(withAppId: appId, state: state)!
        XCTAssertEqual(url.scheme, "yandexauth")
        XCTAssertEqual(url.host, "authorize")
        XCTAssertEqual(url.path, "")
        if #available(iOS 8.0, *) {
            let queryItems = NSURLComponents(url: url, resolvingAgainstBaseURL: false)!.queryItems!
            XCTAssertTrue(queryItems.contains(URLQueryItem(name: "client_id", value: appId)))
            XCTAssertTrue(queryItems.contains(URLQueryItem(name: "response_type", value: "token")))
            XCTAssertTrue(queryItems.contains(URLQueryItem(name: "redirect_uri", value: redirectUri)))
            XCTAssertTrue(queryItems.contains(URLQueryItem(name: "state", value: state)))
        }
    }
    func testErrorFromUrl() {
        let testError: (String, YXLErrorCode) -> Void = { value, code in
            let error = YXLURLParser.error(from: URL(string: "http://oauth.yandex.ru#error=\(value)")) as NSError
            XCTAssertEqual(error.code, code.rawValue)
            XCTAssertEqual(error.userInfo[NSLocalizedFailureReasonErrorKey] as? String, value.removingPercentEncoding)
        }
        testError("invalid_request", .other)
        testError("unauthorized_client", .other)
        testError("access_denied", .denied)
        testError("unsupported_response_type", .other)
        testError("invalid_scope", .invalidScope)
        testError("server_error", .other)
        testError("temporarily_unavailable", .other)
        testError("invalid_client", .invalidClient)
        testError("test_error", .other)
        testError("test%3Derror", .other)
    }
    func testNilErrorFromUrl() {
        XCTAssertNil(YXLURLParser.error(from: URL(string: "http://oauth.yandex.ru#errors=access_denied")))
        XCTAssertNil(YXLURLParser.error(from: URL(string: "http://oauth.yandex.ru?error=access_denied")))
    }
    func testTokenFromUrl() {
        XCTAssertEqual(YXLURLParser.token(from: URL(string: "http://oauth.yandex.ru#access_token=test_token")), "test_token")
    }
    func testNilTokenFromUrl() {
        XCTAssertNil(YXLURLParser.token(from: URL(string: "http://oauth.yandex.ru#access_tokens=test_token")))
        XCTAssertNil(YXLURLParser.token(from: URL(string: "http://oauth.yandex.ru?access_token=test_token")))
    }
    func testStateFromUrl() {
        XCTAssertEqual(YXLURLParser.state(from: URL(string: "http://oauth.yandex.ru#state=test_state")), "test_state")
    }
    func testNilStateFromUrl() {
        XCTAssertNil(YXLURLParser.state(from: URL(string: "http://oauth.yandex.ru#states=test_token")))
        XCTAssertNil(YXLURLParser.state(from: URL(string: "http://oauth.yandex.ru?state=test_token")))
    }

    private var redirectUri: String {
        return "https://yx" + appId + ".oauth.yandex.ru/auth/finish?platform=ios"
    }
}
