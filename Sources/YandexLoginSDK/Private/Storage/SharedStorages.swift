
import Foundation

enum SharedStorages {
    
    static let loginResultStorage = SecureStorage<String>(key: "YandexLoginSDKToken")
    static let codeVerifierStorage = SecureStorage<String>(key: "YandexLoginSDKCodeVerifier")
    static let statesStorage = DefaultStorage<Date>(key: "YandexLoginSDKStates")
}

class SpecializedStorages {
    static func loginResultStorage(clientID: String) -> SecureStorage<String> {
        SecureStorage<String>(key: "YandexLoginSDKToken"+clientID)
    }

    static func codeVerifierStorage(clientID: String) -> SecureStorage<String> {
        SecureStorage<String>(key: "YandexLoginSDKCodeVerifier"+clientID)
    }

    static func statesStorage(clientID: String) -> DefaultStorage<Date> {
        DefaultStorage<Date>(key: "YandexLoginSDKStates"+clientID)
    }
}

