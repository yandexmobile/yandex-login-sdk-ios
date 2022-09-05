final class HomeViewController: BaseViewController, YXLObserver {
    private var uid: String?
    private var login: String?
    private var phone: String?
    private var firstName: String?
    private var lastName: String?
    private var customValues: [String: String]?
    private var scopes: [String]?
    private var optionalScopes: [String]?

    override func viewDidLoad() {
        super.viewDidLoad()
        YXLSdk.shared.add(observer: self)
        updateTitle()
        sections = [loginSection, logoutSection]
    }

    private func updateTitle () {
        let appName = "Yandex SDK Sample v. \(YXLSdk.sdkVersion)\n"
        let isTesting: Bool? = Bundle.main.object(forInfoDictionaryKey: "YXLUseTestEnvironment") as! Bool?
        var appConfig = isTesting ?? false ? "Environment: Testing, " : "Environment: Production, "
        appConfig.append(NSClassFromString("YMMYandexMetrica") != nil ? "Metrica: On" : "Metrica: Off")
        let text = NSMutableAttributedString(string: appName + appConfig)
        text.addAttributes([NSAttributedString.Key.font : UIFont.boldSystemFont(ofSize: 14),
                            NSAttributedString.Key.foregroundColor : UIColor.black],
                           range: NSRange(location: 0, length: appName.count))
        text.addAttributes([NSAttributedString.Key.font : UIFont.boldSystemFont(ofSize: 10),
                            NSAttributedString.Key.foregroundColor : UIColor.darkGray],
                           range: NSRange(location: appName.count, length: appConfig.count))

        let titleLabel = UILabel()
        titleLabel.numberOfLines = 2
        titleLabel.textAlignment = .center
        titleLabel.attributedText = text
        self.navigationItem.titleView = titleLabel
    }

    private var loginSection: SectionItem {
        let items: [CellItem] = [
            InputCellItem(label: "Uid:", placeholder: "expected uid or 0",
                          valueBlock: { [unowned self] in self.uid },
                          action: { [unowned self] text in self.uid = text }),
            InputCellItem(label: "Login:", placeholder: "login hint",
                          valueBlock: { [unowned self] in self.login },
                          action: { [unowned self] text in self.login = text }),
            InputCellItem(label: "Phone:", placeholder: "phone hint",
                          valueBlock: { [unowned self] in self.phone },
                          action: { [unowned self] text in self.phone = text }),
            InputCellItem(label: "First name:", placeholder: "first name hint",
                          valueBlock: { [unowned self] in self.firstName },
                          action: { [unowned self] text in self.firstName = text }),
            InputCellItem(label: "Last name:", placeholder: "last name hint",
                          valueBlock: { [unowned self] in self.lastName },
                          action: { [unowned self] text in self.lastName = text }),
            SwitchCellItem(label: "Force confirm dialog",
                           valueBlock: { YXLSdk.shared.forceConfirmationDialog },
                           action: { value in YXLSdk.shared.forceConfirmationDialog = value }),
            SwitchCellItem(label: "Force fullscreen",
                           valueBlock: { YXLSdk.shared.forceFullscreenDialogs },
                           action: { value in YXLSdk.shared.forceFullscreenDialogs = value }),
            ActionCellItem(text: "Scopes", type: .button) { [unowned self] in
                self.showScopesEditor()
            },
            ActionCellItem(text: "Optional scopes", type: .button) { [unowned self] in
                self.showOptionalScopesEditor()
            },
            ActionCellItem(text: "Custom values", type: .button) { [unowned self] in
                self.showCustomValuesEditor()
            },
            ActionCellItem(text: "Login", type: .button) { [unowned self] in self.loginPressed() }
            ]
        return SectionItem(title: nil, footer: nil, items: items)
    }

    private var logoutSection: SectionItem {
        let item = ActionCellItem(text: "Logout", type: .destructiveButton) { [unowned self] in self.logoutPressed() }
        return SectionItem(title: nil, footer: nil, items: [item])
    }

    private func showCustomValuesEditor() {
        let customValuesEditor = CustomValuesEditor(customValues: self.customValues) { [weak self] customValues in
            self?.customValues = customValues
        }
        self .present(customValuesEditor, animated: false, completion: nil)
    }

    private func showScopesEditor() {
        let customValuesEditor = CustomArrayEditor(customValues: self.scopes) { [weak self] scopes in
            self?.scopes = scopes
        }
        self .present(customValuesEditor, animated: false, completion: nil)
    }

    private func showOptionalScopesEditor() {
        let customValuesEditor = CustomArrayEditor(customValues: self.optionalScopes) { [weak self] optionalScopes in
            self?.optionalScopes = optionalScopes
        }
        self .present(customValuesEditor, animated: false, completion: nil)
    }

    private func loginPressed() {
        setStatus(nil)
      YXLSdk.shared.scopes = scopes
      YXLSdk.shared.optionalScopes = optionalScopes
        YXLSdk.shared.authorize(withUid: Int64(uid ?? "") ?? 0,
                                login: login,
                                phone: phone,
                                firstName: firstName,
                                lastName: lastName,
                                customValues: self.customValues,
                                parentController: self)
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
