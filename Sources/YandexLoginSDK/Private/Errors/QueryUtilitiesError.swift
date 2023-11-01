
enum QueryUtilitiesError: YandexLoginSDKError {
    
    case couldntPerformPercentEncoding(string: String)
    case invalidAmountOfElementsInComponent(elementCount: Int)
    case couldntRemovePercentEncoding(attribute: String, value: String)
    
    var message: String {
        var message: String
        
        switch self {
        case .couldntPerformPercentEncoding(let string):
            message = """
                      Couldn't perform percent encoding on a string.
                      - string: \(string)
                      """
        case .invalidAmountOfElementsInComponent(let elementCount):
            message = """
                      Couldn't split query string into query components. Each component must contain exactly 2 \
                      elements: an attribute and a value.
                      - elements in the component: \(elementCount)
                      """
        case .couldntRemovePercentEncoding(let attribute, let value):
            message = """
                      Couldn't remove percent encoding from attribute-value pair.
                      - attribute: "\(attribute)"
                      - value: "\(value)"
                      """
        }
        
        return message
    }
    
}
