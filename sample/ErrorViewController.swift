final class ErrorViewController: BaseViewController {
    var errorText: String = "" {
        didSet {
            reloadSections()
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Yandex SDK Sample v. \(YXLSdk.sdkVersion)"
        reloadSections()
    }

    private func reloadSections() {
        let item = ActionCellItem(text: "Activation error", type: .text)
        sections = [ SectionItem(title: nil, footer: errorText, items: [item]) ]
    }
}
