protocol CellItem {
}

enum ActionCellType {
    case text, button, destructiveButton
}

struct ActionCellItem: CellItem {
    let text: String
    let detailedText: String?
    let type: ActionCellType
    let action: (() -> Void)?

    init(text: String, detailedText: String? = nil, type: ActionCellType, action: @escaping () -> Void) {
        self.text = text
        self.detailedText = detailedText
        self.type = type
        self.action = action
    }
    init(text: String, detailedText: String? = nil, type: ActionCellType) {
        self.text = text
        self.detailedText = detailedText
        self.type = type
        self.action = nil
    }
}

struct InputCellItem: CellItem {
    let label: String?
    let placeholder: String?
    let valueBlock: () -> String?
    let action: (String?) -> Void
}

struct SwitchCellItem: CellItem {
    let label: String?
    let valueBlock: () -> Bool
    let action: (Bool) -> Void
}
