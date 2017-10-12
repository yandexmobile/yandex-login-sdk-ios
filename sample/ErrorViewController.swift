final class ErrorViewController : HomeViewController {
    var errorText: String = "" {
        didSet {
            reloadSections()
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        reloadSections()
    }

    private func reloadSections() {
        let controller = TextSectionController(text: "Activation error")
        controller.footer = errorText
        sectionControllers = [ controller ]
    }
}
