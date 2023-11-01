
import AuthenticationServices
import Foundation
import SafariServices

public final class YandexLoginSDK: NSObject {
    
    public enum AuthorizationStrategy {
        
        case `default`, webOnly, primaryOnly
        
    }
    
    public static let shared = YandexLoginSDK()
    public static let version: String = "3.0.0"
    
    private var clientID: String?
    private var observersController = ObserversController()
    private var httpClient = HTTPClient()
    private var presentationController: UIViewController?
    private var safariViewController: SFSafariViewController?
    private var webAuthenticationSession: ASWebAuthenticationSession?
    
    static var isInTestEnvironment: Bool {
        Bundle.main.infoDictionary?["YandexLoginSDKUseTestEnvironment"] as? Bool ?? false
    }
    
    private var isActivated: Bool { self.clientID != nil }
    
    private var loginResult: LoginResult? {
        guard let loginResultAsDictionary = try? SharedStorages.loginResultStorage.loadObject() else {
            return nil
        }
        
        return LoginResult(dictionary: loginResultAsDictionary)
    }
    
    private override init() { super.init() }
    
    public func activate(with clientID: String, authorizationStrategy: AuthorizationStrategy = .default) throws {
        try ActivationValidator.validateActivation(with: clientID, authorizationStrategy: authorizationStrategy)
        self.clientID = clientID
    }
    
    public func tryHandleUserActivity(_ userActivity: NSUserActivity) -> Bool {
        do {
            try self.handleUserActivity(userActivity)
        } catch {
            return false
        }
        
        return true
    }
    
    public func handleUserActivity(_ userActivity: NSUserActivity) throws {
        guard self.isActivated else {
            throw CoreLoginSDKError.loginSDKIsNotActivated
        }
        
        guard userActivity.activityType == NSUserActivityTypeBrowsingWeb else {
            throw CoreLoginSDKError.invalidActivityType(
                activityType: userActivity.activityType,
                expectedActivityType: NSUserActivityTypeBrowsingWeb
            )
        }
        
        guard let url = userActivity.webpageURL else {
            throw CoreLoginSDKError.absentWebPageURLInUserActivity
        }
        
        try self.handleOpenWithUniversalLink(with: url)
    }
    
    public func tryHandleOpenURL(_ url: URL) -> Bool {
        do {
            try self.handleOpenURL(url)
        } catch {
            return false
        }
        
        return true
    }
    
    public func handleOpenURL(_ url: URL) throws {
        guard self.isActivated else {
            throw CoreLoginSDKError.loginSDKIsNotActivated
        }
        
        guard self.isURLRelatedToSDK(url: url) else {
            throw CoreLoginSDKError.urlIsNotRelatedToLoginSDK(url: url)
        }
        
        try self.handleOpenWithDeepLink(with: url)
    }
    
    public func isURLRelatedToSDK(url: URL) -> Bool {
        guard let clientID = self.clientID else { return false }
        return URLUtilities.isURLSchemeDefinedBySDK(url: url, clientID: clientID)
    }
    
    public func add(observer: any YandexLoginSDKObserver) {
        self.observersController.add(observer)
    }
    
    public func remove(observer: any YandexLoginSDKObserver) {
        self.observersController.remove(observer)
    }
    
