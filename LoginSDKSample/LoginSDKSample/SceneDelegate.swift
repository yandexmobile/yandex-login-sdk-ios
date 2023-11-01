
import UIKit
import YandexLoginSDK

@available(iOS 13.0, *)
class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?

    func scene(
        _ scene: UIScene,
        willConnectTo session: UISceneSession,
        options connectionOptions: UIScene.ConnectionOptions
    ) {
        guard let _ = (scene as? UIWindowScene) else { return }
    }
    
    func scene(
        _ scene: UIScene,
        openURLContexts URLContexts: Set<UIOpenURLContext>
    ) {
        for urlContext in URLContexts {
            let url = urlContext.url
            
            do {
                try YandexLoginSDK.shared.handleOpenURL(url)
            } catch {
                UIApplication.shared.keyWindow?.rootViewController?.errorOccured(error)
            }
        }
    }
    
}

