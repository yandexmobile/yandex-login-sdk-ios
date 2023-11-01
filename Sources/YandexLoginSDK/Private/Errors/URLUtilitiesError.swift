
import Foundation

enum URLUtilitiesError: YandexLoginSDKError {
    
    case couldntCreateURLComponentsFromURL(url: URL)
    case absentValueForKeyInURLComponentParameters(key: String, parameters: [String: String])
    case couldntCreateURLFromURLComponents(urlComponents: URLComponents)
    case couldntCreateURLFromString(string: String)
    
    var message: String {
        var message: String
        
        switch self {
        case .couldntCreateURLComponentsFromURL(let url):
            message = """
                      Couldn't create URLComponents from URL.
                      - URL: \(url.absoluteString)
                      """
        case .absentValueForKeyInURLComponentParameters(let key, let parameters):
            message = """
                      Couldn't find value for key in URL component parameters.
                      - key: \(key)
                      - parameters:
                      
                      """
            for (key, value) in parameters {
                message.append("    \(key)=\(value)\n")
            }
        case .couldntCreateURLFromURLComponents(let components):
            let portAsString: String
            if let port = components.port {
                portAsString = String(port)
            } else {
                portAsString = "nil"
            }
            
            message = """
                      Couldn't create URL from URLComponents.
                      - URL components:
                          - scheme: \(components.scheme ?? "nil")
                          - user: \(components.user ?? "nil")
                          - password: \(components.password ?? "nil")
                          - host: \(components.host ?? "nil")
                          - port: \(portAsString)
                          - path: \(components.path)
                          - query: \(components.query ?? "nil")
                          - fragment: \(components.fragment ?? "nil")
                      """
        case .couldntCreateURLFromString(let string):
            message = """
                      Couldn't create URL from String.
                      - string: \(string)
                      """
        }
        
        return message
    }
    
}
