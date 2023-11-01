
struct JWTRequestComponents: RequestComponentsProvider {
    
    private let token: String
    
    init(token: String) {
        self.token = token
    }
    
    var urlAsString: String {
        "https://\(HostProvider.host(for: .login))/info"
    }
    
    var parameters: [String: String] {
        [
            "oauth_token": self.token,
            "format": "jwt",
        ]
    }
    
}
