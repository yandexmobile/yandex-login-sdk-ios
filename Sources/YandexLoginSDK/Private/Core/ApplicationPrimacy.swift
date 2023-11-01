
enum ApplicationPrimacy: String {
    
    case primary, secondary
    
    var scheme: String {
        switch self {
        case .primary:
            return "primaryyandexloginsdk"
        case .secondary:
            return "secondaryyandexloginsdk"
        }
    }
    
    static func primacies(for strategy: YandexLoginSDK.AuthorizationStrategy) -> [ApplicationPrimacy]? {
        switch strategy {
        case .webOnly:
            return nil
        case .`default`:
            return [.secondary, .primary]
        case .primaryOnly:
            return [.primary]
        }
    }
    
}
