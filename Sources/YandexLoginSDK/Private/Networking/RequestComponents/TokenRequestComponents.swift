
struct TokenRequestComponents: RequestComponentsProvider {
    
    private let code: String
    private let codeVerifier: String
    private let clientID: String
    
    init(code: String, codeVerifier: String, clientID: String) {
        self.code = code
        self.codeVerifier = codeVerifier
        self.clientID = clientID
    }
    
    var urlAsString: String {
        "https://\(HostProvider.host(for: .oauth))/token"
    }
    
    var parameters: [String : String] {
        [
            "code": self.code,
            "code_verifier": self.codeVerifier,
            "client_id": self.clientID,
            "grant_type": "authorization_code",
        ]
    }
    
}
