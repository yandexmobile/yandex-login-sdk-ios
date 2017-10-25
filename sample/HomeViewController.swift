class HomeViewController : UITableViewController, YXLObserver {
    var sectionControllers: [SectionController] = [] {
        didSet {
            tableView.reloadData()
        }
    }

    private enum Section: Int {
        case loginButton = 0, options
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        YXLSdk.shared.add(observer: self)
        title = "Yandex SDK Sample v. \(YXLSdk.sdkVersion)"
        sectionControllers = [ buttonSectionController, logoutSectionController ]
    }

    private var buttonSectionController: SectionController {
        return ButtonSectionController(text: "Login", textColor: ColorUtils.buttonTextColor) { [unowned self] in
            self.loginPressed()
        }
    }

    private var logoutSectionController: SectionController {
        return ButtonSectionController(text: "Logout", textColor: ColorUtils.destructiveButtonTextColor) { [unowned self] in
            self.logoutPressed()
        }
    }

    private func loginPressed() {
        setStatus(nil)
        YXLSdk.shared.authorize()
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
        sectionControllers[Section.loginButton.rawValue].footer = string
        tableView.reloadSections(IndexSet(integer: Section.loginButton.rawValue), with: .none)
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

extension HomeViewController {
    override func numberOfSections(in tableView: UITableView) -> Int {
        return sectionControllers.count
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return sectionControllers[section].tableView(tableView, numberOfRowsInSection: section)
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        return sectionControllers[indexPath.section].tableView(tableView, cellForRowAt: indexPath)
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        sectionControllers[indexPath.section].tableView(tableView, didSelectRowAt: indexPath)
    }

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return sectionControllers[section].tableView(tableView, titleForHeaderInSection: section)
    }

    override func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        return sectionControllers[section].tableView(tableView, titleForFooterInSection: section)
    }
}
