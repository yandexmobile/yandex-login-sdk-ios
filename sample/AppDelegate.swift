@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow? = nil
    private let clientId = "57a8133c69d947388a67164dfdbc46d3"

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool
    {
        let window = UIWindow(frame: UIScreen.main.bounds)
        self.window = window

        let navigationController: UINavigationController
        do {
            try YXLSdk.shared.activate(withAppId: clientId)
            navigationController = UINavigationController(rootViewController: HomeViewController(style: .grouped))
        } catch {
            let vc = ErrorViewController(style: .grouped)
            vc.errorText = String(describing: error)
            navigationController = UINavigationController(rootViewController: vc)
        }
        window.rootViewController = navigationController
        window.makeKeyAndVisible()
        return true
    }

    @available(iOS 8.0, *)
    func application(_ application: UIApplication, continue userActivity: NSUserActivity, restorationHandler: @escaping ([Any]?) -> Void) -> Bool {
        YXLSdk.shared.processUserActivity(userActivity)
        return true
    }
}
