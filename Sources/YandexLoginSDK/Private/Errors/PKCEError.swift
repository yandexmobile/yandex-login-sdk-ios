
enum PKCEError: YandexLoginSDKError {
    
    case couldntCreateDataFromCodeVerifierString(codeVerifier: String)
    case absentValueForCodeVerifierKeyInDictionary(dictionary: [String: Any])
    
    var message: String {
        var message: String
        
        switch self {
        case .couldntCreateDataFromCodeVerifierString(let codeVerifier):
            message = """
                      Couldn't create data from code verifier string using UTF-8 encoding.
                      - code verifier: \(codeVerifier)
                      """
        case .absentValueForCodeVerifierKeyInDictionary(let dictionary):
            message = """
                      Couldn't find value for code verifier key in dictionary.
                      - key: \(PKCE.codeVerifierKey)
                      - dictionary:
                      
                      """
            for (key, value) in dictionary {
                message.append("    - \(key): \(value)\n")
            }
        }
        
        return message
    }
    
}
