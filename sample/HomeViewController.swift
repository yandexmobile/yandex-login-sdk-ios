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
        title = "Yandex SDK Sample"
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
        YXLSdk.shared.authorize(withParentViewController: self)
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
        setStatus(String(describing: error))
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
