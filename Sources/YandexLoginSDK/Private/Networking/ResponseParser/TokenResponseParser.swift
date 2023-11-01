
import Foundation

struct TokenResponseParser: ResponseParser {
    
    func parseData(_ data: Data) throws -> String {
        guard let jsonObject = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw NetworkingError.couldntCreateJSONObjectFromData
        }
        
        guard let token = jsonObject["access_token"] else {
            throw NetworkingError.absentTokenInJSON(jsonObject: jsonObject)
        }
        
        guard let stringToken = token as? String else {
            throw NetworkingError.invalidTokenType(tokenType: "\(type(of: token))")
        }
        
        return stringToken
    }
    
}