    public func authorize(
        with parentViewController: UIViewController,
        customValues: [String: String]? = nil,
        authorizationStrategy: AuthorizationStrategy = .default
    ) throws {
        guard let clientID = self.clientID else {
            throw CoreLoginSDKError.loginSDKIsNotActivated
        }
        
        if let loginResult = self.loginResult {
            self.observersController.notifyLoginDidFinish(with: .success(loginResult))
            return
        }
        
        let state = try StatesManager.generateNewState()
        let pkce = try PKCE()
        
        try SharedStorages.codeVerifierStorage.save(object: pkce.codeVerifierAsDictionary)
        
        var customValuesAsString: String? = nil
        if let customValues {
            let data = try JSONEncoder().encode(customValues)
            let jsonAsString = String(data: data, encoding: .utf8)
            if let jsonAsString {
                customValuesAsString = try QueryUtilities.percentEncoded(jsonAsString)
            }
        }
        
        let authorizationParameters = AuthorizationParameters(
            clientID: clientID,
            state: state,
            codeChallenge: pkce.codeChallenge,
            customValues: customValuesAsString
        )
        
        let webURL = try URLUtilities.urlForWebAuthorization(with: authorizationParameters)
        let primaciesStack = ApplicationPrimacy.primacies(for: authorizationStrategy) ?? []
        switch authorizationStrategy {
        case .webOnly:
            self.performWebAuthorization(with: webURL, parentViewController: parentViewController)
        default:
            self.performAppAuthorization(
                with: primaciesStack,
                parentViewController: parentViewController,
                authorizationParameters: authorizationParameters,
                fallbackWebURL: webURL
            )
        }
    }
    
    public func logout() throws {
        SharedStorages.loginResultStorage.removeObject()
        SharedStorages.codeVerifierStorage.removeObject()
        try? StatesManager.removeAll()
    }
    
    
    
    private func handleOpenWithUniversalLink(with url: URL) throws {
        if let error = try? URLUtilities.urlComponentParameterValue(
            url: url,
            component: .fragment,
            pararmeter: .error
        ) {
            throw CoreLoginSDKError.errorParameterInResponseURL(error: error)
        }
        
        let token = try URLUtilities.urlComponentParameterValue(url: url, component: .fragment, pararmeter: .code)
        let state = try URLUtilities.urlComponentParameterValue(url: url, component: .fragment, pararmeter: .state)
        
        guard try StatesManager.checkStateValidity(state) else {
            throw CoreLoginSDKError.couldntFindStateInStatesManager(state: state)
        }
        try StatesManager.remove(state: state)
        
        try self.requestJWT(with: token)
        self.safariViewController?.dismiss(animated: true)
    }
    
    private func handleOpenWithDeepLink(with url: URL) throws {
        if let error = try? URLUtilities.urlComponentParameterValue(
            url: url,
            component: .query,
            pararmeter: .error
        ) {
            throw CoreLoginSDKError.errorParameterInResponseURL(error: error)
        }
        
        let code = try URLUtilities.urlComponentParameterValue(url: url, component: .query, pararmeter: .code)
        let state = try URLUtilities.urlComponentParameterValue(url: url, component: .query, pararmeter: .state)
        
        guard try StatesManager.checkStateValidity(state) else {
            throw CoreLoginSDKError.couldntFindStateInStatesManager(state: state)
        }
        try StatesManager.remove(state: state)
        
        let codeVerifierAsDictionary = try SharedStorages.codeVerifierStorage.loadObject()
        let pkce = try PKCE(from: codeVerifierAsDictionary)
        
        let codeVerifier = pkce.codeVerifier
        try self.requestToken(with: code, codeVerifier: codeVerifier)
        self.safariViewController?.dismiss(animated: true)
    }
    
    private func performAppAuthorization(
        with primaciesStack: [ApplicationPrimacy],
        parentViewController: UIViewController,
        authorizationParameters: AuthorizationParameters,
        fallbackWebURL webURL: URL
    ) {
        guard let primacy = primaciesStack.last else {
            self.performWebAuthorization(with: webURL, parentViewController: parentViewController)
            return
        }
        
        let failureHandler = { [weak self] in
            let poppedPrimaciesStack = Array(primaciesStack.dropLast(1))
            self?.performAppAuthorization(
                with: poppedPrimaciesStack,
                parentViewController: parentViewController,
                authorizationParameters: authorizationParameters,
                fallbackWebURL: webURL
            )
        }
        
        do {
            let deepLinkURL = try URLUtilities.deepLinkForAppAuthorization(
                with: authorizationParameters,
                primacy: primacy
            )
            
            let universalLinkURL = try URLUtilities.universalLinkForAppAuthorization(
                with: authorizationParameters,
                primacy: primacy
            )
            
            if UIApplication.shared.canOpenURL(deepLinkURL) {
                UIApplication.shared.open(universalLinkURL) { success in
                    if !success { failureHandler() }
                }
            } else {
                failureHandler()
            }
        } catch {
            self.observersController.notifyLoginDidFinish(with: .failure(error))
        }
    }
    
