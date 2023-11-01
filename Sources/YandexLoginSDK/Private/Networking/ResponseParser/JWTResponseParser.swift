
import Foundation

struct JWTResponseParser: ResponseParser {
    
    func parseData(_ data: Data) throws -> String {
        guard let jwt = String(data: data, encoding: .utf8) else {
            throw NetworkingError.couldntCreateStringFromData
        }
        
        return jwt
    }
    
}
