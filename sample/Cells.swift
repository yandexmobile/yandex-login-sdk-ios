final class ActionCell: UITableViewCell {
    func configure(withText text: String, detailedText: String?, type: ActionCellType) {
        textLabel!.text = text
        textLabel!.textColor = color(byType: type)
    }

    private func color(byType type: ActionCellType) -> UIColor {
        switch type {
        case .text: return .black
        case .button: return UIColor(red: 0.2, green: 0.4, blue: 0.6, alpha: 1)
        case .destructiveButton: return UIColor(red: 0.8, green: 0.2, blue: 0.2, alpha: 1)
        }
    }
}

final class InputCell: UITableViewCell, UITextFieldDelegate {
    private let label = UILabel()
    private let input = UITextField()
    private var action: ((String?) -> Void)?

    func configure(withLabel labelText: String?, placeholder: String?, inputText: String?, action: @escaping (String?) -> Void) {
        label.text = labelText
        input.placeholder = placeholder
        input.text = inputText
        self.action = action
        if input.superview == nil {
            input.autocapitalizationType = .none
            input.autocorrectionType = .no
            input.delegate = self
            addSubview(label)
            addSubview(input)
            selectionStyle = .none
            input.addTarget(self, action: #selector(onChanged), for: .editingChanged)
        }
    }

    override func layoutSubviews() {
        let kMarginX: CGFloat = 10.0
        super.layoutSubviews()

        let labelWidth = label.sizeThatFits(contentView.bounds.size).width
        let rect = contentView.bounds.insetBy(dx: kMarginX, dy: 0)
        (label.frame, input.frame) = rect.divided(atDistance: labelWidth + kMarginX, from: .minXEdge)
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        action?(input.text)
        return true
    }

    @objc func onChanged() {
        action?(input.text)
    }
}
