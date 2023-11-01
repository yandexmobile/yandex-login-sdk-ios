
import UIKit
import YandexLoginSDK

final class ViewController: UIViewController {
    
    @IBOutlet weak var segmentedControl: UISegmentedControl!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var logoutButton: UIButton!
    
    private var customValues: [String: String] = [:]
    private var customValuesAsArray: [(key: String, value: String)] = []
    private var authorizationSource: YandexLoginSDK.AuthorizationStrategy = .default
    private var loginResult: LoginResult? {
        didSet {
            logoutButton.isEnabled = (loginResult != nil)
        }
    }
    
    private let decoder = JSONDecoder()
    private let encoder = JSONEncoder()
    
    private var customValuesURL: URL? {
        guard let cachesURL = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first
        else { return nil }
        
        let customValuesURL: URL
        if #available(iOS 16.0, *) {
            customValuesURL = cachesURL.appending(path: "CustomValues.json")
        } else {
            customValuesURL = cachesURL.appendingPathComponent("CustomValues.json")
        }
        
        return customValuesURL
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = "Yandex LoginSDK \(YandexLoginSDK.version)"
        self.loadCustomValues()
        self.customValuesAsArray = self.customValues.map { ($0, $1) }
        
        self.tableView.delegate = self
        self.tableView.dataSource = self
        self.tableView.register(CustomValuesCell.self, forCellReuseIdentifier: CustomValuesCell.reuseIdentfier)
        
        YandexLoginSDK.shared.add(observer: self)
    }
    
    private func loadCustomValues() {
        do {
            guard let customValuesURL = self.customValuesURL else { return }
            guard FileManager.default.fileExists(atPath: customValuesURL.absoluteString) else { return }
            
            let data = try Data(contentsOf: customValuesURL)
            self.customValues = try decoder.decode(Dictionary<String, String>.self, from: data)
        } catch {
            self.errorOccured(error)
        }
    }
    
    private func saveCustomValues() {
        do {
            guard let customValuesURL = self.customValuesURL else { return }
            
            let data = try encoder.encode(self.customValues)
            try data.write(to: customValuesURL)
        } catch {
            self.errorOccured(error)
        }
    }
    
    @IBAction func loginButtonPressed(_ sender: UIButton) {
        do {
            let authorizationStrategy: YandexLoginSDK.AuthorizationStrategy
            switch self.segmentedControl.selectedSegmentIndex {
            case 0:
                authorizationStrategy = .default
            case 1:
                authorizationStrategy = .webOnly
            case 2:
                authorizationStrategy = .primaryOnly
            default:
                fatalError("Segmented control is configured to only have 2 segments.")
            }
            
            try YandexLoginSDK.shared.authorize(
                with: self,
                customValues: self.customValues.isEmpty ? nil : self.customValues,
                authorizationStrategy: authorizationStrategy
            )
        } catch {
            self.errorOccured(error)
        }
    }
    
    @IBAction func logoutButtonPressed(_ sender: UIButton) {
        do {
            try YandexLoginSDK.shared.logout()
            self.loginResult = nil
        } catch {
            self.errorOccured(error)
        }
    }
    
    @IBAction func infoButtonPressed(_ sender: UIBarButtonItem) {
        let alertController: UIAlertController
        
        if let loginResult = self.loginResult {
            alertController = UIAlertController(
                title: "Login Result",
                message: loginResult.asString,
                preferredStyle: .alert
            )
            
            let copyAction = UIAlertAction(title: "Copy and Close", style: .default) { _ in
                UIPasteboard.general.string = loginResult.asString
            }
            alertController.addAction(copyAction)
        } else {
            alertController = UIAlertController(
                title: "Login Result",
                message: "There is no login result.",
                preferredStyle: .alert
            )
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
        alertController.addAction(cancelAction)
        
        self.present(alertController, animated: true)
    }
    
    @IBAction func plusButtonPressed(_ sender: UIButton) {
        let alertController = UIAlertController(title: "Add New Custom Value", message: nil, preferredStyle: .alert)
        
        let addAction = UIAlertAction(title: "OK", style: .default) { _ in
            guard let key = alertController.textFields?[0].text,
                  self.customValues[key] == nil,
                  let value = alertController.textFields?[1].text
            else { return }
            
            self.customValues[key] = value
            self.customValuesAsArray.append((key, value))
            self.tableView.reloadData()
            self.saveCustomValues()
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
        
        alertController.addTextField { textField in
            textField.placeholder = "key"
        }
        
        alertController.addTextField { textField in
            textField.placeholder = "value"
        }
        
        alertController.addAction(addAction)
        alertController.addAction(cancelAction)
        
        self.present(alertController, animated: true)
    }
    
    @IBAction func eraseButtonPressed(_ sender: UIButton) {
        var totalValues: Double = 0
        for _ in self.customValuesAsArray {
            Timer.scheduledTimer(withTimeInterval: 0.15 * totalValues, repeats: false) { _ in
                let (key, _) = self.customValuesAsArray.removeFirst()
                self.customValues.removeValue(forKey: key)
                self.tableView.deleteRows(at: [IndexPath(row: 0, section: 0)], with: .automatic)
                self.saveCustomValues()
            }
            totalValues += 1
        }
    }
}

extension ViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
}

extension ViewController: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.customValuesAsArray.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: CustomValuesCell.reuseIdentfier, for: indexPath)
        guard let customValuesCell = cell as? CustomValuesCell else { return cell }
        customValuesCell.key = self.customValuesAsArray[indexPath.row].key
        customValuesCell.value = self.customValuesAsArray[indexPath.row].value
        return customValuesCell
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool { true }
    
    func tableView(
        _ tableView: UITableView,
        commit editingStyle: UITableViewCell.EditingStyle,
        forRowAt indexPath: IndexPath
    ) {
        switch editingStyle {
        case .delete:
            let key = self.customValuesAsArray[indexPath.row].key
            self.customValuesAsArray.remove(at: indexPath.row)
            self.customValues.removeValue(forKey: key)
            self.tableView.deleteRows(at: [indexPath], with: .automatic)
            self.saveCustomValues()
        default:
            break
        }
    }
    
}

extension ViewController: YandexLoginSDKObserver {
    
    func didFinishLogin(with result: Result<LoginResult, Error>) {
        switch result {
        case .success(let loginResult):
            self.loginResult = loginResult
        case .failure(let error):
            self.errorOccured(error)
        }
    }
    
}
