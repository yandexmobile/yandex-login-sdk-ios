struct SectionItem {
    let title: String?
    var footer: String?
    var items: [CellItem]
}

class BaseViewController: UITableViewController {
    var sections: [SectionItem] = [] {
        didSet {
            reload()
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        CellItemFactory.cellsIdsToClass.forEach { tableView.register($1, forCellReuseIdentifier: $0) }
    }

    func reload() {
        tableView.reloadData()
    }

    override func numberOfSections(in tableView: UITableView) -> Int {
        return sections.count
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return sections[section].items.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        return CellItemFactory.cell(by: sections[indexPath.section].items[indexPath.row], tableView: tableView)
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let item = sections[indexPath.section].items[indexPath.row]
        if let item = item as? ActionCellItem {
            item.action?()
        }
        tableView.deselectRow(at: indexPath, animated: true)
    }

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return sections[section].title
    }

    override func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        return sections[section].footer
    }
}
