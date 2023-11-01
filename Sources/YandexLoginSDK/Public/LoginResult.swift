
public struct LoginResult {
    
    public let token: String
    public let jwt: String
    
    init(token: String, jwt: String) {
        self.token = token
        self.jwt = jwt
    }
    
    init?(dictionary: [String: String]) {
        guard let token = dictionary["token"],
              let jwt = dictionary["jwt"]
        else { return nil }
        
        self.init(token: token, jwt: jwt)
    }
    
    public var asDictionary: [String: String] {
        [
            "token": self.token,
            "jwt": self.jwt,
        ]
    }
    
    public var asString: String {
        """
        token: \(self.token)
        
        jwt: \(self.jwt)
        """
    }
    
}
