
import UIKit
import YandexLoginSDK

@main

class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        let clientId = "57a8133c69d947388a67164dfdbc46d3"
        
        do {
            try YandexLoginSDK.shared.activate(with: clientId)
        } catch {
            UIApplication.shared.keyWindow?.rootViewController?.errorOccured(error)
        }
        return true
    }
    
    func application(
        _ app: UIApplication,
        open url: URL,
        options: [UIApplication.OpenURLOptionsKey : Any] = [:]
    ) -> Bool {
        do {
            try YandexLoginSDK.shared.handleOpenURL(url)
        } catch {
            UIApplication.shared.keyWindow?.rootViewController?.errorOccured(error)
        }
        
        return true
    }
    
    func application(
        _ application: UIApplication,
        continue userActivity: NSUserActivity,
        restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void
    ) -> Bool {
        do {
            try YandexLoginSDK.shared.handleUserActivity(userActivity)
        } catch {
            UIApplication.shared.keyWindow?.rootViewController?.errorOccured(error)
        }
        
        return true
    }

    // MARK: UISceneSession Lifecycle

    @available(iOS 13.0, *)
    func application(
        _ application: UIApplication,
        configurationForConnecting connectingSceneSession: UISceneSession,
        options: UIScene.ConnectionOptions
    ) -> UISceneConfiguration {
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

}
