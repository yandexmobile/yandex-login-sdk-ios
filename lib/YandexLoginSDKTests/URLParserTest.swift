import XCTest

class URLParserTest: XCTestCase {
    private let appId = "test.app"
    private let state = "test.state"

    func testAuthorizationURL() {
        let url = YXLURLParser.authorizationURL(withAppId: appId, state: state, pkce: "test.pkce")!
        XCTAssertEqual(url.scheme, "https")
        XCTAssertEqual(url.host, YXLHostProvider.oauthHost)
        XCTAssertEqual(url.path, "/authorize")
        if #available(iOS 8.0, *) {
            let queryItems = NSURLComponents(url: url, resolvingAgainstBaseURL: false)!.queryItems!
            XCTAssertTrue(queryItems.contains(URLQueryItem(name: "client_id", value: appId)))
            XCTAssertTrue(queryItems.contains(URLQueryItem(name: "response_type", value: "code")))
            XCTAssertTrue(queryItems.contains(URLQueryItem(name: "redirect_uri", value: redirectUri)))
            XCTAssertTrue(queryItems.contains(URLQueryItem(name: "state", value: state)))
            XCTAssertTrue(queryItems.contains(URLQueryItem(name: "force_confirm", value: "yes")))
            XCTAssertTrue(queryItems.contains(URLQueryItem(name: "origin", value: "yandex_auth_sdk_ios")))
            XCTAssertTrue(queryItems.contains(URLQueryItem(name: "code_challenge", value: "test.pkce")))
            XCTAssertTrue(queryItems.contains(URLQueryItem(name: "code_challenge_method", value: "S256")))
        }
    }
    func testAddStatistics() {
        let parameters = YXLStatisticsDataProvider.statisticsParameters!
        XCTAssertGreaterThan(parameters.count, 0)
        if #available(iOS 8.0, *) {
            let url = YXLURLParser.authorizationURL(withAppId: appId, state: state, pkce: "test.pkce")!
            let queryItems = NSURLComponents(url: url, resolvingAgainstBaseURL: false)!.queryItems!
            for parameter in parameters {
                XCTAssertTrue(queryItems.contains(URLQueryItem(name: parameter.key, value: parameter.value)))
            }
        }
    }
    func testOpenURL() {
        let url = YXLURLParser.openURL(withAppId: appId, state: state, pkce: "test.pkce")!
        XCTAssertEqual(url.scheme, "yandexauth2")
        XCTAssertEqual(url.host, "authorize")
        XCTAssertEqual(url.path, "")
        if #available(iOS 8.0, *) {
            let queryItems = NSURLComponents(url: url, resolvingAgainstBaseURL: false)!.queryItems!
            XCTAssertTrue(queryItems.contains(URLQueryItem(name: "client_id", value: appId)))
            XCTAssertTrue(queryItems.contains(URLQueryItem(name: "response_type", value: "code")))
            XCTAssertTrue(queryItems.contains(URLQueryItem(name: "redirect_uri", value: redirectUri)))
            XCTAssertTrue(queryItems.contains(URLQueryItem(name: "state", value: state)))
            XCTAssertTrue(queryItems.contains(URLQueryItem(name: "code_challenge", value: "test.pkce")))
            XCTAssertTrue(queryItems.contains(URLQueryItem(name: "code_challenge_method", value: "S256")))
        }
    }
    func testOpenURLUniversalLink() {
        let url = YXLURLParser.openURLUniversalLink(withAppId: appId, state: state)!
        XCTAssertEqual(url.scheme, "yandexauth")
        XCTAssertEqual(url.host, "authorize")
        XCTAssertEqual(url.path, "")
        if #available(iOS 8.0, *) {
            let queryItems = NSURLComponents(url: url, resolvingAgainstBaseURL: false)!.queryItems!
            XCTAssertTrue(queryItems.contains(URLQueryItem(name: "client_id", value: appId)))
            XCTAssertTrue(queryItems.contains(URLQueryItem(name: "response_type", value: "token")))
            XCTAssertTrue(queryItems.contains(URLQueryItem(name: "redirect_uri", value: redirectUriUniversalLink)))
            XCTAssertTrue(queryItems.contains(URLQueryItem(name: "state", value: state)))
            XCTAssertFalse(queryItems.contains(URLQueryItem(name: "code_challenge_method", value: "S256")))
        }
    }
    func testErrorFromUrl() {
        let testError: (String, YXLErrorCode) -> Void = { value, code in
            let error = YXLURLParser.error(from: URL(string: "http://oauth.yandex.ru?error=\(value)")) as NSError
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
        XCTAssertNil(YXLURLParser.error(from: URL(string: "http://oauth.yandex.ru?errors=access_denied")))
        XCTAssertNil(YXLURLParser.error(from: URL(string: "http://oauth.yandex.ru#error=access_denied")))
    }
    func testCodeFromUrl() {
        XCTAssertEqual(YXLURLParser.code(from: URL(string: "http://oauth.yandex.ru?code=test_code")), "test_code")
    }
    func testNilCodeFromUrl() {
        XCTAssertNil(YXLURLParser.code(from: URL(string: "http://oauth.yandex.ru?codes=test_code")))
        XCTAssertNil(YXLURLParser.code(from: URL(string: "http://oauth.yandex.ru#code=test_code")))
    }
    func testStateFromUrl() {
        XCTAssertEqual(YXLURLParser.state(from: URL(string: "http://oauth.yandex.ru?state=test_state")), "test_state")
    }
    func testNilStateFromUrl() {
        XCTAssertNil(YXLURLParser.state(from: URL(string: "http://oauth.yandex.ru?states=test_token")))
        XCTAssertNil(YXLURLParser.state(from: URL(string: "http://oauth.yandex.ru#state=test_token")))
    }
    func testTokenFromUniversalLinkUrl() {
        XCTAssertEqual(YXLURLParser.token(fromUniversalLinkURL: URL(string: "http://oauth.yandex.ru#access_token=test_token")), "test_token")
    }
    func testNilTokenFromUniversalLinkUrl() {
        XCTAssertNil(YXLURLParser.token(fromUniversalLinkURL: URL(string: "http://oauth.yandex.ru#access_tokens=test_token")))
        XCTAssertNil(YXLURLParser.token(fromUniversalLinkURL: URL(string: "http://oauth.yandex.ru?access_token=test_token")))
    }
    func testStateFromUniversalLinkUrl() {
        XCTAssertEqual(YXLURLParser.state(fromUniversalLinkURL: URL(string: "http://oauth.yandex.ru#state=test_state")), "test_state")
    }
    func testNilStateFromUniversalLinkUrl() {
        XCTAssertNil(YXLURLParser.state(fromUniversalLinkURL: URL(string: "http://oauth.yandex.ru#states=test_token")))
        XCTAssertNil(YXLURLParser.state(fromUniversalLinkURL: URL(string: "http://oauth.yandex.ru?state=test_token")))
    }
    func testErrorFromUniversalLinkUrl() {
        let error = YXLURLParser.error(fromUniversalLinkURL: URL(string: "http://oauth.yandex.ru#error=invalid_client")) as NSError
        XCTAssertEqual(error.code, YXLErrorCode.invalidClient.rawValue)
        XCTAssertEqual(error.userInfo[NSLocalizedFailureReasonErrorKey] as? String, "invalid_client")
    }
    func testNilErrorFromUniversalLinkUrl() {
        XCTAssertNil(YXLURLParser.error(fromUniversalLinkURL: URL(string: "http://oauth.yandex.ru#errors=access_denied")))
        XCTAssertNil(YXLURLParser.error(fromUniversalLinkURL: URL(string: "http://oauth.yandex.ru?error=access_denied")))
    }

    private var redirectUri: String {
        return "yx" + appId + ":///auth/finish?platform=ios"
    }

    private var redirectUriUniversalLink: String {
        return "https://yx" + appId + ".oauth.yandex.ru/auth/finish?platform=ios"
    }
}
