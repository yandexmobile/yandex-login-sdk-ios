struct CellItemFactory {
    private static let actionCellIdentifier = "ActionCell"
    private static let inputCellIdentifier = "InputCell"
    private static let switchCellIdentifier = "SwitchCell"

    private init() { }

    static var cellsIdsToClass: [String: Swift.AnyClass] {
        return [
            actionCellIdentifier: ActionCell.self,
            inputCellIdentifier: InputCell.self,
            switchCellIdentifier: SwitchCell.self,
        ]
    }

    static func cell(by item: CellItem, tableView: UITableView) -> UITableViewCell {
        let resultCell: UITableViewCell
        if let item = item as? ActionCellItem {
            let cell = tableView.dequeueReusableCell(withIdentifier: actionCellIdentifier)! as! ActionCell
            cell.configure(withText: item.text, detailedText: item.detailedText, type: item.type)
            cell.selectionStyle = item.action == nil ? .none : .default
            resultCell = cell
        } else if let item = item as? InputCellItem {
            let cell = tableView.dequeueReusableCell(withIdentifier: inputCellIdentifier)! as! InputCell
            cell.configure(withLabel: item.label, placeholder: item.placeholder, inputText: item.valueBlock(), action: item.action)
            resultCell = cell
        } else if let item = item as? SwitchCellItem {
            let cell = tableView.dequeueReusableCell(withIdentifier: switchCellIdentifier)! as! SwitchCell
            cell.configure(withText: item.label, value: item.valueBlock(), action: item.action)
            resultCell = cell
        } else {
            fatalError("Invalid type of cell item \(item)")
        }
        return resultCell
    }
}

