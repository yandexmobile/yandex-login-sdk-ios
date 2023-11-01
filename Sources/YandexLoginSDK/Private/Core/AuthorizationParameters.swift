
struct AuthorizationParameters {
    
    let clientID: String
    let state: String
    let codeChallenge: String?
    let customValues: String?
    
    var asDictionary: [String: String] {
        var queryParameters = [
            "client_id": self.clientID,
            "state": self.state,
        ]
        
        if let codeChallenge {
            queryParameters["code_challenge"] = codeChallenge
            queryParameters["code_challenge_method"] = "S256"
        }
        
        if let customValues {
            queryParameters["custom_values"] = customValues
        }
        
        return queryParameters
    }
    
}