    private func performWebAuthorization(with url: URL, parentViewController parent: UIViewController) {
        if #available(iOS 13.0, *) {
            self.performWebAuthorizationUsingAuthenticationServices(with: url, parentViewController: parent)
        } else {
            self.performWebAuthorizationUsingSafariServices(with: url, parentViewController: parent)
        }
    }
    
    @available(iOS 13.0, *)
    private func performWebAuthorizationUsingAuthenticationServices(
        with url: URL,
        parentViewController parent: UIViewController
    ) {
        guard let clientID = self.clientID else {
            fatalError("Client ID must not be nil at this point.")
        }
        
        self.presentationController = parent
        
        let authenticationSession = ASWebAuthenticationSession(
            url: url,
            callbackURLScheme: URLUtilities.urlSchemeDefinedBySDK(forAppWith: clientID)
        ) { [weak self] url, error in
            guard let self else { return }
            if let url {
                if self.isActivated && self.isURLRelatedToSDK(url: url) {
                    do {
                        try self.handleOpenWithDeepLink(with: url)
                    } catch {
                        self.failureHandler(with: error)
                    }
                }
            } else if let error {
                self.failureHandler(with: error)
            }
            
            self.presentationController = nil
            self.webAuthenticationSession = nil
        }
        authenticationSession.presentationContextProvider = self
        
        self.webAuthenticationSession = authenticationSession
        authenticationSession.start()
    }
    
    private func performWebAuthorizationUsingSafariServices(
        with url: URL,
        parentViewController parent: UIViewController
    ) {
        let safariViewController = SFSafariViewController(url: url)
        safariViewController.delegate = self
        safariViewController.modalPresentationStyle = .overFullScreen
        
        self.safariViewController = safariViewController
        parent.present(safariViewController, animated: true)
    }
    
    private func requestToken(with code: String, codeVerifier: String) throws {
        guard let clientID = self.clientID else { return }
        let requestComponents = TokenRequestComponents(code: code, codeVerifier: codeVerifier, clientID: clientID)
        try self.httpClient.executeRequest(
            with: requestComponents,
            onSuccess: { [weak self] token in
                do {
                    try self?.requestJWT(with: token)
                } catch {
                    self?.failureHandler(with: error)
                }
            },
            onFailure: { [weak self] error in
                self?.failureHandler(with: error)
            }
        )
    }
    
    private func requestJWT(with token: String) throws {
        let requestComponents = JWTRequestComponents(token: token)
        try self.httpClient.executeRequest(
            with: requestComponents,
            onSuccess: { [weak self] jwt in
                let result = LoginResult(token: token, jwt: jwt)
                
                do {
                    try SharedStorages.loginResultStorage.save(object: result.asDictionary)
                } catch {
                    self?.failureHandler(with: error)
                    return
                }
                
                self?.observersController.notifyLoginDidFinish(with: .success(result))
            },
            onFailure: { [weak self] error in
                self?.failureHandler(with: error)
            }
        )
    }
    
    private func failureHandler(with error: Error) -> Void {
        self.observersController.notifyLoginDidFinish(with: .failure(error))
    }
    
}

// MARK: Safari view controller delegate

extension YandexLoginSDK: SFSafariViewControllerDelegate {
    
    public func safariViewControllerDidFinish(_ controller: SFSafariViewController) {
        self.observersController.notifyLoginDidFinish(with: .failure(CoreLoginSDKError.userClosedWebViewController))
    }
    
}

// MARK: Providing web authentiation presentation context

@available (iOS 13.0, *)
extension YandexLoginSDK: ASWebAuthenticationPresentationContextProviding {
    
    public func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        return self.presentationController?.view.window ?? ASPresentationAnchor()
    }
    
}
