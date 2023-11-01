
import UIKit
import YandexLoginSDK

extension UIViewController {
    func errorOccured(_ error: Error) {
        let alertController: UIAlertController
        
        if let yandexLoginSDKError = error as? YandexLoginSDKError {
            alertController = UIAlertController(
                title: "A LoginSDK Error Occured",
                message: yandexLoginSDKError.message,
                preferredStyle: .alert
            )
        } else {
            alertController = UIAlertController(
                title: "An Error Occured",
                message: error.localizedDescription,
                preferredStyle: .alert
            )
        }
        
        let okAction = UIAlertAction(title: "OK", style: .cancel)
        
        alertController.addAction(okAction)
        self.present(alertController, animated: true)
    }
}
