
enum HostType {
    
    case oauth, login, pssp
    
}

enum HostProvider {
    
    static func host(for hostType: HostType) -> String {
        let inTestEnvironment = YandexLoginSDK.isInTestEnvironment
        
        switch hostType {
        case .oauth:
            return inTestEnvironment ? "oauth-test.yandex.ru" : "oauth.yandex.ru"
        case .login:
            return inTestEnvironment ? "login-test.yandex.ru" : "login.yandex.ru"
        case .pssp:
            return inTestEnvironment ? "loginsdk.passport-test.yandex.ru" : "loginsdk.passport.yandex.ru"
        }
    }
    
}
