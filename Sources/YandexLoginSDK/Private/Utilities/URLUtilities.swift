
import Foundation

enum URLUtilities {
    
    enum URLComponent {
        
        case query, fragment
        
    }
    
    enum URLComponentParameter: String {
        
        case state, uid, code, error
        case token = "access_token"
        
        var key: String { self.rawValue }
        
    }
    
    static func urlSchemeDefinedBySDK(forAppWith clientID: String) -> String {
        "yx\(clientID)"
    }
    
    static func isURLSchemeDefinedBySDK(url: URL, clientID: String) -> Bool {
        guard let scheme = url.scheme else { return false }
        return scheme == self.urlSchemeDefinedBySDK(forAppWith: clientID)
    }
    
    static func deepLinkForAppAuthorization(
        with parameters: AuthorizationParameters,
        primacy: ApplicationPrimacy
    ) throws -> URL {
        var components = URLComponents()
        components.scheme = primacy.scheme
        components.host = "/authorize"
        
        guard let path = components.url?.absoluteString else {
            throw URLUtilitiesError.couldntCreateURLFromURLComponents(urlComponents: components)
        }
        
        return try self.url(with: path, parameters: parameters)
    }
    
    static func universalLinkForAppAuthorization(
        with parameters: AuthorizationParameters,
        primacy: ApplicationPrimacy
    ) throws -> URL {
        var components = URLComponents()
        components.scheme = "https"
        components.host = HostProvider.host(for: .pssp)
        components.path = "/am/loginsdk/\(primacy.rawValue)"
        
        guard let path = components.url?.absoluteString else {
            throw URLUtilitiesError.couldntCreateURLFromURLComponents(urlComponents: components)
        }
        
        return try self.url(with: path, parameters: parameters)
    }
    
    static func urlForWebAuthorization(with parameters: AuthorizationParameters) throws -> URL {
        var components = URLComponents()
        components.scheme = "https"
        components.host = HostProvider.host(for: .oauth)
        components.path = "/authorize"
        
        guard let path = components.string else {
            throw URLUtilitiesError.couldntCreateURLFromURLComponents(urlComponents: components)
        }
        
        return try self.url(with: path, parameters: parameters, includingEnvironmentInfo: true)
    }
    
    static func urlComponentParameterValue(
        url: URL,
        component: URLComponent,
        pararmeter: URLComponentParameter
    ) throws -> String {
        let parameters = try self.urlComponentParameters(url: url, component: component)
        let key = pararmeter.key
        
        guard let value = parameters[key] else {
            throw URLUtilitiesError.absentValueForKeyInURLComponentParameters(key: key, parameters: parameters)
        }
        
        return value
    }
    
    private static func url(
        with path: String,
        parameters: AuthorizationParameters,
        includingEnvironmentInfo: Bool = false
    ) throws -> URL {
        var queryParameters = includingEnvironmentInfo ? EnvironmentInfo.parametersWithStringKeys : [:]
        queryParameters.merge(parameters.asDictionary) { (current, _) in current }
        queryParameters["force_confirm"] = "yes"
        queryParameters["force_fullscreen"] = "yes"
        
        if parameters.codeChallenge != nil {
            queryParameters["response_type"] = "code"
            queryParameters["redirect_uri"] = try self.redirectDeepLink(with: parameters.clientID)
        } else {
            queryParameters["response_type"] = "token"
            queryParameters["redirect_uri"] = try self.redirectUniversalLink(with: parameters.clientID)
        }
        queryParameters["origin"] = "yandex_auth_sdk_ios"
        
        let query = try QueryUtilities.query(from: queryParameters)
        let urlAsString = "\(path)?\(query)"
        guard let url = URL(string: urlAsString) else {
            throw URLUtilitiesError.couldntCreateURLFromString(string: urlAsString)
        }
        
        return url
    }
    
    private static func redirectDeepLink(with clientID: String) throws -> String {
        var components = URLComponents()
        components.scheme = self.urlSchemeDefinedBySDK(forAppWith: clientID)
        components.host = ""
        components.path = "/auth/finish"
        components.query = "platform=ios"
        
        guard let url = components.url else {
            throw URLUtilitiesError.couldntCreateURLFromURLComponents(urlComponents: components)
        }
        
        return url.absoluteString
    }
    
    private static func redirectUniversalLink(with clientID: String) throws -> String {
        var components = URLComponents()
        components.scheme = "https"
        components.host = "yx\(clientID).\(YandexLoginSDK.isInTestEnvironment ? "oauth-test" : "oauth").ru"
        components.path = "/auth/finish"
        components.query = "platform=ios"
        
        guard let url = components.url else {
            throw URLUtilitiesError.couldntCreateURLFromURLComponents(urlComponents: components)
        }
        
        return url.absoluteString
    }
    
    private static func urlComponentParameters(url: URL, component: URLComponent) throws -> [String: String] {
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
            throw URLUtilitiesError.couldntCreateURLComponentsFromURL(url: url)
        }
        
        switch component {
        case .query:
            guard let query = components.query else { return [:] }
            return try QueryUtilities.parameters(from: query)
        case .fragment:
            guard let fragment = components.fragment else { return [:] }
            return try QueryUtilities.parameters(from: fragment)
        }
    }
    
}
