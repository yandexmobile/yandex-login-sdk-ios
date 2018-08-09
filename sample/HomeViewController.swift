final class HomeViewController: BaseViewController, YXLObserver {
    private var uid: String?
    private var login: String?

    override func viewDidLoad() {
        super.viewDidLoad()
        YXLSdk.shared.add(observer: self)
        title = "Yandex SDK Sample v. \(YXLSdk.sdkVersion)"
        sections = [loginSection, logoutSection]
    }
    
    private var loginSection: SectionItem {
        let items: [CellItem] = [
            InputCellItem(label: "Uid:", placeholder: "expected uid or 0",
                          valueBlock: { [unowned self] in self.uid },
                          action: { [unowned self] text in self.uid = text }),
            InputCellItem(label: "Login:", placeholder: "login hint",
                          valueBlock: { [unowned self] in self.login },
                          action: { [unowned self] text in self.login = text }),
            ActionCellItem(text: "Login", type: .button) { [unowned self] in self.loginPressed() }
            ]
        return SectionItem(title: nil, footer: nil, items: items)
    }

    private var logoutSection: SectionItem {
        let item = ActionCellItem(text: "Logout", type: .destructiveButton) { [unowned self] in self.logoutPressed() }
        return SectionItem(title: nil, footer: nil, items: [item])
    }

    private func loginPressed() {
        setStatus(nil)
        YXLSdk.shared.authorize(withUid: Int64(uid ?? "") ?? 0, login: login)
    }

    private func logoutPressed() {
        let cookies = HTTPCookieStorage.shared.cookies ?? []
        for cookie in cookies {
            HTTPCookieStorage.shared.deleteCookie(cookie)
        }
        YXLSdk.shared.logout()
        setStatus(nil)
    }

    private func setStatus(_ string: String?) {
        sections[sections.count - 1].footer = string
        reload()
    }

    func loginDidFinish(with result: YXLLoginResult) {
        setStatus(String(describing: result))
    }

    func loginDidFinishWithError(_ error: Error) {
        setStatus("Error! " + stringForError(error))
    }

    private func stringForError(_ error: Error) -> String {
        guard (error as NSError).domain == kYXLErrorDomain, let code = YXLErrorCode(rawValue: (error as NSError).code) else {
            return String(describing: error)
        }
        switch code {
        case .notActivated:
            return "Sdk is not activated"
        case .cancelled:
            return "Authorization controller closed by user"
        case .denied:
            return "User denied access in permissions page"
        case .invalidClient:
            return "AppId authentication failed"
        case .invalidScope:
            return "The requested scope is invalid, unknown, or malformed"
        case .other:
            return "Other error " + String(describing: error)
        case .requestError:
            return "Internal HTTP request error"
        case .requestConnectionError:
            return "HTTP internet connection error"
        case .requestSSLError:
            return "HTTP SSL error"
        case .requestNetworkError:
            return "Other HTTP error"
        case .requestResponseError:
            return "Bad response for HTTP request (not NSHTTPURLResponse or status code not in 200..299)"
        case .requestEmptyDataError:
            return "Empty data returns on some HTTP request"
        case .requestTokenError:
            return "Bad answer for token request"
        case .requestJwtError:
            return "Bad answer for jwt request"
        case .requestJwtInternalError:
            return "Jwt request internal error"
        case .invalidState:
            return "Invalid state parameter"
        case .invalidCode:
            return "Invalid authorization code"
        }
    }
}
