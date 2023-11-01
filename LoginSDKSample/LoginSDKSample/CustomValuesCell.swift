
import Foundation
import UIKit

final class CustomValuesCell: UITableViewCell {
    
    static let reuseIdentfier = "CustomValuesCell"
    
    var key: String? {
        get {
            self.textLabel?.text
        }
        
        set {
            self.textLabel?.text = newValue
        }
    }
    
    var value: String? {
        get {
            self.detailTextLabel?.text
        }
        
        set {
            self.detailTextLabel?.text = newValue
        }
    }
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: .subtitle, reuseIdentifier: reuseIdentifier)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}
