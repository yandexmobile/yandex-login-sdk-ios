
enum NetworkingError: YandexLoginSDKError {
    
    // ResponseParser errors
    case couldntCreateStringFromData
    case couldntCreateJSONObjectFromData
    case absentTokenInJSON(jsonObject: [String: Any])
    case invalidTokenType(tokenType: String)
    
    // HTTPOperation error
    case httpOperationAlreadyStarted
    
    // HTTPClient errors
    case unknownRequestComponentsProviderType(type: String)
    case emptyDataObject
    case invalidResponseType(type: String)
    case badStatusCode(code: Int)
    case couldntCreateURLFromString(_ string: String)
    case couldntCreateDataFromString(_ string: String)
    
    var message: String {
        var message: String
        
        switch self {
        case .couldntCreateStringFromData:
            message = "Couldn't create an instance of type String from Data using UTF-8 encoding."
        case .couldntCreateJSONObjectFromData:
            message = """
                      Couldn't create JSON object from an instance of type Data. \
                      Top-level JSON object must be a dictionary.
                      """
        case .absentTokenInJSON(let jsonObject):
            message = """
                      Couldn't retreive token from JSON dictionary by key "access_token".
                      - JSON dictionary:
                      
                      """
            for (key, value) in jsonObject {
                message += "    - \(key): \(value)\n"
            }
        case .invalidTokenType(let tokenType):
            message = """
                      Value for key "access_token" in JSON dictionary must be of type String.
                      - value type: \(tokenType)
                      """
            
            
        case .httpOperationAlreadyStarted:
            message = "Couldn't start a new operation. Already running some task."
            
            
        case .unknownRequestComponentsProviderType(let type):
            message = """
                      Encountered instance with unknown type conforming to RequestComponentsProvider protocol.
                      - instance type: \(type)
                      """
        case .emptyDataObject:
            message = "The data object is empty."
        case .invalidResponseType(let type):
            message = """
                      Invalid response type. Response must be of type HTTPURLResponse.
                      - response type: \(type)
                      """
        case .badStatusCode(let code):
            message = """
                      Bad status code. Status code must lie in range from 200 to 300.
                      - status code: \(code)
                      """
        case .couldntCreateURLFromString(let string):
            message = """
                      Couldn't create URL from String.
                      - string: \(string)
                      """
        case .couldntCreateDataFromString(let string):
            message = """
                      Couldn't create  Data from String using UTF-8 encoding.
                      - string: \(string)
                      """
        }
        
        return message
    }
    
}
