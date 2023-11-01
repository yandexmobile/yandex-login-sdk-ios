
enum ResponseParserFactory {
    
    static func parser(for components: any RequestComponentsProvider) -> (any ResponseParser)? {
        switch components {
        case is JWTRequestComponents:
            return JWTResponseParser()
        case is TokenRequestComponents:
            return TokenResponseParser()
        default:
            return nil
        }
    }
    
}
