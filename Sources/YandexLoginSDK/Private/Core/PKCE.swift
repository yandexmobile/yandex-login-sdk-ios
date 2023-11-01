
import Foundation

struct PKCE {
    
    static let codeVerifierKey = "code"
    
    let codeVerifier: String
    let codeChallenge: String
    
    var codeVerifierAsDictionary: [String: String] {
        [PKCE.codeVerifierKey: self.codeVerifier]
    }
    
    init(codeVerifier: String) throws {
        self.codeVerifier = codeVerifier
        self.codeChallenge = try PKCE.codeChallenge(for: codeVerifier)
    }
    
    init() throws {
        try self.init(codeVerifier: PKCE.generateCodeVerifier())
    }
    
    init(from dictionary: [String: Any]) throws {
        guard let codeVerifier = dictionary[PKCE.codeVerifierKey] as? String else {
            throw  PKCEError.absentValueForCodeVerifierKeyInDictionary(dictionary: dictionary)
        }
        
        try self.init(codeVerifier: codeVerifier)
    }
    
    private static func generateCodeVerifier() -> String {
        /*
         Сode verifier's length must be in range from 43 up to 128 after base64 encoding.
         This means the data object must contain bytes in amount from 32 up to 96.
         */
        let bytesCount = Int.random(in: 32...96)
        var data = Data(capacity: bytesCount)
        for _ in 0..<bytesCount {
            data.append(UInt8.random(in: UInt8.min...UInt8.max))
        }
        let codeVerifier = CryptoUtilities.base64URLEncodedString(from: data)
        
        return codeVerifier
    }
    
    private static func codeChallenge(for codeVerifier: String) throws -> String {
        guard let codeVerifierData = codeVerifier.data(using: .utf8) else {
            throw PKCEError.couldntCreateDataFromCodeVerifierString(codeVerifier: codeVerifier)
        }
        
        let hashedData = CryptoUtilities.sha256(from: codeVerifierData)
        let codeChallenge = CryptoUtilities.base64URLEncodedString(from: hashedData)
        
        return codeChallenge
    }
    
}
