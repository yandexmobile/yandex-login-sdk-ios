
enum ActivationError: YandexLoginSDKError {
    
    case absentQueriesScheme(scheme: String, primacies: [ApplicationPrimacy])
    case absentURLTypesScheme(scheme: String)
    
    var message: String {
        var message: String
        
        switch self {
        case .absentQueriesScheme(let scheme, let primacies):
            message = """
                      Couldn't find URL scheme in queries schemes. Add all schemes from the list below \
                      to an LSApplicationQueriesSchemes array in Info.plist file.
                      - absent scheme: \(scheme)
                      - schemes:
                      
                      """
            for primacy in primacies {
                message += "    - \(primacy.scheme)\n"
            }
        case .absentURLTypesScheme(let scheme):
            message = """
                      Couldn't find URL scheme in URL types. In Info.plist file one of dictionaries in \
                      CFBundleURLTypes array must contain a value for key CFBundleURLSchemes. This value must \
                      be an array containig the scheme.
                      - URL scheme: \(scheme)
                      """
        }
        
        return message
    }
    
}
