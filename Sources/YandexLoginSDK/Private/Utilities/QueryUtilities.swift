
enum QueryUtilities {
    
    static func percentEncoded(_ string: String) throws -> String {
        guard let encoded = string.addingPercentEncoding(withAllowedCharacters: .alphanumerics) else {
            throw QueryUtilitiesError.couldntPerformPercentEncoding(string: string)
        }
        
        return encoded
    }
    
    static func query(from parameters: [String: String]) throws -> String {
        try parameters.map { "\(try percentEncoded($0))=\(try percentEncoded($1))" }.joined(separator: "&")
    }
    
    static func parameters(from query: String) throws -> [String: String] {
        var parameters: [String: String] = [:]
        
        let attributeValuePairs = query.split(separator: "&").map { $0.split(separator: "=") }
        for pair in attributeValuePairs {
            guard pair.count == 2
            else { throw QueryUtilitiesError.invalidAmountOfElementsInComponent(elementCount: pair.count) }
            
            guard let attribute = String(pair[0]).removingPercentEncoding,
                  let value = String(pair[1]).removingPercentEncoding
            else {
                throw QueryUtilitiesError.couldntRemovePercentEncoding(attribute: String(pair[0]),
                                                                        value: String(pair[1]))
            }
            
            parameters[attribute] = value
        }
        
        return parameters
    }
    
}
