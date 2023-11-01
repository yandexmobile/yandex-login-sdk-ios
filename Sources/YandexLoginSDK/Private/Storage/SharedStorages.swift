
import Foundation

enum SharedStorages {
    
    static let loginResultStorage = SecureStorage<String>(key: "YandexLoginSDKToken")
    static let codeVerifierStorage = SecureStorage<String>(key: "YandexLoginSDKCodeVerifier")
    static let statesStorage = DefaultStorage<Date>(key: "YandexLoginSDKStates")
    
}

