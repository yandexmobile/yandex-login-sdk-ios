
public protocol YandexLoginSDKObserver: AnyObject {
    
    func didFinishLogin(with result: Result<LoginResult, any Error>)
    
}
