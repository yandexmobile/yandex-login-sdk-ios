class SectionController: NSObject, UITableViewDataSource, UITableViewDelegate {
    var header: String? = nil
    var footer: String? = nil

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        return UITableViewCell(style: .default, reuseIdentifier: nil)
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return header
    }

    func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        return footer
    }
}

final class ButtonSectionController : SectionController {
    private let text: String
    private let textColor: UIColor?
    private let actionBlock: () -> Void
    private static let kCellIdentifier = "ButtonCell"

    init(text: String, textColor: UIColor?, actionBlock: @escaping () -> Void) {
        self.text = text
        self.textColor = textColor
        self.actionBlock = actionBlock
        super.init()
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: type(of: self).kCellIdentifier) ??
            UITableViewCell(style: .default, reuseIdentifier: type(of: self).kCellIdentifier)
        cell.textLabel!.textColor = self.textColor
        cell.textLabel!.text = text
        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        actionBlock()
        tableView.deselectRow(at: indexPath, animated: true)
    }
}

final class TextSectionController : SectionController {
    private let text: String
    private static let kCellIdentifier = "TextCell"

    init(text: String) {
        self.text = text
        super.init()
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: type(of: self).kCellIdentifier) ??
            UITableViewCell(style: .default, reuseIdentifier: type(of: self).kCellIdentifier)
        cell.selectionStyle = .none
        cell.textLabel!.text = text
        return cell
    }
}
